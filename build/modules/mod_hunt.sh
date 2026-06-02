#!/bin/bash
# Blue team / SOC - Threat hunting and detection.
# Categories: Log Analysis/Threat Hunting, SIEM

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/pacman
nihil::import lib/registry/go

# ===========================================================================
# Log Analysis / Threat Hunting
# ===========================================================================

function install_chainsaw() {
    local install_dir="/opt/tools/chainsaw"

    if command -v chainsaw > /dev/null 2>&1; then
        colorecho "  ✓ chainsaw already installed"
        return 0
    fi

    colorecho "  → Installing chainsaw (Windows event log hunter)"

    local url="https://github.com/WithSecureLabs/chainsaw/releases/latest/download/chainsaw_x86_64-unknown-linux-gnu.tar.gz"

    mkdir -p "$install_dir"
    curl -fsSL "$url" -o /tmp/chainsaw.tar.gz || {
        colorecho "  ✗ Warning: Failed to download chainsaw"
        return 0
    }

    tar xzf /tmp/chainsaw.tar.gz -C "$install_dir" --strip-components=1
    rm -f /tmp/chainsaw.tar.gz

    if [ -x "$install_dir/chainsaw" ]; then
        ln -sf "$install_dir/chainsaw" /opt/tools/bin/chainsaw
        add-history "chainsaw"
        colorecho "  ✓ chainsaw installed"
    else
        colorecho "  ✗ Warning: chainsaw binary not found after extraction"
    fi
    return 0
}

function install_hayabusa() {
    local install_dir="/opt/tools/hayabusa"

    if command -v hayabusa > /dev/null 2>&1; then
        colorecho "  ✓ hayabusa already installed"
        return 0
    fi

    colorecho "  → Installing hayabusa (Windows DFIR timeline generator)"
    pacman -S --noconfirm --needed unzip 2>/dev/null || true

    local tag version url
    tag=$(_latest_tag "Yamato-Security/hayabusa")
    version="${tag#v}"

    if [ -z "$tag" ]; then
        colorecho "  ✗ Warning: Failed to resolve hayabusa latest tag"
        return 0
    fi

    url="https://github.com/Yamato-Security/hayabusa/releases/download/${tag}/hayabusa-${version}-lin-x64-gnu.zip"

    mkdir -p "$install_dir"
    curl -fsSL "$url" -o /tmp/hayabusa.zip || {
        colorecho "  ✗ Warning: Failed to download hayabusa"
        return 0
    }

    unzip -o /tmp/hayabusa.zip -d "$install_dir" 2>/dev/null
    rm -f /tmp/hayabusa.zip

    local hayabusa_bin
    hayabusa_bin=$(find "$install_dir" -maxdepth 1 -name "hayabusa-*" -not -name "*.zip" -type f 2>/dev/null | head -1)
    if [ -n "$hayabusa_bin" ]; then
        chmod +x "$hayabusa_bin"
        ln -sf "$hayabusa_bin" /opt/tools/bin/hayabusa
        add-history "hayabusa"
        colorecho "  ✓ hayabusa installed"
    else
        colorecho "  ✗ Warning: hayabusa binary not found after extraction"
    fi
    return 0
}

function install_sigma_cli() {
    install_pipx_tool "sigma" "sigma-cli"
}

# ===========================================================================
# SIEM
# ===========================================================================

function install_wazuh_cli() {
    install_go_tool "github.com/0xbbuddha/wazuh-cli@latest" "wazuh-cli"
}

# ===========================================================================
# Module entry point
# ===========================================================================

function install_mod_hunt() {
    colorecho "Installing threat hunting and detection tools"

    colorecho "  [log] Log analysis and threat hunting:"
    install_chainsaw
    install_hayabusa
    install_sigma_cli

    colorecho "  [siem] SIEM tools:"
    install_wazuh_cli

    colorecho "Threat hunting tools installation finished"
}
