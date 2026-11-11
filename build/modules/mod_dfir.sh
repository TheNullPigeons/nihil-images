#!/bin/bash
# Blue team / SOC - Digital Forensics and Incident Response.
# Categories: Malware Triage, Disk Forensics

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/pacman
nihil::import lib/registry/git

_latest_tag() {
    retry-command 3 "resolve $1 latest tag" curl -Ls -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's:.*/::' || true
}

# ===========================================================================
# Malware Triage
# ===========================================================================

function install_yara() {
    install_pacman_tool "yara"
}

function install_capa() {
    local install_dir="/opt/tools/capa"

    if command -v capa > /dev/null 2>&1; then
        colorecho "  ✓ capa already installed"
        return 0
    fi

    colorecho "  → Installing capa (FLARE malware capability detection)"
    install_pacman_tool unzip || true

    local tag url
    tag=$(_latest_tag "mandiant/capa")

    if [ -z "$tag" ]; then
        colorecho "  ✗ Warning: Failed to resolve capa latest tag"
        return 0
    fi

    url="https://github.com/mandiant/capa/releases/download/${tag}/capa-${tag}-linux.zip"

    mkdir -p "$install_dir"
    download-retry "$url" /tmp/capa.zip || {
        colorecho "  ✗ Warning: Failed to download capa"
        return 0
    }

    unzip -o /tmp/capa.zip -d "$install_dir" 2>/dev/null
    rm -f /tmp/capa.zip

    if [ -f "$install_dir/capa" ]; then
        chmod +x "$install_dir/capa"
        ln -sf "$install_dir/capa" /opt/tools/bin/capa
        add-history "capa"
        colorecho "  ✓ capa installed"
    else
        colorecho "  ✗ Warning: capa binary not found after extraction"
    fi
    return 0
}

function install_loki() {
    # yara-python has no Python 3.14 wheel and cannot build against the image's
    # system YARA reliably. Use Arch's matching bindings, then install Loki's
    # remaining Python dependencies explicitly so a failed aggregate pip
    # resolution cannot leave behind a broken launcher.
    install_pacman_tool "python-yara" || return 1
    install_git_tool "loki" "https://github.com/Neo23x0/Loki.git" "loki.py" "" \
        '^yara-python([<=> ].*)?$' || return 1

    local requirements="${GIT_INSTALL_DIR:-/usr/local/share}/loki/requirements.txt"
    local filtered_requirements
    filtered_requirements=$(mktemp) || return 1
    grep -vE '^yara-python([<=> ].*)?$' "$requirements" > "$filtered_requirements"
    retry-command 3 "install Loki Python dependencies" \
        python3 -m pip install --break-system-packages --quiet \
        -r "$filtered_requirements"
    local status=$?
    rm -f "$filtered_requirements"
    return "$status"
}

# ===========================================================================
# Disk Forensics
# ===========================================================================

function install_sleuthkit() {
    command -v fls > /dev/null 2>&1 && { colorecho "  ✓ sleuthkit already installed"; return 0; }
    install_pacman_tool "sleuthkit"
}

# ===========================================================================
# Module entry point
# ===========================================================================

function install_mod_dfir() {
    install_selected_tools "mod_dfir"
}
