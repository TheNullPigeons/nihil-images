#!/bin/bash
# Build entrypoint for package installation

set -e

# Load utilities and modules
source lib/common.sh
source modules/base.sh
source modules/install_tools.sh
source modules/netexec.sh

if [[ $EUID -ne 0 ]]; then
    criticalecho "This script must be run as root"
else
    if declare -f "$1" > /dev/null
    then
        if [[ -f '/.dockerenv' ]]; then
            "$@"
        else
            "$@"
        fi
    else
        echo "Unknown function: '$1'" >&2
        exit 1
    fi
fi
