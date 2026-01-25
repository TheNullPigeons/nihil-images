#!/bin/bash
# Build entrypoint for package installation

set -e

# Load utilities and modules
source lib/common.sh
source modules/base.sh
source modules/core_tools.sh

# Registres d'installation (pipx/cargo/pacman)
source modules/redteam_pipx.sh
source modules/redteam_cargo.sh
source modules/redteam_pacman.sh

# Modules par domaine
source modules/redteam_ad.sh
source modules/redteam_web.sh
source modules/redteam_network.sh
source modules/redteam_credential.sh

# Outils spéciaux
source modules/netexec.sh                # NetExec via pipx

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
