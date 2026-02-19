#!/bin/bash
# Registry pour installation d'outils via AUR (clone + makepkg + pacman -U)
# builder exécute makepkg -s (qui appelle sudo pacman pour les deps) : sudoers NOPASSWD pour pacman

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

AUR_BASE="https://aur.archlinux.org"
SUDOERS_AUR="/etc/sudoers.d/builder-aur"

# Usage: install_aur_tool "package_name" [command_to_check]
# Exemple: install_aur_tool "binaryninja-free" "binaryninja"
install_aur_tool() {
    local pkg_name="$1"
    local check_cmd="${2:-$pkg_name}"
    local build_dir="/tmp/aur-build-${pkg_name}"

    if command -v "$check_cmd" >/dev/null 2>&1; then
        colorecho "  ✓ $check_cmd already installed (AUR)"
        return 0
    fi

    colorecho "  → Installing $pkg_name via AUR (makepkg)"
    pacman -S --noconfirm --needed sudo >/dev/null 2>&1 || true
    echo 'builder ALL=(ALL) NOPASSWD: /usr/bin/pacman' > "$SUDOERS_AUR"
    chmod 440 "$SUDOERS_AUR"
    useradd -m -s /bin/bash builder 2>/dev/null || true
    git config --global --add safe.directory '*' 2>/dev/null || true

    if ! git clone "${AUR_BASE}/${pkg_name}.git" "$build_dir"; then
        colorecho "  ✗ Warning: Failed to clone AUR $pkg_name"
        rm -f "$SUDOERS_AUR"
        userdel -r builder 2>/dev/null || true
        return 1
    fi

    chown -R builder:builder "$build_dir"
    if ! su builder -c "cd $build_dir && makepkg -s --noconfirm"; then
        colorecho "  ✗ Warning: Failed to build $pkg_name (makepkg)"
        rm -rf "$build_dir"
        rm -f "$SUDOERS_AUR"
        userdel -r builder 2>/dev/null || true
        return 1
    fi

    if ls "$build_dir"/*.pkg.tar.zst 1>/dev/null 2>&1; then
        pacman -U --noconfirm "$build_dir"/*.pkg.tar.zst || colorecho "  ✗ Warning: Failed to install $pkg_name (pacman -U)"
    fi
    rm -rf "$build_dir"
    rm -f "$SUDOERS_AUR"
    userdel -r builder 2>/dev/null || true

    # Ajouter aliases et history si disponibles (utiliser check_cmd si différent de pkg_name)
    add-aliases "$check_cmd"
    add-history "$check_cmd"

    colorecho "  ✓ $pkg_name installed (AUR)"
}
