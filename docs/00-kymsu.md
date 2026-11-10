# 00-kymsu.sh — README

Nov 7, 2026 · @clicclac

## Description

`00-kymsu.sh` est le plugin système d'[altKYMSU](https://github.com/Bruno21/kymsu). Il est exécuté en premier à chaque lancement de kymsu (le préfixe `00-` garantit l'ordre). Son rôle est unique : afficher la date de la dernière mise à jour et de la prochaine, et déclencher automatiquement un `git pull` du dépôt kymsu lorsque l'intervalle configuré est dépassé. Il ne met à jour aucun paquet et ne pose aucune question.

## Prérequis

- **altKYMSU** installé et configuré (`config.shlib`, `kymsu.cfg`)
- **git** : pour le `git pull` du dépôt kymsu
- Le chemin du dépôt kymsu stocké dans `~/.kymsu/path` (écrit par `install.sh`)
- **GNU date** (recommandé sur macOS) : `brew install coreutils` — le script détecte automatiquement GNU date ou BSD date

## Installation

Ce plugin fait partie du dépôt altKYMSU et est copié automatiquement par `install.sh`. Il n'a pas besoin d'être installé manuellement.

Son nom `00-kymsu.sh` garantit qu'il est exécuté en premier par kymsu, avant tous les autres plugins (tri alphabétique).

Ajouter les clés suivantes dans `kymsu.cfg` :

```ini
update_interval=1w
last.update=
```

`last.update` est géré automatiquement par le script et ne doit pas être modifié à la main sauf pour forcer une mise à jour immédiate (le vider ou le supprimer).

## Configuration (`kymsu.cfg`)

| Clé | Valeur par défaut | Description |
| --- | --- | --- |
| `update_interval` | `1w` | Intervalle entre deux auto-updates du dépôt kymsu |
| `last.update` | *(géré automatiquement)* | Timestamp Unix de la dernière mise à jour |

### Format de `update_interval`

Un nombre suivi d'une lettre :

| Suffixe | Signification | Exemple |
| --- | --- | --- |
| `m` | minutes | `30m` |
| `h` | heures | `12h` |
| `d` | jours | `3d` |
| `w` | semaines | `1w` |
| `M` | mois (30 jours) | `2M` |
| `Y` | année (365 jours) | `1Y` |

## Utilisation

Le script est lancé automatiquement en premier à chaque exécution de kymsu :

```bash
kymsu2
```

Il affiche toujours :

```log
Last update: 31-10-2026 10:00:00
Next update: 07-11-2026 10:00:00 (in 6j 19h 50m 21s)
```

Si l'intervalle est dépassé, `git pull` est lancé dans le dossier du dépôt kymsu et `last.update` est mis à jour dans `kymsu.cfg`. Si la prochaine mise à jour est en retard, `Next update: overdue` s'affiche en rouge.

## Fonctionnement détaillé

### Intervalle et calcul du temps

Au démarrage, le script lit `update_interval` depuis `kymsu.cfg` (défaut `1w`). Il convertit cet intervalle en secondes (`w`), récupère le timestamp actuel et celui de `last.update`, puis calcule :

- `temps` : secondes écoulées depuis la dernière mise à jour
- `next_update` : timestamp de la prochaine mise à jour prévue
- `duree` : secondes restantes avant la prochaine mise à jour

Si `last.update` est absent de `kymsu.cfg`, il est initialisé à la date courante et le fichier est mis à jour immédiatement via `awk`.

### Self-update (`git pull`)

Si `temps > w` (l'intervalle est dépassé), le script :

1. Lit le chemin du dépôt dans `~/.kymsu/path` (écrit par `install.sh`).
2. Lance `git pull` dans ce dossier via `pushd`/`popd`.
3. Met à jour `last.update` dans `kymsu.cfg` avec le timestamp courant.

Le `git pull` est sans options : il utilise la configuration git du dépôt (branche de suivi, remote). Si le dépôt n'a pas de branche de suivi configurée, il échoue silencieusement.

### Compatibilité `date` GNU / BSD

Au démarrage, le script détecte si `date --version` répond avec `GNU` :

- **GNU date** (Linux, macOS avec `coreutils` Homebrew) : `date -d "@$timestamp"`
- **BSD date** (macOS natif) : `date -jf "%s" "$timestamp"`

La variable `date_gnu` est utilisée dans `format_timestamp()` pour choisir la bonne syntaxe. Les deux produisent le même format `dd-mm-yyyy HH:MM:SS`.

### Mise à jour de `kymsu.cfg`

Le fichier `kymsu.cfg` est modifié par `awk` via un fichier temporaire (`kymsu.cfg.tmp`), pour éviter de tronquer le fichier en cas d'échec. Seule la clé `last.update` est modifiée ; les autres valeurs restent intactes.

## Limitations connues

- **`git pull` sans option** : si le dépôt local n'a pas de branche de suivi configurée (`git branch --set-upstream-to`), `git pull` échoue. Vérifier avec `git remote -v` et `git branch -vv` dans le dossier du dépôt.
- **Pas de gestion des conflits git** : si des fichiers locaux ont été modifiés (par exemple `kymsu.cfg` versionné), `git pull` peut échouer sur un conflit de merge. Dans ce cas, résoudre manuellement dans le dossier du dépôt.
- **`last.update` absent de `kymsu.cfg`** : si la clé manque complètement (première installation, `kymsu.cfg` recréé), elle est initialisée à la date courante. Cela décale la prochaine mise à jour d'un intervalle complet.
- **Forcer une mise à jour immédiate** : vider la valeur de `last.update` dans `kymsu.cfg` (`last.update=`) ou la supprimer. Au prochain lancement, `temps > w` sera vrai et `git pull` sera lancé.
- **Pi-hole ou DNS lent** : si le DNS est lent (résolveur injoignable en déplacement), le `git pull` peut prendre plusieurs secondes avant d'échouer. Ce n'est pas un bug du script.
