#!/bin/bash
# Health check: validates that installed tools are accessible.
# Usage: ./entrypoint.sh healthcheck [module1 module2 ...]
# If no modules specified, checks all modules.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

TOOLS_JSON="${SCRIPT_DIR}/../config/tools.json"

function healthcheck() {
    local modules=("$@")
    local total=0
    local passed=0
    local failed=0
    local failed_tools=()

    if [ ! -f "$TOOLS_JSON" ]; then
        criticalecho "tools.json not found at $TOOLS_JSON"
        return 1
    fi

    # If no modules specified, detect from args
    if [ ${#modules[@]} -eq 0 ]; then
        modules=($(python3 -c "
import json, sys
with open('$TOOLS_JSON') as f:
    data = json.load(f)
for key in data:
    print(key)
"))
    fi

    colorecho "Running health check for modules: ${modules[*]}"
    echo ""

    for module in "${modules[@]}"; do
        local tools_data
        tools_data=$(python3 -c "
import json, sys
with open('$TOOLS_JSON') as f:
    data = json.load(f)
module = data.get('$module', [])
for tool in module:
    cmd = tool.get('cmd') or ''
    check_path = tool.get('check_path') or ''
    name = tool['name']
    print(f'{name}\t{cmd}\t{check_path}')
" 2>/dev/null)

        if [ -z "$tools_data" ]; then
            continue
        fi

        colorecho "[$module]"

        while IFS=$'\t' read -r name cmd check_path; do
            total=$((total + 1))

            if [ -n "$check_path" ] && [ -z "$cmd" ]; then
                # Check by path (for resources/wordlists)
                if [ -e "$check_path" ]; then
                    echo "  ✓ $name ($check_path)"
                    passed=$((passed + 1))
                else
                    echo "  ✗ $name — path not found: $check_path"
                    failed=$((failed + 1))
                    failed_tools+=("$name")
                fi
            elif [ -n "$cmd" ]; then
                # Check by command
                if command -v "$cmd" > /dev/null 2>&1; then
                    echo "  ✓ $name ($cmd)"
                    passed=$((passed + 1))
                else
                    echo "  ✗ $name — command not found: $cmd"
                    failed=$((failed + 1))
                    failed_tools+=("$name")
                fi
            fi
        done <<< "$tools_data"

        echo ""
    done

    colorecho "Health check results: $passed/$total passed, $failed failed"

    if [ $failed -gt 0 ]; then
        colorecho "Failed tools: ${failed_tools[*]}"
        return 1
    fi

    colorecho "All tools OK"
    return 0
}
