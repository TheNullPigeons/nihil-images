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
    local src_file="/opt/nihil/build/config/aliases.d/$*"
    # Ensure destination directory exists
    mkdir -p /opt/nihil/config
    
    if [ -f "$src_file" ]; then
        colorecho "Adding aliases for: $*"
        # Removing empty lines and trailing newline, adding one at the end
        # We append to a central aliases file in /opt/nihil/config/aliases
        grep -vE "^\s*$" "$src_file" | tee -a /opt/nihil/config/aliases >/dev/null
        # Ensure a newline at the end
        echo "" >> /opt/nihil/config/aliases
    fi
    # Silently skip if file doesn't exist (no warning needed)
}

function add-history() {
    local src_file="/opt/nihil/build/config/history.d/$*"
    # Ensure destination directory exists
    mkdir -p /opt/nihil/config

    if [ -f "$src_file" ]; then
        colorecho "Adding history commands for: $*"
        # Injecter directement dans .zsh_history au format EXTENDED_HISTORY
        # Format: : <timestamp>:0;<command>
        # Utiliser un timestamp de base et incrémenter pour chaque commande
        # Le compteur global permet d'éviter les collisions de timestamp
        local base_timestamp="${ADD_HISTORY_BASE_TIMESTAMP:-1735689600}"
        local counter_file="/opt/nihil/config/.history_counter"
        local counter=$(cat "$counter_file" 2>/dev/null || echo "0")
        
        # S'assurer que .zsh_history existe
        touch /root/.zsh_history
        
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Supprimer \r (fins de ligne Windows) pour éviter décalage du curseur au rappel
            line="${line//$'\r'/}"
            # Nettoyer espaces en début et fin pour éviter commandes modifiées au rappel
            line="${line#"${line%%[![:space:]]*}"}"
            line="${line%"${line##*[![:space:]]}"}"
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            # Format EXTENDED_HISTORY: : <timestamp>:<duration>;<command>
            # printf '%s\n' pour éviter interprétation de % ou \ dans la commande
            printf '%s\n' ": $((base_timestamp + counter)):0;$line" >> /root/.zsh_history
            counter=$((counter + 1))
        done < "$src_file"
        
        # Sauvegarder le compteur pour les prochains appels
        echo "$counter" > "$counter_file"
    else
        # Debug: afficher si le fichier n'existe pas (pour diagnostiquer)
        colorecho "History file not found: $src_file (skipping silently)"
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
