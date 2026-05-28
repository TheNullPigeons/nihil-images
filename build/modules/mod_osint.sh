#!/bin/bash
# Red-team tools for OSINT / reconnaissance
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/go
nihil::import lib/registry/git

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_amass() {
    install_go_tool "github.com/owasp-amass/amass/v4/cmd/amass@latest"
}

function install_recon_ng() {
    install_git_tool "recon-ng" "https://github.com/lanmaster53/recon-ng" "recon-ng"
}

function install_sherlock() {
    install_pipx_tool "sherlock" "sherlock-project"
}

function install_spiderfoot() {
    local install_dir="${GIT_INSTALL_DIR}/spiderfoot"
    local venv_dir="${install_dir}/venv"

    if command -v spiderfoot > /dev/null 2>&1; then
        colorecho "  ✓ spiderfoot already installed"
        return 0
    fi

    colorecho "  → Installing spiderfoot"
    git clone --depth 1 https://github.com/smicallef/spiderfoot "$install_dir" || {
        colorecho "  ✗ Warning: Failed to clone spiderfoot"
        return 1
    }

    python3 -m venv --system-site-packages "$venv_dir" || {
        colorecho "  ✗ Warning: Failed to create venv for spiderfoot"
        return 1
    }
    source "$venv_dir/bin/activate"
    pip install --quiet -r "$install_dir/requirements.txt" || {
        colorecho "  ✗ Warning: Failed to install spiderfoot requirements"
        deactivate
        return 1
    }
    deactivate

    mkdir -p "$GIT_BIN_DIR"
    cat > "${GIT_BIN_DIR}/spiderfoot" <<EOF
#!/bin/sh
cd "${install_dir}" || exit 1
exec "${venv_dir}/bin/python3" "${install_dir}/sf.py" "\$@"
EOF
    chmod +x "${GIT_BIN_DIR}/spiderfoot"

    add-history "spiderfoot"
    colorecho "  ✓ spiderfoot installed"
}

function install_sublist3r() {
    install_pipx_tool "sublist3r" "sublist3r"
}

function install_theharvester() {
    install_pipx_tool "theHarvester" "theHarvester"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_osint() {
    colorecho "Installing OSINT red-team tools"

    colorecho "  [go] OSINT tools:"
    install_amass

    colorecho "  [pipx] OSINT tools:"
    install_recon_ng
    install_sherlock
    install_spiderfoot
    install_sublist3r
    install_theharvester

    colorecho "OSINT tools installation finished"
}
