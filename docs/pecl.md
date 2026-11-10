# pecl.sh — README

Nov 7, 2026 · @clicclac

## Description

`pecl.sh` est un plugin pour [altKYMSU](https://github.com/Bruno21/kymsu), un fork de [KYMSU](https://github.com/welcoMattic/kymsu). Il gère la mise à jour des extensions PHP installées via [PECL](https://pecl.php.net), affiche les versions PHP disponibles sur la machine, rafraîchit les canaux PECL, propose la mise à jour de chaque extension de façon interactive, surveille les modifications de `php.ini` et envoie une notification macOS en cas de changement récent.

> **Note :** Ce plugin est en phase bêta. Le format de sortie de `pecl list-upgrades` n'a pas été confirmé sur toutes les configurations. Si la liste des mises à jour s'affiche incorrectement, merci de communiquer la sortie brute.

## Prérequis

- **altKYMSU** installé et configuré (`config.shlib`, `kymsu.cfg`)
- **PHP** avec `pecl` disponibles dans le `PATH` — `brew install php`
- **Homebrew** (`brew`) : utilisé pour détecter les versions PHP installées
- **terminal-notifier** (optionnel, macOS uniquement) : `brew install terminal-notifier` — pour les notifications système en cas de modification de `php.ini`
- Un serveur web local configuré avec `info.php` si `pecl_php_info=true` (optionnel)

## Installation

Copier `pecl.sh` dans le dossier des plugins de kymsu :

```bash
cp pecl.sh ~/.kymsu/plugins.d/
chmod +x ~/.kymsu/plugins.d/pecl.sh
```

Ou laisser `install.sh` le copier automatiquement depuis le dépôt.

Ajouter les clés suivantes dans `kymsu.cfg` :

```ini
pecl_php_info=false
```

Pour recevoir les notifications macOS en cas de modification de `php.ini` :

```bash
brew install terminal-notifier
```

## Configuration (`kymsu.cfg`)

| Clé | Valeur par défaut | Description |
| --- | --- | --- |
| `pecl_php_info` | `false` | `true` : ouvre `https://hostname/info.php` dans le navigateur après une mise à jour d'extension |

Les autres options (`display_info`, `no_distract`) sont contrôlées par les arguments passés à kymsu (`-n` pour no-distract) ou directement dans le script.

## Utilisation

Le script est lancé automatiquement par kymsu :

```bash
kymsu2
```

Ou directement :

```bash
~/.kymsu/plugins.d/pecl.sh
```

En mode no-distract (aucune confirmation demandée, toutes les extensions sont mises à jour) :

```bash
kymsu2 -n
```

Le script effectue dans l'ordre :

1. Vérifie la présence de `php`, `pecl` et `brew`.
2. Affiche la version PHP active et les versions Homebrew installées.
3. Vérifie la connexion Internet.
4. Rafraîchit tous les canaux PECL (`pecl update-channels`).
5. Liste les extensions installées (`pecl list -a`).
6. Détecte les mises à jour disponibles (`pecl list-upgrades`).
7. Pour chaque extension à mettre à jour : affiche les infos, demande confirmation (sauf en mode no-distract), lance `pecl upgrade`.
8. Affiche les chemins des fichiers `php.ini` et des fichiers ini additionnels.
9. Si `php.ini` a été modifié dans les 5 dernières minutes : alerte, notification macOS, et propose d'ouvrir le fichier dans `$EDITOR`.

## Fonctionnement détaillé

### Versions PHP installées

Le script détecte toutes les versions PHP installées via Homebrew en parcourant `$(brew --prefix)/opt/php` et `$(brew --prefix)/opt/php@*`. La version active (celle retournée par `php -r 'echo PHP_MAJOR_VERSION...'`) est marquée `[active]`.

### Canaux PECL

Avant la recherche de mises à jour, `pecl update-channels` rafraîchit tous les canaux enregistrés. Cela équivaut à `apt update` : les métadonnées des paquets disponibles sont mises à jour sans rien installer.

### Upgrade des extensions

Seules les extensions du canal `pecl.php.net` sont traitées. Les extensions d'autres canaux (ex: `pear.php.net`) sont signalées mais pas mises à jour. Pour chaque extension :

- `pecl info $pkg` affiche les informations détaillées avant la mise à jour.
- `pecl upgrade $pkg </dev/null` lance la mise à jour en acceptant les réponses par défaut.
- En mode no-distract (`-n`), la confirmation est sautée et toutes les extensions sont mises à jour automatiquement.

### Surveillance de `php.ini`

Après les mises à jour, le script vérifie si `php.ini` a été modifié dans les 5 dernières minutes via `find -mmin -5`. Si c'est le cas :

- Un message d'alerte s'affiche en rouge.
- Une notification macOS est envoyée via `terminal-notifier` si disponible.
- En mode interactif, le script propose d'ouvrir `php.ini` dans `$EDITOR` (par défaut `vi`).

### Page PHP info

Si `pecl_php_info=true` dans `kymsu.cfg`, ou si au moins une extension a été mise à jour, le script ouvre `https://$(hostname)/info.php` dans le navigateur par défaut. Cela suppose qu'un serveur web local est configuré et qu'un fichier `info.php` contenant `<?php phpinfo(); ?>` est présent à la racine.

### Notification macOS

La notification est envoyée via `terminal-notifier` uniquement si la commande est disponible et si le système est macOS. Elle inclut le titre `pecl`, le message d'alerte et optionnellement une image `error.png` si le fichier est présent dans le dossier courant.

## Limitations connues

- **Plugin en bêta** : le format de sortie de `pecl list-upgrades` n'a pas été confirmé sur toutes les configurations PHP et versions PECL. Si la liste des mises à jour ne s'affiche pas correctement, partager la sortie brute de `pecl list-upgrades` pour ajuster le parsing.
- **macOS uniquement pour les notifications** : `terminal-notifier` n'existe pas sur Linux. Le script détecte `darwin*` avant d'appeler la commande, mais les autres fonctionnalités (PHP info, édition de `php.ini`) fonctionnent sur Linux.
- **`pecl_php_info` nécessite un serveur local** : l'URL `https://$(hostname)/info.php` suppose qu'Apache ou Nginx est actif localement avec un vhost configuré. Sans serveur, la page ne s'ouvrira pas.
- **Canaux non-pecl.php.net non gérés** : les extensions des canaux tiers (ex: `pear.php.net`) sont détectées et signalées mais pas mises à jour. Un message informatif s'affiche pour chacune.
- **`pecl upgrade` pose parfois des questions** : `</dev/null` accepte les réponses par défaut, mais certaines extensions complexes peuvent nécessiter une intervention manuelle (compilation native, dépendances système).
- **Une seule version PHP active** : `pecl` opère sur la version PHP active dans le `PATH`. Si plusieurs versions coexistent via Homebrew, basculer de l'une à l'autre (via `sphp` ou en modifiant le `PATH`) et relancer kymsu pour gérer chaque version.
