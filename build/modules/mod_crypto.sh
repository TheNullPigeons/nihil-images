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
    local tool_name="RsaCtfTool"
    local git_url="https://github.com/RsaCtfTool/RsaCtfTool.git"
    local repo_dir="${GIT_INSTALL_DIR}/${tool_name}"
    local venv_dir="${repo_dir}/venv"

    if command -v RsaCtfTool >/dev/null 2>&1; then
        colorecho "  ✓ RsaCtfTool already installed"
        return 0
    fi

    colorecho "  → Installing RsaCtfTool via Git with venv ($git_url)"

    if [ ! -d "$repo_dir" ]; then
        git clone --depth=1 "$git_url" "$repo_dir" || {
            colorecho "  ✗ Warning: Failed to clone RsaCtfTool"
            return 1
        }
    fi

    python3 -m venv --system-site-packages "$venv_dir" || {
        colorecho "  ✗ Warning: Failed to create venv for RsaCtfTool"
        return 1
    }

    source "$venv_dir/bin/activate"
    # Try installing via setup.py/pyproject.toml first (handles repo restructuring)
    if [ -f "$repo_dir/setup.py" ] || [ -f "$repo_dir/pyproject.toml" ]; then
        pip install --quiet "$repo_dir" 2>/dev/null || true
    fi
    # Fallback: install from requirements.txt
    if [ -f "$repo_dir/requirements.txt" ]; then
        pip install --quiet -r "$repo_dir/requirements.txt" 2>/dev/null || true
    fi
    deactivate

    mkdir -p "$GIT_BIN_DIR"
    local wrapper="${GIT_BIN_DIR}/RsaCtfTool"

    if [ -f "$venv_dir/bin/RsaCtfTool" ]; then
        # Entry point installed by pip
        cat > "$wrapper" <<EOF
#!/bin/sh
exec "$venv_dir/bin/RsaCtfTool" "\$@"
EOF
    elif [ -f "$repo_dir/RsaCtfTool.py" ]; then
        # Classic .py entrypoint at repo root
        cat > "$wrapper" <<EOF
#!/bin/sh
cd "$repo_dir" || exit 1
source "$venv_dir/bin/activate"
exec python3 "$repo_dir/RsaCtfTool.py" "\$@"
EOF
    else
        colorecho "  ✗ Warning: Could not find RsaCtfTool entry point after install"
        return 1
    fi

    chmod +x "$wrapper"
    add-aliases "RsaCtfTool"
    add-history "RsaCtfTool"
    colorecho "  ✓ RsaCtfTool installed"
}

function install_xortool() {
    install_pipx_tool "xortool" "xortool"
}

function install_z3_solver() {
    colorecho "  → Installing z3-solver"
    if ! python3 -c "import z3" 2>/dev/null; then
        python3 -m pip install --break-system-packages z3-solver --quiet 2>/dev/null || \
            python3 -m pip install z3-solver --quiet 2>/dev/null || {
            colorecho "  ✗ Warning: Failed to install z3-solver"
            return 1
        }
    fi
    cat > /usr/local/bin/z3-solver <<'EOF'
#!/bin/sh
exec python3 -c "import z3, sys; print('z3-solver', z3.__version__)"
EOF
    chmod +x /usr/local/bin/z3-solver
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
