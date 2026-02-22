#!/bin/bash
# load_my_resources.sh
# Appelé au premier démarrage du container pour déployer les configurations
# utilisateur depuis le volume monté /opt/my-resources.
# Même logique qu'Exegol : si le dossier existe → on applique la config ;
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
# Exécution
# ---------------------------------------------------------------------------
init_my_resources
deploy_zsh
deploy_nvim
deploy_tmux

echo "[NIHIL] my-resources déployés avec succès."
