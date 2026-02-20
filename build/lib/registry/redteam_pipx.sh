#!/bin/bash
# Registry for pipx-based tool installation
# Contains generic helper functions; domain modules (redteam_ad.sh, etc.) call these.

# Resolve path to lib/common.sh relative to this registry file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

# Ensure pipx is installed
_ensure_pipx() {
    if ! command -v pipx > /dev/null 2>&1; then
        colorecho "python-pipx not found, installing via pacman"
        pacman -Sy --noconfirm && \
        pacman -S --noconfirm --needed python-pipx || {
            criticalecho "Failed to install python-pipx"
            return 1
        }
    fi
}

# Install a tool via pipx
# Usage: install_pipx_tool "cmd_name" "package_name" ["check_cmd"]
# Example: install_pipx_tool "bloodhound" "bloodhound"
# Example: install_pipx_tool "impacket" "impacket" "secretsdump"
install_pipx_tool() {
    local cmd_name="$1"
    local pkg_name="${2:-$cmd_name}"   # defaults to cmd_name if not provided
    local check_cmd="${3:-}"           # optional command to verify installation

    _ensure_pipx || return 1

    # Check if package is already installed via pipx
    if pipx list 2>/dev/null | grep -q "^  $pkg_name "; then
        colorecho "  ✓ $cmd_name already installed (pipx)"
        # Re-apply aliases and history in case config files were added later
        add-aliases "$cmd_name"
        add-history "$cmd_name"
        return 0
    fi

    # Fallback: check a specific binary if provided (handles multi-binary packages)
    if [ -n "$check_cmd" ] && command -v "$check_cmd" > /dev/null 2>&1; then
        colorecho "  ✓ $cmd_name already installed (pipx, detected via $check_cmd)"
        add-aliases "$cmd_name"
        add-history "$cmd_name"
        return 0
    fi

    colorecho "  → Installing $cmd_name via pipx ($pkg_name)"
    pipx install "$pkg_name" || {
        colorecho "  ✗ Warning: Failed to install $pkg_name via pipx"
        return 1
    }

    # Create global symlink if needed
    if [ -f "/root/.local/bin/$cmd_name" ] && [ ! -f "/usr/bin/$cmd_name" ]; then
        ln -sf "/root/.local/bin/$cmd_name" "/usr/bin/$cmd_name" || true
    fi

    # Apply aliases and history if available
    add-aliases "$cmd_name"
    add-history "$cmd_name"
}

# Install a tool via pipx from a Git repository
# Usage: install_pipx_tool_git "cmd_name" "url" [env_vars]
# The URL is automatically prefixed with "git+" if absent.
# Example: install_pipx_tool_git "netexec" "https://github.com/Pennyw0rth/NetExec" "PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1"
install_pipx_tool_git() {
    local cmd_name="$1"
    local git_url="$2"
    local env_vars="${3:-}"   # optional environment variables

    [[ "$git_url" != git+* ]] && git_url="git+$git_url"

    _ensure_pipx || return 1

    if command -v "$cmd_name" > /dev/null 2>&1; then
        colorecho "  ✓ $cmd_name already installed (pipx)"
        return 0
    fi

    colorecho "  → Installing $cmd_name via pipx from Git ($git_url)"

    # Apply optional environment variables
    if [ -n "$env_vars" ]; then
        eval "export $env_vars"
    fi

    pipx install "$git_url" || {
        colorecho "  ✗ Warning: Failed to install $cmd_name via pipx from Git"
        return 1
    }

    # Create global symlinks if needed
    if [ -f "/root/.local/bin/$cmd_name" ] && [ ! -f "/usr/bin/$cmd_name" ]; then
        ln -sf "/root/.local/bin/$cmd_name" "/usr/bin/$cmd_name" || true
    fi

    # Apply aliases and history if available
    add-aliases "$cmd_name"
    add-history "$cmd_name"
}
