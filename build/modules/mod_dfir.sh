#!/bin/bash
# Blue team / SOC - Digital Forensics and Incident Response.
# Categories: Malware Triage, Disk Forensics

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/pacman
nihil::import lib/registry/git

_latest_tag() {
    curl -Ls -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's:.*/::' || true
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
    pacman -S --noconfirm --needed unzip 2>/dev/null || true

    local tag url
    tag=$(_latest_tag "mandiant/capa")

    if [ -z "$tag" ]; then
        colorecho "  ✗ Warning: Failed to resolve capa latest tag"
        return 0
    fi

    url="https://github.com/mandiant/capa/releases/download/${tag}/capa-${tag}-linux.zip"

    mkdir -p "$install_dir"
    curl -fsSL "$url" -o /tmp/capa.zip || {
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
    install_git_tool "loki" "https://github.com/Neo23x0/Loki.git" "loki.py"
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
    colorecho "Installing DFIR and malware analysis tools"

    colorecho "  [malware] Malware triage:"
    install_yara
    install_capa
    install_loki

    colorecho "  [disk] Disk forensics:"
    install_sleuthkit

    colorecho "DFIR tools installation finished"
}
