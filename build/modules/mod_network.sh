#!/bin/bash
# Red-team tools for Network
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/cargo
nihil::import lib/registry/pacman
nihil::import lib/registry/aur
nihil::import lib/registry/go

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_nmap() {
    install_pacman_tool "nmap"
}

function install_netcat() {
    install_pacman_tool "openbsd-netcat"
}

function install_socat() {
    install_pacman_tool "socat"
}

function install_wireshark_cli() {
    install_pacman_tool "wireshark-cli"
}

function install_bettercap() {
    install_pacman_tool "bettercap"
}

function install_fping() {
    install_pacman_tool "fping"
}

function install_bettercap_ui() {
    install_aur_tool "bettercap-ui"
}

function install_udpx() {
    install_go_tool "github.com/nullt3r/udpx/cmd/udpx@latest"
}

function install_zone_dnsenum() {
    install_pipx_tool_git "zone-dnsenum" "https://github.com/Goultarde/Zone-DNSenum"
}

function install_ligolo_ng() {
    local arch
    local url
    arch="$(uname -m)"
    url="$(curl -fsSL "https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest" \
        | grep 'browser_download_url.*ligolo-ng_proxy.*linux.*'"$arch"'.*tar.gz"' \
        | grep -o 'https://[^"]*')"
    if [ -z "$url" ]; then
        colorecho "  ✗ Warning: Failed to resolve ligolo-ng proxy download URL"
        return 1
    fi
    curl -fsSL "$url" | tar -xz -C /tmp proxy
    mv /tmp/proxy /opt/tools/bin/ligolo-ng
    chmod +x /opt/tools/bin/ligolo-ng
    add-history "ligolo-ng"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_network() {
    colorecho "Installing Network red-team tools"

    colorecho "  [pacman] Network tools:"
    install_nmap
    install_netcat
    install_socat
    install_wireshark_cli
    install_bettercap
    install_fping
#   install_bettercap_ui

    colorecho "  [go] Network tools:"
    install_udpx

    colorecho "  [pipx] Network tools:"
    install_zone_dnsenum

    colorecho "  [bin] Tunneling tools:"
    install_ligolo_ng

    add-aliases "network"

    colorecho "Network tools installation finished"
}
