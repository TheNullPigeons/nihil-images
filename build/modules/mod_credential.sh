#!/bin/bash
# Red-team tools for Credentials / Password attacks
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

function install_pypykatz() {
    install_pipx_tool "pypykatz" "pypykatz"
}

function install_binwalk() {
    install_pacman_tool "binwalk"
}

function install_haiti() {
    install_gem_tool "haiti" "haiti-hash"
}

function install_john() {
    install_pacman_tool "john"
}

function install_hashcat() {
    install_pacman_tool "hashcat"
}

function install_fcrackzip() {
    install_pacman_tool "fcrackzip"
}

function install_hydra() {
    install_pacman_tool "hydra"
}

function install_name_that_hash() {
    install_pipx_tool "nth" "name-that-hash"
}

function install_pdfcrack() {
    install_pacman_tool "pdfcrack"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_credential() {
    colorecho "Installing Credential red-team tools"

    colorecho "  [pipx] Credential tools:"
    install_pypykatz
    install_name_that_hash

    colorecho "  [gem] Credential tools:"
    install_haiti

    colorecho "  [pacman] Credential tools:"
    install_binwalk
    install_john
    install_hashcat
    install_fcrackzip
    install_hydra
    install_pdfcrack

    colorecho "Credential tools installation finished"
}
