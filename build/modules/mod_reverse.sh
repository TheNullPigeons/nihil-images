#!/bin/bash
# Red-team tools for Reverse Engineering
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/pacman

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_ghidra() {
    install_pacman_tool "ghidra"
}

function install_angr() {
    install_pipx_tool "angr" "angr"
}

function install_pycdc() {
    local install_dir="/opt/tools/pycdc"

    if command -v pycdc > /dev/null 2>&1; then
        colorecho "  ✓ pycdc already installed"
        return 0
    fi

    colorecho "  → Installing pycdc (Python bytecode decompiler)"
    pacman -S --noconfirm --needed cmake || true
    git clone --depth 1 https://github.com/zrax/pycdc.git "$install_dir" || {
        colorecho "  ✗ Warning: Failed to clone pycdc"
        return 1
    }
    cd "$install_dir" && cmake . && make || {
        colorecho "  ✗ Warning: Failed to build pycdc"
        return 1
    }
    ln -sf "$install_dir/pycdc" /usr/local/bin/pycdc
    ln -sf "$install_dir/pycdas" /usr/local/bin/pycdas
    cd - > /dev/null

    colorecho "  ✓ pycdc installed"
}

function install_uncompyle6() {
    install_pipx_tool "uncompyle6" "uncompyle6"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_reverse() {
    colorecho "Installing Reverse Engineering red-team tools"

    colorecho "  [pacman] Reverse tools:"
    install_ghidra

    colorecho "  [pipx] Reverse tools:"
    install_angr
    install_uncompyle6

    colorecho "  [git] Reverse tools:"
    install_pycdc

    colorecho "Reverse Engineering tools installation finished"
}
