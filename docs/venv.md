# venv.sh — README

Nov 5, 2026 · @clicclac

## Description

`venv.sh` est un plugin pour [altKYMSU](https://github.com/Bruno21/kymsu), un fork de [KYMSU](https://github.com/welcoMattic/kymsu). Il met à jour les applications Python installées dans des environnements virtuels (`venv`), ainsi que leurs extensions. Chaque venv est activé, mis à jour, puis désactivé. Un rapport avant/après indique pour chaque paquet s'il a été mis à jour, installé ou était déjà à jour.

## Prérequis

- **altKYMSU** installé et configuré (`config.shlib`, `kymsu.cfg`)
- **Python 3** avec `pip` disponible dans chaque venv
- Un environnement virtuel par application, dont le nom correspond exactement au nom du paquet pip (ex : `mkdocs` → `~/Documents/venv/mkdocs/`)
- bash 4.0 ou supérieur (tableaux associatifs `declare -A`) — bash 5.3 via Homebrew recommandé sur macOS

## Installation

Copier `venv.sh` dans le dossier des plugins de kymsu :

```bash
cp venv.sh ~/.kymsu/plugins.d/
chmod +x ~/.kymsu/plugins.d/venv.sh
```

Ou laisser `install.sh` le copier automatiquement depuis le dépôt.

Créer le venv pour chaque application à gérer (exemple avec mkdocs) :

```bash
# macOS
mkdir -p ~/Documents/venv/mkdocs
python3 -m venv ~/Documents/venv/mkdocs
source ~/Documents/venv/mkdocs/bin/activate
pip install mkdocs
deactivate
```

## Configuration

Toute la configuration se fait directement dans le script, dans la section Settings.

### Applications gérées

```bash
apps=("mkdocs")
```

Ajouter une application en ajoutant son nom dans le tableau. Le venv correspondant doit exister au bon emplacement (voir ci-dessous).

### Emplacement des venv par OS

| OS | Dossier |
| --- | --- |
| macOS | `~/Documents/venv/` |
| Raspberry Pi (`linux-gnueabihf`) | `~/venv/` |
| Linux (`linux-gnu`) | `~/Applications/` |

### Extensions mkdocs

```bash
mkdocs_ext=("mkdocs-material" "mkdocs-material-extensions" ...)
```

Les extensions listées dans `mkdocs_ext` sont mises à jour en même temps que `mkdocs`, dans le même appel `pip install -U`. Pour ajouter ou retirer une extension, modifier ce tableau.

## Utilisation

Le script est lancé automatiquement par kymsu :

```bash
kymsu2
```

Ou directement :

```bash
~/.kymsu/plugins.d/venv.sh
```

Le script est entièrement non interactif. Pour chaque application listée dans `apps`, il :

1. Vérifie que le venv existe (`bin/activate` présent).
2. Active le venv.
3. Met à jour `pip` et `setuptools`.
4. Enregistre les versions installées avant la mise à jour.
5. Lance `pip install -U` sur l'application et ses extensions en un seul appel.
6. Compare les versions avant/après et affiche un rapport.
7. Affiche le résumé `pip show` de l'application principale.
8. Désactive le venv.

## Fonctionnement détaillé

### Rapport avant/après

Avant la mise à jour, les versions de chaque paquet (application + extensions) sont enregistrées dans un tableau associatif `before`. Après `pip install -U`, chaque paquet est comparé et le rapport affiche :

| Situation | Affichage |
| --- | --- |
| Paquet mis à jour | `nom: 1.2.3 → 1.3.0` (en gras) |
| Paquet déjà à jour | `nom: up to date (1.3.0)` (souligné) |
| Paquet nouvellement installé | `nom: installed (1.3.0)` (en gras) |

### Mise à jour groupée

L'application et toutes ses extensions sont passées en un seul appel `pip install -U pkg1 pkg2 ...`. Cela permet à pip de résoudre les dépendances en une seule passe et évite les conflits entre versions.

### Résumé pip show

En fin de traitement, `pip show <app>` est affiché avec la première ligne soulignée (nom et version). C'est un résumé rapide : version, auteur, licence, dépendances.

### Réinitialisation du tableau before

Le tableau associatif `before` est déclaré en haut du script et remis à zéro (`before=()`) à chaque tour de boucle, ce qui évite les collisions si plusieurs applications sont listées dans `apps`.

## Limitations connues

- **Convention de nommage stricte** : le nom du venv doit correspondre exactement au nom du paquet pip. Un venv nommé `mkdocs-project` ne sera pas trouvé si `apps=("mkdocs")`.
- **Extensions mkdocs codées en dur** : `mkdocs_ext` est défini dans le script. Il n'y a pas de clé `kymsu.cfg` pour les gérer à distance. Modifier directement le tableau dans le script.
- **`mkdocs-material-extensions`** est déjà une dépendance de `mkdocs-material` : il est mis à jour deux fois (implicitement par `mkdocs-material`, explicitement dans `mkdocs_ext`). Sans effet négatif, mais redondant.
- **Pas de dry-run** : le script applique directement les mises à jour sans option de simulation.
- **Pas de sélection interactive** : toutes les applications listées dans `apps` sont traitées. Il n'y a pas de mode fzf pour choisir lesquelles mettre à jour.
- **OS non reconnu** : si `$OSTYPE` ne correspond à aucun des cas (`darwin*`, `linux-gnueabihf*`, `linux-gnu*`), le script s'arrête avec une erreur. Ajouter une entrée dans le `case` pour tout nouvel OS.
