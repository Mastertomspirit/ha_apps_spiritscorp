#!/usr/bin/env bash

# shellcheck shell=bash disable=SC2034

# ===============================================================================================================================================
# Grafana Mimir App - Option Loading and Mimir Configuration
# ===============================================================================================================================================

# -----------------------------------------------------------------------------------------------------------------------------------------------
# Read Home Assistant App options.
#
# Only the options listed under 'options:' in config.yaml are shown in the Home Assistant UI. Optional schema-only values are read when an
# explicit value exists; otherwise the existing application defaults are used here without exposing them in the UI.
# -----------------------------------------------------------------------------------------------------------------------------------------------

mimir_load_options() {
    bashio::config.has_value 'log_level' && LOG_LEVEL="$(bashio::config 'log_level')" || LOG_LEVEL="${DEFAULT_LOG_LEVEL}"
    bashio::config.has_value 'retention_period' && RETENTION_PERIOD="$(bashio::config 'retention_period')" || RETENTION_PERIOD="${DEFAULT_RETENTION_PERIOD}"
    bashio::config.has_value 'auth_token_enabled' && AUTH_TOKEN_ENABLED="$(bashio::config 'auth_token_enabled')" || AUTH_TOKEN_ENABLED="${DEFAULT_AUTH_TOKEN_ENABLED}"
    bashio::config.has_value 'auth_user' && AUTH_USER="$(bashio::config 'auth_user')" || AUTH_USER="${DEFAULT_AUTH_USER}"
    bashio::config.has_value 'auth_token' && AUTH_TOKEN="$(bashio::config 'auth_token')" || AUTH_TOKEN="${DEFAULT_AUTH_TOKEN}"
    bashio::config.has_value 'custom_config' && CUSTOM_CONFIG_ENABLED="$(bashio::config 'custom_config')" || CUSTOM_CONFIG_ENABLED="${DEFAULT_CUSTOM_CONFIG}"
    bashio::config.has_value 'custom_config_file' && CUSTOM_CONFIG_FILE="$(bashio::config 'custom_config_file')" || CUSTOM_CONFIG_FILE="${DEFAULT_CUSTOM_CONFIG_FILE}"

    bashio::config.has_value 'multitenancy_enabled' && MULTITENANCY_ENABLED="$(bashio::config 'multitenancy_enabled')" || MULTITENANCY_ENABLED="${DEFAULT_MULTITENANCY_ENABLED}"
    bashio::config.has_value 'default_tenant_id' && DEFAULT_TENANT="$(bashio::config 'default_tenant_id')" || DEFAULT_TENANT="${DEFAULT_DEFAULT_TENANT_ID}"
#    bashio::config.has_value 'tenants' && TENANTS="$(bashio::config 'tenants')" || TENANTS=""

    bashio::config.has_value 'storage_backend' && STORAGE_BACKEND="$(bashio::config 'storage_backend')" || STORAGE_BACKEND="${DEFAULT_STORAGE_BACKEND}"
    bashio::config.has_value 'storage_path' && STORAGE_PATH="$(bashio::config 'storage_path')" || STORAGE_PATH="${DEFAULT_STORAGE_PATH}"
    bashio::config.has_value 's3_endpoint' && S3_ENDPOINT="$(bashio::config 's3_endpoint')" || S3_ENDPOINT=""
    bashio::config.has_value 's3_bucket_name' && S3_BUCKET="$(bashio::config 's3_bucket_name')" || S3_BUCKET=""
    bashio::config.has_value 's3_access_key' && S3_ACCESS_KEY="$(bashio::config 's3_access_key')" || S3_ACCESS_KEY=""
    bashio::config.has_value 's3_secret_key' && S3_SECRET_KEY="$(bashio::config 's3_secret_key')" || S3_SECRET_KEY=""
    bashio::config.has_value 's3_insecure' && S3_INSECURE="$(bashio::config 's3_insecure')" || S3_INSECURE="${DEFAULT_S3_INSECURE}"
    bashio::config.has_value 's3_region' && S3_REGION="$(bashio::config 's3_region')" || S3_REGION="${DEFAULT_S3_REGION}"

    bashio::config.has_value 'tls_enabled' && TLS_ENABLED="$(bashio::config 'tls_enabled')" || TLS_ENABLED="${DEFAULT_TLS_ENABLED}"
    bashio::config.has_value 'certfile' && CERT_FILE="$(bashio::config 'certfile')" || CERT_FILE="${DEFAULT_CERT_FILE}"
    bashio::config.has_value 'keyfile' && KEY_FILE="$(bashio::config 'keyfile')" || KEY_FILE="${DEFAULT_KEY_FILE}"
#    TODO: set settings in nginx.sh
#    bashio::config.has_value 'client_ca_file' && CLIENT_CA_FILE="$(bashio::config 'client_ca_file')" || CLIENT_CA_FILE=""
#    bashio::config.has_value 'require_client_auth' && REQUIRE_CLIENT_AUTH="$(bashio::config 'require_client_auth')" || REQUIRE_CLIENT_AUTH="${DEFAULT_REQUIRE_CLIENT_AUTH}"

    bashio::config.has_value 'max_global_series_per_user' && MAX_SERIES="$(bashio::config 'max_global_series_per_user')" || MAX_SERIES="${DEFAULT_MAX_GLOBAL_SERIES}"
    bashio::config.has_value 'ingestion_rate_mb' && INGESTION_RATE_OPTION="$(bashio::config 'ingestion_rate_mb')" || INGESTION_RATE_OPTION="${DEFAULT_INGESTION_RATE}"
    bashio::config.has_value 'ingestion_burst_size_mb' && INGESTION_BURST_OPTION="$(bashio::config 'ingestion_burst_size_mb')" || INGESTION_BURST_OPTION="${DEFAULT_INGESTION_BURST_SIZE}"

    bashio::config.has_value 'ruler_api_enabled' && RULER_ENABLED="$(bashio::config 'ruler_api_enabled')" || RULER_ENABLED="${DEFAULT_RULER_API_ENABLED}"
    bashio::config.has_value 'alertmanager_api_enabled' && ALERTMANAGER_ENABLED="$(bashio::config 'alertmanager_api_enabled')" || ALERTMANAGER_ENABLED="${DEFAULT_ALERTMANAGER_API_ENABLED}"

    bashio::config.has_value 'http_listen_port' && HTTP_PORT="$(bashio::config 'http_listen_port')" || HTTP_PORT="${DEFAULT_HTTP_PORT}"
    MIMIR_PORT="${MIMIR_INTERNAL_HTTP_PORT}"

    # Preserve the existing option semantics: ingestion_rate and ingestion_burst_size are expressed 
    # in the existing MB/s-style app options and converted to the samples/s values expected by Mimir.
    INGEST_RATE=$(( INGESTION_RATE_OPTION * 1000 ))
    INGEST_BURST=$(( INGESTION_BURST_OPTION * 1000 ))

    log_info "Multi-tenancy enabled: ${MULTITENANCY_ENABLED}"
    log_info "Default tenant ID: ${DEFAULT_TENANT}"
    log_info "Retention period: ${RETENTION_PERIOD}"
    log_info "Storage backend: ${STORAGE_BACKEND} (Path: ${STORAGE_PATH})"
    log_info "Ingestion rate: ${INGESTION_RATE_OPTION} MB/s -> ${INGEST_RATE} samples/s (Burst: ${INGESTION_BURST_OPTION} MB/s -> ${INGEST_BURST} samples/s)"
    log_info "Ruler API: ${RULER_ENABLED} | Alertmanager API: ${ALERTMANAGER_ENABLED}"
    log_info "Log level: ${LOG_LEVEL}"
    log_info "TLS enabled: ${TLS_ENABLED}"
}

