#!/bin/bash
# Registry pour installation d'outils via curl/wget (script ou binaire unique)
# Les modules par domaine peuvent appeler install_download_tool pour des outils
# distribués en un seul fichier (script ou binaire)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Usage: install_download_tool "cmd_name" "url"
# Exemple: install_download_tool "testssl" "https://raw.githubusercontent.com/drwetter/testssl.sh/3.2/testssl.sh"
# Pour un binaire: URL doit pointer vers le fichier exécutable (raw)
install_download_tool() {
    local cmd_name="$1"
    local url="$2"
    local dest="${INSTALL_DIR}/${cmd_name}"

    if command -v "$cmd_name" >/dev/null 2>&1; then
        colorecho "  ✓ $cmd_name already installed (download)"
        return 0
    fi

    colorecho "  → Installing $cmd_name via curl/wget ($url)"
    mkdir -p "$INSTALL_DIR"
    if curl -sSLf "$url" -o "$dest" 2>/dev/null || wget -q -O "$dest" "$url" 2>/dev/null; then
        chmod +x "$dest"
        colorecho "  ✓ $cmd_name installed"
        return 0
    fi
    colorecho "  ✗ Warning: Failed to download $cmd_name"
    rm -f "$dest"
    return 1
}
