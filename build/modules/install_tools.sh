#!/bin/bash
# Red-team tools installation (offensive tooling)

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

function install_redteam_tools() {
    colorecho "Updating system and installing red-team tools"
    pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed nmap openbsd-netcat john sqlmap gobuster binwalk && \
    pacman -Syu --noconfirm && \
    pacman -Sc --noconfirm

    colorecho "Red-team tools installed"
}