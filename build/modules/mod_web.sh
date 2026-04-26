#!/bin/bash
# Red-team tools for Web / HTTP
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/cargo
nihil::import lib/registry/pacman
nihil::import lib/registry/aur
nihil::import lib/registry/curl
nihil::import lib/registry/git
nihil::import lib/registry/go

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_sqlmap() {
    install_pacman_tool "sqlmap"
}

function install_gobuster() {
    install_pacman_tool "gobuster"
}

function install_nikto() {
    install_pacman_tool "nikto"
}

function install_wfuzz() {
    install_pipx_tool_git "wfuzz" "https://github.com/xmendez/wfuzz.git"
}

function install_arjun() {
    install_pipx_tool_git "arjun" "https://github.com/s0md3v/Arjun.git"
}

function install_wafw00f() {
    install_pipx_tool "wafw00f" "wafw00f"
}

function install_gopherus() {
    install_pipx_tool_git "gopherus3" "https://github.com/Esonhugh/Gopherus3.git"
    add-symlink "/root/.local/bin/gopherus3" "gopherus"
}

function install_droopescan() {
    install_pipx_tool_git "droopescan" "https://github.com/SamJoan/droopescan.git"
}

function install_cmsmap() {
    install_pipx_tool_git "cmsmap" "https://github.com/dionach/CMSmap.git"
}

function install_ssrfmap() {
    install_git_tool "ssrfmap" "https://github.com/swisskyrepo/SSRFmap.git" "ssrfmap.py"
}

function install_jwt_tool() {
    install_git_tool "jwt-tool" "https://github.com/ticarpi/jwt_tool.git" "jwt-tool.py"
}

function install_xsstrike() {
    install_git_tool "xsstrike" "https://github.com/s0md3v/XSStrike.git" "xsstrike.py"
}

function install_feroxbuster() {
    install_cargo_tool "feroxbuster"
}

function install_testssl() {
    install_download_tool "testssl.sh" "https://raw.githubusercontent.com/drwetter/testssl.sh/v3.2.2/testssl.sh"
}

# ---------------------------------------------------------------------------
# Scanners / Discovery (ProjectDiscovery suite + others)
# ---------------------------------------------------------------------------

function install_nuclei() {
    install_go_tool "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
}

function install_httpx_pd() {
    install_go_tool "github.com/projectdiscovery/httpx/cmd/httpx@latest"
}

function install_subfinder() {
    install_go_tool "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
}

function install_katana() {
    install_go_tool "github.com/projectdiscovery/katana/cmd/katana@latest"
}

function install_ffuf() {
    install_go_tool "github.com/ffuf/ffuf/v2@latest" "ffuf"
}

function install_dirsearch() {
    install_pipx_tool "dirsearch" "dirsearch"
}

function install_whatweb() {
    install_git_tool "whatweb" "https://github.com/urbanadventurer/WhatWeb.git" "whatweb"
}

function install_hakrawler() {
    install_go_tool "github.com/hakluke/hakrawler@latest"
}

function install_gau() {
    install_go_tool "github.com/lc/gau/v2/cmd/gau@latest"
}

function install_waybackurls() {
    install_go_tool "github.com/tomnomnom/waybackurls@latest"
}

# ---------------------------------------------------------------------------
# Exploitation
# ---------------------------------------------------------------------------

function install_commix() {
    install_pipx_tool_git "commix" "https://github.com/commixproject/commix.git"
}

function install_tplmap() {
    install_git_tool "tplmap" "https://github.com/epinna/tplmap" "tplmap.py"
}

function install_nosqlmap() {
    install_git_tool_venv "nosqlmap" "https://github.com/codingo/NoSQLMap" "nosqlmap.py" "" "yes"
}

function install_graphqlmap() {
    install_pipx_tool_git "graphqlmap" "https://github.com/swisskyrepo/GraphQLmap.git"
}

function install_corsy() {
    install_git_tool "corsy" "https://github.com/s0md3v/Corsy" "corsy.py"
}

function install_crlfuzz() {
    install_go_tool "github.com/dwisiswant0/crlfuzz/cmd/crlfuzz@latest"
}

# ---------------------------------------------------------------------------
# Proxy / Interception
# ---------------------------------------------------------------------------

function install_mitmproxy() {
    install_pipx_tool "mitmproxy" "mitmproxy" "mitmdump"
}

# ---------------------------------------------------------------------------
# API Testing / HTTP clients
# ---------------------------------------------------------------------------

