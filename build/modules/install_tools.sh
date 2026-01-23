#!/bin/bash
# Tools package installation

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

function package_base() {
    colorecho "Updating system and installing tools packages"
    pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed nmap && \
    pacman -Syu --noconfirm && \
    pacman -Sc --noconfirm
}