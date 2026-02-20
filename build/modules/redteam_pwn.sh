#!/bin/bash
# Red-team tools for Pwn / Binary exploitation
# Each tool has its own install_$TOOL function for easier maintenance.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${MODULE_DIR}/../lib/registry/redteam_pipx.sh"
source "${MODULE_DIR}/../lib/registry/redteam_cargo.sh"
source "${MODULE_DIR}/../lib/registry/redteam_pacman.sh"
source "${MODULE_DIR}/../lib/registry/redteam_aur.sh"

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_radare2() {
    install_pacman_tool "radare2"
}

function install_strace() {
    install_pacman_tool "strace"
}

function install_ltrace() {
    install_pacman_tool "ltrace"
}

function install_cmake() {
    install_pacman_tool "cmake"
}

function install_pwntools() {
    install_pipx_tool "pwn" "pwntools"
}

function install_ropgadget() {
    install_pipx_tool "ROPgadget" "ROPgadget"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_redteam_pwn() {
    colorecho "Installing Pwn red-team tools"

    colorecho "  [pacman] Pwn / reverse tools:"
    install_radare2
    install_strace
    install_ltrace
    install_cmake

    colorecho "  [pipx] Pwn / exploit tools:"
    install_pwntools
    install_ropgadget

    colorecho "Pwn tools installation finished"
}
