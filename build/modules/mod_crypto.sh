#!/bin/bash
# Red-team tools for Cryptography
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/git

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_rsactftool() {
    install_git_tool_venv "RsaCtfTool" \
        "https://github.com/RsaCtfTool/RsaCtfTool.git" \
        "RsaCtfTool.py" \
        "" \
        "yes"
}

function install_xortool() {
    install_pipx_tool "xortool" "xortool"
}

function install_z3_solver() {
    colorecho "  → Installing z3-solver"
    if python3 -c "import z3" 2>/dev/null; then
        colorecho "  ✓ z3-solver already installed"
        return 0
    fi
    python3 -m pip install --break-system-packages z3-solver --quiet 2>/dev/null || \
        python3 -m pip install z3-solver --quiet 2>/dev/null || {
        colorecho "  ✗ Warning: Failed to install z3-solver"
        return 1
    }
    colorecho "  ✓ z3-solver installed"
}

function install_pycryptodome() {
    colorecho "  → Installing pycryptodome"
    if ! python3 -c "import Crypto" 2>/dev/null; then
        python3 -m pip install --break-system-packages pycryptodome --quiet 2>/dev/null || \
            python3 -m pip install pycryptodome --quiet 2>/dev/null || {
            colorecho "  ✗ Warning: Failed to install pycryptodome"
            return 1
        }
    fi
    cat > /usr/local/bin/pycryptodome <<'EOF'
#!/bin/sh
exec python3 -c "import Crypto,sys; print(Crypto.__name__)"
EOF
    chmod +x /usr/local/bin/pycryptodome
    colorecho "  ✓ pycryptodome installed"
}

function install_hashid() {
    install_pipx_tool "hashid" "hashid"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_crypto() {
    colorecho "Installing Crypto red-team tools"

    colorecho "  [git] Crypto tools:"
    install_rsactftool

    colorecho "  [pipx] Crypto tools:"
    install_xortool
    install_hashid

    colorecho "  [pip] Crypto libraries:"
    install_z3_solver
    install_pycryptodome

    colorecho "Crypto tools installation finished"
}
