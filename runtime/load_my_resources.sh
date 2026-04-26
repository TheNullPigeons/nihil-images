#!/bin/bash
# load_my_resources.sh
# Appelé au premier démarrage du container pour déployer les configurations
# utilisateur depuis le volume monté /opt/my-resources.
# Si le dossier existe → on applique la config ;
# sinon → on le crée vide pour que l'utilisateur sache qu'il peut le remplir.

MY_ROOT_PATH="/opt/my-resources"
MY_SETUP_PATH="$MY_ROOT_PATH/setup"

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------
function init_my_resources() {
    if [[ ! -d "$MY_ROOT_PATH" ]]; then
        echo "[NIHIL] my-resources est désactivé dans ce container (volume non monté), abandon."
        exit 0
    fi

    mkdir -p "$MY_SETUP_PATH"
}

# ---------------------------------------------------------------------------
# zsh
# ---------------------------------------------------------------------------
function deploy_zsh() {
    if [[ -d "$MY_SETUP_PATH/zsh" ]]; then
        # Charger les aliases custom
        if [[ -f "$MY_SETUP_PATH/zsh/aliases" ]]; then
            cat "$MY_SETUP_PATH/zsh/aliases" >> /opt/nihil/config/aliases
        fi
        # Charger les commandes zshrc custom
        if [[ -f "$MY_SETUP_PATH/zsh/zshrc" ]]; then
            cat "$MY_SETUP_PATH/zsh/zshrc" >> /root/.zshrc
        fi
        # Injecter l'historique custom
        if [[ -f "$MY_SETUP_PATH/zsh/history" ]]; then
            grep -vE "^(\s*|#.*)$" "$MY_SETUP_PATH/zsh/history" >> /root/.zsh_history || true
        fi
    else
        mkdir -p "$MY_SETUP_PATH/zsh"
        # Créer des fichiers exemples vides
        touch "$MY_SETUP_PATH/zsh/aliases" \
              "$MY_SETUP_PATH/zsh/zshrc" \
              "$MY_SETUP_PATH/zsh/history"
    fi
}

# ---------------------------------------------------------------------------
# nvim
# ---------------------------------------------------------------------------
function deploy_nvim() {
    if [[ -d "$MY_SETUP_PATH/nvim" ]]; then
        # Si l'utilisateur a mis des fichiers → on les copie dans ~/.config/nvim
        mkdir -p ~/.config/
        cp -r "$MY_SETUP_PATH/nvim/" ~/.config/
    else
        # Sinon on crée le dossier vide (visible sur l'hôte via le volume)
        mkdir -p "$MY_SETUP_PATH/nvim"
    fi
}

# ---------------------------------------------------------------------------
# tmux
# ---------------------------------------------------------------------------
function deploy_tmux() {
    if [[ -d "$MY_SETUP_PATH/tmux" ]]; then
        if [[ -f "$MY_SETUP_PATH/tmux/tmux.conf" ]]; then
            # Cette option doit toujours être définie en premier
            echo 'set-option -g default-shell /bin/zsh' > ~/.tmux.conf
            cat "$MY_SETUP_PATH/tmux/tmux.conf" >> ~/.tmux.conf
        fi
    else
        mkdir -p "$MY_SETUP_PATH/tmux"
        chmod 770 "$MY_SETUP_PATH/tmux"
    fi
}

# ---------------------------------------------------------------------------
# Burp CA
# ---------------------------------------------------------------------------

function deploy_burp_ca() {
    local burp_jar="/opt/tools/BurpSuiteCommunity/BurpSuiteCommunity.jar"
    local burp_conf="/opt/tools/BurpSuiteCommunity/conf.json"
    local ca_path="/opt/tools/BurpSuiteCommunity/cacert.der"

    [[ -f "$burp_jar" ]] || return 0
    command -v certutil > /dev/null 2>&1 || return 0

    echo "[NIHIL] Generating Burp CA certificate..."

    # Start Burp headlessly and wait for proxy to be up
    local burp_port=8080
    echo y | java -Djava.awt.headless=true -jar "$burp_jar" \
        --config-file="$burp_conf" > /dev/null 2>&1 &
    local burp_pid=$!

    local timeout=0
    while ! curl -sf "http://127.0.0.1:${burp_port}/cert" -o /dev/null 2>/dev/null; do
        sleep 1
        timeout=$((timeout + 1))
        if (( timeout >= 60 )); then
            echo "[NIHIL] Burp CA timeout, skipping."
            kill "$burp_pid" 2>/dev/null
            return 1
        fi
    done

    curl -sf "http://127.0.0.1:${burp_port}/cert" -o "$ca_path"
    kill "$burp_pid" 2>/dev/null
    wait "$burp_pid" 2>/dev/null

    # Trust in Firefox (Nihil profile)
    local ff_profile="/root/.mozilla/firefox/nihil.Nihil"
    if [[ -d "$ff_profile" ]]; then
        certutil -A -n "Burp CA" -t "CT,," -i "$ca_path" -d "sql:${ff_profile}/" 2>/dev/null \
            && echo "[NIHIL] Burp CA trusted in Firefox"
    fi

    # Trust in Chromium (NSS database)
    local nss_dir="/root/.pki/nssdb"
    if [[ ! -d "$nss_dir" ]]; then
        mkdir -p "$nss_dir"
        certutil -N -d "sql:${nss_dir}" --empty-password 2>/dev/null
    fi
    certutil -A -n "Burp CA" -t "CT,," -i "$ca_path" -d "sql:${nss_dir}" 2>/dev/null \
        && echo "[NIHIL] Burp CA trusted in Chromium"
}

# ---------------------------------------------------------------------------
# Exécution
# ---------------------------------------------------------------------------
init_my_resources
deploy_zsh
deploy_nvim
deploy_tmux
deploy_burp_ca

echo "[NIHIL] my-resources déployés avec succès."
