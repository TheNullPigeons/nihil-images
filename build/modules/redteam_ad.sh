#!/bin/bash
# Outils red-team orientés Active Directory
# Ce module installe les outils AD en appelant les registres (pipx/cargo/pacman)
# Inspiré Exegol : outils faciles à installer (pipx) et impactants uniquement

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/redteam_pipx.sh"
source "${SCRIPT_DIR}/redteam_cargo.sh"
source "${SCRIPT_DIR}/redteam_pacman.sh"
source "${SCRIPT_DIR}/redteam_go.sh"
source "${SCRIPT_DIR}/redteam_git.sh"
source "${SCRIPT_DIR}/redteam_curl.sh"

function install_redteam_ad() {
    colorecho "Installing Active Directory red-team tools"

    colorecho "  [pipx] AD tools:"
    install_pipx_tool "bloodhound" "bloodhound"
    install_pipx_tool "ldapdomaindump" "ldapdomaindump"
    install_pipx_tool "adidnsdump" "adidnsdump"
    install_pipx_tool "certipy" "certipy-ad"
    install_pipx_tool "bloodyAD" "bloodyad"
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
    install_pipx_tool_git "sprayhound" "https://github.com/Hackndo/sprayhound.git"

    colorecho "  [pacman] AD tools:"
    install_pacman_tool "openldap"
    install_pacman_tool "smbclient"
    install_pacman_tool "python-pcapy"

    colorecho "  [AUR] AD tools:"
    install_aur_tool "responder" "responder"   

    colorecho "  [cargo] AD tools:"
    install_cargo_tool "rusthound-ce"

    colorecho "  [go] AD tools:"
    install_go_tool "github.com/ropnop/kerbrute@latest"

    colorecho "  [git+venv] AD tools:"
    install_git_tool_venv "krbrelayx" "https://github.com/dirkjanm/krbrelayx.git" "krbrelayx.py addspn.py printerbug.py" "dnspython ldap3 impacket dsinternals" "yes"

    colorecho "  [download] AD tools:"
    install_tar_tool "powershell" \
        "https://github.com/PowerShell/PowerShell/releases/download/v{version}/powershell-{version}-linux-{arch}.tar.gz" \
        "/usr/local/share/powershell/{version}" \
        "pwsh" \
        "pwsh powershell" \
        "" \
        "7.3.4"

    colorecho "Active Directory tools installation finished"
}