#!/bin/bash
# Outils red-team orientés pwn / exploitation binaire
# Ce module installe les outils pwn en appelant les registres (pipx/cargo/pacman/aur)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/redteam_pipx.sh"
source "${SCRIPT_DIR}/redteam_cargo.sh"
source "${SCRIPT_DIR}/redteam_pacman.sh"
source "${SCRIPT_DIR}/redteam_aur.sh"

function install_redteam_pwn() {
    colorecho "Installing Pwn red-team tools"

    colorecho "  [pacman] Pwn / reverse tools:"
    install_pacman_tool "radare2"
    install_pacman_tool "strace"
    install_pacman_tool "ltrace"
    install_pacman_tool "cmake"

    colorecho "  [AUR] Pwn / reverse tools:"
    install_aur_tool "binaryninja-free" "binaryninja"

    colorecho "  [pipx] Pwn / exploit tools:"
    install_pipx_tool "pwn" "pwntools"
    install_pipx_tool "ROPgadget" "ROPgadget"
    install_pipx_tool "pwndbg" "pwndbg"

    colorecho "Pwn tools installation finished"
}
