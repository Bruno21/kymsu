# homebrew.sh — README

Nov 7, 2026 · @clicclac

## Description

`homebrew.sh` est un plugin pour [altKYMSU](https://github.com/Bruno21/kymsu), un fork de [KYMSU](https://github.com/welcoMattic/kymsu). C'est le plugin central de kymsu : il gère la mise à jour complète de [Homebrew](https://brew.sh/) — formulas, casks, et casks avec version `:latest`. Il affiche les informations détaillées de chaque paquet (description, homepage, versions), gère les formulas et casks épinglés, surveille les fichiers de configuration Apache et PHP modifiés par une mise à jour, envoie des notifications macOS, et lance `brew doctor` en fin de script.

## Prérequis

- **altKYMSU** installé et configuré (`config.shlib`, `kymsu.cfg`)
- **Homebrew** : [brew.sh](https://brew.sh)
- **jq** (obligatoire) : `brew install jq` — utilisé pour parser la sortie JSON de `brew outdated --json=v2`
- **terminal-notifier** (recommandé, macOS uniquement) : `brew install terminal-notifier` — pour les notifications système en cas de modification de fichiers de configuration Apache ou PHP

## Installation

Copier `homebrew.sh` dans le dossier des plugins de kymsu :

```bash
cp homebrew.sh ~/.kymsu/plugins.d/
chmod +x ~/.kymsu/plugins.d/homebrew.sh
```

Ou laisser `install.sh` le copier automatiquement depuis le dépôt.

Installer les dépendances :

```bash
brew install jq terminal-notifier
```

Ajouter les clés suivantes dans `kymsu.cfg` :

```
pinned_cask=
```

## Configuration

### `kymsu.cfg`

| Clé | Valeur par défaut | Description |
| --- | --- | --- |
| `pinned_cask` | *(vide)* | Noms exacts des casks à ne jamais mettre à jour, séparés par des espaces |

Exemple : `pinned_cask=docker firefox`

### Variables dans le script

Ces options sont configurées directement dans la section Settings du script :

| Variable | Défaut | Description |
| --- | --- | --- |
| `display_info` | `true` | Affiche description, homepage et versions de chaque paquet/cask à mettre à jour |
| `latest` | `false` | `true` : force la mise à jour des casks avec `version :latest` ou `auto_updates true` |

### Options en ligne de commande

| Option | Description |
| --- | --- |
| `-n` / `--nodistract` | Mode no-distract : toutes les mises à jour sont appliquées sans confirmation |
| `-c` / `--cleanup` | Lance `brew cleanup --prune=30` en fin de script |

## Utilisation

Le script est lancé automatiquement par kymsu :

```bash
kymsu2
```

Ou directement :

```bash
~/.kymsu/plugins.d/homebrew.sh
```

Avec options :

```bash
kymsu2 -n          # no-distract : tout mettre à jour sans confirmation
kymsu2 -c          # cleanup : supprimer les vieilles versions après mise à jour
kymsu2 -n -c       # les deux combinés
```

Le script effectue dans l'ordre :

1. `brew update` pour rafraîchir la liste des formulas.
2. `brew outdated --greedy --json=v2` pour détecter tout ce qui est obsolète.
3. Affichage et mise à jour des **formulas** (en excluant les pinned et bash).
4. Affichage et mise à jour des **casks** (en excluant `pinned_cask`).
5. Si `latest=true` : affichage et mise à jour des casks avec version `:latest`.
6. Surveillance des fichiers de configuration Apache et PHP (notification si modifiés).
7. `brew doctor` et `brew missing`.
8. Si `-c` : `brew cleanup --prune=30`.

## Fonctionnement détaillé

### Formulas (packages)

Les formulas obsolètes sont détectées via `brew outdated --greedy --json=v2`. Si `display_info=true`, `brew info --json=v2` est appelé pour afficher nom, description, homepage, versions installée/stable, et statut `keg-only` ou `pinned`.

Les formulas **épinglées par Homebrew** (`brew pin`) sont détectées automatiquement via le JSON et ne sont pas mises à jour. Pour les débloquer : `brew unpin <formula>`.

**Cas particulier : bash.** La mise à jour de bash via Homebrew peut remplacer le bash système macOS. Le script la détecte et affiche un message invitant à la faire manuellement dans un autre terminal, sans jamais l'appliquer automatiquement.

### Casks

Deux catégories de casks sont gérées séparément :

- **Casks avec version numérique** : détectés par `brew outdated`, mis à jour normalement.
- **Casks avec `version :latest` ou `auto_updates true`** : Homebrew ne peut pas suivre leur version. Ils sont listés séparément. La mise à jour n'est appliquée que si `latest=true` dans le script.

Les casks dans `pinned_cask` sont exclus des deux catégories et signalés en rouge.

### Modes de confirmation (formulas et casks)

En mode interactif, trois réponses possibles à la question de mise à jour :

- `y` : confirmation cask/formula par cask/formula (`xargs -p`)
- `a` : tout mettre à jour sans confirmation supplémentaire
- autre : passer à l'étape suivante

En mode no-distract (`-n`), la question est sautée et tout est mis à jour automatiquement.

### Surveillance des fichiers de configuration

Après `brew update`, le script crée un fichier checkpoint dans `/tmp/kymsu_checkpoint`. Après les mises à jour, il vérifie si les fichiers `httpd.conf` (Apache) et `php.ini` (toutes versions PHP Homebrew) ont été modifiés depuis ce checkpoint, via `find -newer`. Si c'est le cas, une alerte rouge s'affiche et une notification macOS est envoyée via `terminal-notifier`.

### `brew doctor` et `brew missing`

En fin de script, `brew doctor` vérifie l'intégrité de l'installation Homebrew. `brew missing` détecte les dépendances manquantes. Les avertissements connus (python-cryptography, python-certifi, numpy) sont signalés en commentaire car requis par certbot, yt-dlp et ffmpeg.

### Cleanup

Si `-c` est passé, `brew cleanup --prune=30` supprime les vieilles versions des formulas et les téléchargements de plus de 30 jours. Homebrew 2.0+ fait ce nettoyage automatiquement tous les 30 jours ; `-c` permet de le forcer.

## Limitations connues

- **`config.shlib` sourcé sans vérification** : contrairement aux autres plugins, `homebrew.sh` ne teste pas si `config.shlib` est lisible avant de le sourcer. Si le fichier est absent, le script échoue avec une erreur peu explicite. À corriger si tu veux l'uniformiser avec les autres plugins.
- **`latest=false` par défaut** : les casks avec `version :latest` ou `auto_updates true` ne sont jamais mis à jour automatiquement, même si une nouvelle version est disponible. Mettre `latest=true` dans le script pour les inclure.
- **bash exclu de la mise à jour automatique** : la mise à jour de bash via Homebrew doit être faite manuellement. Le script l'affiche mais ne l'applique jamais.
- **`display_info=true` ajoute des appels réseau** : `brew info --json=v2` est appelé pour chaque formula et cask à mettre à jour. Sur une connexion lente ou avec de nombreux paquets, cela ralentit l'affichage.
- **`xargs -p` pour la confirmation individuelle** : en mode `y`, chaque paquet est confirmé via `xargs -p`. Sur certaines versions de macOS, le comportement de `-p` peut varier légèrement.
- **Notifications macOS uniquement** : `terminal-notifier` n'est pas disponible sur Linux. Le script vérifie `$OSTYPE == darwin*` avant d'appeler la commande.
- **`brew doctor` peut afficher des faux positifs** : certains avertissements connus (python-cryptography, numpy, python-certifi) sont des dépendances légitimes de certbot, yt-dlp et ffmpeg. Ils sont signalés en commentaire dans le script mais s'affichent quand même dans la sortie de `brew doctor`.
