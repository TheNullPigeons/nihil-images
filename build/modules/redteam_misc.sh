#!/bin/bash
# Outils red-team divers (exploit-db, etc.)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${MODULE_DIR}/../lib/registry/redteam_git.sh"

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_searchsploit() {
    local install_dir="/opt/tools/exploitdb"
    local repo_url="https://gitlab.com/exploit-database/exploitdb.git"

    install_git_tool_symlink "$install_dir" "$repo_url" "searchsploit" || return 1
    if [ -f "$install_dir/.searchsploit_rc" ]; then
        cp -n "$install_dir/.searchsploit_rc" ~/.searchsploit_rc
        sed -i 's/\(.*[pP]aper.*\)/#\1/' ~/.searchsploit_rc
        sed -i 's|opt/exploitdb|opt/tools/exploitdb|g' ~/.searchsploit_rc
    fi
}


# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_redteam_misc() {
    colorecho "Installing misc red-team tools"

    colorecho "  [git] Misc tools:"
    install_searchsploit

    colorecho "Misc red-team tools installation finished"
}