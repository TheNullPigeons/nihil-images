#!/bin/bash
# Base package installation

# Resolve path to lib/common.sh relative to this module file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

function package_base() {
    colorecho "Updating system and installing base packages"
    pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed base base-devel dialog python python-pip python-wheel python-setuptools && \
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

