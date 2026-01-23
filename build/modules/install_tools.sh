#!/bin/bash
# Tools package installation

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

function install_tools() {
    colorecho "Updating system and installing tools packages"
    pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed nmap openbsd-netcat john sqlmap gobuster gdb binwalk whois && \
    pacman -Syu --noconfirm && \
    pacman -Sc --noconfirm

    colorecho "Tools packages installed"
}