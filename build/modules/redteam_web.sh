#!/bin/bash
# Outils red-team orientés Web / HTTP
# Ce module installe les outils web (pipx/cargo/pacman/curl)
# Inspiré Exegol : outils faciles à installer et impactants

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/redteam_pipx.sh"
source "${SCRIPT_DIR}/redteam_cargo.sh"
source "${SCRIPT_DIR}/redteam_pacman.sh"
source "${SCRIPT_DIR}/redteam_curl.sh"

function install_redteam_web() {
    colorecho "Installing Web red-team tools"

    colorecho "  [pacman] Web scanners / fuzzers:"
    install_pacman_tool "sqlmap"
    install_pacman_tool "gobuster"
    install_pacman_tool "nikto"

    colorecho "  [pipx] Web fuzzers / scanners:"
    install_pipx_tool "wfuzz" "wfuzz"
    install_pipx_tool "arjun" "arjun"
    install_pipx_tool "xsstrike" "xsstrike"
    install_pipx_tool "wafw00f" "wafw00f"
    install_pipx_tool "ssrfmap" "ssrfmap"
    install_pipx_tool "gopherus" "gopherus"
    install_pipx_tool "smuggler" "smuggler"
    install_pipx_tool "droopescan" "droopescan"
    install_pipx_tool "cmsmap" "cmsmap"
    install_pipx_tool "patator" "patator"
    install_pipx_tool "jwt_tool" "jwt-tool"

    colorecho "  [cargo] Web fuzzer:"
    install_cargo_tool "feroxbuster"

    colorecho "  [curl] Web SSL / script:"
    install_download_tool "testssl.sh" "https://raw.githubusercontent.com/drwetter/testssl.sh/v3.2.2/testssl.sh"

    colorecho "Web tools installation finished"
}
