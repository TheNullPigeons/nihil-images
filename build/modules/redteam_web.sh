#!/bin/bash
# Outils red-team orientés Web / HTTP
# Ce module installe les outils web (pacman/pipx/git/cargo/curl)
# Inspiré Exegol : outils faciles à installer et impactants

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/redteam_pipx.sh"
source "${SCRIPT_DIR}/redteam_cargo.sh"
source "${SCRIPT_DIR}/redteam_pacman.sh"
source "${SCRIPT_DIR}/redteam_curl.sh"
source "${SCRIPT_DIR}/redteam_git.sh"

function install_redteam_web() {
    colorecho "Installing Web red-team tools"

    colorecho "  [pacman] Web scanners / fuzzers:"
    install_pacman_tool "sqlmap"
    install_pacman_tool "gobuster"
    install_pacman_tool "nikto"

    colorecho "  [pipx] Web fuzzers / scanners:"
    install_pipx_tool_git "wfuzz" "https://github.com/xmendez/wfuzz.git"
    install_pipx_tool_git "arjun" "https://github.com/s0md3v/Arjun.git"
    install_pipx_tool "wafw00f" "wafw00f"
    install_pipx_tool_git "gopherus" "https://github.com/Esonhugh/Gopherus3.git"
    install_pipx_tool_git "droopescan" "https://github.com/SamJoan/droopescan.git"
    install_pipx_tool_git "cmsmap" "https://github.com/dionach/CMSmap.git"

    colorecho "  [git] Scripts (clone + requirements):"
    install_git_tool "ssrfmap" "https://github.com/swisskyrepo/SSRFmap.git" "ssrfmap.py"
    install_git_tool "jwt-tool" "https://github.com/ticarpi/jwt_tool.git" "jwt-tool.py"
    install_git_tool "xsstrike" "https://github.com/s0md3v/XSStrike.git" "xsstrike.py"

    install_aur_tool "patator" "patator"

    colorecho "  [cargo] Web fuzzer:"
    install_cargo_tool "feroxbuster"

    colorecho "  [curl] Web SSL / script:"
    install_download_tool "testssl.sh" "https://raw.githubusercontent.com/drwetter/testssl.sh/v3.2.2/testssl.sh"

    colorecho "Web tools installation finished"
}
