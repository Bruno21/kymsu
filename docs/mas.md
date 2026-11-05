# mas.sh — README

5 nov. 2026 · @clicclac

## Description

`mas.sh` est un plugin pour [altKYMSU](https://github.com/Bruno21/kymsu), un fork de [KYMSU](https://github.com/welcoMattic/kymsu). Il détecte les applications Mac App Store obsolètes via [mas-cli](https://github.com/mas-cli/mas) et propose de les mettre à jour de façon interactive, avec sélection dans fzf et prévisualisation des détails de chaque app.

## Prérequis

- **altKYMSU** installé et configuré (`config.shlib`, `kymsu.cfg`)
- **mas** : `brew install mas`
- **fzf** : `brew install fzf` (requis uniquement pour le mode `y=choose`)
- macOS uniquement (mas ne fonctionne pas sur Linux)
- Être connecté à l'App Store dans Réglages Système

## Installation

Copier `mas.sh` dans le dossier des plugins de kymsu :

```bash
cp mas.sh ~/.kymsu/plugins.d/
chmod +x ~/.kymsu/plugins.d/mas.sh
```

Ou laisser `install.sh` le copier automatiquement depuis le dépôt.

Ajouter les clés suivantes dans `kymsu.cfg` :

```
mas_dry_run=false
mas_store_country=fr
pinned_mas=
```
