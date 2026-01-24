#!/bin/bash
# Red-team tools installed via Rust / cargo (feroxbuster, rustscan, ...)

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

function install_redteam_rust_tools() {
    colorecho "Installing Rust-based red-team tools (cargo)"

    # S'assurer que cargo est dispo
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

    # Liste des outils Rust à installer via cargo
    local tools=(
        "feroxbuster"
        "rustscan"
        "rusthound-ce"
    )

    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            colorecho "$tool already installed (cargo)"
            continue
        fi

        colorecho "Installing $tool via cargo"
        cargo install "$tool" || {
            colorecho "Warning: Failed to install $tool via cargo"
            continue
        }
    done

    # Rendez les binaires accessibles globalement
    if [ -d "/root/.cargo/bin" ]; then
        for tool in "${tools[@]}"; do
            if [ -f "/root/.cargo/bin/$tool" ] && [ ! -f "/usr/bin/$tool" ]; then
                ln -sf "/root/.cargo/bin/$tool" "/usr/bin/$tool" || true
            fi
        done
    fi

    colorecho "Rust-based red-team tools installation finished"
}

