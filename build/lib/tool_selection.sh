#!/bin/bash
# Catalogue identities select explicit installers; dependency calls stay untouched.

nihil::import lib/common

declare -gA NIHIL_ENABLED_TOOLS=()
declare -gA NIHIL_MODULE_INSTALLERS=()

_nihil_tool_key() {
    local value="$1"
    value="${value,,}"
    value="${value//_/-}"
    printf '%s' "$value"
}

tool_selection_enabled_name() {
    local key
    key="$(_nihil_tool_key "$1")"
    [[ -n "${NIHIL_ENABLED_TOOLS[$key]:-}" ]]
}

tool_selection_prepare() {
    local plan kind key value
    plan=$(python3 "${NIHIL_BUILD}/lib/tool_selection.py" "$NIHIL_BUILD") || return 1
    NIHIL_ENABLED_TOOLS=()
    NIHIL_MODULE_INSTALLERS=()
    while IFS='|' read -r kind key value; do
        case "$kind" in
            tool)
                if [[ "$value" == 1 ]]; then
                    NIHIL_ENABLED_TOOLS["$key"]=1
                fi
                ;;
            function)
                if ! declare -F "$key" >/dev/null; then
                    echo "Unknown tool installer: $key" >&2
                    return 1
                fi
                ;;
            installer)
                NIHIL_MODULE_INSTALLERS["$key"]+="$value"$'\n'
                ;;
        esac
    done <<< "$plan"
}

install_selected_tools() {
    local module="$1" installer
    local -A installed=()
    while IFS= read -r installer; do
        [[ -n "$installer" ]] || continue
        [[ -z "${installed[$installer]:-}" ]] || continue
        colorecho "Installing $module: $installer"
        # Keep this a plain call: testing a function with `if`/`||` disables
        # Bash errexit inside it and can hide a failed dependency.
        "$installer"
        installed["$installer"]=1
    done <<< "${NIHIL_MODULE_INSTALLERS[$module]:-}"
}
