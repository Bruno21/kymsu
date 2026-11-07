# wp.sh — README

Nov 7, 2026 · @clicclac

## Description

`wp.sh` est un plugin pour [altKYMSU](https://github.com/Bruno21/kymsu), un fork de [KYMSU](https://github.com/welcoMattic/kymsu). Il gère la mise à jour complète d'une ou plusieurs installations WordPress via [wp-cli](https://wp-cli.org/) : core, plugins, thèmes, traductions, puis une phase de maintenance (base de données, backup chiffré GPG, nettoyage des commentaires, révisions). Toutes les opérations sont interactives ou automatisées selon le mode choisi.

## Prérequis

- **altKYMSU** installé et configuré (`config.shlib`, `kymsu.cfg`)
- **wp-cli** : `brew install wp-cli` ou [wp-cli.org](https://wp-cli.org/#installing)
- **fzf** : `brew install fzf` (requis uniquement pour le mode `y=choose`)
- **PHP** disponible dans le `PATH` (fourni avec macOS ou Homebrew)
- **GPG** : `brew install gnupg` (requis uniquement pour le backup chiffré)
- Une installation WordPress locale accessible en lecture/écriture
- bash 4.0 ou supérieur — bash 5.3 via Homebrew recommandé sur macOS

## Installation

Copier `wp.sh` dans le dossier des plugins de kymsu :

```bash
cp wp.sh ~/.kymsu/plugins.d/
chmod +x ~/.kymsu/plugins.d/wp.sh
```

Ou laisser `install.sh` le copier automatiquement depuis le dépôt.

Ajouter les clés suivantes dans `kymsu.cfg` :

```
wp_sites=$HOME/Sites/wordpress
wp_gpg_recipient=
wp_passphrase_file=
wp_backup_keep=5
```

## Configuration (`kymsu.cfg`)

| Clé | Valeur par défaut | Description |
| --- | --- | --- |
| `wp_sites` | `$HOME/Sites/blog` | Chemins des installations WordPress, séparés par des espaces. Accepte `$HOME` et `~`. |
| `wp_gpg_recipient` | *(vide)* | Adresse email ou ID de la clé GPG pour le chiffrement asymétrique du backup. |
| `wp_passphrase_file` | *(vide)* | Chemin vers un fichier contenant la passphrase pour le chiffrement symétrique AES-256. |
| `wp_backup_keep` | `5` | Nombre de sauvegardes SQL à conserver dans le dossier parent. |

Si ni `wp_gpg_recipient` ni `wp_passphrase_file` ne sont définis, le backup est exporté en clair (`.sql`). Si les deux sont définis, le chiffrement asymétrique est prioritaire.

Les options de maintenance (`maint`, `backup`, `removespam`…) sont configurables directement dans le script, section Settings.

## Utilisation

Le script est lancé automatiquement par kymsu :

```bash
kymsu2
```

Ou directement :

```bash
~/.kymsu/plugins.d/wp.sh
```

En mode no-distract (aucune interaction, tout est mis à jour automatiquement) :

```bash
kymsu2 -n
```

Pour chaque installation listée dans `wp_sites`, le script effectue dans l'ordre :

1. Affichage des infos wp-cli et de la version WordPress.
2. Vérification et mise à jour du core.
3. Mise à jour des plugins avec sélection interactive ou automatique.
4. Mise à jour des thèmes avec sélection interactive ou automatique.
5. Mise à jour des traductions (core, plugins, thèmes).
6. Phase de maintenance (si `maint=true`).
7. Rapport final.

## Fonctionnement détaillé

### Mises à jour (plugins et thèmes)

Pour chaque type (plugins, thèmes), le script affiche d'abord la liste complète des éléments installés, puis la liste de ceux qui ont une mise à jour disponible avec les versions installée et disponible alignées en colonnes.

Trois modes de réponse :

| Choix | Comportement |
| --- | --- |
| `a` (all) | Met à jour tous les éléments listés |
| `y` (choose) | Ouvre fzf pour sélectionner élément par élément |
| `n` | Passe à l'étape suivante sans rien faire |

En mode `no_distract` (`-n`), la question est sautée et tout est mis à jour automatiquement.

### Maintenance

Les opérations de maintenance sont contrôlées par des variables booléennes en haut du script :

| Variable | Défaut | Opération |
| --- | --- | --- |
| `transient` | `true` | Supprime les transients expirés |
| `database` | `true` | Optimise la base de données |
| `backup` | `true` | Exporte et chiffre la base (voir section GPG) |
| `removespam` | `true` | Liste les commentaires spam (dry-run) |
| `emptytrash` | `true` | Liste les commentaires en corbeille (dry-run) |
| `rev` | `true` | Nettoie les révisions (dry-run, nécessite `trepmal/wp-revisions-cli`) |
| `back` | `true` | Liste trackbacks et pingbacks (dry-run) |
| `admin` | `false` | Ouvre wp-admin dans le navigateur |

### Rapport final

En fin de script, un résumé affiche pour chaque composant son statut : **up to date**, **updated** (en vert), **failed** (en rouge) ou **skipped**. Les éléments qui ont échoué sont aussi listés globalement.

## Sécurité GPG

Le backup de la base de données contient l'intégralité du contenu WordPress, y compris les hash de mots de passe, les tokens de session et les données personnelles des utilisateurs. Un export non chiffré (`.sql`) en clair dans un dossier partagé, synchronisé (Dropbox, iCloud, git) ou sur un serveur mal sécurisé est un risque sérieux.

### Chiffrement asymétrique (recommandé)

Le backup est chiffré avec ta clé publique GPG. Seul le détenteur de la clé privée peut le déchiffrer. C'est le mode le plus sûr : même si le fichier `.gpg` est compromis, il est inutilisable sans la clé privée.

**Prérequis :** avoir une paire de clés GPG et la clé publique dans ton trousseau.

```bash
# Générer une paire de clés (si tu n'en as pas)
gpg --gen-key

# Vérifier que ta clé est dans le trousseau
gpg --list-keys ton@email.com
```

Dans `kymsu.cfg` :

```
wp_gpg_recipient=ton@email.com
```

Pour déchiffrer un backup :

```bash
gpg --decrypt wp-monsite-2026-11-07_10-00-00.sql.gpg > backup.sql
```

### Chiffrement symétrique (AES-256)

Le backup est chiffré avec une passphrase stockée dans un fichier. Plus simple à mettre en place, mais la sécurité dépend entièrement de la protection de ce fichier.

```bash
# Créer le fichier de passphrase (droits stricts obligatoires)
echo 'ma_passphrase_longue_et_aléatoire' > ~/.wp_gpg_passphrase
chmod 600 ~/.wp_gpg_passphrase
```

Dans `kymsu.cfg` :

```
wp_passphrase_file=$HOME/.wp_gpg_passphrase
```

Pour déchiffrer :

```bash
gpg --decrypt --passphrase-file ~/.wp_gpg_passphrase wp-monsite-2026-11-07_10-00-00.sql.gpg > backup.sql
```

### Bonnes pratiques

- Ne jamais versionner les fichiers `.sql` ou `.sql.gpg` dans git.
- Stocker les backups dans un dossier hors du répertoire WordPress (`../` dans le script).
- Tester la restauration périodiquement : `wp db import backup.sql`.
- Si tu utilises le chiffrement symétrique, ne jamais stocker la passphrase dans un fichier versionné ou synchronisé sans chiffrement.

## Limitations connues

- **Opérations de maintenance en dry-run** : spam, corbeille, révisions, trackbacks et pingbacks sont listés mais pas supprimés. Retirer `--dry-run` des commandes correspondantes dans le script pour activer la suppression réelle.
- **Multi-site local uniquement** : plusieurs installations WordPress sur la même machine sont supportées via `wp_sites`. Le support SSH (`wp --ssh=user@host/path`) est prévu mais pas encore implémenté.
- **`WP_CLI_PHP_ARGS` ignoré via SSH** : si le support SSH est ajouté, les erreurs PHP `Deprecated:` peuvent réapparaître côté serveur.
- **Backup dans le dossier parent** : le fichier SQL est exporté dans `../` par rapport au dossier WordPress. Si ce dossier n'existe pas ou n'est pas accessible en écriture, le backup échoue silencieusement après l'export.
- **Pas de rollback** : en cas d'échec d'une mise à jour de plugin ou de thème, wp-cli ne restaure pas automatiquement la version précédente. Un backup récent est la seule protection.
- **`revisions` nécessite `trepmal/wp-revisions-cli`** : si ce paquet n'est pas installé, le script propose de l'installer en mode interactif, ou skip en mode `no_distract`.
