#!/bin/bash
# Base package installation

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

function package_base() {
    colorecho "Updating system and installing base OS packages"
    pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed \
    base \
    base-devel \
    dialog \
    python \
    python-pip \
    python-wheel \
    python-setuptools \
    zsh \
    git \
    go \
    php \
    rust \
    openssl \
    pkg-config \
    clang \
    && \
    pacman -Syu --noconfirm && \
    pacman -Sc --noconfirm
    
    colorecho "Adding Nihil repository to pacman.conf"
    # Ajouter le dépôt nihil à pacman.conf
    if ! grep -q "^\[nihil\]" /etc/pacman.conf; then
        echo "" >> /etc/pacman.conf
        echo "[nihil]" >> /etc/pacman.conf
        echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf
        echo "Server = https://TheNullPigeons.github.io/\$arch" >> /etc/pacman.conf
        colorecho "Nihil repository added to pacman.conf"
    else
        colorecho "Nihil repository already exists in pacman.conf"
    fi

    # Ajouter Chaotic-AUR repository (méthode officielle)
    colorecho "Adding Chaotic-AUR repository"
    if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
        # Récupérer et signer la clé GPG principale (méthode officielle)
        pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>/dev/null || true
        pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || true
        
        # Installer chaotic-keyring et chaotic-mirrorlist depuis le CDN officiel
        colorecho "Installing chaotic-keyring and chaotic-mirrorlist"
        keyring_ok=0
        mirrorlist_ok=0
        
        # Télécharger et installer chaotic-keyring
        cd /tmp
        if curl -L -o chaotic-keyring.pkg.tar.zst 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 2>/dev/null || \
           wget -O chaotic-keyring.pkg.tar.zst 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 2>/dev/null; then
            if pacman -U --noconfirm chaotic-keyring.pkg.tar.zst 2>/dev/null; then
                keyring_ok=1
                colorecho "chaotic-keyring installed successfully"
            else
                colorecho "Warning: Failed to install chaotic-keyring package"
            fi
            rm -f chaotic-keyring.pkg.tar.zst
        else
            colorecho "Warning: Failed to download chaotic-keyring"
        fi
        
        # Télécharger et installer chaotic-mirrorlist
        if [ "$keyring_ok" -eq 1 ]; then
            if curl -L -o chaotic-mirrorlist.pkg.tar.zst 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>/dev/null || \
               wget -O chaotic-mirrorlist.pkg.tar.zst 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>/dev/null; then
                if pacman -U --noconfirm chaotic-mirrorlist.pkg.tar.zst 2>/dev/null; then
                    mirrorlist_ok=1
                    colorecho "chaotic-mirrorlist installed successfully"
                else
                    colorecho "Warning: Failed to install chaotic-mirrorlist package"
                fi
                rm -f chaotic-mirrorlist.pkg.tar.zst
            else
                colorecho "Warning: Failed to download chaotic-mirrorlist"
            fi
        fi
        cd - > /dev/null
        
        # Ajouter le dépôt Chaotic-AUR dans pacman.conf UNIQUEMENT si le mirrorlist est installé
        if [ "$mirrorlist_ok" -eq 1 ] && [ -f "/etc/pacman.d/chaotic-mirrorlist" ]; then
            echo "" >> /etc/pacman.conf
            echo "[chaotic-aur]" >> /etc/pacman.conf
            echo "Include = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf
            colorecho "Chaotic-AUR repository added to pacman.conf"
        else
            colorecho "Warning: Chaotic-AUR mirrorlist not available, skipping repo activation"
        fi
    else
        colorecho "Chaotic-AUR repository already exists in pacman.conf"
    fi

    # Configure zsh + oh-my-zsh for a nicer shell experience
    colorecho "Installing and configuring zsh with oh-my-zsh"
    export ZSH="/root/.oh-my-zsh"
    if [ ! -d "$ZSH" ]; then
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH" || colorecho "Failed to clone oh-my-zsh"
    fi

    if [ ! -f "/root/.zshrc" ] && [ -d "$ZSH" ]; then
        cp "$ZSH/templates/zshrc.zsh-template" /root/.zshrc || true
        # Optionally set a nicer theme
        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' /root/.zshrc 2>/dev/null || true
    fi

    # Plugins oh-my-zsh utiles pour le pentest
    if [ -d "$ZSH/custom" ]; then
        # Autosuggestions
        if [ ! -d "$ZSH/custom/plugins/zsh-autosuggestions" ]; then
            git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH/custom/plugins/zsh-autosuggestions" || \
                colorecho "Warning: Failed to clone zsh-autosuggestions"
        fi

        # Syntax highlighting
        if [ ! -d "$ZSH/custom/plugins/zsh-syntax-highlighting" ]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH/custom/plugins/zsh-syntax-highlighting" || \
                colorecho "Warning: Failed to clone zsh-syntax-highlighting"
        fi

        # Activer les plugins dans .zshrc si possible
        if [ -f "/root/.zshrc" ]; then
            # Si la ligne plugins=(...) existe déjà, on la remplace proprement
            if grep -q "^plugins=" /root/.zshrc; then
                sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' /root/.zshrc 2>/dev/null || true
            else
                # Sinon on ajoute une ligne plugins à la fin
                {
                    echo ""
                    echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)"
                } >> /root/.zshrc
            fi

            # Configurer la couleur des autosuggestions en vert (comme demandé)
            echo "ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=green'" >> /root/.zshrc
        fi
    fi

    # Inject custom zsh history
    if [ -f "/opt/nihil/build/config/zsh_history" ]; then
        colorecho "Injecting custom zsh history"
        while read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            
            # If line starts with ':', assume it's already formatted (EXTENDED_HISTORY)
            if [[ "$line" == :* ]]; then
                echo "$line" >> /root/.zsh_history
            else
                # Format for EXTENDED_HISTORY: : <timestamp>:0;<command>
                # Using a fixed timestamp (Jan 1 2025)
                echo ": 1735689600:0;$line" >> /root/.zsh_history
            fi
        done < "/opt/nihil/build/config/zsh_history"
    fi

    # Try to set zsh as default shell for root (non bloquant)
    if command -v chsh >/dev/null 2>&1; then
        chsh -s /usr/bin/zsh root || true
    fi

    # Installer yay (AUR helper)
    colorecho "Installing yay AUR helper"
    if ! command -v yay >/dev/null 2>&1; then
        # Utilisateur non-root pour makepkg
        useradd -m -s /bin/bash builder 2>/dev/null || true
        cd /tmp
        # Cloner les sources sous /tmp
        git clone https://aur.archlinux.org/yay.git yay-build || colorecho "Warning: Failed to clone yay"
        if [ -d "yay-build" ]; then
            # Donner les droits à builder sur le dossier
            chown -R builder:builder yay-build || true
            cd yay-build
            # Compiler en tant que builder (makepkg refusera le root)
            su builder -c "cd /tmp/yay-build && makepkg -s --noconfirm" || colorecho "Warning: Failed to build yay"
            # Installer le paquet compilé en root
            if ls /tmp/yay-build/*.pkg.tar.zst 1> /dev/null 2>&1; then
                pacman -U --noconfirm /tmp/yay-build/*.pkg.tar.zst || colorecho "Warning: Failed to install yay"
            fi
            cd /
            rm -rf /tmp/yay-build
            userdel -r builder 2>/dev/null || true
        fi
    else
        colorecho "yay is already installed"
    fi
    
    # Synchroniser le dépôt nihil
    colorecho "Synchronizing Nihil repository"
    pacman -Sy --noconfirm

    # Installer les paquets système depuis packages.txt
    if [ -f "/opt/nihil/packages.txt" ]; then
        colorecho "Installing system packages from packages.txt"
        while IFS= read -r package || [ -n "$package" ]; do
            # Ignorer les lignes vides et les commentaires
            [[ -z "$package" || "$package" =~ ^# ]] && continue
            colorecho "Installing $package"
            pacman -S --noconfirm --needed "$package" || colorecho "Warning: Failed to install $package"
        done < "/opt/nihil/packages.txt"
    fi
    
    # Installer TOUS les paquets du dépôt nihil
    colorecho "Listing all packages in Nihil repository"
    # Récupère la liste des paquets du dépôt nihil
    nihil_packages=$(pacman -Sl nihil | cut -d' ' -f2)
    
    if [ -n "$nihil_packages" ]; then
        colorecho "Installing all Nihil packages: $nihil_packages"
        # Convertir les nouvelles lignes en espaces pour la commande pacman
        package_list=$(echo "$nihil_packages" | tr '\n' ' ')
        pacman -S --noconfirm --needed $package_list || colorecho "Warning: Failed to install some packages"
    else
        colorecho "No packages found in Nihil repository"
    fi
    
    # Nettoyage final du cache pacman pour réduire la taille
    colorecho "Cleaning pacman cache"
    pacman -Sc --noconfirm
    
    colorecho "Base packages installed"
}

