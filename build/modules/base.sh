#!/bin/bash
# Base package installation

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

function package_base() {
    colorecho "Updating system and installing base packages"
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
    apt-get -y update && \
    apt-get -y install apt-utils dialog && \
    apt-get -y upgrade && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    colorecho "Base packages installed"
}

