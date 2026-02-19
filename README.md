## Images Docker disponibles

Nihil fournit plusieurs images Docker spécialisées :

### Image de base (`base`)
Image minimale avec les outils système de base :
- Système Arch Linux configuré
- zsh + oh-my-zsh
- Outils CLI de base (vim, tmux, fzf, etc.)
- Dépôts nihil et Chaotic-AUR configurés

**Image GitHub Packages :** `ghcr.io/thenullpigeons/nihil-images:base` ou `ghcr.io/thenullpigeons/nihil-images:latest`

### Image Active Directory (`active-directory`)
Image spécialisée pour le pentest Active Directory :
- Tout ce qui est dans l'image de base
- Outils AD : bloodhound, certipy, ldapdomaindump, adidnsdump, netexec, rusthound-ce, kerbrute, krbrelayx, PowerShell, etc.
- Outils credentials : hashcat, john, pypykatz, donpapi
- Outils réseau : responder, smbclient, openldap
- Historique zsh pré-configuré avec commandes d'exemple pour tous les outils

**Image GitHub Packages :** `ghcr.io/thenullpigeons/nihil-images-ad:active-directory` ou `ghcr.io/thenullpigeons/nihil-images-ad:latest`

### Image Web (`web`)
Image orientée tests Web / HTTP :
- Base + outils web : sqlmap, gobuster, etc.

**Image GitHub Packages :** `ghcr.io/thenullpigeons/nihil-images-web:web` ou `ghcr.io/thenullpigeons/nihil-images-web:latest`

### Image Pwn (`pwn`)
Image orientée exploitation binaire / reverse :
- Base + radare2, strace, ltrace, pwntools, ROPgadget, pwndbg (gdb déjà dans core), etc.

**Image GitHub Packages :** `ghcr.io/thenullpigeons/nihil-images-pwn:pwn` ou `ghcr.io/thenullpigeons/nihil-images-pwn:latest`

## Construction des images Docker

### Construire l'image de base
```bash
cd nihil-images
docker build -f Dockerfile -t nihil:base .
```

### Construire l'image Active Directory
```bash
cd nihil-images
docker build -f Dockerfile.ad -t nihil:ad .
```

### Construire l'image Web
```bash
cd nihil-images
docker build -f Dockerfile.web -t nihil:web .
```

### Construire l'image Pwn
```bash
cd nihil-images
docker build -f Dockerfile.pwn -t nihil:pwn .
```

### Pull depuis GitHub Packages
```bash
# Image de base
docker pull ghcr.io/thenullpigeons/nihil-images:base

# Image Active Directory
docker pull ghcr.io/thenullpigeons/nihil-images-ad:active-directory

# Image Web
docker pull ghcr.io/thenullpigeons/nihil-images-web:web

# Image Pwn
docker pull ghcr.io/thenullpigeons/nihil-images-pwn:pwn
```

### Installer les dépendances (hôte)
```bash
sudo pacman -S --needed $(cat packages.txt)
```

## Utilisation

### Lancer le conteneur en mode interactif

```bash
docker run -it --rm nihil:local
```

### Lancer avec un shell bash

```bash
docker run -it --rm nihil:local bash
```

### Exécuter une commande spécifique

```bash
docker run -it --rm nihil:local cmd ls -la
```

Ou directement :

```bash
docker run -it --rm nihil:local ls -la
```

### Monter un volume pour le workspace

```bash
docker run -it --rm -v $(pwd):/workspace nihil:local
```

## Dépendances (hôte Arch/Manjaro)

Installez les dépendances nécessaires avec pacman :

```bash
sudo pacman -Syu --needed $(grep -vE '^\s*#' packages.txt | grep -vE '^\s*$')
```

Contenu dans `packages.txt` (éditable selon vos besoins).

## Fonctionnalités

### Historique zsh pré-configuré
Tous les outils installés ont leurs commandes d'exemple automatiquement ajoutées dans l'historique zsh. Utilisez `Ctrl+R` dans zsh pour rechercher et réutiliser les commandes.

### Installation standardisée
Les modules d'installation suivent un pattern standardisé :
- `install_pipx_tool` : outils Python via pipx
- `install_cargo_tool` : outils Rust via cargo
- `install_go_tool` : outils Go via go install
- `install_git_tool` : outils depuis Git
- `install_git_tool_venv` : outils Git avec venv Python
- `install_tar_tool` : outils depuis archives tar.gz (multi-arch)
- `install_pacman_tool` : paquets Arch Linux
- `install_aur_tool` : paquets AUR

Toutes ces fonctions ajoutent automatiquement les aliases et l'historique si les fichiers existent dans `build/config/aliases.d/` et `build/config/history.d/`.

## Structure du projet

```
nihil-images/
├── Dockerfile
├── Dockerfile.ad
├── Dockerfile.web
├── build/
│   ├── entrypoint.sh
│   ├── lib/
│   │   └── common.sh
│   ├── config/
│   │   ├── aliases.d/
│   │   └── history.d/
│   └── modules/
│       ├── base.sh
│       ├── core_tools.sh
│       ├── redteam_ad.sh
│       ├── redteam_cargo.sh
│       ├── redteam_credential.sh
│       ├── redteam_network.sh
│       ├── redteam_pacman.sh
│       ├── redteam_pipx.sh
│       ├── redteam_aur.sh
│       ├── redteam_curl.sh
│       ├── redteam_git.sh
│       ├── redteam_go.sh
│       ├── redteam_web.sh
│       └── redteam_pwn.sh
├── runtime/
│   └── entrypoint.sh
└── packages.txt
```
