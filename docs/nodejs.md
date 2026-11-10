# nodejs.sh — README

Nov 7, 2026 · @clicclac

## Description

`nodejs.sh` est un plugin pour [altKYMSU](https://github.com/Bruno21/kymsu), un fork de [KYMSU](https://github.com/welcoMattic/kymsu). Il gère la mise à jour de [nvm](https://github.com/nvm-sh/nvm) (Node Version Manager), des paquets npm locaux et globaux, et optionnellement de Node.js lui-même. Il inclut un mode diagnostic (`npm doctor`) avec colorisation des erreurs, et gère les paquets épinglés (pinned) et les paquets installés depuis git ou un chemin local.

## Prérequis

- **altKYMSU** installé et configuré (`config.shlib`, `kymsu.cfg`)
- **Node.js** et **npm** disponibles dans le `PATH`
- **nvm** (optionnel mais recommandé) : installé depuis [github.com/nvm-sh/nvm](https://github.com/nvm-sh/nvm) ou via Homebrew (`brew install nvm`). Sans nvm, les sections de gestion des versions Node sont sautées.
- **jq** : `brew install jq` — mentionné dans le script comme dépendance optionnelle pour certains traitements JSON
- Un dossier local avec `package.json` et `node_modules/` si tu veux gérer des paquets locaux (`npm_local_path`)

## Installation

Copier `nodejs.sh` dans le dossier des plugins de kymsu :

```bash
cp nodejs.sh ~/.kymsu/plugins.d/
chmod +x ~/.kymsu/plugins.d/nodejs.sh
```

Ou laisser `install.sh` le copier automatiquement depuis le dépôt.

Ajouter les clés suivantes dans `kymsu.cfg` :

```ini
npm_display_info=false
npm_doctor=false
npm_update_node=false
npm_local_path=$HOME/Sites
pinned_npm=
```

## Configuration (`kymsu.cfg`)

| Clé | Valeur par défaut | Description |
| --- | --- | --- |
| `npm_display_info` | `false` | `true` : affiche description et homepage de chaque paquet installé (appels `npm view` parallèles) |
| `npm_doctor` | `false` | `true` : lance `npm doctor` et `npm cache verify` en fin de script |
| `npm_update_node` | `false` | `true` : propose de mettre à jour Node.js via nvm si une version plus récente est détectée |
| `npm_local_path` | `$HOME/Sites` | Chemin du projet local avec `package.json`. Accepte `$HOME` et `~`. |
| `pinned_npm` | *(vide)* | Noms exacts des paquets à ne jamais mettre à jour, séparés par des espaces |

Exemple :

```ini
npm_display_info=false
npm_doctor=false
npm_update_node=false
npm_local_path=$HOME/Sites/monprojet
pinned_npm=thumbsup angular-cli
```

## Utilisation

Le script est lancé automatiquement par kymsu :

```bash
kymsu2
```

Ou directement :

```bash
~/.kymsu/plugins.d/nodejs.sh
```

En mode no-distract (aucune confirmation, toutes les mises à jour sont appliquées automatiquement) :

```bash
kymsu2 -n
```

Le script effectue dans l'ordre :

1. Affiche les versions Node.js et npm actives.
2. Vérifie la connexion Internet.
3. Détecte et affiche nvm (GitHub ou Homebrew), propose une mise à jour si disponible.
4. Affiche la liste des paquets épinglés (`pinned_npm`).
5. Gère les **paquets locaux** (`npm_local_path`) : liste, détection des outdated, mise à jour.
6. Gère les **paquets globaux** : liste, détection des outdated, mise à jour.
7. Si `npm_doctor=true` : diagnostic, proposition de mise à jour de Node.js, `npm cache verify`.

## Fonctionnement détaillé

### nvm (Node Version Manager)

Le script détecte nvm dans deux emplacements : `~/.nvm/nvm.sh` (installation GitHub) ou `$(brew --prefix nvm)/nvm.sh` (Homebrew). La version courante est comparée à la dernière version disponible sur GitHub (via `git ls-remote`), avec un timeout de 10 secondes pour éviter de bloquer le script sur une connexion lente.

- **Installation GitHub** : si nvm est en retard, le script propose de le mettre à jour via `git fetch` + `git checkout` dans `$NVM_DIR`.
- **Installation Homebrew** : si nvm est en retard, le script suggère de lancer `brew upgrade nvm` ou `kymsu homebrew.sh`.

### Paquets locaux

Le dossier `npm_local_path` est analysé si `node_modules/` est présent et non vide. Le script lance `npm outdated --long` pour détecter les paquets obsolètes. Deux stratégies de mise à jour :

- **Minor/patch** (`current == wanted`) : `npm update <pkg>`
- **Major** (`current < latest`, majeur différent) : `npm install <pkg>@latest`

Le tout s'exécute dans un sous-shell pour que le `cd` reste local.

### Paquets globaux

Même logique que les paquets locaux, avec `--location=global`. La liste des paquets obsolètes distingue le nombre de paquets mettables à jour et le nombre épinglés.

### Paquets épinglés (pinned)

Les paquets listés dans `pinned_npm` sont détectés mais ne sont jamais mis à jour. Un message en rouge les signale. Les paquets installés depuis git ou un chemin local (version `git`, `linked` ou `N/A`) sont automatiquement sautés avec un message informatif.

### Mode `npm_display_info`

Si `npm_display_info=true`, le script récupère la description et la homepage de chaque paquet via `npm view` en parallèle (`npm_view_jobs=8` requêtes simultanées). Le résultat est affiché en dessous de chaque paquet dans la liste.

### Mode `npm_doctor`

Si `npm_doctor=true`, le script lance `npm doctor` et colorise sa sortie : vert pour `ok`, rouge pour `not ok`, cyan pour les suggestions `Use ...`. Si une version de Node.js plus récente est détectée et `npm_update_node=true` :

1. Les paquets globaux sont listés avant le changement de version.
2. `nvm install <nouvelle_version>` installe la nouvelle version.
3. Les paquets globaux sont réinstallés un par un, en sautant ceux dans `pinned_npm`.

En mode no-distract, la mise à jour de Node est signalée mais pas appliquée.

### Angular CLI

Si `@angular/cli` figure parmi les paquets globaux à mettre à jour, `NG_CLI_ANALYTICS=false` est exporté pour éviter le prompt interactif « Do you want to share anonymous usage data ».

## Limitations connues

- **Un seul dossier local** : `npm_local_path` pointe vers un seul projet. Pour gérer plusieurs projets locaux, relancer le script avec une valeur différente ou étendre le script avec un tableau (sur le modèle de `wp_sites` dans `wp.sh`).
- **`nvm reinstall-packages` désactivé** : remplacé par une boucle manuelle car `nvm reinstall-packages` peut se bloquer sur certains paquets installés depuis GitHub (ex: `thumbsup`). Ces paquets doivent être réinstallés manuellement après une mise à jour de Node.
- **`xargs -p` en mode interactif** : les mises à jour de paquets utilisent `xargs -p` (confirmation paquet par paquet) en mode interactif. Sur certains systèmes, le comportement de `-p` peut varier. En mode no-distract, `-p` est retiré.
- **Mise à jour Node uniquement via nvm** : `npm_update_node=true` ne fonctionne que si nvm est installé. Avec Node installé directement via Homebrew, la mise à jour n'est pas gérée par ce script.
- **`latest_nvm_version` peut échouer** : la détection de la dernière version nvm fait un `git ls-remote` avec un timeout de 10 secondes. Sur une connexion lente ou sans accès à GitHub, la version disponible n'est pas affichée mais le script continue.
- **`npm_view_jobs` et charge réseau** : avec `npm_display_info=true`, le script lance jusqu'à 8 requêtes `npm view` en parallèle. Sur une connexion lente ou avec de nombreux paquets, cela peut ralentir l'affichage.