_mimir_select_config() {
    CONFIG_PATH="${MIMIR_CONFIG_PATH}"

    if is_true "${CUSTOM_CONFIG_ENABLED}"; then
        CUSTOM_CONFIG_PATH="/homeassistant/${CUSTOM_CONFIG_FILE}";

        if [ ! -f "${CUSTOM_CONFIG_PATH}" ]; then
            log_error "Custom configuration was enabled, but '${CUSTOM_CONFIG_PATH}' does not exist."
            exit 1
        fi

        CONFIG_PATH="${CUSTOM_CONFIG_PATH}"
        log_info "CUSTOM CONFIGURATION ACTIVE: ${CONFIG_PATH}"
    fi

    readonly CONFIG_PATH
}

_mimir_render_common() {
    if [ "${STORAGE_BACKEND}" = "s3" ] || [ "${STORAGE_BACKEND}" = "minio" ]; then
        COMMON_YAML="common:
  storage:
    backend: s3
    s3:
      endpoint: ${S3_ENDPOINT}
      access_key_id: ${S3_ACCESS_KEY}
      secret_access_key: ${S3_SECRET_KEY}
      insecure: ${S3_INSECURE}
      region: ${S3_REGION}"
    else
        COMMON_YAML="common:
  storage:
    backend: filesystem
    filesystem:
      dir: ${STORAGE_PATH}/data"
    fi
}

