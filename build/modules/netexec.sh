#!/bin/bash
# NetExec installation via pipx

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

function install_netexec() {
    colorecho "Installing NetExec (nxc) via pipx"
    
    # Vérifier que pipx est installé
    if ! command -v pipx &> /dev/null; then
        colorecho "pipx not found, installing python-pipx"
        pacman -S --noconfirm --needed python-pipx || {
            criticalecho "Failed to install python-pipx"
            return 1
        }
    fi
    
    # NetExec nécessite Rust pour compiler la dépendance aardwolf
    colorecho "Installing Rust (required for NetExec dependencies)"
    if ! command -v rustc &> /dev/null; then
        pacman -S --noconfirm --needed rust || {
            criticalecho "Failed to install rust"
            return 1
        }
    fi
    
    # Installer netexec via pipx depuis GitHub
    colorecho "Installing netexec via pipx from GitHub"
    
    # Fix pour Arch Linux (Python 3.14+) et PyO3/aardwolf
    export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1
    
    pipx install git+https://github.com/Pennyw0rth/NetExec || {
        criticalecho "Failed to install netexec via pipx"
        return 1
    }
    
    colorecho "Ensuring pipx path"
    pipx ensurepath
    
    # Créer des liens symboliques dans /usr/bin pour être sûr que nxc soit dispo partout
    # (pipx ensurepath ne modifie que le PATH utilisateur, pas le système global)
    colorecho "Creating global symlinks in /usr/bin"
    if [ -f "/root/.local/bin/nxc" ]; then
        ln -sf /root/.local/bin/nxc /usr/bin/nxc
        ln -sf /root/.local/bin/netexec /usr/bin/netexec
    fi
    
    # Créer des alias pour nxc (compatibilité)
    colorecho "Creating nxc alias for netexec"
    if [ -f "/root/.zshrc" ]; then
        if ! grep -q "alias nxc=" /root/.zshrc; then
            echo 'alias nxc="netexec"' >> /root/.zshrc
        fi
    fi
    
    # Aussi pour bash
    if [ -f "/root/.bashrc" ]; then
        if ! grep -q "alias nxc=" /root/.bashrc; then
            echo 'alias nxc="netexec"' >> /root/.bashrc
        fi
    fi
    
    # Vérifier l'installation
    if command -v netexec &> /dev/null; then
        colorecho "NetExec installed successfully"
        netexec --version || true
    else
        criticalecho "NetExec installation verification failed"
        return 1
    fi
    
    colorecho "NetExec installation completed"
}

