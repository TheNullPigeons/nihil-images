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
    local arch goarch url
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  goarch="amd64" ;;
        aarch64) goarch="arm64" ;;
        *)        colorecho "  ✗ Warning: Unsupported arch $arch for ligolo-ng"; return 0 ;;
    esac
    url="$(curl -sSL "https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest" \
        | grep -o "\"browser_download_url\": \"[^\"]*ligolo-ng_proxy[^\"]*Linux_${goarch}\.tar\.gz\"" \
        | grep -o 'https://[^"]*' || true)"
    if [ -z "$url" ]; then
        colorecho "  ✗ Warning: Failed to resolve ligolo-ng proxy download URL"
        return 0
    fi
    curl -fsSL "$url" | tar -xz -C /tmp proxy
    mv /tmp/proxy /opt/tools/bin/ligolo-ng
    chmod +x /opt/tools/bin/ligolo-ng
    add-history "ligolo-ng"
}

function install_ngrok() {
    if command -v ngrok >/dev/null 2>&1; then
        colorecho "  ✓ ngrok already installed"
        add-history "ngrok"
        return 0
    fi
    local arch goarch url
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  goarch="amd64" ;;
        aarch64) goarch="arm64" ;;
        *)        colorecho "  ✗ Warning: Unsupported arch $arch for ngrok"; return 0 ;;
    esac
    local equinox_arch
    case "$arch" in
        x86_64)  equinox_arch="amd64" ;;
        aarch64) equinox_arch="arm64" ;;
    esac
    url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-${equinox_arch}.tgz"
    curl -fsSL "$url" | tar -xz -C /tmp ngrok
    mv /tmp/ngrok /opt/tools/bin/ngrok
    chmod +x /opt/tools/bin/ngrok
    add-history "ngrok"
    colorecho "  ✓ ngrok installed"
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
    install_ngrok

    add-aliases "network"

    colorecho "Network tools installation finished"
}
