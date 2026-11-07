# rustup.sh — README

Nov 5, 2026 · @clicclac

## Description

`rustup.sh` est un plugin pour [altKYMSU](https://github.com/Bruno21/kymsu), un fork de [KYMSU](https://github.com/welcoMattic/kymsu). Il met à jour la toolchain Rust via [rustup](https://rust-lang.github.io/rustup/) et les paquets installés depuis [crates.io](https://crates.io) via `cargo install`. Les deux outils sont gérés indépendamment : le script fonctionne si l'un ou l'autre est absent.

## Prérequis

- **altKYMSU** installé et configuré (`config.shlib`, `kymsu.cfg`)
- **rustup** : `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh` (inclut `cargo`)
- Au moins l'un des deux doit être dans le `PATH` : `rustup` ou `cargo`
- Le script fonctionne sans `rustup` (gère uniquement `cargo`) ou sans `cargo` (gère uniquement la toolchain)

## Installation

Copier `rustup.sh` dans le dossier des plugins de kymsu :

```bash
cp rustup.sh ~/.kymsu/plugins.d/
chmod +x ~/.kymsu/plugins.d/rustup.sh
```

Ou laisser `install.sh` le copier automatiquement depuis le dépôt.

Ajouter les clés suivantes dans `kymsu.cfg` :

```
rust_dry_run=false
rust_locked=true
```

## Configuration (`kymsu.cfg`)

`rustup.sh` ajoute deux clés dans `kymsu.cfg` en plus des variables de couleur communes :

| Clé | Valeur par défaut | Description |
| --- | --- | --- |
| `rust_dry_run` | `false` | `true` : affiche les mises à jour sans rien installer |
| `rust_locked` | `true` | `true` : réessaie avec `--locked` si `cargo install` échoue |

## Utilisation

Le script est lancé automatiquement par kymsu :

```bash
kymsu2
```

Ou directement :

```bash
~/.kymsu/plugins.d/rustup.sh
```

Le script est interactif pour la partie cargo (choix des paquets à mettre à jour). Il effectue dans l'ordre :

1. Vérifie que `rustup` ou `cargo` est disponible dans le `PATH`.
2. Vérifie la connexion Internet.
3. (**rustup**) Affiche la toolchain active, lance `rustup check` et met à jour si nécessaire.
4. (**cargo**) Vérifie les versions disponibles sur crates.io, propose une sélection interactive (fzf ou tout installer), met à jour avec retry `--locked` si activé, puis affiche la liste finale.

## Fonctionnement détaillé

### Partie rustup

`rustup check` est lancé en premier pour savoir si une mise à jour est disponible. Sa sortie est nettoyée des codes ANSI et des retours chariot (`\r`) avant analyse, ce qui garantit un comportement identique quelle que soit la version de rustup ou le terminal.

Chaque ligne est colorisée selon son contenu :

- **Rouge** : `update available` — une mise à jour existe
- **Vert gras** : `up to date` — la toolchain est à jour
- **Neutre** : toute autre ligne (ex : nom de toolchain sans statut)

Si au moins une ligne signale une mise à jour, `rustup update` est lancé pour toutes les toolchains installées.

### Partie cargo

Seuls les paquets installés depuis **crates.io** sont pris en compte. Les paquets installés depuis git ou un chemin local (signalés par des parenthèses dans la sortie de `cargo install --list`) sont ignorés.

Avant la mise à jour, `cargo search` est appelé pour chaque paquet afin de récupérer la version disponible sur crates.io. Seuls les paquets dont la version installée diffère de la version disponible sont proposés. Chaque paquet sélectionné est installé individuellement avec `cargo install <nom>`. Cette approche permet :

- De continuer en cas d'échec sur un paquet (les autres sont toujours traités).
- De réessayer automatiquement avec `cargo install --locked <nom>` si `rust_locked=true` dans `kymsu.cfg`. Cette option utilise les versions de dépendances testées par l'auteur et peut débloquer certains échecs de compilation.

La liste finale des paquets installés (avec leurs versions) est affichée en fin de section. Elle n'est recalculée que si au moins un paquet a changé.

### Mode dry-run

Si `rust_dry_run=true` dans `kymsu.cfg`, le script affiche les paquets qui seraient mis à jour sans rien installer. La recherche des versions disponibles sur crates.io est quand même effectuée.

La liste des paquets cargo est lue sur le descripteur de fichier 3 (`3<<< "$installed"`), ce qui laisse stdin disponible pour d'éventuelles interactions du terminal dans d'autres parties du script.

## Limitations connues

- **Vérification des versions lente** : `cargo search` fait un appel réseau par paquet. Avec 10 paquets installés, la phase de vérification peut prendre 10 à 20 secondes avant que la sélection s'affiche.
- **`cargo search` peut rater un paquet** : si le nom n'est pas trouvé exactement sur crates.io (paquet retiré, renommé ou privé), la version disponible affichée sera `?` et le paquet sera ignoré dans la sélection.
- **Pas de liste d'exclusion** : tous les paquets obsolètes sont proposés. L'ajout d'un `do_not_update` (sur le modèle de `gem.sh`) pourrait être envisagé si le besoin se présente.
- **Echec de compilation persistant** : si `cargo install --locked` échoue aussi, le paquet apparaît dans la liste `Still failed` en fin de script. Il peut nécessiter une intervention manuelle (mise à jour de la toolchain, installation d'une dépendance système comme OpenSSL ou cmake).
- **`rustup update` met à jour toutes les toolchains** : si plusieurs toolchains sont installées (`stable`, `beta`, `nightly`), elles sont toutes mises à jour en une seule passe.
