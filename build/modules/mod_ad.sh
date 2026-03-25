#!/bin/bash
# Red-team tools for Active Directory
# Each tool has its own install_$TOOL function for easier maintenance.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${MODULE_DIR}/../lib/registry/pipx.sh"
source "${MODULE_DIR}/../lib/registry/cargo.sh"
source "${MODULE_DIR}/../lib/registry/pacman.sh"
source "${MODULE_DIR}/../lib/registry/go.sh"
source "${MODULE_DIR}/../lib/registry/git.sh"
source "${MODULE_DIR}/../lib/registry/curl.sh"

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_bloodhound() {
    install_pipx_tool "bloodhound" "bloodhound"
}

function install_bloodhound_ce() {
    install_pipx_tool "bloodhound-ce-python" "bloodhound-ce"
}

function install_ldapdomaindump() {
    install_pipx_tool "ldapdomaindump" "ldapdomaindump"
}

function install_adidnsdump() {
    install_pipx_tool "adidnsdump" "adidnsdump"
}

function install_certipy() {
    install_pipx_tool "certipy" "certipy-ad"
}

function install_bloodyad() {
    install_pipx_tool "bloodyad" "bloodyad"
}

function install_evil_winrm_py() {
    install_pipx_tool "evil-winrm-py" "evil-winrm-py"
}

function install_netexec() {
    # Ensure Rust is available (required to build NetExec native extensions)
    if ! command -v rustc > /dev/null 2>&1; then
        pacman -Sy --noconfirm && \
        pacman -S --noconfirm --needed rust || {
            colorecho "  ✗ Warning: Failed to install rust for NetExec"
            return 1
        }
    fi

    install_pipx_tool_git "netexec" "https://github.com/Pennyw0rth/NetExec" "PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1" || return 1
    add-symlink "/root/.local/bin/netexec" "nxc"
    # add-aliases and add-history are already called by install_pipx_tool_git
}

function install_impacket() {
    install_pipx_tool_git "impacket" "https://github.com/fortra/impacket.git"
}

function install_mitm6() {
    install_pipx_tool "mitm6" "mitm6"
}

function install_aclpwn() {
    install_pipx_tool "aclpwn" "aclpwn"
}

function install_lsassy() {
    install_pipx_tool "lsassy" "lsassy"
}

function install_donpapi() {
    install_pipx_tool_git "donpapi" "https://github.com/login-securite/DonPAPI.git"
}

function install_coercer() {
    install_pipx_tool "coercer" "coercer"
}

function install_pywhisker() {
    install_pipx_tool "pywhisker" "pywhisker"
}

function install_enum4linux_ng() {
    install_pipx_tool_git "enum4linux-ng" "https://github.com/cddmp/enum4linux-ng.git"
}

function install_smbmap() {
    install_pipx_tool "smbmap" "smbmap"
}

function install_sprayhound() {
    install_pipx_tool_git "sprayhound" "https://github.com/Hackndo/sprayhound.git"
}

function install_openldap() {
    install_pacman_tool "openldap"
}

function install_smbclient() {
    install_pacman_tool "smbclient"
}

function install_python_pcapy() {
    install_pacman_tool "python-pcapy"
}

function install_responder() {
    install_aur_tool "responder" "responder"
}

function install_rusthound_ce() {
    install_cargo_tool "rusthound-ce"
}

function install_kerbrute() {
    install_go_tool "github.com/ropnop/kerbrute@latest"
}

function install_krbrelayx() {
    install_git_tool_venv "krbrelayx" "https://github.com/dirkjanm/krbrelayx.git" "krbrelayx.py addspn.py printerbug.py" "dnspython ldap3 impacket dsinternals" "yes"
}

function install_gmsadumper() {
    install_git_tool "gmsadumper" "https://github.com/micahvandeusen/gMSADumper.git" "gMSADumper.py"
}

