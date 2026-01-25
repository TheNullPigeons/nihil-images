#!/bin/bash
# Outils red-team orientés Credentials / Password
# Ce module installe les outils de credentials en appelant les registres (pipx/cargo/pacman)

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Sourcer les registres d'installation
source "${SCRIPT_DIR}/redteam_pipx.sh"
source "${SCRIPT_DIR}/redteam_cargo.sh"
source "${SCRIPT_DIR}/redteam_pacman.sh"

function install_redteam_credential() {
    colorecho "Installing Credential red-team tools"

    # Outils credentials via pipx
    colorecho "  [pipx] Credential tools:"
    install_pipx_tool "pypykatz" "pypykatz"

    # Outils credentials via pacman
    colorecho "  [pacman] Credential tools:"
    install_pacman_tool "john"
    install_pacman_tool "binwalk"

    colorecho "Credential tools installation finished"
}
