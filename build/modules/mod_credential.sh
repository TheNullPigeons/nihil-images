#!/bin/bash
# Red-team tools for Credentials / Password attacks
# Each tool has its own install_$TOOL function for easier maintenance.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${MODULE_DIR}/../lib/registry/pipx.sh"
source "${MODULE_DIR}/../lib/registry/cargo.sh"
source "${MODULE_DIR}/../lib/registry/pacman.sh"
source "${MODULE_DIR}/../lib/registry/aur.sh"

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_pypykatz() {
    install_pipx_tool "pypykatz" "pypykatz"
}

function install_binwalk() {
    install_pacman_tool "binwalk"
}

function install_john() {
    install_pacman_tool "john"
}

function install_hashcat() {
    install_pacman_tool "hashcat"
}

function install_seclists() {
    install_aur_tool "seclists" "seclists"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_credential() {
    colorecho "Installing Credential red-team tools"

    colorecho "  [pipx] Credential tools:"
    install_pypykatz

    colorecho "  [pacman] Credential tools:"
    install_binwalk
    install_john
    install_hashcat

    colorecho "  [AUR] Credential tools:"
    install_seclists

    colorecho "Credential tools installation finished"
}
