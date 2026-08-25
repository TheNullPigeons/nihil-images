#!/bin/bash
# Optional per-image tool selection.

nihil::import lib/common

declare -gA NIHIL_DISABLED_TOOLS=()
declare -gA NIHIL_ENABLED_TOOLS=()
declare -gA NIHIL_WRAPPED_INSTALLERS=()
declare -g NIHIL_ALLOWLIST_MODE=0

_nihil_tool_key() {
    local value="$1"
    value="${value,,}"
    value="${value//_/-}"
    printf '%s' "$value"
}

tool_selection_init() {
    local selection_file="${NIHIL_BUILD}/config/tool-selection.json"
    NIHIL_DISABLED_TOOLS=()
    NIHIL_ENABLED_TOOLS=()
    NIHIL_ALLOWLIST_MODE=0
    [[ -f "$selection_file" ]] || return 0

    while IFS='|' read -r mode tool; do
        [[ -n "$tool" ]] || continue
        if [[ "$mode" == mode ]]; then
            NIHIL_ALLOWLIST_MODE=1
        elif [[ "$mode" == enabled ]]; then
            NIHIL_ENABLED_TOOLS["$(_nihil_tool_key "$tool")"]=1
        else
            NIHIL_DISABLED_TOOLS["$(_nihil_tool_key "$tool")"]=1
        fi
    done < <(python3 - "$selection_file" <<'PY'
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as handle:
        data = json.load(handle)
except (OSError, json.JSONDecodeError):
    data = {}

if "enabled_tools" in data:
    print("mode|allowlist")
for item in data.get("enabled_tools", []):
    print("enabled|" + str(item))
for item in data.get("disabled_tools", []):
    print("disabled|" + str(item))
PY
    )
}

tool_selection_enabled_name() {
    local key
    key="$(_nihil_tool_key "$1")"

    # Core tools are mandatory and cannot be disabled.
    case "$key" in
        vim|nano|neovim|tmux|fzf|gdb|asciinema|whois|nihil-history|zoxide|yazi|nihil-ntp)
            return 0
            ;;
    esac

    if ((NIHIL_ALLOWLIST_MODE)); then
        [[ -n "${NIHIL_ENABLED_TOOLS[$key]:-}" ]]
        return
    fi
    [[ -z "${NIHIL_DISABLED_TOOLS[$key]:-}" ]]
}

tool_selection_enabled_for_function() {
    local key="${1#install_}"
    key="$(_nihil_tool_key "$key")"

    case "$key" in
        bloodhound-python) key="bloodhound" ;;
        bloodhound-ce-desktop) key="bloodhound-ce" ;;
        bloodhound-legacy-desktop) key="bloodhound-legacy" ;;
        bloodhound-import|bloodhound-quickwin) key="bloodhound" ;;
        powerview-py) key="powerview.py" ;;
        wireshark) key="wireshark-cli" ;;
        httpx-pd) key="httpx" ;;
        testssl) key="testssl.sh" ;;
        silverc2) key="sliver" ;;
        pycdc) key="pycdas" ;;
        vol) key="volatility3" ;;
    esac

    tool_selection_enabled_name "$key"
}

tool_selection_filter_packages() {
    local package package_key
    local filtered=()

    for package in "$@"; do
        package_key="$(_nihil_tool_key "$package")"
        if tool_selection_enabled_name "$package_key"; then
            filtered+=("$package")
        else
            colorecho "  - $package disabled by tool selection" >&2
        fi
    done

    printf '%s\n' "${filtered[@]}"
}

tool_selection_wrap_installers() {
    local function_name original definition
    while IFS= read -r function_name; do
        case "$function_name" in
            install_mod_*|install_core_tools|install_list_tools|install_nihil_ntp)
                continue
                ;;
            install_*_tool*)
                # Registry helpers are dependencies of actual tool installers.
                continue
                ;;
            install_pacman_tools|install_download_tool|install_tar_tool)
                continue
                ;;
        esac
        [[ -n "${NIHIL_WRAPPED_INSTALLERS[$function_name]:-}" ]] && continue

        original="_nihil_original_${function_name}"
        definition="$(declare -f "$function_name")"
        [[ -n "$definition" ]] || continue
        definition="${definition/#$function_name /$original }"
        eval "$definition"
        eval "$function_name() {
            if ! tool_selection_enabled_for_function '$function_name'; then
                colorecho \"  - $function_name disabled by tool selection\"
                return 0
            fi
            $original \"\$@\"
        }"
        NIHIL_WRAPPED_INSTALLERS["$function_name"]=1
    done < <(declare -F | awk '{print $3}' | grep '^install_')
}

tool_selection_prepare() {
    tool_selection_init
    tool_selection_wrap_installers
}
