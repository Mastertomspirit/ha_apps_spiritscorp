#!/usr/bin/env bash
# =====================================================================
# Grafana Mimir App - Process Startup and Shutdown
# =====================================================================

cleanup() {
    log_info "Received shutdown signal. Stopping services cleanly..."

    if [ -n "${STATS_PID:-}" ]; then
        kill -TERM "${STATS_PID}" 2>/dev/null || true
        wait "${STATS_PID}" 2>/dev/null || true
    fi

    if [ -n "${MIMIR_PID:-}" ]; then
        kill -TERM "${MIMIR_PID}" 2>/dev/null || true
        wait "${MIMIR_PID}" 2>/dev/null || true
    fi

    nginx -s quit 2>/dev/null || true
    exit 0
}

mimir_update_storage_stats() {
    local target_dir="${STORAGE_PATH:-/data/mimir}"
    local history_file="${target_dir}/.db-size-history.json"
    local runtime_file="${MIMIR_RUNTIME_DIR}/storage-stats.json"
    local tmp_history="${history_file}.tmp"
    local tmp_runtime="${runtime_file}.tmp"

    mkdir -p "${target_dir}" "${MIMIR_RUNTIME_DIR}" 2>/dev/null || true

    local kb_size=0
    if [ -d "${target_dir}" ]; then
        kb_size="$(du -sk "${target_dir}" 2>/dev/null | awk '{print $1}' || echo 0)"
    fi
    case "${kb_size}" in
        ''|*[!0-9]*) kb_size=0 ;;
    esac
    local current_bytes=$(( kb_size * 1024 ))
    local today
    today="$(date '+%Y-%m-%d')"
    local now_iso
    now_iso="$(date '+%Y-%m-%dT%H:%M:%S%z')"

    if command -v jq >/dev/null 2>&1; then
        local existing_history="[]"
        if [ -s "${history_file}" ] && jq -e 'type == "array"' "${history_file}" >/dev/null 2>&1; then
            existing_history="$(cat "${history_file}")"
        fi

        local updated_history
        updated_history="$(printf '%s' "${existing_history}" | jq -c --arg d "${today}" --argjson b "${current_bytes}" '
            map(select(.date != $d)) + [{date: $d, bytes: $b}]
            | sort_by(.date)
            | .[-90:]
        ' 2>/dev/null || printf '[{"date":"%s","bytes":%s}]' "${today}" "${current_bytes}")"

        printf '%s\n' "${updated_history}" > "${tmp_history}" && mv -f "${tmp_history}" "${history_file}"

        printf '%s' "${updated_history}" | jq -c \
            --arg path "${target_dir}" \
            --arg updated "${now_iso}" \
            --argjson cur "${current_bytes}" '
            . as $hist
            | ($hist | length) as $cnt
            | (if $cnt > 0 then (($hist | map(.bytes) | add) / $cnt | floor) else $cur end) as $avg_total
            | (if $cnt > 1 then ((($hist[-1].bytes - $hist[0].bytes) / ($cnt - 1)) | floor) else 0 end) as $avg_growth
            | {
                current_bytes: $cur,
                storage_path: $path,
                updated_at: $updated,
                days_tracked: $cnt,
                daily_avg_bytes: $avg_total,
                daily_growth_avg_bytes: $avg_growth,
                history: $hist
              }
        ' > "${tmp_runtime}" && mv -f "${tmp_runtime}" "${runtime_file}"
    else
        cat > "${tmp_runtime}" <<EOF_STATS
{"current_bytes":${current_bytes},"storage_path":"${target_dir}","updated_at":"${now_iso}","days_tracked":1,"daily_avg_bytes":${current_bytes},"daily_growth_avg_bytes":0,"history":[{"date":"${today}","bytes":${current_bytes}}]}
EOF_STATS
        mv -f "${tmp_runtime}" "${runtime_file}"
    fi
}

mimir_start_stats_loop() {
    while true; do
        sleep 300 &
        wait $! 2>/dev/null || break
        mimir_update_storage_stats || true
    done
}

mimir_start() {
    trap cleanup SIGTERM SIGINT

    mkdir -p "${MIMIR_RUNTIME_DIR}"

    # Export the runtime healthcheck parameters for Docker HEALTHCHECK.
    cat > "${MIMIR_HEALTHCHECK_CONFIG}" <<EOF_HEALTHCHECK
SCHEME=http
PORT=${MIMIR_PORT}
ADDRESS=127.0.0.1
SERVER_NAME=
CA_FILE=
EOF_HEALTHCHECK

    log_info "Launching Grafana Mimir using '${CONFIG_PATH}'..."
    START_TIME="$(date +%s)"

    /usr/local/bin/mimir \
        -config.file="${CONFIG_PATH}" \
        -log.level="${LOG_LEVEL}" &
    MIMIR_PID=$!

    log_info "Waiting for Grafana Mimir readiness..."

    while kill -0 "${MIMIR_PID}" 2>/dev/null; do
        if /usr/local/bin/mimir-healthcheck; then
            END_TIME="$(date +%s)"
            log_info "Grafana Mimir is ready after $((END_TIME - START_TIME)) seconds."
            break
        fi
        sleep 1
    done

    if ! kill -0 "${MIMIR_PID}" 2>/dev/null; then
        wait "${MIMIR_PID}"
        local exit_code=$?
        log_error "Grafana Mimir terminated during startup with exit code ${exit_code}."
        exit "${exit_code}"
    fi

    mimir_update_storage_stats || true
    mimir_start_stats_loop &
    STATS_PID=$!

    log_info "Starting nginx reverse proxy (Ingress: ${DEFAULT_INGRESS_PORT}, API: ${HTTP_PORT})..."
    nginx

    wait "${MIMIR_PID}"
    local exit_code=$?
    log_info "Grafana Mimir terminated with exit code ${exit_code}."
    exit "${exit_code}"
}
