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
    # Guard on the venv, not gdbinit.py: the clone creates gdbinit.py, so checking
    # it would mark a half-finished install (no venv) as "done" and ship a broken
    # pwndbg that aborts on every launch with "Cannot find Pwndbg virtualenv".
    if [ -x /opt/tools/gdb/pwndbg/.venv/bin/python ]; then
        colorecho "  ✓ pwndbg already installed (source)"
    else
        colorecho "  → Installing pwndbg GDB plugin (from source)"
        mkdir -p /opt/tools/gdb
        if git-clone-retry "https://github.com/pwndbg/pwndbg.git" "/opt/tools/gdb/pwndbg"; then
            # We can't use pwndbg's setup.sh: it runs `sudo pacman -S ...` and, under
            # `set -e`, aborts before creating the venv when the pacman sync db is
            # absent during the image build. Our base image already ships gdb, python,
            # git, etc., so we provision the venv directly, mirroring setup.sh's steps
            # (use GDB's own Python so the C-extension ABI matches).
            local gdb_python
            gdb_python=$(gdb -batch -q --nx -ex 'pi import sysconfig; print(sysconfig.get_config_vars().get("EXENAME", sysconfig.get_config_var("BINDIR")+"/python"+sysconfig.get_config_var("VERSION")+sysconfig.get_config_var("EXE")))')
            if ( cd /opt/tools/gdb/pwndbg \
                    && "$gdb_python" -m venv .venv \
                    && .venv/bin/pip install -q uv \
                    && .venv/bin/uv sync ); then
                colorecho "  ✓ pwndbg venv provisioned"
            else
                colorecho "  ✗ Warning: pwndbg venv setup failed"
            fi
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
    if git-clone-retry "https://github.com/longld/peda.git" "/opt/tools/gdb/peda"; then
        # peda vendors six 1.9.0 (2015) in lib/ and prepends that dir to sys.path.
        # That version's six.moves is incompatible with Python 3.14 and makes peda
        # fail to load with "No module named 'six.moves'". Refresh the vendored copy
        # with a current six so peda loads under GDB's modern Python.
        if python3 -m pip install -q --break-system-packages --upgrade six; then
            cp "$(python3 -c 'import six, sys; sys.stdout.write(six.__file__)')" \
               /opt/tools/gdb/peda/lib/six.py \
               && rm -rf /opt/tools/gdb/peda/lib/__pycache__
        else
            colorecho "  ✗ Warning: failed to refresh peda's vendored six"
        fi
    else
        colorecho "  ✗ Warning: Failed to install peda"
    fi
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
