#!/bin/bash
# Registry for uv-based tool installation (uv tool install, the pipx equivalent)
# Contains generic helper functions; domain modules (mod_ad.sh, etc.) call these.
# NOTE: pipx remains the default for now; this registry is provided ahead of a
# planned pipx -> uv migration so modules can opt in gradually.

nihil::import lib/common

# Ensure uv is installed
_ensure_uv() {
    if ! command -v uv > /dev/null 2>&1; then
        colorecho "uv not found, installing via pacman"
        pacman -Sy --noconfirm && \
        pacman -S --noconfirm --needed uv || {
            criticalecho "Failed to install uv"
            return 1
        }
    fi
}

_uv_bin_dir() {
    uv tool dir --bin 2>/dev/null || printf '%s\n' /root/.local/bin
}

# Install a tool via uv
# Usage: install_uv_tool "cmd_name" "package_name" ["check_cmd"] ["extra_args"]
# Example: install_uv_tool "bloodhound" "bloodhound"
# Example: install_uv_tool "impacket" "impacket" "secretsdump"
install_uv_tool() {
    local cmd_name="$1"
    local pkg_name="${2:-$cmd_name}"   # defaults to cmd_name if not provided
    local check_cmd="${3:-}"           # optional command to verify installation
    local extra_args="${4:-}"          # optional extra flags for `uv tool install`

    _ensure_uv || return 1

    # Check if package is already installed via uv
    if uv tool list 2>/dev/null | grep -q "^$pkg_name "; then
        colorecho "  ✓ $cmd_name already installed (uv)"
        # Re-apply aliases and history in case config files were added later
        add-aliases "$cmd_name"
        add-history "$cmd_name"
        return 0
    fi

    # Fallback: check a specific binary if provided (handles multi-binary packages)
    if [ -n "$check_cmd" ] && command -v "$check_cmd" > /dev/null 2>&1; then
        colorecho "  ✓ $cmd_name already installed (uv, detected via $check_cmd)"
        add-aliases "$cmd_name"
        add-history "$cmd_name"
        return 0
    fi

    colorecho "  → Installing $cmd_name via uv ($pkg_name)"
    retry-command 3 "uv tool install $pkg_name" uv tool install $extra_args "$pkg_name" || {
        colorecho "  ✗ Warning: Failed to install $pkg_name via uv"
        return 1
    }

    # Create global symlink if needed
    local uv_bin_dir
    uv_bin_dir="$(_uv_bin_dir)"
    if [ -f "$uv_bin_dir/$cmd_name" ] && [ ! -f "/usr/bin/$cmd_name" ]; then
        ln -sf "$uv_bin_dir/$cmd_name" "/usr/bin/$cmd_name" || true
    fi

    # Apply aliases and history if available
    add-aliases "$cmd_name"
    add-history "$cmd_name"
}

# Install a tool via uv from a Git repository
# Usage: install_uv_tool_git "cmd_name" "url" [env_vars] [check_cmd]
# The URL is automatically prefixed with "git+" if absent.
# Example: install_uv_tool_git "netexec" "https://github.com/Pennyw0rth/NetExec"
install_uv_tool_git() {
    local cmd_name="$1"
    local git_url="$2"
    local env_vars="${3:-}"   # optional environment variables
    local check_cmd="${4:-$cmd_name}" # command exposed by the package

    [[ "$git_url" != git+* ]] && git_url="git+$git_url"

    _ensure_uv || return 1

    if command -v "$check_cmd" > /dev/null 2>&1; then
        colorecho "  ✓ $cmd_name already installed (uv)"
        add-aliases "$cmd_name"
        add-history "$cmd_name"
        return 0
    fi

    colorecho "  → Installing $cmd_name via uv from Git ($git_url)"

    # Apply optional environment variables
    if [ -n "$env_vars" ]; then
        eval "export $env_vars"
    fi

    retry-command 3 "uv tool install $git_url" uv tool install "$git_url" || {
        colorecho "  ✗ Warning: Failed to install $cmd_name via uv from Git"
        return 1
    }

    # Create global symlinks if needed
    local uv_bin_dir
    uv_bin_dir="$(_uv_bin_dir)"
    if [ -f "$uv_bin_dir/$check_cmd" ] && [ ! -f "/usr/bin/$check_cmd" ]; then
        ln -sf "$uv_bin_dir/$check_cmd" "/usr/bin/$check_cmd" || true
    fi

    if ! command -v "$check_cmd" > /dev/null 2>&1; then
        colorecho "  ✗ Warning: $cmd_name was installed via uv but no matching command ($check_cmd) was found"
        return 1
    fi

    # Apply aliases and history if available
    add-aliases "$cmd_name"
    add-history "$cmd_name"
}