_mimir_render_storage() {
    if [ "${STORAGE_BACKEND}" = "s3" ] || [ "${STORAGE_BACKEND}" = "minio" ]; then
        STORAGE_YAML="blocks_storage:
  s3:
    bucket_name: ${S3_BUCKET}"
    else
        STORAGE_YAML="blocks_storage:
  filesystem:
    dir: ${STORAGE_PATH}/blocks"
    fi
}

_mimir_render_ruler() {
    if bashio::var.true "${RULER_ENABLED}"; then
        if [ "${STORAGE_BACKEND}" = "s3" ] || [ "${STORAGE_BACKEND}" = "minio" ]; then
            RULER_YAML="ruler:
  rule_path: ${STORAGE_PATH}/ruler

ruler_storage:
  s3:
    bucket_name: mimir-ruler"
        else
            RULER_YAML="ruler:
  rule_path: ${STORAGE_PATH}/ruler

ruler_storage:
  filesystem:
    dir: ${STORAGE_PATH}/ruler-storage"
        fi
    else
        RULER_YAML=""
    fi
}

_mimir_render_alertmanager() {
    if bashio::var.true "${ALERTMANAGER_ENABLED}"; then
        if [ "${STORAGE_BACKEND}" = "s3" ] || [ "${STORAGE_BACKEND}" = "minio" ]; then
            ALERTMANAGER_YAML="alertmanager:
  data_dir: ${STORAGE_PATH}/alertmanager

alertmanager_storage:
  s3:
    bucket_name: mimir-alertmanager"
        else
            ALERTMANAGER_YAML="alertmanager:
  data_dir: ${STORAGE_PATH}/alertmanager

alertmanager_storage:
  filesystem:
    dir: ${STORAGE_PATH}/alertmanager-storage"
        fi
    else
        ALERTMANAGER_YAML=""
    fi
}

_mimir_render_auth() {
    AUTH_YAML="multitenancy_enabled: ${MULTITENANCY_ENABLED}"

    if ! is_true "${MULTITENANCY_ENABLED}"; then
        AUTH_YAML="${AUTH_YAML}
no_auth_tenant: \"${DEFAULT_TENANT}\""
    fi
}

