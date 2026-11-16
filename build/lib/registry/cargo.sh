#!/bin/bash
# Registry pour installation d'outils via cargo
# Ce fichier contient les fonctions génériques pour installer via cargo
# Les fichiers par domaine (mod_ad.sh, etc.) appellent ces fonctions

nihil::import lib/common

# Fonction pour s'assurer que cargo est installé avec toutes les dépendances de build
_ensure_cargo() {
    if ! command -v cargo >/dev/null 2>&1; then
        colorecho "cargo not found, installing rust toolchain via pacman"
        pacman -Sy --noconfirm && \
        pacman -S --noconfirm --needed rust || {
            criticalecho "Failed to install rust (cargo)"
            return 1
        }
    fi

    # Installer les dépendances système nécessaires pour compiler des outils Rust complexes
    # (OpenSSL, pkg-config, clang/libclang pour bindgen, etc.)
    colorecho "Ensuring build dependencies for Rust tools"
    pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed \
        openssl \
        pkg-config \
        clang \
        || colorecho "Warning: Some build dependencies may be missing"

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
        add-aliases "$tool_name"
        add-history "$tool_name"
        return 0
    fi

    colorecho "  → Installing $tool_name via cargo"
    if [[ "${2:-}" == "nolocked" ]]; then
        # Some tools ship a Cargo.lock pinning crates that no longer build on the
        # current Rust (e.g. rusthound pins time 0.3.30, which fails on Rust >=1.80).
        # Skip --locked so cargo resolves fresh, compilable dependency versions.
        retry-command 3 "cargo install $tool_name" \
            env CARGO_NET_GIT_FETCH_WITH_CLI=true cargo install "$tool_name" || {
            colorecho "  ✗ Warning: Failed to install $tool_name via cargo"
            return 1
        }
    else
        # --locked keeps builds reproducible; fall back to a fresh resolve on failure.
        retry-command 3 "cargo install --locked $tool_name" \
            env CARGO_NET_GIT_FETCH_WITH_CLI=true cargo install --locked "$tool_name" || {
            colorecho "  ✗ Warning: Failed to install $tool_name via cargo"
            colorecho "  → Trying without --locked flag..."
            retry-command 3 "cargo install $tool_name" cargo install "$tool_name" || {
                colorecho "  ✗ Failed to install $tool_name (both methods failed)"
                return 1
            }
        }
    fi

    # Créer symlink global si nécessaire
    if [ -f "/root/.cargo/bin/$tool_name" ] && [ ! -f "/usr/bin/$tool_name" ]; then
        ln -sf "/root/.cargo/bin/$tool_name" "/usr/bin/$tool_name" || true
    fi

    # Ajouter aliases et history si disponibles
    add-aliases "$tool_name"
    add-history "$tool_name"
}
