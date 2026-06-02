#!/bin/bash
# Red-team tools for Command & Control (C2)
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pacman
nihil::import lib/registry/git
nihil::import lib/registry/pipx
nihil::import lib/registry/go

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_metasploit() {
    local repo_dir="/usr/local/share/metasploit-framework"

    install_git_tool_bundler \
        "metasploit-framework" \
        "https://github.com/rapid7/metasploit-framework.git" \
        "msfconsole msfvenom msfdb msfrpc msfd" \
        "ruby ruby-bundler postgresql libpcap zlib sqlite ruby-pg" \
        "rex rex-text timeout:0.4.1" \
        "--without test development" \
        "metasploit" || return 1

    # Metasploit-specific configuration (PostgreSQL, PEASS module)
    colorecho "  → Configuring Metasploit-specific settings"

    # Initialize msfdb with PostgreSQL
    colorecho "  → Initializing Metasploit database"

    # Create postgres user if needed
    if ! id -u postgres > /dev/null 2>&1; then
        useradd -r -d /var/lib/postgres -s /bin/bash postgres || true
    fi

    # Initialize PostgreSQL data directory if needed
    if [ ! -d "/var/lib/postgres/data" ]; then
        mkdir -p /var/lib/postgres
        chown postgres:postgres /var/lib/postgres
        sudo -u postgres initdb -D /var/lib/postgres/data || true
    fi

    # Start PostgreSQL
    if command -v systemctl > /dev/null 2>&1; then
        systemctl start postgresql || true
        systemctl enable postgresql || true
    else
        # Fallback: start manually when systemd is not available (Docker)
        sudo -u postgres pg_ctl -D /var/lib/postgres/data -l /var/lib/postgres/logfile start || true
    fi

    # Copy .bundle for postgres user and initialize msfdb
    if [ -d "/root/.bundle" ]; then
        cp -r /root/.bundle /var/lib/postgres/ 2>/dev/null || true
        chown -R postgres:postgres /var/lib/postgres/.bundle 2>/dev/null || true
    fi

    # Mark the repo as safe for the postgres user
    sudo -u postgres git config --global --add safe.directory "$repo_dir" || true

    # Initialize msfdb
    cd "$repo_dir" || return 1
    sudo -u postgres bundle exec ruby msfdb init || {
        colorecho "  ✗ Warning: Failed to initialize msfdb, continuing anyway"
    }

    # Copy msf4 config to root
    if [ -d "/var/lib/postgres/.msf4" ]; then
        cp -r /var/lib/postgres/.msf4 /root/ 2>/dev/null || true
        chown -R root:root /root/.msf4 2>/dev/null || true
    fi

    # Install PEASS Ruby MSF module
    colorecho "  → Installing PEASS MSF module"
    mkdir -p "$repo_dir/modules/post/multi/gather"
    wget -q https://raw.githubusercontent.com/peass-ng/PEASS-ng/master/metasploit/peass.rb -O "$repo_dir/modules/post/multi/gather/peass.rb" || {
        colorecho "  ✗ Warning: Failed to download PEASS module"
    }

    colorecho "  ✓ Metasploit configured"
    return 0
}

function install_silverc2() {
    colorecho "  → Installing Sliver C2 (server + client)"
    local installer="${NIHIL_BUILD}/lib/installers/sliver/sliver_install.sh"
    if [ -f "$installer" ]; then
        bash "$installer" || colorecho "  ✗ Warning: Sliver installation failed"
    else
        colorecho "  ✗ Warning: sliver_install.sh not found; skipping Sliver installation"
    fi
}

function install_penelope() {
    install_pipx_tool_git "penelope" "https://github.com/brightio/penelope"
}

function install_pwncat_vl() {
    install_pipx_tool "pwncat-vl" "pwncat-vl"
    pipx inject pwncat-vl cryptography==36.0.2 2>/dev/null || true
}

function install_mythic_cli() {
    local install_dir="/opt/tools/mythic"
    local repo_dir="/tmp/mythic-src"

    if command -v mythic-cli > /dev/null 2>&1; then
        colorecho "  ✓ mythic-cli already installed"
        return 0
    fi

    colorecho "  → Installing mythic-cli (Mythic C2 management CLI, build from source)"

    _ensure_go || return 0

    git clone --depth 1 https://github.com/its-a-feature/Mythic.git "$repo_dir" 2>/dev/null || {
        colorecho "  ✗ Warning: Failed to clone Mythic"
        return 0
    }

    mkdir -p "$install_dir"
    (cd "$repo_dir/Mythic_CLI/src" && go build -o "$install_dir/mythic-cli" .) || {
        colorecho "  ✗ Warning: Failed to build mythic-cli"
        rm -rf "$repo_dir"
        return 0
    }

    rm -rf "$repo_dir"
    ln -sf "$install_dir/mythic-cli" /opt/tools/bin/mythic-cli
    add-history "mythic-cli"
    colorecho "  ✓ mythic-cli installed"
    return 0
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_c2() {
    colorecho "Installing Command & Control red-team tools"

    colorecho "  [git] C2 tools:"
    install_metasploit
    install_silverc2

    colorecho "  [pipx] C2 tools:"
    install_penelope
    install_pwncat_vl

    colorecho "  [bin] C2 management:"
    install_mythic_cli

    colorecho "Command & Control tools installation finished"
}
