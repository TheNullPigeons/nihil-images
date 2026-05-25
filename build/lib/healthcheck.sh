#!/bin/bash
# Health check: validates that installed tools are accessible.
# Usage: ./entrypoint.sh healthcheck [module1 module2 ...]
# If no modules specified, checks all modules.

nihil::import lib/common

TOOLS_JSON="${NIHIL_BUILD}/config/tools.json"

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
    print(f'{name}|{cmd}|{check_path}')
" 2>/dev/null)

        if [ -z "$tools_data" ]; then
            continue
        fi

        colorecho "[$module]"

        # Add binary dirs to PATH for healthcheck since we're not running in a full login shell here
        export PATH="/opt/tools/bin:/root/.local/bin:/root/.cargo/bin:/root/go/bin:${PATH}"

        while IFS='|' read -r name cmd check_path; do
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

# Usage: filter_tools_json module1 module2 ...
# Rewrites tools.json to only contain the specified modules.
function filter_tools_json() {
    local modules=("$@")
    python3 - "$TOOLS_JSON" "${modules[@]}" << 'PYEOF'
import json, sys
path = sys.argv[1]
keep = set(sys.argv[2:])
with open(path) as f:
    data = json.load(f)
filtered = {k: v for k, v in data.items() if k in keep}
with open(path, 'w') as f:
    json.dump(filtered, f, indent=4)
    f.write('\n')
PYEOF
    colorecho "tools.json filtered to: ${modules[*]}"
}

# Usage: list_tools [module1 module2 ...]
# Lists all tools from tools.json with name, command and description.
# Without arguments, lists all modules.
function list_tools() {
    local modules=("$@")

    if [ ! -f "$TOOLS_JSON" ]; then
        criticalecho "tools.json not found at $TOOLS_JSON"
        return 1
    fi

    if [ ${#modules[@]} -eq 0 ]; then
        modules=($(python3 -c "
import json
with open('$TOOLS_JSON') as f:
    data = json.load(f)
for key in data:
    print(key)
"))
    fi

    local total=0
    for module in "${modules[@]}"; do
        python3 -c "
import json
with open('$TOOLS_JSON') as f:
    data = json.load(f)
tools = data.get('$module', [])
if not tools:
    exit(0)
print(f'\n[$module]')
for t in tools:
    name = t['name']
    cmd  = t.get('cmd') or '-'
    desc = t.get('description') or ''
    print(f'  {name:<30} {cmd:<25} {desc}')
print(f'  ({len(tools)} tools)')
" 2>/dev/null
        total=$(python3 -c "
import json
with open('$TOOLS_JSON') as f:
    data = json.load(f)
print(sum(len(v) for v in data.values() if isinstance(v, list)))
" 2>/dev/null)
    done

    echo ""
    colorecho "$total tools total"
}
