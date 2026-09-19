#! /usr/bin/env bash

# shellcheck disable=SC2120
test_validate_nginx_complete_setup() {
    local nginx_script="${1:-mimir/rootfs/usr/local/lib/mimir/nginx.sh}"
    local ui_file="${2:-mimir/rootfs/var/www/mimir-ui/index.html}"

    log_test "Test 8: Validating complete Nginx configuration script & UI template..."

    local missing_patterns=()

    # 1. File existence and permissions check
    if [ ! -f "$nginx_script" ]; then
        fail "Nginx script missing: $nginx_script"
        return
    fi

    if [ ! -f "$ui_file" ]; then
        fail "UI index file missing: $ui_file"
        return
    fi

    if [ -x "$nginx_script" ]; then
        missing_patterns+=("File permissions: Script should not be executable (-x)")
    fi

    # 2. Native Bash syntax check
    if ! bash -n "$nginx_script" 2>/dev/null; then
        fail "Syntax error in script $nginx_script (bash -n failed)"
        return
    fi

    # 3. Critical single patterns (Must appear at least once)
    local required_single_patterns=(
        # Function & basic structure
        "mimir_configure_nginx"
        "DEFAULT_INGRESS_PORT"
        "MIMIR_PORT"
        "HTTP_PORT"

        # Server 1: Ingress Specifics
        "/var/www/mimir-ui"
        "location /proxy/mimir/"
        "proxy_set_header X-Ingress-Path"
        "location /healthz"
        "proxy_hide_header Content-Security-Policy"

        # Server 2: Public API & Security
        "client_max_body_size"
        "map \$http_authorization \$mimir_auth_ok"
        "map \\\$http_authorization \\\$mimir_auth_ok"
        "if (\\\$mimir_auth_ok = 0)"
        "return 401"
        "AUTH_TOKEN_ENABLED"
        "TLS_ENABLED"
        "ssl_certificate"

        # Validate Nginx syntax before completion
        "nginx -t"
    )

    for pattern in "${required_single_patterns[@]}"; do
        if ! grep -Fq -- "$pattern" "$nginx_script"; then
            missing_patterns+=("Skript-Muster fehlt: '$pattern'")
        fi
    done

    # 4. Critical multi-patterns (Must be present in BOTH server blocks: Count >= 2)
    # Format: "Pattern:MinCount"
    local required_multi_patterns=(
        "proxy_buffering off:2"
        "proxy_request_buffering off:2"
        "proxy_pass http://127.0.0.1:2"
        "proxy_set_header Upgrade:2"
        "proxy_read_timeout:2"
    )

    local pattern min_count actual_count
    for item in "${required_multi_patterns[@]}"; do
        pattern="${item%%:*}"
        min_count="${item##*:}"
        actual_count=$(grep -c -- "$pattern" "$nginx_script" 2>/dev/null || echo 0)

        if [ "$actual_count" -lt "$min_count" ]; then
            missing_patterns+=("Multi-pattern '$pattern' count insufficient (Expected: >=${min_count}, Found: ${actual_count})")
        fi
    done

    # 5. UI integrity check
    local required_ui_patterns=(
        "/services"
        "/config"
        "/metrics"
        "/ready"
    )

    for pattern in "${required_ui_patterns[@]}"; do
        if ! grep -q -- "$pattern" "$ui_file"; then
            missing_patterns+=("UI pattern missing: '$pattern'")
        fi
    done

    # 6. Final evaluation
    if [ ${#missing_patterns[@]} -gt 0 ]; then
        fail "Nginx script validation failed (${#missing_patterns[@]} error(s)): ${missing_patterns[*]}"
        return
    fi

    pass "Nginx script and UI template successfully validated"
    return
}
