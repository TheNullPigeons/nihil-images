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
docker run -it --rm -v $(pwd):/workspace nihil:locals