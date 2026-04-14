#!/bin/bash
# Registry pour installation d'outils via pacman
# Ce fichier contient les fonctions génériques pour installer via pacman
# Les fichiers par domaine (mod_ad.sh, etc.) appellent ces fonctions

nihil::import lib/common

# Fonction générique pour installer un outil via pacman
# Usage: install_pacman_tool "package_name"
# Exemple: install_pacman_tool "nmap"
install_pacman_tool() {
    local pkg_name="$1"

    if command -v "$pkg_name" >/dev/null 2>&1; then
        colorecho "  ✓ $pkg_name already installed (pacman)"
        return 0
    fi

    colorecho "  → Installing $pkg_name via pacman"
    pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed "$pkg_name" 2>/dev/null || {
        colorecho "  ⟳ Retrying $pkg_name with --overwrite (pip/pacman file conflicts)"
        pacman -S --noconfirm --needed --overwrite '/usr/lib/python3.*/site-packages/*' "$pkg_name" || {
            colorecho "  ✗ Warning: Failed to install $pkg_name via pacman"
            return 1
        }
    }

    # Ajouter aliases et history si disponibles
    add-aliases "$pkg_name"
    add-history "$pkg_name"
}

# Fonction pour installer plusieurs outils pacman en une fois
# Usage: install_pacman_tools "pkg1" "pkg2" "pkg3"
install_pacman_tools() {
    local packages=("$@")
    
    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi

    colorecho "Installing packages via pacman: ${packages[*]}"
    pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed "${packages[@]}" 2>/dev/null || {
        colorecho "  ⟳ Retrying with --overwrite (pip/pacman file conflicts)"
        pacman -S --noconfirm --needed --overwrite '/usr/lib/python3.*/site-packages/*' "${packages[@]}" || {
            colorecho "Warning: Some packages failed to install"
            return 1
        }
    }
}
