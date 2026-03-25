#!/bin/bash
# Red-team tools for Pwn / Binary exploitation
# Each tool has its own install_$TOOL function for easier maintenance.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${MODULE_DIR}/../lib/registry/pipx.sh"
source "${MODULE_DIR}/../lib/registry/cargo.sh"
source "${MODULE_DIR}/../lib/registry/pacman.sh"
source "${MODULE_DIR}/../lib/registry/aur.sh"
source "${MODULE_DIR}/../lib/registry/gem.sh"

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

function install_pwndbg() {
    local install_dir="/opt/tools/pwndbg"

    if [ -d "$install_dir" ]; then
        colorecho "  ✓ pwndbg already installed"
        return 0
    fi

    colorecho "  → Installing pwndbg (GDB plugin)"
    git clone --depth 1 https://github.com/pwndbg/pwndbg.git "$install_dir" || {
        colorecho "  ✗ Warning: Failed to clone pwndbg"
        return 1
    }
    cd "$install_dir" && ./setup.sh || {
        colorecho "  ✗ Warning: Failed to setup pwndbg"
        return 1
    }
    cd - > /dev/null

    add-aliases "pwndbg"
    add-history "pwndbg"
    colorecho "  ✓ pwndbg installed"
}

function install_one_gadget() {
    install_gem_tool "one_gadget"
}

function install_seccomp_tools() {
    install_gem_tool "seccomp-tools"
}

function install_checksec() {
    install_pacman_tool "checksec"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_pwn() {
    colorecho "Installing Pwn red-team tools"

    colorecho "  [pacman] Pwn / reverse tools:"
    install_radare2
    install_strace
    install_ltrace
    install_cmake
    install_checksec

    colorecho "  [pipx] Pwn / exploit tools:"
    install_pwntools
    install_ropgadget

    colorecho "  [git] Pwn tools:"
    install_pwndbg

    colorecho "  [gem] Pwn tools:"
    install_one_gadget
    install_seccomp_tools

    colorecho "Pwn tools installation finished"
}
