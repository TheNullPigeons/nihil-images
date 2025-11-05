#!/bin/bash
# Author: Nihil Project
# Entrypoint script for package installation during Docker build

set -e

# Load common utilities and modules
source lib/common.sh
source modules/base.sh

if [[ $EUID -ne 0 ]]; then
    criticalecho "This script must be run as root"
else
    if declare -f "$1" > /dev/null
    then
        if [[ -f '/.dockerenv' ]]; then
            echo -e "${GREEN}"
            echo "Running in Docker container"
            echo -e "${NOCOLOR}"
            "$@"
        else
            echo -e "${RED}"
            echo "[!] Warning: This script is intended to run inside Docker/VM. Do not run on your host system unless you know what you are doing and have backups."
            echo -e "${NOCOLOR}"
            "$@"
        fi
    else
        echo "Unknown function: '$1'" >&2
        exit 1
    fi
fi
