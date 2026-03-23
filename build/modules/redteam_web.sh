#!/bin/bash
# Red-team tools for Web / HTTP
# Each tool has its own install_$TOOL function for easier maintenance.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${MODULE_DIR}/../lib/registry/redteam_pipx.sh"
source "${MODULE_DIR}/../lib/registry/redteam_cargo.sh"
source "${MODULE_DIR}/../lib/registry/redteam_pacman.sh"
source "${MODULE_DIR}/../lib/registry/redteam_curl.sh"
source "${MODULE_DIR}/../lib/registry/redteam_git.sh"
source "${MODULE_DIR}/../lib/registry/redteam_go.sh"

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
    install_pipx_tool_git "gopherus" "https://github.com/Esonhugh/Gopherus3.git"
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

function install_redteam_web() {
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

    colorecho "  [resources] Offline payloads / cheat sheets:"
    install_payloadsallthethings

    colorecho "Web tools installation finished"
}
