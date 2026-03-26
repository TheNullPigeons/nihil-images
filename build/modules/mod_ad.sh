#!/bin/bash
# Red-team tools for Active Directory
# Each tool has its own install_$TOOL function for easier maintenance.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${MODULE_DIR}/../lib/registry/pipx.sh"
source "${MODULE_DIR}/../lib/registry/cargo.sh"
source "${MODULE_DIR}/../lib/registry/pacman.sh"
source "${MODULE_DIR}/../lib/registry/aur.sh"
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

function install_bloodhound_ce_desktop() {
    local install_root="/opt/tools/BloodHound-CE"
    local src_dir="${install_root}/src"
    local api_bin="${install_root}/bloodhound"
    local tmp_json
    local tag_name

    if command -v bloodhound-ce > /dev/null 2>&1; then
        colorecho "  ✓ bloodhound-ce already installed"
        add-aliases "bloodhound-ce"
        add-history "bloodhound-ce"
        return 0
    fi

    colorecho "  → Installing bloodhound-ce from upstream source (Exegol-like flow)"

    # Exegol builds BloodHound CE from SpecterOps sources (not AUR).
    install_pacman_tool "nodejs" || return 1
    install_pacman_tool "npm" || true
    install_pacman_tool "yarn" || return 1
    install_pacman_tool "go" || return 1
    install_pacman_tool "jq" || return 1
    install_pacman_tool "postgresql" || return 1
    install_aur_tool "neo4j-community" "neo4j" || return 1

    mkdir -p "${install_root}"
    tmp_json="$(mktemp)"
    if ! curl -fsSL "https://api.github.com/repos/SpecterOps/BloodHound/releases" -o "${tmp_json}"; then
        colorecho "  ✗ Warning: Failed to fetch BloodHound releases"
        rm -f "${tmp_json}"
        return 1
    fi

    tag_name="$(jq -r 'first(.[] | select(.tag_name | contains("-rc") | not) | .tag_name)' "${tmp_json}")"
    rm -f "${tmp_json}"
    if [ -z "${tag_name}" ] || [ "${tag_name}" = "null" ]; then
        colorecho "  ✗ Warning: Unable to resolve BloodHound release tag"
        return 1
    fi

    rm -rf "${src_dir}"
    if ! git clone --depth 1 --branch "${tag_name}" "https://github.com/SpecterOps/BloodHound.git" "${src_dir}"; then
        colorecho "  ✗ Warning: Failed to clone BloodHound source"
        return 1
    fi

    if ! (cd "${src_dir}" && yarn install && yarn build); then
        colorecho "  ✗ Warning: Failed to build BloodHound UI"
        return 1
    fi

    if ! (cd "${src_dir}" && mkdir -p ./cmd/api/src/api/static/assets && cp -r ./cmd/ui/dist/. ./cmd/api/src/api/static/assets); then
        colorecho "  ✗ Warning: Failed to stage BloodHound UI assets"
        return 1
    fi

    if ! go build -C "${src_dir}/cmd/api/src" -o "${api_bin}" github.com/specterops/bloodhound/cmd/api/src/cmd/bhapi; then
        colorecho "  ✗ Warning: Failed to build BloodHound API binary"
        return 1
    fi

    cat > /usr/local/bin/bloodhound-ce <<'EOF'
#!/bin/bash
# bloodhound-ce wrapper — starts PostgreSQL and Neo4j automatically

BHCE_BIN="/opt/tools/BloodHound-CE/bloodhound"

# PostgreSQL
if ! pg_isready -q 2>/dev/null; then
    mkdir -p /run/postgresql
    chown postgres:postgres /run/postgresql
    if [ ! -f /var/lib/postgres/data/PG_VERSION ]; then
        echo "[nihil] Initializing PostgreSQL..."
        su -s /bin/bash postgres -c "initdb -D /var/lib/postgres/data" >/dev/null
    fi
    echo "[nihil] Starting PostgreSQL..."
    su -s /bin/bash postgres -c "pg_ctl -D /var/lib/postgres/data -l /tmp/postgres.log start" >/dev/null
    for i in $(seq 1 15); do pg_isready -q 2>/dev/null && break || sleep 1; done
fi

# Neo4j
if ! neo4j status 2>/dev/null | grep -q "is running"; then
    echo "[nihil] Starting Neo4j..."
    neo4j start >/dev/null 2>&1
    echo "[nihil] Waiting for Neo4j..."
    for i in $(seq 1 30); do
        bash -c "echo > /dev/tcp/127.0.0.1/7687" 2>/dev/null && break || sleep 2
    done
fi

echo "[nihil] Starting BloodHound CE..."
exec "$BHCE_BIN" "$@"
EOF
    chmod +x /usr/local/bin/bloodhound-ce

    add-aliases "bloodhound-ce"
    add-history "bloodhound-ce"
    colorecho "  ✓ bloodhound-ce installed"
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

    colorecho "  [source-build] AD tools:"
    install_bloodhound_ce_desktop

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