function install_kiterunner() {
    install_tar_tool "kiterunner" \
        "https://github.com/assetnote/kiterunner/releases/download/v{version}/kiterunner_{version}_linux_amd64.tar.gz" \
        "/usr/local/share/kiterunner/{version}" \
        "kr" \
        "kr kiterunner" \
        "" \
        "1.0.2"
}

function install_httpie() {
    install_pacman_tool "httpie"
}

function install_caido() {
    local caido_bin
    local caido_cli_bin
    local arch
    local release_json

    colorecho "  → Installing Caido (desktop + CLI)"

    # Runtime deps for the desktop app (Electron/GTK)
    local electron_deps=(
        atk
        at-spi2-atk
        at-spi2-core
        gtk3
        nss
        libxss
        libdrm
        libxcomposite
        libxdamage
        libxrandr
        mesa
        xdg-utils
        alsa-lib
    )
    for dep in "${electron_deps[@]}"; do
        install_pacman_tool "$dep" || true
    done

    # 1) Try AUR first on Arch
    install_aur_tool "caido-desktop" "caido" || colorecho "  ✗ Warning: Failed to install caido-desktop from AUR"
    install_aur_tool "caido-cli" "caido-cli" || colorecho "  ✗ Warning: Failed to install caido-cli from AUR"

    # 2) Normalize paths for healthcheck expectations
    caido_bin="$(command -v caido 2>/dev/null || true)"
    if [ -n "$caido_bin" ]; then
        ln -sf "$caido_bin" /usr/local/bin/caido
    fi
    caido_cli_bin="$(command -v caido-cli 2>/dev/null || true)"
    if [ -n "$caido_cli_bin" ]; then
        ln -sf "$caido_cli_bin" /usr/local/bin/caido-cli
    fi

    if [ -x /usr/local/bin/caido ] && command -v caido-cli >/dev/null 2>&1; then
        colorecho "  ✓ Caido binaries detected"
        add-aliases "caido"
        add-history "caido"
        return 0
    fi

    # 3) Fallback: install from upstream release assets
    colorecho "  → Falling back to upstream release downloads"
    arch="$(uname -m)"

    release_json="$(curl -fsSL https://api.caido.io/releases/latest 2>/dev/null)" || release_json=""
    if [ -z "$release_json" ]; then
        colorecho "  ✗ Warning: Failed to fetch Caido release metadata"
        return 0
    fi

    local appimage_url
    local cli_url

    appimage_url="$(ARCH="$arch" python3 -c 'import sys, json, os
data=json.load(sys.stdin)
arch=os.environ.get("ARCH","")
assets=data.get("assets",[])
links=[a.get("link","") for a in assets if a.get("link")]
app=[l for l in links if l.endswith(".AppImage")]
if not app:
    print("")
    raise SystemExit
arch_map={
  "x86_64":["amd64","x86_64","linux-x86_64","linux-amd64"],
  "aarch64":["arm64","aarch64","linux-arm64","linux-aarch64"],
  "armv7l":["armv7l","arm-linux-gnueabihf","linux-armv7l"],
}
want=arch_map.get(arch,[arch])
for w in want:
    if not w: 
        continue
    for l in app:
        if w in l:
            print(l)
            raise SystemExit
print(app[0])' <<<"$release_json")"

    cli_url="$(ARCH="$arch" python3 -c 'import sys, json, os
data=json.load(sys.stdin)
arch=os.environ.get("ARCH","")
assets=data.get("assets",[])
links=[a.get("link","") for a in assets if a.get("link")]
cli=[l for l in links if "caido-cli" in l and l.endswith(".tar.gz")]
if not cli:
    print("")
    raise SystemExit
arch_map={
  "x86_64":["amd64","x86_64","linux-x86_64","linux-amd64"],
  "aarch64":["arm64","aarch64","linux-arm64","linux-aarch64"],
  "armv7l":["armv7l","arm-linux-gnueabihf","linux-armv7l"],
}
want=arch_map.get(arch,[arch])
for w in want:
    if not w:
        continue
    for l in cli:
        if w in l:
            print(l)
            raise SystemExit
print(cli[0])' <<<"$release_json")"

    mkdir -p /opt/tools/caido /opt/tools/bin

    if [ -n "$appimage_url" ]; then
        local appimage_name
        appimage_name="$(basename "$appimage_url")"
        if curl -fsSL "$appimage_url" -o "/opt/tools/caido/${appimage_name}" 2>/dev/null; then
            chmod +x "/opt/tools/caido/${appimage_name}" || true
            ln -sf "/opt/tools/caido/${appimage_name}" /usr/local/bin/caido
        fi
    fi

    if [ -n "$cli_url" ]; then
        local cli_archive
        cli_archive="/tmp/$(basename "$cli_url")"
        if curl -fsSL "$cli_url" -o "$cli_archive" 2>/dev/null; then
            if tar -xzf "$cli_archive" -C /opt/tools/bin 2>/dev/null; then
                if [ -f /opt/tools/bin/caido-cli ]; then
                    chmod +x /opt/tools/bin/caido-cli || true
                    ln -sf /opt/tools/bin/caido-cli /usr/local/bin/caido-cli
                else
                    local extracted
                    extracted="$(python3 -c 'import os
root="/opt/tools/bin"
target="caido-cli"
for dp,_,files in os.walk(root):
  for f in files:
    if f==target:
      print(os.path.join(dp,f))
      raise SystemExit
print("")')"
                    if [ -n "$extracted" ] && [ -f "$extracted" ]; then
                        chmod +x "$extracted" || true
                        ln -sf "$extracted" /usr/local/bin/caido-cli
                    fi
                fi
            fi
            rm -f "$cli_archive" || true
        fi
    fi

    add-aliases "caido"
    add-history "caido"
}

