#!/bin/bash
# Outils red-team orientés Réseau
# Ce module installe les outils réseau en appelant les registres (pipx/cargo/pacman)

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Sourcer les registres d'installation
source "${SCRIPT_DIR}/redteam_pipx.sh"
source "${SCRIPT_DIR}/redteam_cargo.sh"
source "${SCRIPT_DIR}/redteam_pacman.sh"

function install_redteam_network() {
    colorecho "Installing Network red-team tools"

    # Outils réseau via pacman
    colorecho "  [pacman] Network tools:"
    install_pacman_tool "nmap"
    install_pacman_tool "openbsd-netcat"

    colorecho "Network tools installation finished"
}
