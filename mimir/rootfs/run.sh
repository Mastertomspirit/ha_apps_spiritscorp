#!/usr/bin/env bashio
# =====================================================================
# Home Assistant App Startup Entrypoint: Grafana Mimir
# Repository: https://github.com/mastertomspirit/ha_apps_spiritscorp
# =====================================================================

set -Eeuo pipefail

source /usr/local/lib/mimir/common.sh
source /usr/local/lib/mimir/config.sh
source /usr/local/lib/mimir/nginx.sh
source /usr/local/lib/mimir/start.sh

mimir_load_options
mimir_prepare_config
mimir_validate_tls
mimir_validate_config
mimir_configure_nginx
mimir_start