function install_powershell() {
    install_tar_tool "powershell" \
        "https://github.com/PowerShell/PowerShell/releases/download/v{version}/powershell-{version}-linux-{arch}.tar.gz" \
        "/usr/local/share/powershell/{version}" \
        "pwsh" \
        "pwsh powershell" \
        "" \
        "7.3.4"
}

function install_ldapsearch_ad() {
    install_pipx_tool "ldapsearch-ad.py" "ldapsearchad"
    add-symlink "/root/.local/bin/ldapsearch-ad.py" "ldapsearch-ad"
}

function install_windapsearch() {
    install_go_tool "github.com/ropnop/go-windapsearch/cmd/windapsearch@latest" "windapsearch"
}

function install_pywerview() {
    install_pipx_tool "pywerview" "pywerview"
}

function install_finduncommonshares() {
    install_git_tool_venv "FindUncommonShares" "https://github.com/p0dalirius/pyFindUncommonShares.git" "FindUncommonShares.py" "" "yes"
}

function install_targetedkerberoast() {
    install_git_tool_venv "targetedKerberoast" "https://github.com/ShutdownRepo/targetedKerberoast" "targetedKerberoast.py" "" "yes"
}

function install_pkinittools() {
    install_git_tool_venv "PKINITtools" "https://github.com/dirkjanm/PKINITtools" "gettgtpkinit.py getnthash.py gets4uticket.py" "" "yes"
}

function install_nopac() {
    install_git_tool_venv "noPac" "https://github.com/Ridter/noPac" "noPac.py scanner.py" "" "yes"
}

function install_petitpotam() {
    install_git_tool_venv "PetitPotam" "https://github.com/topotam/PetitPotam" "PetitPotam.py" "impacket" "yes"
}

function install_zerologon() {
    install_git_tool_venv "zerologon" "https://github.com/dirkjanm/CVE-2020-1472" "cve-2020-1472-exploit.py restorepassword.py" "impacket" "yes"
}

function install_masky() {
    install_pipx_tool "masky" "masky"
}

function install_pre2k() {
    install_pipx_tool_git "pre2k" "https://github.com/garrettfoster13/pre2k"
}

function install_shadowcoerce() {
    install_git_tool "ShadowCoerce" "https://github.com/ShutdownRepo/ShadowCoerce" "shadowcoerce.py"
}

function install_dfscoerce() {
    install_git_tool "DFSCoerce" "https://github.com/Wh04m1001/DFSCoerce" "dfscoerce.py"
}

function install_manspider() {
    install_pipx_tool "manspider" "man-spider"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_ad() {
    colorecho "Installing Active Directory red-team tools"

    colorecho "  [pipx] AD tools:"
    install_bloodhound
    install_bloodhound_ce
    install_ldapdomaindump
    install_adidnsdump
    install_certipy
    install_bloodyad
    install_evil_winrm_py
    install_netexec
    install_impacket
    install_mitm6
    install_aclpwn
    install_lsassy
    install_donpapi
    install_coercer
    install_pywhisker
    install_enum4linux_ng
    install_smbmap
    install_sprayhound
    install_ldapsearch_ad
    install_pywerview
    install_masky
    install_manspider

    colorecho "  [pipx-git] AD tools:"
    install_pre2k

    colorecho "  [pacman] AD tools:"
    install_openldap
    install_smbclient
    install_python_pcapy

    colorecho "  [AUR] AD tools:"
    install_responder

    colorecho "  [cargo] AD tools:"
    install_rusthound_ce

    colorecho "  [go] AD tools:"
    install_kerbrute
    install_windapsearch

    colorecho "  [git] AD tools:"
    install_krbrelayx
    install_gmsadumper
    install_finduncommonshares
    install_targetedkerberoast
    install_pkinittools
    install_nopac
    install_petitpotam
    install_zerologon
    install_shadowcoerce
    install_dfscoerce

    colorecho "  [download] AD tools:"
    install_powershell

    colorecho "Active Directory tools installation finished"
}