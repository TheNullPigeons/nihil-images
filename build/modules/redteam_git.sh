#!/bin/bash
# Registry pour installation d'outils via Git (clone + build/install personnalisable)
# Supporte : pip requirements.txt, make, make install, ou toute commande shell.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

GIT_INSTALL_DIR="${GIT_INSTALL_DIR:-/usr/local/share}"
GIT_BIN_DIR="${GIT_BIN_DIR:-/usr/local/bin}"

# Usage: install_git_tool "cmd_name" "git_url" ["entrypoint"] ["install_cmd"]
#
#   cmd_name     : nom de la commande (dans PATH)
#   git_url      : URL du dépôt Git
#   entrypoint   : (optionnel) script/binaire relatif au repo (ex: ssrfmap.py, build/tool).
#                  Si vide et install_cmd fourni, on suppose que l'install met le binaire dans PATH.
#   install_cmd  : (optionnel) commande à exécuter dans le repo après clone (ex: "make", "make install").
#                  Si vide : pip install -r requirements.txt si le fichier existe.
#
# Exemples:
#   install_git_tool "ssrfmap" "https://github.com/swisskyrepo/SSRFmap.git" "ssrfmap.py"
#   install_git_tool "outil_c" "https://github.com/..." "" "make && make install"
#   install_git_tool "autre" "https://github.com/..." "bin/autre" "make"
install_git_tool() {
    local cmd_name="$1"
    local git_url="$2"
    local entrypoint="${3:-}"
    local install_cmd="${4:-}"
    local repo_dir="${GIT_INSTALL_DIR}/${cmd_name}"
    local wrapper="${GIT_BIN_DIR}/${cmd_name}"

    if command -v "$cmd_name" >/dev/null 2>&1; then
        colorecho "  ✓ $cmd_name already installed (git)"
        return 0
    fi

    colorecho "  → Installing $cmd_name via Git ($git_url)"
    if [ ! -d "$repo_dir" ]; then
        git clone --depth=1 "$git_url" "$repo_dir" || {
            colorecho "  ✗ Warning: Failed to clone $cmd_name"
            return 1
        }
    fi

    # Étape build/install
    if [ -n "$install_cmd" ]; then
        (cd "$repo_dir" && eval "$install_cmd") || {
            colorecho "  ✗ Warning: Install command failed for $cmd_name"
            return 1
        }
    else
        # Comportement par défaut : pip -r requirements.txt si présent
        if [ -f "$repo_dir/requirements.txt" ]; then
            python3 -m pip install --break-system-packages -r "$repo_dir/requirements.txt" --quiet 2>/dev/null || \
                python3 -m pip install -r "$repo_dir/requirements.txt" --quiet 2>/dev/null || true
        fi
    fi

    # Wrapper si entrypoint fourni
    if [ -n "$entrypoint" ]; then
        mkdir -p "$GIT_BIN_DIR"
        local full_path="$repo_dir/$entrypoint"
        if [[ "$entrypoint" == *.py ]]; then
            printf '%s\n' '#!/bin/sh' "exec python3 $full_path \"\$@\"" > "$wrapper"
        else
            printf '%s\n' '#!/bin/sh' "exec $full_path \"\$@\"" > "$wrapper"
        fi
        chmod +x "$wrapper"
    fi

    colorecho "  ✓ $cmd_name installed"
    return 0
}
