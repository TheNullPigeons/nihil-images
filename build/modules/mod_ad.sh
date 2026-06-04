#!/bin/bash
# Red-team tools for Active Directory
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/cargo
nihil::import lib/registry/pacman
nihil::import lib/registry/aur
nihil::import lib/registry/go
nihil::import lib/registry/git
nihil::import lib/registry/curl
nihil::import lib/registry/gem

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_bloodhound_python() {
  install_pipx_tool "bloodhound" "bloodhound"
}

function install_bloodhound_ce_python() {
  install_pipx_tool "bloodhound-ce-python" "bloodhound-ce"
}

# Neo4j 4.4.x is the shared graph backend for both BloodHound CE desktop and the
# BloodHound legacy desktop. Idempotent: skips if a neo4j binary is already linked.
function install_neo4j() {
  if command -v neo4j >/dev/null 2>&1; then
    colorecho "  ✓ neo4j already installed"
    return 0
  fi

  install_pacman_tool "jq" || return 1
  install_pacman_tool "jre11-openjdk-headless" || return 1
  archlinux-java set java-11-openjdk

  # BloodHound requires Neo4j 4.4.x - Neo4j 5.x removed the db.indexes procedure
  local neo4j_version
  neo4j_version="$(curl -fsSL "https://api.github.com/repos/neo4j/neo4j/releases" |
    jq -r 'first(.[] | select(.tag_name | startswith("4.4.")) | select(.prerelease | not) | .tag_name)' |
    sed 's/^4\.4\.//' | xargs -I{} echo "4.4.{}" 2>/dev/null)" || neo4j_version="4.4.40"
  [ -z "${neo4j_version}" ] && neo4j_version="4.4.40"
  colorecho "  → Installing Neo4j ${neo4j_version}"
  curl -fsSL "https://dist.neo4j.org/neo4j-community-${neo4j_version}-unix.tar.gz" |
    tar -xz -C /opt/
  # Wrappers exec plutot que des symlinks: les scripts Neo4j utilisent
  # dirname "$0" pour retrouver leur arborescence (jars, NEO4J_HOME).
  # Via un symlink, "$0" pointe vers /opt/tools/bin et la detection echoue
  # (find: .../share/cypher-shell: No such file or directory). Le wrapper
  # garde "$0" sur le vrai chemin dans /opt/neo4j-community-*.
  local neo4j_home="/opt/neo4j-community-${neo4j_version}"
  for bin in neo4j neo4j-admin cypher-shell; do
    printf '#!/bin/bash\nexec "%s/bin/%s" "$@"\n' "${neo4j_home}" "${bin}" > "/opt/tools/bin/${bin}"
    chmod +x "/opt/tools/bin/${bin}"
  done
  # Best-effort pre-seed: only takes effect on a pristine data dir (before the
  # Neo4j system db is created). Once that db exists this silently no-ops, so the
  # bloodhound-ce launcher self-heals the password at runtime instead.
  neo4j-admin set-initial-password fly2own1 >/dev/null 2>&1 || true
}

