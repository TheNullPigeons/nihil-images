#!/bin/bash
# Build entrypoint for package installation

set -e

# Chargeur central : définit nihil::import + charge lib/common
source lib/loader.sh

# Modules de base
nihil::import modules/base
nihil::import modules/core_tools

# Modules par domaine (chacun déclare ses propres dépendances de registres)
nihil::import modules/mod_ad
nihil::import modules/mod_web
nihil::import modules/mod_network
nihil::import modules/mod_credential
nihil::import modules/mod_pwn
nihil::import modules/mod_c2
nihil::import modules/mod_misc
nihil::import modules/mod_reverse
nihil::import modules/mod_crypto
nihil::import modules/mod_forensics
nihil::import modules/mod_ctf
nihil::import lib/healthcheck
nihil::import modules/post_install

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
