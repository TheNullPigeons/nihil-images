#!/bin/bash
# Outils red-team orientés Active Directory
# Ce module installe les outils AD en appelant les registres (pipx/cargo/pacman)
# Inspiré Exegol : outils faciles à installer (pipx) et impactants uniquement

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/redteam_pipx.sh"
source "${SCRIPT_DIR}/redteam_cargo.sh"
source "${SCRIPT_DIR}/redteam_pacman.sh"

function install_redteam_ad() {
    colorecho "Installing Active Directory red-team tools"

    colorecho "  [pipx] AD tools:"
    install_pipx_tool "bloodhound" "bloodhound"
    install_pipx_tool "ldapdomaindump" "ldapdomaindump"
    install_pipx_tool "adidnsdump" "adidnsdump"
    install_pipx_tool "certipy" "certipy-ad"
    install_pipx_tool "bloodyad" "bloodyad"
    install_pipx_tool "evil-winrm-py" "evil-winrm-py"
    install_pipx_netexec
    install_pipx_tool "impacket-secretsdump" "impacket"
    install_pipx_tool "mitm6" "mitm6"
    install_pipx_tool "aclpwn" "aclpwn"
    install_pipx_tool "lsassy" "lsassy"
    install_pipx_tool_git "donpapi" "https://github.com/login-securite/DonPAPI.git"
    install_pipx_tool "coercer" "coercer"
    install_pipx_tool "pywhisker" "pywhisker"
    install_pipx_tool_git "enum4linux-ng" "https://github.com/cddmp/enum4linux-ng.git"
    install_pipx_tool "smbmap" "smbmap"

    colorecho "  [AUR] AD tools:"
    install_aur_tool "responder" "responder"   

    colorecho "  [cargo] AD tools:"
    install_cargo_tool "rusthound-ce"

    colorecho "Active Directory tools installation finished"
}