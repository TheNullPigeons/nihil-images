#!/bin/bash
# Outils red-team divers (exploit-db, etc.)

nihil::import lib/common
nihil::import lib/registry/git

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_searchsploit() {
    local install_dir="/opt/tools/exploitdb"
    local repo_url="https://gitlab.com/exploit-database/exploitdb.git"

    install_git_tool_symlink "$install_dir" "$repo_url" "searchsploit" || return 1
    if [ -f "$install_dir/.searchsploit_rc" ]; then
        cp -n "$install_dir/.searchsploit_rc" ~/.searchsploit_rc
        sed -i 's/\(.*[pP]aper.*\)/#\1/' ~/.searchsploit_rc
        sed -i 's|opt/exploitdb|opt/tools/exploitdb|g' ~/.searchsploit_rc
    fi
}


# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_cyberchef() {
    local install_dir="/opt/tools/CyberChef"

    if [ -d "$install_dir" ]; then
        colorecho "  ✓ CyberChef already installed"
        return 0
    fi

    colorecho "  → Installing CyberChef (offline)"
    mkdir -p "$install_dir"
    local latest_url
    latest_url=$(curl -s https://api.github.com/repos/gchq/CyberChef/releases/latest | \
        grep "browser_download_url.*CyberChef.*\.zip" | head -1 | cut -d'"' -f4)
    if [ -n "$latest_url" ]; then
        pacman -S --noconfirm --needed unzip 2>/dev/null || true
        curl -sSL "$latest_url" -o /tmp/cyberchef.zip && \
        unzip -o /tmp/cyberchef.zip -d "$install_dir" && \
        rm -f /tmp/cyberchef.zip
        colorecho "  ✓ CyberChef installed at $install_dir"
    else
        colorecho "  ✗ Warning: Failed to fetch CyberChef release URL"
        return 1
    fi
}

function install_firefox() {
    install_pacman_tool "firefox"
}
function install_chromium() {
    install_pacman_tool "chromium"
}



# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_misc() {
    colorecho "Installing misc red-team tools"

    install_searchsploit
    install_cyberchef
    install_firefox
    install_chromium

    colorecho "Misc red-team tools installation finished"
}