mimir_prepare_config() {
    _mimir_select_config

    if [ "${CONFIG_PATH}" != "${MIMIR_CONFIG_PATH}" ]; then
        return
    fi

    log_info "Rendering managed Mimir configuration at ${CONFIG_PATH}..."

    mkdir -p \
        "${STORAGE_PATH}/blocks" \
        "${STORAGE_PATH}/tsdb" \
        "${STORAGE_PATH}/tsdb-sync" \
        "${STORAGE_PATH}/compactor" \
        "${STORAGE_PATH}/rules" \
        "${STORAGE_PATH}/alertmanager"

    chmod -R 775 "${STORAGE_PATH}" || true

    _mimir_render_common
    _mimir_render_storage
    _mimir_render_ruler
    _mimir_render_alertmanager
    _mimir_render_auth

    cat > "${CONFIG_PATH}" <<EOF_MIMIR
# =====================================================================================
# Grafana Mimir Managed Configuration (Auto-generated from Home Assistant App options)
# =====================================================================================

target: all

${AUTH_YAML}

server:
  http_listen_port: ${MIMIR_PORT}
  log_level: ${LOG_LEVEL}
  graceful_shutdown_timeout: 30s

${COMMON_YAML}

${STORAGE_YAML}
  tsdb:
    dir: ${STORAGE_PATH}/tsdb
    block_ranges_period: [2h]
    ship_concurrency: 10
  bucket_store:
    sync_dir: ${STORAGE_PATH}/tsdb-sync
#    lazy_index_loading_enabled: false

compactor:
  data_dir: ${STORAGE_PATH}/compactor
  compaction_interval: 30m
  compaction_concurrency: 2
  deletion_delay: 2h
  sharding_ring:
    kvstore:
      store: inmemory

distributor:
  ring:
    instance_addr: "127.0.0.1"
    kvstore:
      store: inmemory

ingester:
  ring:
    instance_addr: "127.0.0.1"
    kvstore:
      store: inmemory
    replication_factor: 1

store_gateway:
  sharding_ring:
    replication_factor: 1
    kvstore:
      store: inmemory

querier:
  max_concurrent: 16
  timeout: 2m

query_scheduler:
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

${RULER_YAML}

${ALERTMANAGER_YAML}

limits:
  max_global_series_per_user: ${MAX_SERIES}
  ingestion_rate: ${INGEST_RATE}
  ingestion_burst_size: ${INGEST_BURST}
  max_label_name_length: 1024
  max_label_value_length: 4096
  max_label_names_per_series: 64
  compactor_blocks_retention_period: ${RETENTION_PERIOD}
EOF_MIMIR

    log_info "Managed Mimir configuration rendered successfully."
}

mimir_validate_tls() {
    if ! is_true "${TLS_ENABLED}"; then
        return
    fi

    if [ "${CONFIG_PATH}" != "${MIMIR_CONFIG_PATH}" ]; then
        return
    fi

    log_info "Validating TLS certificates..."

    [ -f "${CERT_FILE}" ] || { log_error "Certificate file '${CERT_FILE}' was not found."; exit 1; }
    [ -f "${KEY_FILE}" ] || { log_error "Private key file '${KEY_FILE}' was not found."; exit 1; }

#    if is_true "${REQUIRE_CLIENT_AUTH}" && [ ! -f "${CLIENT_CA_FILE}" ]; then
#        log_error "Client CA file '${CLIENT_CA_FILE}' was not found while client authentication is enabled."
#        exit 1
#    fi

    # The HA ssl mapping supplies the certificate. Use its first DNS SAN
    # as the backend TLS hostname so nothing is hard-coded to one host.
    MIMIR_SERVER_NAME="$(openssl x509 -in "${CERT_FILE}" -noout -ext subjectAltName 2>/dev/null \
        | tr ',' '\n' \
        | sed -n 's/^[[:space:]]*DNS:[[:space:]]*//p' \
        | head -n 1 \
        | tr -d '[:space:]')"

    if [ -z "${MIMIR_SERVER_NAME}" ]; then
        log_error "Could not determine a DNS name from '${CERT_FILE}'."
        log_error "A TLS certificate with a DNS subjectAltName is required for verified internal HTTPS."
        exit 1
    fi

    export MIMIR_SERVER_NAME
    log_info "TLS backend server name determined from certificate: ${MIMIR_SERVER_NAME}"
}

mimir_validate_config() {
    mkdir -p "${MIMIR_RUNTIME_DIR}"

    log_info "Validating Mimir configuration with '-modules'..."
    if ! /usr/local/bin/mimir -modules -config.file="${CONFIG_PATH}" >"${MIMIR_RUNTIME_DIR}/config-validation.log" 2>&1; then
        log_error "Mimir configuration validation failed."
        cat "${MIMIR_RUNTIME_DIR}/config-validation.log"
        exit 1
    fi

    log_info "Mimir configuration validation successful."
}
