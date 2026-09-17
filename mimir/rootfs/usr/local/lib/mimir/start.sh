#!/usr/bin/env bash
# =====================================================================
# Grafana Mimir App - Process Startup and Shutdown
# =====================================================================

cleanup() {
    log_info "Received shutdown signal. Stopping services cleanly..."

    if [ -n "${MIMIR_PID:-}" ]; then
        kill -TERM "${MIMIR_PID}" 2>/dev/null || true
        wait "${MIMIR_PID}" 2>/dev/null || true
    fi

    nginx -s quit 2>/dev/null || true
    exit 0
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

    log_info "Starting nginx reverse proxy (Ingress: ${DEFAULT_INGRESS_PORT}, API: ${HTTP_PORT})..."
    nginx

    wait "${MIMIR_PID}"
    local exit_code=$?
    log_info "Grafana Mimir terminated with exit code ${exit_code}."
    exit "${exit_code}"
}
