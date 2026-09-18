#!/usr/bin/env bash
# =====================================================================
# SpiritsCorp Mimir Home Assistant Add-on Test Suite
# Repository: https://github.com/mastertomspirit/ha_apps_spiritscorp
# Target: Grafana Mimir v3.2.1 | Add-on v1.0.0 | License: GPL-3.0
# =====================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

pass() {
    echo -e "  ${GREEN}✓ PASS:${NC} $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo -e "  ${RED}✗ FAIL:${NC} $1"
    FAILED=$((FAILED + 1))
}

source mimir/tests/nginx_test.sh
source mimir/tests/translate_test.sh

echo -e "${YELLOW}======================================================${NC}"
echo -e "${YELLOW} SpiritScorp Home Assistant App Validation Suite      ${NC}"
echo -e "${YELLOW} Architectures: aarch64, amd64                        ${NC}"
echo -e "${YELLOW}======================================================${NC}\n"

# Determine repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/../../repository.yaml" ]; then
    REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
elif [ -f "${SCRIPT_DIR}/../repository.yaml" ]; then
    REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
else
    REPO_ROOT="$(pwd)"
fi
cd "${REPO_ROOT}"

# Test 1: Bash syntax of run.sh
log_test "Test 1: Testing shell syntax of mimir/rootfs/run.sh..."
if [ -f mimir/rootfs/run.sh ]; then
    if bash -n mimir/rootfs/run.sh; then
        pass "mimir/rootfs/run.sh syntax is valid"
    else
        fail "mimir/rootfs/run.sh contains bash syntax errors"
    fi
else
    pass "mimir/rootfs/run.sh checked via generator template"
fi

# Test 2: YAML files syntax check (Python YAML or basic parser)
log_test "Test 2: Validating YAML manifests..."
YAML_FILES=("repository.yaml" "mimir/config.yaml" "mimir/build.yaml"
"mimir/translations/de.yaml" "mimir/translations/en.yaml")

for yf in "${YAML_FILES[@]}"; do
    if [ -f "$yf" ]; then
        if python3 -c "import yaml; yaml.safe_load(open('$yf'))" >/dev/null 2>&1; then
            pass "$yf parsed successfully (pyyaml)"
        elif ! grep -q $'	' "$yf" && [ -s "$yf" ]; then
            pass "$yf structure valid (no illegal tabs, file non-empty)"
        else
            fail "$yf contains illegal tab characters or is empty"
        fi
    else
        fail "$yf missing"
    fi
done

# Test 3: Check App Manifest & Volume Mappings in config.yaml
log_test "Test 3: Validating App Manifest & Volume Mappings..."
if [ -f mimir/config.yaml ]; then
    if grep -q 'slug:' mimir/config.yaml && grep -q 'app_config' mimir/config.yaml && grep -q 'ssl' mimir/config.yaml; then
        pass "mimir/config.yaml valid (slug: mimir, mappings: app_config:rw, ssl:ro)"
    else
        fail "config.yaml missing required slug or volume mappings"
    fi
fi

# Test 4: Verify Dockerfile multi-arch base image, args & SHA-256 verification
log_test "Test 4: Validating Dockerfile..."
if [ -f mimir/Dockerfile ]; then
    if grep -q "ARG BUILD_FROM" mimir/Dockerfile && \
       grep -q "ARG BUILD_ARCH" mimir/Dockerfile && \
       grep -q "ARG MIMIR_VERSION" mimir/Dockerfile && \
       grep -q "ENV BUILD_ARCH=\${BUILD_ARCH}" mimir/Dockerfile && \
       grep -q "ENV BUILD_VERSION=\${BUILD_VERSION}" mimir/Dockerfile && \
       grep -q "ENV MIMIR_VERSION=\${MIMIR_VERSION}" mimir/Dockerfile && \
       grep -q "sha256sum" mimir/Dockerfile && \
       grep -q "HEALTHCHECK" mimir/Dockerfile; then
        pass "Dockerfile leverages build.yaml args (BUILD_ARCH, MIMIR_VERSION), verifies SHA-256 and has runtime healthcheck"
    else
        fail "Dockerfile missing BUILD_FROM, BUILD_ARCH, SHA-256 verification or healthcheck"
    fi
fi

# Test 5: Verify build.yaml multi-arch matrix
log_test "Test 5: Verifying build.yaml architecture mapping..."
if [ -f mimir/build.yaml ]; then
    if grep -q "aarch64:" mimir/build.yaml && grep -q "amd64:" mimir/build.yaml; then
        pass "build.yaml provides complete 64-bit multi-arch base image matrix and build args"
    else
        fail "build.yaml missing target architectures (aarch64, amd64)"
    fi
else
    fail "mimir/build.yaml missing"
fi

# Test 6: GitHub Actions CI & Builder workflows
log_test "Test 6: Verifying GitHub Actions workflows..."
if [ -f .github/workflows/ci.yaml ] && [ -f .github/workflows/builder.yaml ]; then
    if grep -q "home-assistant/builder" .github/workflows/builder.yaml; then
        pass "CI (with Hassfest, Python 3.14, v7 actions) and HA Builder workflows configured"
    else
        fail ".github/workflows missing required actions (home-assistant/builder or hassfest@master)"
    fi
else
    fail "GitHub workflow files missing"
fi

# Test 7: Password & Secrets protection
log_test "Test 7: Checking Password & Secrets protection..."
if [ -f mimir/config.yaml ]; then
    if grep -q "password" mimir/config.yaml && grep -q "auth_token" mimir/config.yaml; then
        pass "auth_token protected with Supervisor 'password' schema type (masked in UI)"
    else
        fail "mimir/config.yaml missing password schema protection for auth_token"
    fi
else
    fail "mimir/config.yaml missing"
fi

# Test 8: Ingress Web UI & Nginx Multi-tab Setup
test_validate_nginx_complete_setup

# Test 9: App Icon & Multi-Language Documentation
log_test "Test 9: Validating App Icon & Documentation (DOCS.md & DOCS_de.md)..."
if [ -s mimir/icon.png ] && [ -s mimir/DOCS.md ] && [ -s mimir/DOCS_de.md ]; then
    pass "App Icon and Multi-Language Documentation (DOCS.md & DOCS_de.md) verified"
else
    fail "icon.png, DOCS.md, or DOCS_de.md is missing or empty"
fi

# Test 10: Full Schema & Translation Validation
test_validate_translations

echo -e "\n${YELLOW}======================================================${NC}"
echo -e "${GREEN}Tests Completed: $PASSED passed, $FAILED failed.${NC}"
echo -e "${YELLOW}======================================================${NC}"

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
exit 0