function install_bloodhound_ce_desktop() {
  local install_root="/opt/tools/BloodHound-CE"
  local src_dir="${install_root}/src"
  local api_bin="${install_root}/bloodhound"
  local sharphound_path="${install_root}/collectors/sharphound"
  local azurehound_path="${install_root}/collectors/azurehound"
  local curl_tempfile
  local tag_name

  if command -v bloodhound-ce >/dev/null 2>&1; then
    colorecho "  ✓ bloodhound-ce already installed"
    add-aliases "bloodhound-ce"
    add-history "bloodhound-ce"
    return 0
  fi

  colorecho "  → Installing bloodhound-ce from upstream source"

  install_pacman_tool "nodejs" || return 1
  install_pacman_tool "npm" || true
  install_pacman_tool "yarn" || return 1
  install_pacman_tool "go" || return 1
  install_pacman_tool "jq" || return 1
  install_pacman_tool "p7zip" || true
  install_pacman_tool "postgresql" || return 1
  install_neo4j || return 1

  mkdir -p "${install_root}" "${sharphound_path}" "${azurehound_path}"
  curl_tempfile="$(mktemp)"

  if ! curl -fsSL "https://api.github.com/repos/SpecterOps/BloodHound/releases" -o "${curl_tempfile}"; then
    colorecho "  ✗ Warning: Failed to fetch BloodHound releases"
    rm -f "${curl_tempfile}"
    return 1
  fi

  tag_name="$(jq -r 'first(.[] | select(.tag_name | contains("-rc") | not) | .tag_name)' "${curl_tempfile}")"
  if [ -z "${tag_name}" ] || [ "${tag_name}" = "null" ]; then
    colorecho "  ✗ Warning: Unable to resolve BloodHound release tag"
    rm -f "${curl_tempfile}"
    return 1
  fi

  rm -rf "${src_dir}"
  if ! git clone --depth 1 --branch "${tag_name}" "https://github.com/SpecterOps/BloodHound.git" "${src_dir}"; then
    colorecho "  ✗ Warning: Failed to clone BloodHound source"
    rm -f "${curl_tempfile}"
    return 1
  fi

  if ! (cd "${src_dir}" && yarn install && yarn build); then
    colorecho "  ✗ Warning: Failed to build BloodHound UI"
    rm -f "${curl_tempfile}"
    return 1
  fi

  if ! (cd "${src_dir}" && mkdir -p ./cmd/api/src/api/static/assets && cp -r ./cmd/ui/dist/. ./cmd/api/src/api/static/assets); then
    colorecho "  ✗ Warning: Failed to stage BloodHound UI assets"
    rm -f "${curl_tempfile}"
    return 1
  fi

  # Fix STORAGE MAIN incompatibility in PostgreSQL migration (upstream issue, expires 2026-08-10)
  # Guard with -f: newer BloodHound releases may not include this specific migration file.
  if [[ "$(date +%Y%m%d)" < "20260810" ]]; then
    local migration_file="${src_dir}/cmd/api/src/database/migration/migrations/v8.5.0.sql"
    if [ -f "$migration_file" ]; then
      sed -i 's/\s*STORAGE MAIN//' "$migration_file"
    fi
  fi

  if ! go build -C "${src_dir}/cmd/api/src" -o "${api_bin}" \
    -ldflags "-X 'github.com/specterops/bloodhound/cmd/api/src/version.majorVersion=8' \
                  -X 'github.com/specterops/bloodhound/cmd/api/src/version.minorVersion=0' \
                  -X 'github.com/specterops/bloodhound/cmd/api/src/version.patchVersion=1'" \
    github.com/specterops/bloodhound/cmd/api/src/cmd/bhapi; then
    colorecho "  ✗ Warning: Failed to build BloodHound API binary"
    rm -f "${curl_tempfile}"
    return 1
  fi

  rm -rf "${src_dir}/cache" "${src_dir}/.yarn/cache"

  # SharpHound
  local sharphound_url sharphound_name
  curl -fsSL "https://api.github.com/repos/BloodHoundAD/SharpHound/releases/latest" -o "${curl_tempfile}"
  sharphound_url="$(jq -r '.assets[].browser_download_url | select(contains("debug") | not) | select(contains("sha256") | not)' "${curl_tempfile}")"
  sharphound_name="$(jq -r '.assets[].name | ascii_downcase | select(contains("debug") | not) | select(contains("sha256") | not)' "${curl_tempfile}")"
  if [ -n "${sharphound_url}" ]; then
    wget -q --directory-prefix "${sharphound_path}" "${sharphound_url}"
    mv "${sharphound_path}/$(basename "${sharphound_url}")" "${sharphound_path}/${sharphound_name}" 2>/dev/null || true
    sha256sum "${sharphound_path}/${sharphound_name}" >"${sharphound_path}/${sharphound_name}.sha256"
  fi

  # AzureHound
  local azurehound_version azurehound_url_amd64 azurehound_url_amd64_sha256 azurehound_url_arm64 azurehound_url_arm64_sha256
  curl -fsSL "https://api.github.com/repos/BloodHoundAD/AzureHound/releases/latest" -o "${curl_tempfile}"
  azurehound_version="$(jq -r '.tag_name' "${curl_tempfile}")"
  azurehound_url_amd64="$(jq -r '.assets[].browser_download_url | select(endswith("_linux_amd64.zip"))' "${curl_tempfile}")"
  azurehound_url_amd64_sha256="$(jq -r '.assets[].browser_download_url | select(endswith("_linux_amd64.zip.sha256"))' "${curl_tempfile}")"
  azurehound_url_arm64="$(jq -r '.assets[].browser_download_url | select(endswith("_linux_arm64.zip"))' "${curl_tempfile}")"
  azurehound_url_arm64_sha256="$(jq -r '.assets[].browser_download_url | select(endswith("_linux_arm64.zip.sha256"))' "${curl_tempfile}")"
  rm -f "${curl_tempfile}"
  if [ -n "${azurehound_url_amd64}" ]; then
    wget -q --directory-prefix "${azurehound_path}" "${azurehound_url_amd64}" "${azurehound_url_amd64_sha256}"
    wget -q --directory-prefix "${azurehound_path}" "${azurehound_url_arm64}" "${azurehound_url_arm64_sha256}"
    (cd "${azurehound_path}" && sha256sum --check --warn ./*.sha256) || return 1
    7z a -tzip -mx9 "${azurehound_path}/azurehound-${azurehound_version}.zip" "${azurehound_path}/azurehound-*"
    sha256sum "${azurehound_path}/azurehound-${azurehound_version}.zip" >"${azurehound_path}/azurehound-${azurehound_version}.zip.sha256"
  fi

  mkdir -p /run/postgresql
  chown postgres:postgres /run/postgresql
  if [ ! -f /var/lib/postgres/data/PG_VERSION ]; then
    su -s /bin/bash postgres -c "initdb -D /var/lib/postgres/data" >/dev/null
  fi
  su -s /bin/bash postgres -c "pg_ctl -D /var/lib/postgres/data -l /tmp/postgres.log start" >/dev/null
  for i in $(seq 1 15); do pg_isready -q 2>/dev/null && break || sleep 1; done
  cd /tmp && su -s /bin/bash postgres -c "psql -c \"CREATE USER bloodhound WITH PASSWORD 'nihil4thewin';\""
  cd /tmp && su -s /bin/bash postgres -c "psql -c \"CREATE DATABASE bloodhound;\""
  cd /tmp && su -s /bin/bash postgres -c "psql -c \"ALTER DATABASE bloodhound OWNER TO bloodhound;\""
  su -s /bin/bash postgres -c "pg_ctl -D /var/lib/postgres/data stop" >/dev/null

  local assets="${NIHIL_BUILD}/lib/installers/bloodhound-ce"

  mkdir -p "${install_root}/work"
  cp "${assets}/bloodhound.config.json" "${install_root}/bloodhound.config.json"

  cp "${assets}/bloodhound-ce" /opt/tools/bin/bloodhound-ce
  cp "${assets}/bloodhound-ce-stop" /opt/tools/bin/bloodhound-ce-stop
  cp "${assets}/bloodhound-ce-reset" /opt/tools/bin/bloodhound-ce-reset
  chmod +x /opt/tools/bin/bloodhound-ce /opt/tools/bin/bloodhound-ce-stop /opt/tools/bin/bloodhound-ce-reset

  add-aliases "bloodhound-ce"
  add-history "bloodhound-ce"
  colorecho "  ✓ bloodhound-ce installed"
}

# BloodHound legacy (4.x) is the pre-CE Electron GUI. SpecterOps archived it, so we
# pull the last prebuilt release rather than building the EOL Node 16 toolchain.
function install_bloodhound_legacy_desktop() {
  local install_root="/opt/tools/BloodHound-Legacy"
  local curl_tempfile zip_tempfile
  local tag_name asset_url arch_label bh_bin

  if command -v bloodhound-legacy >/dev/null 2>&1; then
    colorecho "  ✓ bloodhound-legacy already installed"
    add-aliases "bloodhound-legacy"
    add-history "bloodhound-legacy"
    return 0
  fi

  colorecho "  → Installing bloodhound-legacy (BloodHound 4.x Electron GUI)"

  case "$(uname -m)" in
    x86_64) arch_label="linux-x64" ;;
    aarch64) arch_label="linux-arm64"; install_pacman_tool "mesa" || true ;;
    *) colorecho "  ✗ Warning: unsupported architecture $(uname -m) for bloodhound-legacy"; return 1 ;;
  esac

  install_pacman_tool "jq" || return 1
  install_pacman_tool "unzip" || return 1
  install_neo4j || return 1

  mkdir -p "${install_root}"
  curl_tempfile="$(mktemp)"

  if ! curl -fsSL "https://api.github.com/repos/BloodHoundAD/BloodHound/releases/latest" -o "${curl_tempfile}"; then
    colorecho "  ✗ Warning: Failed to fetch BloodHound legacy release"
    rm -f "${curl_tempfile}"
    return 1
  fi

  tag_name="$(jq -r '.tag_name' "${curl_tempfile}")"
  asset_url="$(jq -r --arg a "BloodHound-${arch_label}.zip" '.assets[] | select(.name == $a) | .browser_download_url' "${curl_tempfile}")"
  rm -f "${curl_tempfile}"

  if [ -z "${asset_url}" ] || [ "${asset_url}" = "null" ]; then
    colorecho "  ✗ Warning: No BloodHound-${arch_label}.zip asset in release ${tag_name}"
    return 1
  fi

  zip_tempfile="$(mktemp --suffix=.zip)"
  if ! curl -fsSL "${asset_url}" -o "${zip_tempfile}"; then
    colorecho "  ✗ Warning: Failed to download BloodHound legacy ${tag_name}"
    rm -f "${zip_tempfile}"
    return 1
  fi

  rm -rf "${install_root}/app"
  if ! unzip -q -o "${zip_tempfile}" -d "${install_root}/app"; then
    colorecho "  ✗ Warning: Failed to extract BloodHound legacy archive"
    rm -f "${zip_tempfile}"
    return 1
  fi
  rm -f "${zip_tempfile}"

  # The zip unpacks to a BloodHound-<arch>/ subdir holding the Electron binary.
  bh_bin="$(find "${install_root}/app" -maxdepth 2 -type f -name BloodHound | head -1)"
  if [ -z "${bh_bin}" ]; then
    colorecho "  ✗ Warning: BloodHound binary not found after extraction"
    return 1
  fi
  chmod +x "${bh_bin}"
  ln -sf "${bh_bin}" "${install_root}/BloodHound"

  # Pre-seed the Neo4j connection so the GUI login is one click.
  local assets="${NIHIL_BUILD}/lib/installers/bloodhound-legacy"
  mkdir -p /root/.config/bloodhound
  cp "${assets}/config.json" /root/.config/bloodhound/config.json

  cp "${assets}/bloodhound-legacy" /opt/tools/bin/bloodhound-legacy
  cp "${assets}/bloodhound-legacy-stop" /opt/tools/bin/bloodhound-legacy-stop
  cp "${assets}/bloodhound-legacy-reset" /opt/tools/bin/bloodhound-legacy-reset
  chmod +x /opt/tools/bin/bloodhound-legacy /opt/tools/bin/bloodhound-legacy-stop /opt/tools/bin/bloodhound-legacy-reset

  add-aliases "bloodhound-legacy"
  add-history "bloodhound-legacy"
  colorecho "  ✓ bloodhound-legacy installed (${tag_name})"
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
  install_pipx_tool "evil-winrm-py" "evil-winrm-py[kerberos]"
}

function install_evil_winrm() {
  install_gem_tool "evil-winrm"
}

function install_asrepcatcher() {
    install_pipx_tool_git "ASRepCatcher" "https://github.com/Yaxxine7/ASRepCatcher"
}

function install_autobloody() {
    install_pipx_tool "autobloody" "autobloody"
}

function install_certsync() {
    install_pipx_tool "certsync" "certsync"
}

function install_crackhound() {
    install_git_tool "crackhound" "https://github.com/trustedsec/crackhound.git" "crackhound.py"
}

function install_godap() {
    install_go_tool "github.com/Macmod/godap@latest"
}

function install_goexec() {
    install_go_tool "github.com/FalconOpsLLC/goexec@latest"
}

function install_goldencopy() {
    install_pipx_tool "goldencopy" "goldencopy"
}

function install_gosecretsdump() {
    install_go_tool "github.com/C-Sto/gosecretsdump@latest"
}

function install_gpoddity() {
    install_pipx_tool_git "gpoddity" "https://github.com/synacktiv/GPOddity.git"
}

function install_gpp_decrypt() {
    install_git_tool_venv "gpp-decrypt" "https://github.com/t0thkr1s/gpp-decrypt" "gpp-decrypt.py" "pycryptodome colorama" "yes"
}

function install_keepwn() {
    # pipx registers the entry point as "KeePwn" (capital K+P), not "keepwn"
    install_pipx_tool_git "KeePwn" "https://github.com/Orange-Cyberdefense/KeePwn"
}

function install_krbjack() {
    install_pipx_tool "krbjack" "krbjack"
}

function install_ldaprelayscan() {
    install_git_tool "ldaprelayscan" "https://github.com/zyn3rgy/LdapRelayScan.git" "LdapRelayScan.py"
}

function install_ldeep() {
    install_pipx_tool "ldeep" "ldeep"
}

function install_ldapwordlistharvester() {
    install_git_tool "LDAPWordlistHarvester" "https://github.com/p0dalirius/pyLDAPWordlistHarvester.git" "LDAPWordlistHarvester.py"
}

function install_nbtscan() {
    install_pacman_tool "nbtscan"
}

function install_passthecert() {
    install_git_tool "passthecert" "https://github.com/AlmondOffSec/PassTheCert.git" "Python/passthecert.py"
}

function install_pcredz() {
    install_git_tool_venv "PCredz" "https://github.com/lgandx/PCredz.git" "Pcredz" "Crypto scapy" "yes"
}

function install_pygpoabuse() {
    install_pipx_tool_git "pygpoabuse" "https://github.com/Hackndo/pyGPOAbuse.git"
}

function install_sccmhunter() {
    if command -v sccmhunter > /dev/null 2>&1 || command -v sccmhunter.py > /dev/null 2>&1; then
        colorecho "  ✓ sccmhunter already installed (pipx)"
        return 0
    fi
    # pipx registers the entry point as "sccmhunter.py" (from pyproject.toml console_scripts)
    install_pipx_tool_git "sccmhunter.py" "https://github.com/garrettfoster13/sccmhunter.git" || return 1
    ln -sf "/root/.local/bin/sccmhunter.py" "/usr/bin/sccmhunter" 2>/dev/null || true
}

function install_teamsphisher() {
    install_git_tool_venv "teamsphisher" "https://github.com/Octoberfest7/TeamsPhisher.git" "teamsphisher.py" "msal colorama requests" "yes"
}

function install_netexec() {
  # Ensure Rust is available (required to build NetExec native extensions)
  if ! command -v rustc >/dev/null 2>&1; then
    pacman -Sy --noconfirm &&
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
    install_pipx_tool_git "aclpwn" "https://github.com/fox-it/aclpwn.py"
}

function install_abuseacl() {
  install_pipx_tool_git "abuseACL" "https://github.com/AetherBlack/abuseACL"
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

function install_krb5() {
  install_pacman_tool "krb5"
}

function install_openldap() {
    install_pacman_tool "openldap"
    add-history "ldapsearch"
}

# GSSAPI SASL plugin: enables Kerberos auth over LDAP/SASL (ldapsearch -Y GSSAPI,
# ldap3 / certipy / bloodyAD / netexec with -k). Library only, no binary.
function install_cyrus_sasl_gssapi() {
    install_pacman_tool "cyrus-sasl-gssapi"
}

function install_smbclientng() {
  install_pipx_tool "smbclientng" "smbclientng"
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

function install_rusthound() {
  install_cargo_tool "rusthound"
}

function install_bloodbash() {
  install_pipx_tool_git "bloodbash" "https://github.com/DotNetRussell/BloodBash"
}

function install_kerbrute() {
  install_go_tool "github.com/ropnop/kerbrute@latest"
}

function install_gofenrir() {
  install_go_tool "github.com/0xbbuddha/GoFenrir/cmd/gf@latest"
}

function install_krbrelayx() {
  install_git_tool_venv "krbrelayx" "https://github.com/dirkjanm/krbrelayx.git" "krbrelayx.py addspn.py printerbug.py dnstool.py" "dnspython ldap3 impacket dsinternals" "yes"
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

function install_smtp_user_enum() {
  install_pipx_tool "smtp-user-enum" "smtp-user-enum"
}

function install_ntlm_theft() {
  install_git_tool_venv "ntlm_theft" "https://github.com/Greenwolf/ntlm_theft.git" "ntlm_theft.py" "xlsxwriter" "yes"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_ad() {
  colorecho "Installing Active Directory red-team tools"

  colorecho "  [pipx] AD tools:"
  install_bloodhound_python
  install_bloodhound_ce_python
  install_ldapdomaindump
  install_adidnsdump
  install_certipy
  install_bloodyad
  install_evil_winrm_py
  install_evil_winrm
  install_gpp_decrypt
  install_netexec
  install_impacket
  install_bloodbash
  install_mitm6
  install_aclpwn
  install_abuseacl
  install_lsassy
  install_donpapi
  install_coercer
  install_pywhisker
  install_enum4linux_ng
  install_smbmap
  install_smbclientng
  install_sprayhound
  install_ldapsearch_ad
  install_pywerview
  install_masky
  install_manspider
  install_smtp_user_enum
  install_autobloody
  install_certsync
  install_goldencopy
  install_keepwn
  install_ldeep
  install_gpoddity
  install_asrepcatcher
  install_ldaprelayscan
  install_ldapwordlistharvester
  install_passthecert
  install_pcredz
  install_pygpoabuse
  install_sccmhunter
  install_teamsphisher
  install_crackhound

  colorecho "  [pipx-git] AD tools:"
  install_pre2k

  colorecho "  [pacman] AD tools:"
  install_krb5
  install_openldap
  install_cyrus_sasl_gssapi
  install_smbclient
  install_python_pcapy
  install_nbtscan

  colorecho "  [source-build] AD tools:"
  install_bloodhound_ce_desktop
  install_bloodhound_legacy_desktop

  colorecho "  [AUR] AD tools:"
  install_responder

  colorecho "  [cargo] AD tools:"
  install_rusthound_ce
  install_rusthound

  colorecho "  [go] AD tools:"
  install_kerbrute
  install_gofenrir
  install_windapsearch
  install_godap
  install_goexec
  install_gosecretsdump
  install_krbjack

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
  install_ntlm_theft

  colorecho "  [download] AD tools:"
  install_powershell

  colorecho "Active Directory tools installation finished"
}
