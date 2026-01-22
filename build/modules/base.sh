#!/bin/bash
# Base package installation

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

function package_base() {
    colorecho "Updating system and installing base packages"
    pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed base base-devel dialog python python-pip python-wheel python-setuptools && \
    pacman -Syu --noconfirm && \
    pacman -Sc --noconfirm
    colorecho "Base packages installed"
}

