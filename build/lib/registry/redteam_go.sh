#!/bin/bash
# Registry pour installation d'outils via go install
# Les fichiers par domaine (redteam_ad.sh, etc.) appellent install_go_tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

GO_INSTALL_DIR="${GO_INSTALL_DIR:-/root/go}"
GO_BIN_DIR="${GO_BIN_DIR:-$GO_INSTALL_DIR/bin}"

_ensure_go() {
    if ! command -v go >/dev/null 2>&1; then
        colorecho "go not found, installing via pacman"
        pacman -Sy --noconfirm && \
        pacman -S --noconfirm --needed go || {
            criticalecho "Failed to install go"
            return 1
        }
    fi
    export GOPATH="${GOPATH:-$GO_INSTALL_DIR}"
    export GOBIN="${GOBIN:-$GO_BIN_DIR}"
    mkdir -p "$GO_BIN_DIR"
    export PATH="$GO_BIN_DIR:$PATH"
}

# Usage: install_go_tool "package_path" ["binary_name"]
# Exemple: install_go_tool "github.com/ropnop/kerbrute@latest"
# Exemple: install_go_tool "github.com/ropnop/kerbrute@latest" "kerbrute"
#   package_path : chemin complet (ex: github.com/ropnop/kerbrute@latest)
#   binary_name  : (optionnel) nom du binaire dans PATH ; défaut = dernier segment du package (kerbrute)
install_go_tool() {
    local pkg_path="$1"
    local bin_name="${2:-}"
    if [ -z "$bin_name" ]; then
        bin_name="${pkg_path%@*}"
        bin_name="${bin_name##*/}"
    fi

    _ensure_go || return 1

    if command -v "$bin_name" >/dev/null 2>&1; then
        colorecho "  ✓ $bin_name already installed (go)"
        return 0
    fi

    colorecho "  → Installing $bin_name via go install ($pkg_path)"
    go install "$pkg_path" || {
        colorecho "  ✗ Failed to install $bin_name via go"
        return 1
    }

    if [ -f "$GO_BIN_DIR/$bin_name" ] && [ ! -f "/usr/bin/$bin_name" ]; then
        ln -sf "$GO_BIN_DIR/$bin_name" "/usr/bin/$bin_name" || true
    fi

    # Ajouter aliases et history si disponibles
    add-aliases "$bin_name"
    add-history "$bin_name"

    colorecho "  ✓ $bin_name installed"
    return 0
}
