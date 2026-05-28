#!/bin/bash
# Wordlists installation: SecLists and friends, centralized under /opt/lists.
#
# Convention: every wordlist lives under /opt/lists, with compatibility
# symlinks under /usr/share/seclists and /usr/share/wordlists for tools
# expecting the historical Kali-style locations.

nihil::import lib/common
nihil::import lib/registry/gem
nihil::import lib/registry/pipx
nihil::import lib/registry/pacman
nihil::import lib/registry/aur
nihil::import lib/registry/git

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function _ensure_lists_dir() {
    mkdir -p /opt/lists /usr/share/wordlists
}

# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------

function install_seclists() {
    local install_dir="/opt/lists/seclists"

    _ensure_lists_dir

    if [ -d "$install_dir" ]; then
        colorecho "  ✓ seclists already installed at $install_dir"
    else
        colorecho "  → Cloning SecLists into $install_dir"
        if ! git-clone-retry "https://github.com/danielmiessler/SecLists.git" "$install_dir" 1 3; then
            colorecho "  ✗ Warning: Failed to clone SecLists"
            return 1
        fi
        rm -rf "$install_dir/.git"
    fi

    # Compatibility symlinks (tools and history files reference these paths)
    ln -sfn "$install_dir" /usr/share/seclists
    ln -sfn "$install_dir" /usr/share/wordlists/seclists

    # Extract rockyou.txt next to seclists for direct access
    local rockyou_archive="$install_dir/Passwords/Leaked-Databases/rockyou.txt.tar.gz"
    if [ -f "$rockyou_archive" ] && [ ! -f /opt/lists/rockyou.txt ]; then
        colorecho "  → Extracting rockyou.txt"
        tar -xzf "$rockyou_archive" -C /opt/lists/ || colorecho "  ✗ Warning: Failed to extract rockyou.txt"
    fi
    if [ -f /opt/lists/rockyou.txt ]; then
        ln -sfn /opt/lists/rockyou.txt /usr/share/wordlists/rockyou.txt
    fi

    colorecho "  ✓ seclists installed at $install_dir"
}

function install_cewl() {
    install_git_tool_bundler "CeWL" "https://github.com/digininja/CeWL.git" "cewl.rb"
}

function install_crunch() {
    install_aur_tool "crunch" "crunch"
}

function install_cupp() {
    install_git_tool "cupp" "https://github.com/Mebus/cupp.git" "cupp.py"
}

function install_username_anarchy() {
    install_git_tool_symlink "/opt/tools/username-anarchy" \
        "https://github.com/urbanadventurer/username-anarchy.git" \
        "username-anarchy" \
        "username-anarchy"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_wordlists() {
    colorecho "Installing wordlists in /opt/lists"

    _ensure_lists_dir

    colorecho "  [git] Wordlists:"
    install_seclists

    install_cewl
    install_crunch
    install_cupp
    install_username_anarchy

    colorecho "Wordlists installation finished"
}
