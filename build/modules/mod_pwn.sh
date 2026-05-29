#!/bin/bash
# Red-team tools for Pwn / Binary exploitation
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/cargo
nihil::import lib/registry/pacman
nihil::import lib/registry/aur
nihil::import lib/registry/gem

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
    # Install pwndbg from source (Exegol-style) into /opt/tools/gdb/pwndbg.
    # Its own setup.sh provisions a venv with pinned deps, which sidesteps the Arch
    # package dep-skew (capstone6pwndbg) that breaks a pacman install:
    #   ImportError: cannot import name 'CS_MODE_RISCVC' from 'capstone6pwndbg'
    if [ -f /opt/tools/gdb/pwndbg/gdbinit.py ]; then
        colorecho "  ✓ pwndbg already installed (source)"
    else
        colorecho "  → Installing pwndbg GDB plugin (from source)"
        mkdir -p /opt/tools/gdb
        if git-clone-retry "https://github.com/pwndbg/pwndbg.git" "/opt/tools/gdb/pwndbg"; then
            ( cd /opt/tools/gdb/pwndbg && ./setup.sh ) \
                || colorecho "  ✗ Warning: pwndbg setup.sh failed"
        else
            colorecho "  ✗ Warning: Failed to clone pwndbg"
        fi
    fi
    # Make `gdb` start pwndbg by default (Exegol-style):
    # ~/.gdbinit defines the init-pwndbg/init-peda/init-gef commands,
    # the aliases (gdb, gdb-peda, gdb-gef) trigger the chosen one on launch.
    cp /opt/nihil/build/assets/gdb/gdbinit /root/.gdbinit
    add-aliases "gdb"
}

function install_peda() {
    if [ -f /opt/tools/gdb/peda/peda.py ]; then
        colorecho "  ✓ peda already installed"
        return 0
    fi
    colorecho "  → Installing peda GDB plugin"
    mkdir -p /opt/tools/gdb
    git-clone-retry "https://github.com/longld/peda.git" "/opt/tools/gdb/peda" \
        || colorecho "  ✗ Warning: Failed to install peda"
}

function install_gef() {
    if [ -f /opt/tools/gdb/gef/gef.py ]; then
        colorecho "  ✓ gef already installed"
        return 0
    fi
    colorecho "  → Installing gef GDB plugin"
    mkdir -p /opt/tools/gdb/gef
    curl -sSLf "https://raw.githubusercontent.com/hugsy/gef/refs/heads/main/gef.py" \
        -o /opt/tools/gdb/gef/gef.py \
        || colorecho "  ✗ Warning: Failed to install gef"
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
    install_pwndbg

    colorecho "  [git] GDB plugins:"
    install_peda
    install_gef

    colorecho "  [pipx] Pwn / exploit tools:"
    install_pwntools
    install_ropgadget

    colorecho "  [gem] Pwn tools:"
    install_one_gadget
    install_seccomp_tools

    colorecho "Pwn tools installation finished"
}
