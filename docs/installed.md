# installed.sh — README

Nov 7, 2026 · @clicclac

## Description

`installed.sh` est un plugin pour [altKYMSU](https://github.com/Bruno21/kymsu), un fork de [KYMSU](https://github.com/welcoMattic/kymsu). Contrairement aux autres plugins, il ne met rien à jour : il génère un **inventaire complet** de tous les logiciels installés sur la machine sous forme d'un fichier Markdown horodaté, et crée un **Brewfile** de sauvegarde. Le fichier Markdown est ouvert automatiquement à la fin du script.

Sections générées : Homebrew (taps, formulas, casks), Mac App Store (via mas), PECL, Python (pip), pipx, Rust (cargo), npm (global et local), Ruby (gem), Atom (optionnel).

## Prérequis

- **altKYMSU** installé et configuré (`config.shlib`, `kymsu.cfg`)
- **brew** (Homebrew) pour les sections brew/cask/Brewfile
- **mas** (optionnel) : `brew install mas` — pour la liste App Store
- **pecl** (optionnel) : fourni avec PHP — pour les extensions PHP
- **pip3** (optionnel) : fourni avec Python 3 — pour les paquets Python
- **pipx** (optionnel) : `brew install pipx` — pour les apps pipx
- **cargo** (optionnel) : fourni avec Rust/rustup — pour les crates
- **npm** (optionnel) : fourni avec Node.js — pour les paquets npm
- **gem** (optionnel) : fourni avec Ruby — pour les gems
- **apm** (optionnel) : fourni avec l'éditeur Atom (désactivé par défaut)

Chaque section est générée uniquement si la commande correspondante est disponible dans le `PATH`.

## Installation et configuration

Copier `installed.sh` dans le dossier des plugins de kymsu :

```bash
cp installed.sh ~/.kymsu/plugins.d/
chmod +x ~/.kymsu/plugins.d/installed.sh
```

Ou laisser `install.sh` le copier automatiquement depuis le dépôt.

Toute la configuration se fait directement dans le script, section Settings :

| Variable | Défaut | Description |
| --- | --- | --- |
| `local_path` | `$HOME/Sites/node_modules/` | Dossier des paquets npm locaux |
| `chemin` | `$HOME/Documents/kymsu` | Dossier de destination des fichiers générés |
| `pip_version` | `pip3` | Commande pip à utiliser (`pip` ou `pip3`) |
| `apm` | `false` | `true` : inclut les paquets Atom dans l'inventaire |

Le dossier `chemin` est créé automatiquement s'il n'existe pas.

## Utilisation

Le script est lancé automatiquement par kymsu :

```bash
kymsu2
```

Ou directement :

```bash
~/.kymsu/plugins.d/installed.sh
```

Le script est entièrement non interactif. À la fin, le fichier Markdown généré est ouvert avec `open` (macOS uniquement). Le dossier `chemin` contiendra :

- `Installed_<hostname>@<date>.md` : l'inventaire complet
- `Brewfile_<hostname>@<date>.txt` : le Brewfile de sauvegarde
- Les anciens Brewfiles (les 10 plus récents sont conservés)

## Fonctionnement détaillé

### Fichier Markdown généré

Le fichier est nommé `Installed_<hostname>@<date>.md` (ex: `Installed_macbook@07-11-2026_142305.md`). Si un fichier `Installed*.md` existe déjà dans le dossier, il est supprimé avant génération. Le fichier inclut une table des matières (`[TOC]`) en haut.

### Sections incluses

| Section | Commande source | Contenu |
| --- | --- | --- |
| Homebrew | `brew tap`, `brew list --formula`, `brew list --cask` | Taps, formulas, casks |
| Mac App Store | `mas list` | Nom et ID de chaque app |
| PECL | `pecl list` | Extensions PHP installées |
| Python | `pip3 list` | Paquets Python |
| pipx | `pipx list --short` | Applications pipx |
| Rust | `cargo install --list` | Crates installées |
| npm global | `npm list -g --depth=0` | Paquets globaux |
| npm local | `npm ls` dans `local_path` | Paquets locaux (si `node_modules` présent) |
| Ruby | `gem list --no-versions` | Gems installées |
| Atom | `apm list` | Paquets Atom (si `apm=true`) |

### Brewfile

Après la génération du Markdown, `brew bundle dump` crée un `Brewfile` dans `chemin`. Il est immédiatement renommé `Brewfile_<hostname>@<date>.txt`. Ce fichier permet de restaurer l'environnement complet avec :

```bash
cd ~/Documents/kymsu
brew bundle --file=Brewfile_<hostname>@<date>.txt
```

Si un fichier `Brewfile` (sans date) existe déjà dans `chemin` au démarrage du script, il est renommé avec sa date de modification avant d'être écrasé.

### Rotation des Brewfiles

Le script conserve les **10 Brewfiles les plus récents** et supprime les plus anciens. Avec un lancement hebdomadaire, cela représente environ 10 semaines d'historique.

### Noms des fichiers

Le format `<hostname>@<date>` (ex: `macbook@07-11-2026_142305`) permet d'identifier facilement la machine et la date si les fichiers sont synchronisés sur plusieurs machines ou sauvegardés dans un dossier partagé.

## Limitations connues

- **macOS uniquement pour `open`** : la dernière ligne `open "$chemin/$filename.md"` ouvre le fichier dans l'application par défaut. Sur Linux, remplacer par `xdg-open` ou supprimer la ligne.
- **`chemin` codé en dur** : le dossier de destination (`$HOME/Documents/kymsu`) est défini dans le script, pas dans `kymsu.cfg`. Pour le personnaliser, modifier directement le script.
- **`local_path` pour npm** : un seul dossier local npm est pris en compte. Si `node_modules` n'existe pas à cet emplacement, la section npm local est silencieusement sautée.
- **Atom est désactivé par défaut** : `apm=false`. Atom n'est plus maintenu depuis 2022 (archivé par GitHub). La section peut être retirée du script si Atom n'est pas installé.
- **pip3 liste tous les paquets** : `pip3 list` inclut les paquets système et ceux des environnements virtuels actifs, pas seulement les paquets installés globalement. Le résultat peut être long et inclure des paquets inattendus.
- **Pas de diff entre deux inventaires** : le script génère un nouveau fichier à chaque lancement sans comparer avec le précédent. Pour voir ce qui a changé, comparer manuellement deux fichiers `Installed_*.md` avec `diff` ou un outil de diff.
