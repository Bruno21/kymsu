# kymsu2.sh — README

Nov 7, 2026 · @clicclac

## Description

`kymsu2.sh` est le script principal d'[altKYMSU](https://github.com/Bruno21/kymsu), un fork de [KYMSU](https://github.com/welcoMattic/kymsu). Il orchestre l'exécution de tous les plugins de mise à jour : il les découvre dans `~/.kymsu/plugins.d/`, les lance dans l'ordre alphabétique, et leur passe les options de ligne de commande. Il gère aussi l'activation/désactivation des plugins, l'ouverture de la configuration, et la désinstallation.

altKYMSU (**alt** Keep Your macOS Stuff Updated) met à jour en un seul lancement : Homebrew, Mac App Store, Ruby gems, Perl, Python (venv), PHP (PECL), Rust, Node.js, WordPress et l'inventaire des logiciels installés.

## Prérequis

- macOS (ou Linux pour un usage partiel)
- bash 4.0 ou supérieur — bash 5.3 via Homebrew recommandé sur macOS (`brew install bash`)
- `config.shlib` et `kymsu.cfg` présents dans `~/.kymsu/plugins.d/`
- Les plugins que tu veux activer et leurs propres prérequis (voir la section Plugins)

## Installation

Cloner le dépôt et lancer `install.sh` :

```bash
git clone https://github.com/Bruno21/kymsu.git
cd kymsu
./install.sh
```

`install.sh` :

1. Crée un lien symbolique `kymsu2` dans `/usr/local/bin`.
2. Copie les plugins dans `~/.kymsu/plugins.d/`.
3. Mémorise le chemin du dépôt dans `~/.kymsu/path`.
4. Propose d'activer ou désactiver les plugins au premier lancement.

Pour réinstaller ou mettre à jour manuellement :

```bash
cd ~/Documents/Scripts/kymsu2   # ou le dossier de ton dépôt
./install.sh
```

## Utilisation

```bash
kymsu2 [options]
```

| Option | Description |
| --- | --- |
| *(aucune)* | Lance tous les plugins actifs dans l'ordre |
| `-h`, `--help` | Affiche l'aide |
| `-n`, `--nodistract` | Mode no-distract : aucune confirmation demandée, tout est mis à jour automatiquement |
| `-c`, `--cleanup` | Passe l'option cleanup aux plugins qui la supportent (ex: `brew cleanup`) |
| `-m`, `--modules` | Ouvre le menu d'activation/désactivation des plugins |
| `-p`, `--pref` | Ouvre `kymsu.cfg` dans `$EDITOR` |
| `-s <script>` | Lance uniquement le plugin nommé (avec ou sans le préfixe `_`) |
| `-u`, `--uninstall` | Lance `uninstall.sh` pour désinstaller altKYMSU |
| `-a`, `--all` | Lance tous les plugins, y compris les désactivés (préfixés par `_`) |

### Exemples

```bash
kymsu2                        # mise à jour complète
kymsu2 -n                     # tout mettre à jour sans confirmation
kymsu2 -n -c                  # + cleanup Homebrew
kymsu2 -s homebrew.sh         # uniquement Homebrew
kymsu2 -s _wp.sh              # uniquement WordPress (même s'il est désactivé)
kymsu2 -m                     # activer/désactiver des plugins
kymsu2 -p                     # éditer kymsu.cfg
```

### Désactiver un plugin

Préfixer le fichier du plugin par `_` dans `~/.kymsu/plugins.d/` :

```bash
mv ~/.kymsu/plugins.d/wp.sh ~/.kymsu/plugins.d/_wp.sh
```

Ou utiliser `kymsu2 -m` pour le faire interactivement.

## Automatisation via launchd

Deux fichiers plist sont fournis pour lancer kymsu automatiquement via launchd (macOS).

### `kymsu.plist` — mise à jour hebdomadaire

Lance `kymsu2 --nodistract` tous les mardis à 6h30.

