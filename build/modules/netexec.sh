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
    pipx install git+https://github.com/Pennyw0rth/NetExec || {
        criticalecho "Failed to install netexec via pipx"
        return 1
    }
    
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

