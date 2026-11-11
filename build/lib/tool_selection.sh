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

record_build_failure() {
    [[ "${NIHIL_AUDIT:-0}" == 1 ]] || return 0
    printf '%s\n' "$*" >> "${NIHIL_BUILD}/config/build-failures.log"
    echo "[NIHIL AUDIT] $*"
}

show_build_failures() {
    local report="${NIHIL_BUILD}/config/build-failures.log" line
    [[ -s "$report" ]] || return 0
    echo "[NIHIL AUDIT] Build report: /opt/nihil/build/config/build-failures.log"
    while IFS= read -r line; do
        echo "[NIHIL AUDIT] $line"
    done < "$report"
}

install_selected_tools() {
    local module="$1" installer status
    local -A installed=()
    while IFS= read -r installer; do
        [[ -n "$installer" ]] || continue
        [[ -z "${installed[$installer]:-}" ]] || continue
        colorecho "Installing $module: $installer"
        if [[ "${NIHIL_AUDIT:-0}" == 1 && "$module" != core_tools ]]; then
            # A tested subshell would disable errexit inside the installer too.
            set +e
            (set -e; "$installer")
            status=$?
            set -e
            if ((status != 0)); then
                record_build_failure "Installer failed: $module/$installer (exit $status)"
            fi
        else
            "$installer"
        fi
        installed["$installer"]=1
    done <<< "${NIHIL_MODULE_INSTALLERS[$module]:-}"
}
