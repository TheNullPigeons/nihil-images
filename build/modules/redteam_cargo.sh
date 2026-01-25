#!/bin/bash
# Registry pour installation d'outils via cargo
# Ce fichier contient les fonctions génériques pour installer via cargo
# Les fichiers par domaine (redteam_ad.sh, etc.) appellent ces fonctions

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Fonction pour s'assurer que cargo est installé
_ensure_cargo() {
    if ! command -v cargo >/dev/null 2>&1; then
        colorecho "cargo not found, installing rust toolchain via pacman"
        pacman -Sy --noconfirm && \
        pacman -S --noconfirm --needed rust || {
            criticalecho "Failed to install rust (cargo)"
            return 1
        }
    fi

    export CARGO_HOME="/root/.cargo"
    mkdir -p "$CARGO_HOME"
    export PATH="$CARGO_HOME/bin:$PATH"
}

# Fonction générique pour installer un outil via cargo
# Usage: install_cargo_tool "tool_name"
# Exemple: install_cargo_tool "feroxbuster"
install_cargo_tool() {
    local tool_name="$1"

    _ensure_cargo || return 1

    if command -v "$tool_name" >/dev/null 2>&1; then
        colorecho "  ✓ $tool_name already installed (cargo)"
        return 0
    fi

    colorecho "  → Installing $tool_name via cargo"
    cargo install "$tool_name" || {
        colorecho "  ✗ Warning: Failed to install $tool_name via cargo"
        return 1
    }

    # Créer symlink global si nécessaire
    if [ -f "/root/.cargo/bin/$tool_name" ] && [ ! -f "/usr/bin/$tool_name" ]; then
        ln -sf "/root/.cargo/bin/$tool_name" "/usr/bin/$tool_name" || true
    fi
}
