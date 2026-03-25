## Images Docker disponibles

Nihil fournit plusieurs images Docker spécialisées :

### Full (`full`) — *The whole flock. Every tool, every module.*
Image complète avec tous les outils :
- Système Arch Linux configuré
- zsh + oh-my-zsh
- Outils CLI de base (vim, tmux, fzf, etc.)
- Tous les modules red-team (AD, web, pwn, network, credential, c2, misc)
- Dépôts nihil et Chaotic-AUR configurés

**Image GitHub Packages :** `ghcr.io/thenullpigeons/full:latest` ou `ghcr.io/thenullpigeons/full:flock`

### Active Directory (`ad`) — *Nest in their Active Directory.*
Image spécialisée pour le pentest Active Directory :
- Tout ce qui est dans l'image de base
- Outils AD : bloodhound, certipy, ldapdomaindump, adidnsdump, netexec, rusthound-ce, kerbrute, krbrelayx, PowerShell, etc.
- Outils credentials : hashcat, john, pypykatz, donpapi
- Outils réseau : responder, smbclient, openldap
- Historique zsh pré-configuré avec commandes d'exemple pour tous les outils

**Image GitHub Packages :** `ghcr.io/thenullpigeons/ad:latest` ou `ghcr.io/thenullpigeons/ad:nest`

### Web (`web`) — *Beak through their web apps.*
Image orientée tests Web / HTTP :
- Base + outils web : sqlmap, gobuster, nuclei, ffuf, etc.

**Image GitHub Packages :** `ghcr.io/thenullpigeons/web:latest` ou `ghcr.io/thenullpigeons/web:beak`

### CTF (`ctf`) — *Capture the flag, no fluff.*
Image dédiée CTF (polyvalente) :
- Base + outils pwn/reverse (pwntools, ROPgadget, radare2, etc.)
- Outils web CTF (ffuf, nuclei, sqlmap, etc.)
- Outils réseau/credential utiles en challenges
- Bundle léger par rapport à `full` (pas de stack AD/C2 complète)

**Image GitHub Packages :** `ghcr.io/thenullpigeons/ctf:latest` ou `ghcr.io/thenullpigeons/ctf:flag`

## Construction des images Docker

### Construire l'image full
```bash
cd nihil-images
docker build -f Dockerfile -t nihil:full .
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

### Construire l'image CTF
```bash
cd nihil-images
docker build -f Dockerfile.ctf -t nihil:ctf .
```

### Pull depuis GitHub Packages
```bash
# Image full
docker pull ghcr.io/thenullpigeons/full:latest

# Image Active Directory
docker pull ghcr.io/thenullpigeons/ad:latest

# Image Web
docker pull ghcr.io/thenullpigeons/web:latest

# Image CTF
docker pull ghcr.io/thenullpigeons/ctf:latest
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
│       └── redteam_web.sh
├── runtime/
│   └── entrypoint.sh
└── packages.txt
```
