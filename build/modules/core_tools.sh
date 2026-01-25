#!/bin/bash
# Core CLI / workstation tools (non-spécifiques red-team)
#
# Ici on met tout ce qui est confort d'utilisation dans le conteneur :
# éditeurs, multiplexeurs, utilitaires réseau génériques, etc.

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

function install_core_tools() {
    colorecho "Installing core CLI tools (editors, tmux, fzf, etc.)"

    pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed \
    vim \
    nano \
    neovim \
    tmux \
    fzf \
    curl \
    wget \
    asciinema \
    whois \
    gdb && \
    pacman -Sc --noconfirm

    colorecho "Core tools installed"
}

