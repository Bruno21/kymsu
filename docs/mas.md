# mas.sh — README

Nov 5, 2026 · @clicclac

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

## Configuration (`kymsu.cfg`)

| Clé | Valeur par défaut | Description |
| --- | --- | --- |
| `mas_dry_run` | `false` | `true` : affiche les mises à jour sans rien installer |
| `mas_store_country` | détecté via `AppleLocale` | Code pays pour l'URL App Store (`fr`, `us`, `de`…) |
| `pinned_mas` | *(vide)* | IDs des apps à ne jamais mettre à jour, séparés par des espaces |

Exemple :

```
mas_dry_run=false
mas_store_country=fr
pinned_mas=497799835 408981434
```

Si `mas_store_country` est absent, le pays est déduit de `AppleLocale` (préférences système macOS). Par défaut `us` si la détection échoue.

## Utilisation

Le script est lancé automatiquement par kymsu :

```bash
kymsu2
```

Ou directement :

```bash
~/.kymsu/plugins.d/mas.sh
```

Au lancement, le script :

1. Vérifie la connexion Internet.
2. Vérifie que `mas` est installé.
3. Lance `mas outdated` et affiche la liste des apps obsolètes avec leurs versions.
4. Propose trois modes :

| Choix | Comportement |
| --- | --- |
| `a` (all) | Met à jour toutes les apps listées |
| `y` (choose) | Ouvre fzf pour sélectionner les apps à mettre à jour |
| `n` | Quitte sans rien faire |

## Fonctionnement détaillé

### Affichage de la liste

La liste des apps obsolètes est affichée avec des colonnes alignées dynamiquement (largeur calculée sur les données réelles) :

```
ID            App                             Installed  Available
6749351423    Menu Bar Controller for Sonos   7.3.0      7.3.1
1006087419    SnippetsLab                     2.7        2.7.1
```

### Mode fzf (`y`)

- `Tab` / `Shift-Tab` : sélectionner / désélectionner une app
- `Ctrl-A` : tout sélectionner
- `Entrée` : valider la sélection
- `Échap` : annuler et quitter

Le panneau de prévisualisation (droite, 40 %) affiche pour chaque app surlignée : son ID, son nom complet, les versions installée et disponible, et le lien vers sa page App Store dans la langue configurée.

### Apps épinglées (`pinned_mas`)

Les apps dont l'ID figure dans `pinned_mas` sont exclues de la liste des mises à jour et affichées séparément avec la mention `Pinned (skipped)`. Elles restent visibles pour information.

### Rapport d'échec

Si `mas upgrade` échoue pour une app, son nom et son ID sont affichés en rouge en fin de script.

## Limitations connues

- **macOS uniquement** : `mas` ne fonctionne pas sous Linux.
- **Connexion App Store requise** : si aucun compte n'est connecté dans Réglages Système, `mas outdated` renvoie une liste vide sans message d'erreur explicite.
- **Apps avec nom multi-mots** : le parsing du format de `mas outdated` repose sur un `sed` qui isole l'ID, le nom et les versions. Un nom contenant des parenthèses pourrait perturber l'extraction.
- **`mas upgrade` interactif** : certaines apps demandent une confirmation dans l'App Store (Touch ID, conditions d'utilisation). Le script ne peut pas les automatiser.
- **Xcode** : sa mise à jour pèse plusieurs Go et coupe les outils de développement pendant l'installation. Il est conseillé de l'épingler dans `pinned_mas` et de le mettre à jour manuellement.
