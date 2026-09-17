#!/usr/bin/env bash
# ===========================================================================================================================================
# Grafana Mimir App - Common Functions and Defaults
# ===========================================================================================================================================

set -Eeuo pipefail

# -------------------------------------------------------------------------------------------------------------------------------------------
# Central defaults.
#
# These values preserve the existing run.sh behaviour. The defaults are deliberately kept here instead of being repeated throughout scripts.
# Optional Home Assistant App settings remain hidden unless they are explicitly supplied in config.yaml/options.
# -------------------------------------------------------------------------------------------------------------------------------------------

readonly DEFAULT_LOG_LEVEL="warn"
readonly DEFAULT_RETENTION_PERIOD="180d"
readonly DEFAULT_AUTH_TOKEN_ENABLED="true"
readonly DEFAULT_AUTH_USER="homeassistant"
readonly DEFAULT_AUTH_TOKEN="mimir_secret_token_change_me"
readonly DEFAULT_CUSTOM_CONFIG="false"
readonly DEFAULT_CUSTOM_CONFIG_FILE="mimir.yaml"
readonly DEFAULT_MULTITENANCY_ENABLED="false"
readonly DEFAULT_DEFAULT_TENANT_ID="homeassistant"
readonly DEFAULT_STORAGE_BACKEND="filesystem"
readonly DEFAULT_STORAGE_PATH="/data/mimir"
readonly DEFAULT_S3_INSECURE="false"
readonly DEFAULT_S3_REGION="de-north-1"
readonly DEFAULT_TLS_ENABLED="true"
readonly DEFAULT_CERT_FILE="/ssl/fullchain.pem"
readonly DEFAULT_KEY_FILE="/ssl/privkey.pem"
# TODO: IMPLEMENT IN NGINX / ADD TEXTFIELD FOR CLIENT CERT
#
# DEFAULT_REQUIRE_CLIENT_AUTH="false"
readonly DEFAULT_MAX_GLOBAL_SERIES="250000"
readonly DEFAULT_INGESTION_RATE="25"
readonly DEFAULT_INGESTION_BURST_SIZE="50"
readonly DEFAULT_RULER_API_ENABLED="false"
readonly DEFAULT_ALERTMANAGER_API_ENABLED="false"
readonly DEFAULT_HTTP_PORT="9009"
readonly MIMIR_INTERNAL_HTTP_PORT="9008"
readonly DEFAULT_INGRESS_PORT="34520"
readonly DEFAULT_STARTUP_TIMEOUT="300"

readonly MIMIR_CONFIG_PATH="/config/generated_mimir.yaml"
readonly MIMIR_RUNTIME_DIR="/run/mimir"
readonly MIMIR_NGINX_CONF="/etc/nginx/http.d/mimir.conf"
readonly MIMIR_HEALTHCHECK_CONFIG="${MIMIR_RUNTIME_DIR}/healthcheck.conf"

# ---------------------------------------------------------------------
# Logging helpers with explicit timestamps.
# ---------------------------------------------------------------------

timestamp() {
    date '+%Y-%m-%dT%H:%M:%S%z'
}

log_info() {
    bashio::log.info "[$(timestamp)] $*"
}

log_warning() {
    bashio::log.warning "[$(timestamp)] $*"
}

log_error() {
    bashio::log.error "[$(timestamp)] $*"
}

# ----------------------------------------------------------------------------------------------------
# Read one option while distinguishing an explicitly configured value from an omitted optional value.
# ----------------------------------------------------------------------------------------------------

config_or_default() {
    local key="$1"
    local default_value="$2"

    bashio::config.has_value "${key}" \
        && bashio::config "${key}" \
        || printf '%s\n' "${default_value}"
}

# ---------------------------------------------------------------------
# Mimir/App version information.
# ---------------------------------------------------------------------

#readonly APP_VERSION="$(v=\"$(bashio::app.version 2>/dev/null)\"; echo \"${v:-unknown}\")"
readonly APP_VERSION="${BUILD_VERSION:-unknown}"
#readonly MIMIR_CORE_VERSION="$(v=\"$([ -x /usr/local/bin/mimir ] && /usr/local/bin/mimir -version 2>&1 | sed -n '1p' | sed -E 's/.*version[= ]([^ ,]+).*/\1/')\"; echo \"${v:-unknown}\")"
readonly MIMIR_CORE_VERSION="${MIMIR_VERSION:-unknown}"

log_info "Starting Grafana Mimir App ..."
log_info "App Version: ${APP_VERSION} | Mimir Version: ${MIMIR_CORE_VERSION}"

# ---------------------------------------------------------------------
# Boolean helper.
# ---------------------------------------------------------------------

is_true() {
    bashio::var.true "$1"
}
