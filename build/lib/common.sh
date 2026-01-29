#!/bin/bash
# Common utility functions

export RED='\033[1;31m'
export BLUE='\033[1;34m'
export GREEN='\033[1;32m'
export NOCOLOR='\033[0m'

function colorecho () {
    echo -e "${BLUE}[NIHIL] $*${NOCOLOR}"
}

function criticalecho () {
    echo -e "${RED}[NIHIL ERROR] $*${NOCOLOR}" 2>&1
    exit 1
}

function criticalecho-noexit () {
    echo -e "${RED}[NIHIL ERROR] $*${NOCOLOR}" 2>&1
}

function add-aliases() {
    colorecho "Adding aliases for: $*"
    local src_file="/opt/nihil/build/config/aliases.d/$*"
    # Ensure destination directory exists
    mkdir -p /opt/nihil/config
    
    if [ -f "$src_file" ]; then
        # Removing empty lines and trailing newline, adding one at the end
        # We append to a central aliases file in /opt/nihil/config/aliases
        grep -vE "^\s*$" "$src_file" | tee -a /opt/nihil/config/aliases >/dev/null
        # Ensure a newline at the end
        echo "" >> /opt/nihil/config/aliases
    else
        colorecho "Warning: Alias file $src_file not found"
    fi
}

function add-history() {
    colorecho "Adding history commands for: $*"
    local src_file="/opt/nihil/build/config/history.d/$*"
    # Ensure destination directory exists
    mkdir -p /opt/nihil/config

    if [ -f "$src_file" ]; then
        # We append to /opt/nihil/config/history
        grep -vE "^\s*$" "$src_file" | tee -a /opt/nihil/config/history >/dev/null
        echo "" >> /opt/nihil/config/history
    else
        colorecho "Warning: History file $src_file not found"
    fi
}

function add-symlink() {
    local target="$1"
    local link_name="$2"
    
    # Defaults to /usr/bin if just a name is provided
    if [[ "$link_name" != /* ]]; then
        link_name="/usr/bin/$link_name"
    fi

    colorecho "Creating symlink: $link_name -> $target"
    
    ln -sf "$target" "$link_name" || colorecho "Warning: Failed to create symlink"
}
