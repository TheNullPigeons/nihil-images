### Installer les dépendances
```bash
sudo pacman -S --needed $(cat packages.txt)
```

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
├── runtime/
│   └── entrypoint.sh
└── packages.txt
```
