#!/bin/bash
# Outils red-team orientés Web / HTTP
# Ce module installe les outils web en appelant les registres (pipx/cargo/pacman)

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Sourcer les registres d'installation
source "${SCRIPT_DIR}/redteam_pipx.sh"
source "${SCRIPT_DIR}/redteam_cargo.sh"
source "${SCRIPT_DIR}/redteam_pacman.sh"

function install_redteam_web() {
    colorecho "Installing Web red-team tools"

    # Outils web via pacman
    colorecho "  [pacman] Web tools:"
    install_pacman_tool "sqlmap"
    install_pacman_tool "gobuster"

    colorecho "Web tools installation finished"
}
