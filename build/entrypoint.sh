#!/bin/bash
# Build entrypoint for package installation

set -e

# Load utilities and modules
source lib/common.sh
source modules/base.sh
source modules/core_tools.sh

# Registres d'installation (pipx/cargo/pacman/aur/curl)
source lib/registry/pipx.sh
source lib/registry/cargo.sh
source lib/registry/pacman.sh
source lib/registry/aur.sh
source lib/registry/curl.sh
source lib/registry/go.sh
source lib/registry/git.sh
source lib/registry/gem.sh

# Modules par domaine
source modules/mod_ad.sh
source modules/mod_web.sh
source modules/mod_network.sh
source modules/mod_credential.sh
source modules/mod_pwn.sh
source modules/mod_c2.sh
source modules/mod_misc.sh
source modules/mod_reverse.sh
source modules/mod_crypto.sh
source modules/mod_forensics.sh
source modules/mod_ctf.sh
source lib/healthcheck.sh

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
