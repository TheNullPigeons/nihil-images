#!/bin/bash
# Red-team tools for Credentials / Password attacks
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/cargo
nihil::import lib/registry/pacman
nihil::import lib/registry/aur

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_pypykatz() {
    install_pipx_tool "pypykatz" "pypykatz"
}

function install_binwalk() {
    install_pacman_tool "binwalk"
}

function install_john() {
    install_pacman_tool "john"
}

function install_hashcat() {
    install_pacman_tool "hashcat"
}

function install_seclists() {
    local install_dir="/usr/share/seclists"

    if [ -d "$install_dir" ]; then
        colorecho "  ✓ seclists already installed"
        return 0
    fi

    if install_aur_tool "seclists" "seclists"; then
        return 0
    fi

    colorecho "  → Falling back to upstream SecLists repository"
    mkdir -p /usr/share
    if ! git-clone-retry "https://github.com/danielmiessler/SecLists.git" "$install_dir" 1 3; then
        colorecho "  ✗ Warning: Failed to clone upstream SecLists"
        return 1
    fi

    rm -rf "$install_dir/.git"
    colorecho "  ✓ seclists installed from upstream repository"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_credential() {
    colorecho "Installing Credential red-team tools"

    colorecho "  [pipx] Credential tools:"
    install_pypykatz

    colorecho "  [pacman] Credential tools:"
    install_binwalk
    install_john
    install_hashcat

    colorecho "  [AUR] Credential tools:"
    install_seclists

    colorecho "Credential tools installation finished"
}