# ---------------------------------------------------------------------------
# Burp Suite Community
# ---------------------------------------------------------------------------

function install_burpsuite() {
    colorecho "  → Installing Burp Suite Community"
    install_pacman_tool "jdk-openjdk"
    install_pacman_tool "nss"
    local burp_dir="/opt/tools/BurpSuiteCommunity"
    mkdir -p "$burp_dir"
    local burp_version
    burp_version=$(curl -s "https://portswigger.net/burp/releases#community" | grep -P -o "\d{4}-\d-\d" | head -1 | tr - .)
    wget -q "https://portswigger.net/burp/releases/download?product=community&version=${burp_version}&type=Jar" \
        -O "${burp_dir}/BurpSuiteCommunity.jar"
    cp /opt/nihil/build/assets/burpsuite/conf.json "${burp_dir}/conf.json"
    printf '#!/bin/bash\nexec java -jar -Xmx4g /opt/tools/BurpSuiteCommunity/BurpSuiteCommunity.jar "$@"\n' \
        > /usr/local/bin/burpsuite
    chmod +x /usr/local/bin/burpsuite
    colorecho "  ✓ Burp Suite Community installed at ${burp_dir}"
}

# ---------------------------------------------------------------------------
# Offline resources
# ---------------------------------------------------------------------------

function install_payloadsallthethings() {
    local install_dir="/opt/resources/PayloadsAllTheThings"
    colorecho "  → Cloning PayloadsAllTheThings"
    if [ ! -d "$install_dir" ]; then
        git clone --depth 1 "https://github.com/swisskyrepo/PayloadsAllTheThings.git" "$install_dir" || {
            colorecho "  ✗ Warning: Failed to clone PayloadsAllTheThings"
            return 1
        }
    fi
    colorecho "  ✓ PayloadsAllTheThings installed at $install_dir"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_web() {
    colorecho "Installing Web red-team tools"

    colorecho "  [pacman] Web scanners / fuzzers:"
    install_sqlmap
    install_gobuster
    install_nikto
    install_httpie

    colorecho "  [pipx] Web fuzzers / scanners:"
    install_wfuzz
    install_arjun
    install_wafw00f
    install_gopherus
    install_droopescan
    install_cmsmap
    install_dirsearch
    install_commix
    install_mitmproxy

    colorecho "  [pipx-git] Web scanners:"
    install_graphqlmap

    colorecho "  [go] Web scanners / discovery:"
    install_nuclei
    install_httpx_pd
    install_subfinder
    install_katana
    install_ffuf
    install_hakrawler
    install_gau
    install_waybackurls
    install_crlfuzz

    colorecho "  [git] Scripts (clone + requirements):"
    install_ssrfmap
    install_jwt_tool
    install_xsstrike
    install_tplmap
    install_nosqlmap
    install_corsy
    install_whatweb

    colorecho "  [cargo] Web fuzzer:"
    install_feroxbuster

    colorecho "  [curl/download] Web tools:"
    install_testssl
    install_kiterunner
    install_caido
    install_burpsuite

    colorecho "  [resources] Offline payloads / cheat sheets:"
    install_payloadsallthethings

    colorecho "Web tools installation finished"
}
