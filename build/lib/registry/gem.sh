#!/bin/bash
# Registry for Ruby gem-based tool installation

nihil::import lib/common

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

normalize_gem_executable() {
    local cmd_name="$1"
    if command -v "$cmd_name" > /dev/null 2>&1; then
        return 0
    fi

    local candidate=""
    local gem_bindir
    gem_bindir="$(ruby -e 'require "rubygems"; print Gem.bindir' 2>/dev/null || true)"
    if [ -n "$gem_bindir" ] && [ -x "${gem_bindir}/${cmd_name}" ]; then
        candidate="${gem_bindir}/${cmd_name}"
    fi

    if [ -z "$candidate" ]; then
        local user_bindir
        user_bindir="$(ruby -e 'require "rubygems"; print File.join(Gem.user_dir, "bin")' 2>/dev/null || true)"
        if [ -n "$user_bindir" ] && [ -x "${user_bindir}/${cmd_name}" ]; then
            candidate="${user_bindir}/${cmd_name}"
        fi
    fi

    if [ -z "$candidate" ] && [ -x "/usr/local/bin/${cmd_name}" ]; then
        candidate="/usr/local/bin/${cmd_name}"
    fi
    if [ -z "$candidate" ] && [ -x "/root/.local/bin/${cmd_name}" ]; then
        candidate="/root/.local/bin/${cmd_name}"
    fi

    if [ -n "$candidate" ]; then
        add-symlink "$candidate" "$cmd_name"
        return 0
    fi

    return 1
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

    normalize_gem_executable "$cmd_name" || true
    add-aliases "$cmd_name"
    add-history "$cmd_name"
    colorecho "  ✓ $cmd_name installed"
}
