#!/usr/bin/env bash

test_validate_translations() {
    local config_file="mimir/config.yaml"

    # List of translation files to validate (e.g., German and English)
    local translation_files=(
        "mimir/translations/de.yaml"
        "mimir/translations/en.yaml"
    )

    log_test "Validating schema configuration & translation files (DE & EN)..."

    local missing_patterns=()

    # 1. Existence check for config.yaml
    if [ ! -f "$config_file" ]; then
        fail "Configuration file missing: $config_file"
        return
    fi

    # Check existence of all translation files
    for trans_file in "${translation_files[@]}"; do
        if [ ! -f "$trans_file" ]; then
            fail "Translation file missing: $trans_file"
            return
        fi
    done

    # 2. Extract schema keys from config.yaml
    local schema_keys=()
    if command -v python3 >/dev/null 2>&1; then
        mapfile -t schema_keys < <(python3 -c "
import yaml
try:
    with open('$config_file') as f:
        data = yaml.safe_load(f)
    schema = data.get('schema', {})
    for k in schema.keys():
        print(k)
except Exception:
    pass
" 2>/dev/null)
    elif command -v yq >/dev/null 2>&1; then
        mapfile -t schema_keys < <(yq eval '.schema | keys | .[]' "$config_file" 2>/dev/null)
    else
        # Native fallback via sed/grep if no YAML parser is installed
        mapfile -t schema_keys < <(sed -n '/^schema:/,/^[a-zA-Z]/p' "$config_file" | grep -E '^[[:space:]]+[a-zA-Z0-9_]+:' | sed -E 's/^[[:space:]]+([a-zA-Z0-9_]+):.*/\1/')
    fi

    if [ ${#schema_keys[@]} -eq 0 ]; then
        fail "No schema keys found or failed to parse schema in $config_file"
        return
    fi

    # 3. Verify each schema key exists in every translation file
    for trans_file in "${translation_files[@]}"; do
        for key in "${schema_keys[@]}"; do
            [ -z "$key" ] && continue

            # Checks if the option key is present in the configuration section
            if ! grep -q -E "^[[:space:]]*${key}:" "$trans_file"; then
                missing_patterns+=("Missing translation key '$key' in $trans_file")
            fi
        done
    done

    # 4. Final evaluation
    if [ ${#missing_patterns[@]} -gt 0 ]; then
        fail "Translation validation failed (${#missing_patterns[@]} error(s)): ${missing_patterns[*]}"
        return
    fi

    pass "All schema options successfully verified across translation files"
    return
}
