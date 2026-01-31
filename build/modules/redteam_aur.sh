#!/bin/bash
# Registry pour installation d'outils via AUR (clone + makepkg + pacman -U)
# Même approche que base.sh pour yay : pas de yay/sudo, builder fait makepkg, root fait pacman -U

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

AUR_BASE="https://aur.archlinux.org"

# Usage: install_aur_tool "package_name" [command_to_check]
# Exemple: install_aur_tool "binaryninja-free" "binaryninja"
# Si command_to_check est omis, on utilise package_name pour la vérification
install_aur_tool() {
    local pkg_name="$1"
    local check_cmd="${2:-$pkg_name}"
    local build_dir="/tmp/aur-build-${pkg_name}"

    if command -v "$check_cmd" >/dev/null 2>&1; then
        colorecho "  ✓ $check_cmd already installed (AUR)"
        return 0
    fi

    colorecho "  → Installing $pkg_name via AUR (makepkg)"
    useradd -m -s /bin/bash builder 2>/dev/null || true
    git config --global --add safe.directory '*' 2>/dev/null || true

    if ! git clone "${AUR_BASE}/${pkg_name}.git" "$build_dir"; then
        colorecho "  ✗ Warning: Failed to clone AUR $pkg_name"
        userdel -r builder 2>/dev/null || true
        return 1
    fi

    chown -R builder:builder "$build_dir"
    if ! su builder -c "cd $build_dir && makepkg -s --noconfirm"; then
        colorecho "  ✗ Warning: Failed to build $pkg_name (makepkg)"
        rm -rf "$build_dir"
        userdel -r builder 2>/dev/null || true
        return 1
    fi

    if ls "$build_dir"/*.pkg.tar.zst 1>/dev/null 2>&1; then
        pacman -U --noconfirm "$build_dir"/*.pkg.tar.zst || colorecho "  ✗ Warning: Failed to install $pkg_name (pacman -U)"
    fi
    rm -rf "$build_dir"
    userdel -r builder 2>/dev/null || true
    colorecho "  ✓ $pkg_name installed (AUR)"
}
