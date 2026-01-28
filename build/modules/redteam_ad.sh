#!/bin/bash
# Outils red-team orientés Active Directory
# Ce module installe les outils AD en appelant les registres (pipx/cargo/pacman)

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Sourcer les registres d'installation
source "${SCRIPT_DIR}/redteam_pipx.sh"
source "${SCRIPT_DIR}/redteam_cargo.sh"
source "${SCRIPT_DIR}/redteam_pacman.sh"

function install_redteam_ad() {
    colorecho "Installing Active Directory red-team tools"

    # Outils AD via pipx
    colorecho "  [pipx] AD tools:"
    install_pipx_tool "bloodhound" "bloodhound"
    install_pipx_tool "ldapdomaindump" "ldapdomaindump"
    install_pipx_tool "adidnsdump" "adidnsdump"
    install_pipx_tool "certipy" "certipy-ad"
    install_pipx_tool "bloodyad" "bloodyad"
    install_pipx_tool "evil-winrm-py" "evil-winrm-py"
    install_netexec

    # Outils AD via cargo
    colorecho "  [cargo] AD tools:"
    install_cargo_tool "rusthound-ce"

    colorecho "Active Directory tools installation finished"
}
