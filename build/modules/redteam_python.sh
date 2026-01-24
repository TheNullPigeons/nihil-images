#!/bin/bash
# Red-team tools installed via Python ecosystem (pip/pipx)
# Ici on installe des outils offensifs type AD / réseau (façon Exegol),
# mais sans ajouter un autre orchestrateur. Nihil reste le point central.

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

_rtp_tools=(
  "pypykatz:pypykatz"
  "ldapdomaindump:ldapdomaindump"
  "adidnsdump:adidnsdump"
  "mitm6:mitm6"
  "certipy:certipy-ad"
  "bloodhound:bloodhound"
  "bloodyad:bloodyad"
)

_ensure_pipx() {
    if ! command -v pipx >/dev/null 2>&1; then
        colorecho "python-pipx not found, installing via pacman"
        pacman -Sy --noconfirm && \
        pacman -S --noconfirm --needed python-pipx || {
            criticalecho "Failed to install python-pipx"
            return 1
        }
    fi
}

_pipx_install_tool() {
    local cmd_name="$1"
    local pkg_name="$2"

    if command -v "$cmd_name" >/dev/null 2>&1; then
        colorecho "$cmd_name already installed (pipx / $pkg_name)"
        return 0
    fi

    colorecho "Installing $cmd_name via pipx ($pkg_name)"
    pipx install "$pkg_name" || {
        colorecho "Warning: Failed to install $pkg_name via pipx"
        return 1
    }
}

function install_redteam_python_tools() {
    colorecho "Installing Python-based red-team tools (pipx)"

    _ensure_pipx || return 1

    for entry in "${_rtp_tools[@]}"; do
        cmd="${entry%%:*}"
        pkg="${entry##*:}"
        _pipx_install_tool "$cmd" "$pkg" || true
    done

    # Rendez les binaires facilement accessibles (pipx place tout sous /root/.local/bin)
    if [ -d "/root/.local/bin" ]; then
        for entry in "${_rtp_tools[@]}"; do
            cmd="${entry%%:*}"
            if [ -f "/root/.local/bin/$cmd" ] && [ ! -f "/usr/bin/$cmd" ]; then
                ln -sf "/root/.local/bin/$cmd" "/usr/bin/$cmd" || true
            fi
        done
    fi

    colorecho "Python-based red-team tools installation finished"
}