```bash
# Installer
cp kymsu.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/kymsu.plist

# Désinstaller
launchctl unload ~/Library/LaunchAgents/kymsu.plist
rm ~/Library/LaunchAgents/kymsu.plist
```

### `kymsu_installed.plist` — inventaire hebdomadaire

Lance `installed.sh` tous les lundis à 6h45 pour générer l'inventaire des logiciels.

```bash
# Installer
cp kymsu_installed.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/kymsu_installed.plist
```

### Points à adapter dans les plist

- **`WorkingDirectory`** : remplacer `/Users/bruno/...` par ton propre chemin.
- **`PATH`** : le PATH par défaut de launchd est minimal (`/usr/local/bin:/usr/bin:/bin:...`). Si des commandes comme `brew`, `nvm` ou `gem` ne sont pas dans ce PATH, ajoute leurs dossiers.
- **`StartCalendarInterval`** : `Weekday` de 0 (dimanche) à 7 (dimanche aussi), `Hour` et `Minute` en entiers.
- Si la machine est éteinte à l'heure prévue, launchd ne rattrape pas le lancement manqué (contrairement à cron avec `@reboot`). Pour un lancement au démarrage, ajouter `RunAtLoad` à `true`.

## Plugins

Chaque plugin est un script `.sh` indépendant dans `plugins.d/`. Le préfixe `00-` de `00-kymsu.sh` garantit qu'il est exécuté en premier. Les plugins préfixés par `_` sont désactivés.

| Plugin | Description | README |
| --- | --- | --- |
| `00-kymsu.sh` | Auto-update du dépôt kymsu | [docs/00-kymsu.md](docs/00-kymsu.md) |
| `homebrew.sh` | Homebrew (formulas, casks) | [docs/homebrew.md](docs/homebrew.md) |
| `mas.sh` | Mac App Store | [docs/mas.md](docs/mas.md) |
| `gem.sh` | Ruby gems | [docs/gem.md](docs/gem.md) |
| `perl.sh` | Modules Perl (cpan) | [docs/perl.md](docs/perl.md) |
| `venv.sh` | Python (environnements virtuels) | [docs/venv.md](docs/venv.md) |
| `pecl.sh` | Extensions PHP (PECL) | [docs/pecl.md](docs/pecl.md) |
| `rustup.sh` | Rust (toolchain + cargo) | [docs/rustup.md](docs/rustup.md) |
| `nodejs.sh` | Node.js / npm | [docs/nodejs.md](docs/nodejs.md) |
| `wp.sh` | WordPress (wp-cli) | [docs/wp.md](docs/wp.md) |
| `installed.sh` | Inventaire des logiciels installés | [docs/installed.md](docs/installed.md) |

## Limitations connues

- **bash 3.2 macOS** : le shebang `#!/usr/bin/env bash` utilise le premier `bash` du `PATH`. Si `/opt/homebrew/bin` n'est pas avant `/bin`, c'est le bash 3.2 du système qui est utilisé. Les tableaux associatifs et certaines syntaxes bash 4+ échouent silencieusement. Vérifier avec `bash --version` et configurer le `PATH` correctement.
- **launchd et PATH** : le PATH de launchd est minimal. Les commandes installées par Homebrew (`brew`, `nvm`, `gem`…) peuvent ne pas être trouvées. Ajouter leurs chemins dans la clé `EnvironmentVariables.PATH` du plist, ou utiliser des chemins absolus.
- **`find` + noms avec espaces** : la liste des plugins est construite avec `find` et lue ligne par ligne. Un plugin dont le nom contient un espace serait mal géré. Convention : noms de fichiers sans espaces.
- **Options transmises aux plugins** : les options `-n` et `-c` sont passées à tous les plugins via `"$@"`. Chaque plugin parse ses propres options via `getopts`. Un plugin qui ne connaît pas une option l'ignore silencieusement.
- **`fd 3` pour stdin** : les plugins sont lus sur le descripteur de fichier 3 pour préserver stdin. Si un plugin ouvre lui-même fd 3, il y aurait un conflit. Aucun des plugins actuels ne le fait.
