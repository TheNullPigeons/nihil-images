#!/bin/bash
# Red-team tools for Network
# Each tool has its own install_$TOOL function for easier maintenance.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${MODULE_DIR}/../lib/registry/redteam_pipx.sh"
source "${MODULE_DIR}/../lib/registry/redteam_cargo.sh"
source "${MODULE_DIR}/../lib/registry/redteam_pacman.sh"

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_nmap() {
    install_pacman_tool "nmap"
}

function install_netcat() {
    install_pacman_tool "openbsd-netcat"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_redteam_network() {
    colorecho "Installing Network red-team tools"

    colorecho "  [pacman] Network tools:"
    install_nmap
    install_netcat

    colorecho "Network tools installation finished"
}
