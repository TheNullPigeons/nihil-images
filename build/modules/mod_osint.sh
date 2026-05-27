#!/bin/bash
# Red-team tools for OSINT / reconnaissance
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/go

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_amass() {
    install_go_tool "github.com/owasp-amass/amass/v4/cmd/amass@latest"
}

function install_recon_ng() {
    install_pipx_tool_git "recon-ng" "https://github.com/lanmaster53/recon-ng"
}

function install_sherlock() {
    install_pipx_tool "sherlock" "sherlock-project"
}

function install_spiderfoot() {
    install_pipx_tool "spiderfoot" "spiderfoot"
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
