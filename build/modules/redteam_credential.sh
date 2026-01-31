#!/bin/bash
# Outils red-team orientés Credentials / Password
# Ce module installe les outils credentials en appelant les registres (pipx/cargo/pacman)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/redteam_pipx.sh"
source "${SCRIPT_DIR}/redteam_cargo.sh"
source "${SCRIPT_DIR}/redteam_pacman.sh"

function install_redteam_credential() {
    colorecho "Installing Credential red-team tools"

    colorecho "  [pipx] Credential tools:"
    install_pipx_tool "pypykatz" "pypykatz"

    colorecho "  [pacman] Credential tools:"
    install_pacman_tool "binwalk"
    install_pacman_tool "john"

    colorecho "  [AUR] Pwn / reverse tools:"
    install_aur_tool "seclists" "seclists"

    colorecho "Credential tools installation finished"
}
