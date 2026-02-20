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
# Module entry point
# ---------------------------------------------------------------------------

function install_redteam_web() {
    colorecho "Installing Web red-team tools"

    colorecho "  [pacman] Web scanners / fuzzers:"
    install_sqlmap
    install_gobuster
    install_nikto

    colorecho "  [pipx] Web fuzzers / scanners:"
    install_wfuzz
    install_arjun
    install_wafw00f
    install_gopherus
    install_droopescan
    install_cmsmap

    colorecho "  [git] Scripts (clone + requirements):"
    install_ssrfmap
    install_jwt_tool
    install_xsstrike

    colorecho "  [cargo] Web fuzzer:"
    install_feroxbuster

    colorecho "  [curl] Web SSL / script:"
    install_testssl

    colorecho "Web tools installation finished"
}
