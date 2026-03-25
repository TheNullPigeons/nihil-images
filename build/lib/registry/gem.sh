#!/bin/bash
# Registry for Ruby gem-based tool installation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

_ensure_ruby() {
    if ! command -v ruby > /dev/null 2>&1; then
        colorecho "ruby not found, installing via pacman"
        pacman -Sy --noconfirm && \
        pacman -S --noconfirm --needed ruby || {
            criticalecho "Failed to install ruby"
            return 1
        }
    fi
}

# Usage: install_gem_tool "cmd_name" ["gem_name"]
# Example: install_gem_tool "one_gadget"
# Example: install_gem_tool "zsteg" "zsteg"
install_gem_tool() {
    local cmd_name="$1"
    local gem_name="${2:-$cmd_name}"

    _ensure_ruby || return 1

    if command -v "$cmd_name" > /dev/null 2>&1; then
        colorecho "  ✓ $cmd_name already installed (gem)"
        add-aliases "$cmd_name"
        add-history "$cmd_name"
        return 0
    fi

    colorecho "  → Installing $cmd_name via gem ($gem_name)"
    gem install "$gem_name" --no-document || {
        colorecho "  ✗ Warning: Failed to install $gem_name via gem"
        return 1
    }

    add-aliases "$cmd_name"
    add-history "$cmd_name"
    colorecho "  ✓ $cmd_name installed"
}
