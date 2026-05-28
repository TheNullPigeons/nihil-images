#!/bin/bash
# Red-team tools for Network
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/cargo
nihil::import lib/registry/pacman
nihil::import lib/registry/aur
nihil::import lib/registry/go
nihil::import lib/registry/git

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
    local arch goarch tag version url
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  goarch="amd64" ;;
        aarch64) goarch="arm64" ;;
        *)        colorecho "  ✗ Warning: Unsupported arch $arch for ligolo-ng"; return 0 ;;
    esac

    # Resolve latest tag via redirect (no API, no rate limit)
    tag=$(curl -Ls -o /dev/null -w '%{url_effective}' "https://github.com/nicocha30/ligolo-ng/releases/latest" | sed 's:.*/::' || true)
    if [ -z "$tag" ]; then
        colorecho "  ✗ Warning: Failed to resolve ligolo-ng latest tag"
        return 0
    fi
    version="${tag#v}"

    # Asset format: ligolo-ng_proxy_0.8.3_linux_amd64.tar.gz
    url="https://github.com/nicocha30/ligolo-ng/releases/download/${tag}/ligolo-ng_proxy_${version}_linux_${goarch}.tar.gz"

    if ! curl -fsSL "$url" | tar -xz -C /tmp proxy 2>/dev/null; then
        colorecho "  ✗ Warning: Failed to download/extract ligolo-ng proxy"
        return 0
    fi
    mv /tmp/proxy /opt/tools/bin/ligolo-ng
    chmod +x /opt/tools/bin/ligolo-ng
    add-history "ligolo-ng"
    colorecho "  ✓ ligolo-ng proxy installed (${tag})"
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

function install_chisel() {
    install_go_tool "github.com/jpillora/chisel@latest"
}

function install_masscan() {
    install_pacman_tool "masscan"
}

function install_netdiscover() {
    install_aur_tool "netdiscover" "netdiscover"
}

function install_nmap_parse_output() {
    install_git_tool_symlink "/opt/tools/nmap-parse-output" \
        "https://github.com/ernw/nmap-parse-output.git" \
        "nmap-parse-output" \
        "nmap-parse-output"
}

function install_proxychains() {
    install_pacman_tool "proxychains-ng"
}

function install_rustscan() {
    install_cargo_tool "rustscan"
}

function install_ssh_audit() {
    install_pipx_tool "ssh-audit" "ssh-audit"
}

function install_sshuttle() {
    install_pipx_tool "sshuttle" "sshuttle"
}

function install_tcpdump() {
    install_pacman_tool "tcpdump"
}

function install_xfreerdp() {
    install_pacman_tool "freerdp"
}

function install_nfs_utils() {
    install_pacman_tool "nfs-utils"
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

    install_chisel
    install_masscan
    install_netdiscover
    install_nmap_parse_output
    install_proxychains
    install_rustscan
    install_ssh_audit
    install_sshuttle
    install_tcpdump
    install_xfreerdp
    install_nfs_utils

    add-aliases "network"

    colorecho "Network tools installation finished"
}
