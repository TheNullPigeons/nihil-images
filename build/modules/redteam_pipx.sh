#!/bin/bash
# Registry pour installation d'outils via pipx
# Ce fichier contient les fonctions génériques pour installer via pipx
# Les fichiers par domaine (redteam_ad.sh, etc.) appellent ces fonctions

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Fonction pour s'assurer que pipx est installé
_ensure_pipx() {
    if ! command -v pipx >/dev/null 2>&1; then
        colorecho "python-pipx not found, installing via pacman"
        pacman -Sy --noconfirm && \
        pacman -S --noconfirm --needed python-pipx || {
            criticalecho "Failed to install python-pipx"
            return 1
        }
    fi
}

# Fonction générique pour installer un outil via pipx
# Usage: install_pipx_tool "cmd_name" "package_name"
# Exemple: install_pipx_tool "bloodhound" "bloodhound"
install_pipx_tool() {
    local cmd_name="$1"
    local pkg_name="${2:-$cmd_name}"  # Si pkg_name non fourni, utilise cmd_name

    _ensure_pipx || return 1

    if command -v "$cmd_name" >/dev/null 2>&1; then
        colorecho "  ✓ $cmd_name already installed (pipx)"
        return 0
    fi

    colorecho "  → Installing $cmd_name via pipx ($pkg_name)"
    pipx install "$pkg_name" || {
        colorecho "  ✗ Warning: Failed to install $pkg_name via pipx"
        return 1
    }

    # Créer symlink global si nécessaire
    if [ -f "/root/.local/bin/$cmd_name" ] && [ ! -f "/usr/bin/$cmd_name" ]; then
        ln -sf "/root/.local/bin/$cmd_name" "/usr/bin/$cmd_name" || true
    fi

    # Ajouter aliases et history si disponibles
    add-aliases "$cmd_name"
    add-history "$cmd_name"
}

# Fonction pour installer un outil via pipx depuis Git
# Usage: install_pipx_tool_git "cmd_name" "url" [env_vars]
# L'URL reçoit automatiquement le préfixe "git+" si absent (ex: https://... ou git@...)
# Exemple: install_pipx_tool_git "netexec" "https://github.com/Pennyw0rth/NetExec" "PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1"
install_pipx_tool_git() {
    local cmd_name="$1"
    local git_url="$2"
    local env_vars="${3:-}"  # Variables d'environnement optionnelles

    [[ "$git_url" != git+* ]] && git_url="git+$git_url"

    _ensure_pipx || return 1

    if command -v "$cmd_name" >/dev/null 2>&1; then
        colorecho "  ✓ $cmd_name already installed (pipx)"
        return 0
    fi

    colorecho "  → Installing $cmd_name via pipx from Git ($git_url)"
    
    # Appliquer les variables d'environnement si fournies
    if [ -n "$env_vars" ]; then
        eval "export $env_vars"
    fi
    
    pipx install "$git_url" || {
        colorecho "  ✗ Warning: Failed to install $cmd_name via pipx from Git"
        return 1
    }

    # Créer symlinks globaux si nécessaire
    if [ -f "/root/.local/bin/$cmd_name" ] && [ ! -f "/usr/bin/$cmd_name" ]; then
        ln -sf "/root/.local/bin/$cmd_name" "/usr/bin/$cmd_name" || true
    fi

    # Ajouter aliases et history si disponibles
    add-aliases "$cmd_name"
    add-history "$cmd_name"
}

# Fonction spécialisée pour installer NetExec (gère Rust, env vars, alias)
# Usage: install_netexec
install_pipx_netexec() {
    # Vérifier/installer Rust si nécessaire
    if ! command -v rustc >/dev/null 2>&1; then
        pacman -Sy --noconfirm && \
        pacman -S --noconfirm --needed rust || {
            colorecho "  ✗ Warning: Failed to install rust for NetExec"
            return 1
        }
    fi

    install_pipx_tool_git "netexec" "https://github.com/Pennyw0rth/NetExec" "PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1" || return 1
    add-symlink "/root/.local/bin/netexec" "nxc"
    # add-aliases et add-history sont déjà appelés par install_pipx_tool_git
}
