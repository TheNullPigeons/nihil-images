#!/bin/bash
# Registry pour installation d'outils via AUR (yay)
# Ce fichier contient les fonctions génériques pour installer via AUR
# Les fichiers par domaine (redteam_pwn.sh, etc.) appellent ces fonctions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Usage: install_aur_tool "package_name" [command_to_check]
# Exemple: install_aur_tool "binaryninja-free" "binaryninja"
# Si command_to_check est omis, on utilise package_name pour la vérification
install_aur_tool() {
    local pkg_name="$1"
    local check_cmd="${2:-$pkg_name}"

    if command -v "$check_cmd" >/dev/null 2>&1; then
        colorecho "  ✓ $check_cmd already installed (AUR)"
        return 0
    fi

    if ! command -v yay >/dev/null 2>&1; then
        colorecho "  ✗ yay not found, skipping $pkg_name (AUR)"
        return 1
    fi

    colorecho "  → Installing $pkg_name via AUR (yay)"
    useradd -m -s /bin/bash builder 2>/dev/null || true
    su builder -c "yay -S --noconfirm --answercode None $pkg_name" || {
        colorecho "  ✗ Warning: Failed to install $pkg_name via AUR"
        userdel -r builder 2>/dev/null || true
        return 1
    }
    userdel -r builder 2>/dev/null || true
    colorecho "  ✓ $pkg_name installed (AUR)"
}
