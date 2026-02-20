#!/bin/bash
# Red-team tools for Command & Control (C2)
# Each tool has its own install_$TOOL function for easier maintenance.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${MODULE_DIR}/../lib/registry/redteam_pacman.sh"
source "${MODULE_DIR}/../lib/registry/redteam_git.sh"

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

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_redteam_c2() {
    colorecho "Installing Command & Control red-team tools"

    colorecho "  [git] C2 tools:"
    install_metasploit

    colorecho "Command & Control tools installation finished"
}
