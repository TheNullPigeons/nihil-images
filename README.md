## Images Docker disponibles

Nihil fournit deux images Docker spécialisées :

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
- Outils AD : bloodhound, certipy, ldapdomaindump, adidnsdump, netexec, rusthound-ce, etc.

**Image GitHub Packages :** `ghcr.io/thenullpigeons/nihil-images-ad:active-directory` ou `ghcr.io/thenullpigeons/nihil-images-ad:latest`

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

### Pull depuis GitHub Packages
```bash
# Image de base
docker pull ghcr.io/thenullpigeons/nihil-images:base

# Image Active Directory
docker pull ghcr.io/thenullpigeons/nihil-images-ad:active-directory
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

## Structure du projet

```
nihil-images/
├── Dockerfile
├── build/
│   ├── entrypoint.sh
│   ├── lib/
│   │   └── common.sh
│   └── modules/
│       └── base.sh
│       └── core_tools.sh
│       └── redteam_ad.sh
│       └── redteam_cargo.sh
│       └── redteam_credential.sh
│       └── redteam_network.sh
│       └── redteam_pacman.sh
│       └── redteam_pipx.sh
│       └── redteam_web.sh
├── runtime/
│   └── entrypoint.sh
└── packages.txt
```
