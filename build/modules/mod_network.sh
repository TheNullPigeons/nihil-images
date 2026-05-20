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

    colorecho "Network tools installation finished"
}
