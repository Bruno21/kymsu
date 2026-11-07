# gem.sh — README

Nov 7, 2026 · @clicclac

## Description

`gem.sh` est un plugin pour [altKYMSU](https://github.com/Bruno21/kymsu), un fork de [KYMSU](https://github.com/welcoMattic/kymsu). Il détecte les gems Ruby obsolètes via `gem outdated` et propose de les mettre à jour de façon interactive, avec sélection dans fzf, gestion des gems épinglés (pinned) et rapport avant/après.

## Prérequis

- **altKYMSU** installé et configuré (`config.shlib`, `kymsu.cfg`)
- **Ruby** avec `gem` disponible dans le `PATH`
- **fzf** : `brew install fzf` (requis uniquement pour le mode `y=choose`)
- Sur macOS, le Ruby système (`/usr/bin/gem`) nécessite `sudo` ou `--user-install` pour `gem update`. L'utilisation de Ruby via Homebrew, rbenv ou asdf est recommandée pour éviter ce problème.

## Installation

Copier `gem.sh` dans le dossier des plugins de kymsu :

```bash
cp gem.sh ~/.kymsu/plugins.d/
chmod +x ~/.kymsu/plugins.d/gem.sh
```

Ou laisser `install.sh` le copier automatiquement depuis le dépôt.

Ajouter les clés suivantes dans `kymsu.cfg` :

```
gem_dry_run=false
gem_no_document=true
gem_pinned=
```

Pour désactiver définitivement la génération de documentation pour tous les `gem install` et `gem update`, ajouter dans `~/.gemrc` :

```
gem: --no-document
```

## Configuration (`kymsu.cfg`)

| Clé | Valeur par défaut | Description |
| --- | --- | --- |
| `gem_dry_run` | `false` | `true` : affiche les mises à jour sans rien installer |
| `gem_no_document` | `true` | `true` : passe `--no-document` à `gem update` (plus rapide) |
| `gem_pinned` | *(vide)* | Noms exacts des gems à ne jamais mettre à jour, séparés par des espaces |

Exemple :

```
gem_dry_run=false
gem_no_document=true
gem_pinned=rdoc bundler
```

Si `gem_no_document` est absent de `kymsu.cfg`, `--no-document` est appliqué par défaut. Pour forcer la génération de documentation, mettre explicitement `gem_no_document=false`.

## Utilisation

Le script est lancé automatiquement par kymsu :

```bash
kymsu2
```

Ou directement :

```bash
~/.kymsu/plugins.d/gem.sh
```

Le script est interactif. Il effectue dans l'ordre :

1. Vérifie la connexion Internet et la présence de `gem`.
2. Lance `gem outdated --local` et sépare les gems pinned des autres.
3. Affiche les gems épinglés (skipped) s'il y en a.
4. Affiche la liste des gems à mettre à jour avec versions installée et disponible.
5. Propose trois modes :

| Choix | Comportement |
| --- | --- |
| `a` (all) | Met à jour tous les gems listés |
| `y` (choose) | Ouvre fzf pour sélectionner gem par gem |
| `n` | Quitte sans rien faire |

## Fonctionnement détaillé

### Gems épinglés (pinned)

Les gems listés dans `gem_pinned` sont exclus de la mise à jour et affichés séparément avec la mention `(pinned)`. Ils restent visibles pour information avec leurs versions installée et disponible. Utile pour les gems comme `rdoc` (default gem fourni avec Ruby, mieux géré via Homebrew) ou `bundler` (version souvent fixée par un projet).

### Mode fzf (`y`)

- `Tab` / `Shift-Tab` : sélectionner / désélectionner un gem
- `Ctrl-A` : tout sélectionner
- `Entrée` : valider la sélection
- `Échap` : annuler et quitter

Le panneau de prévisualisation (droite, 40 %) affiche pour chaque gem surligné : son nom, les versions installée et disponible, et le lien vers sa page rubygems.org.

### Option `--no-document`

Par défaut (`gem_no_document=true`), le script passe `--no-document` à `gem update`. Cela évite la génération de documentation RDoc et ri, ce qui accélère significativement la mise à jour. Les messages du type `Couldn't find file to include` ou `Installing ri documentation` disparaissent.

Si la documentation locale est nécessaire (consultation via `ri NomDuGem`), mettre `gem_no_document=false`. Elle peut aussi être régénérée à la demande :

```bash
gem rdoc --ri nom_du_gem
```

### Mode dry-run

Si `gem_dry_run=true` dans `kymsu.cfg`, le script affiche les gems qui seraient mis à jour sans rien installer. Utile pour inspecter les mises à jour disponibles avant de les appliquer.

### Rapport d'échec

Si `gem update` échoue pour un gem, son nom est affiché en rouge en fin de script dans la liste `Failed`.

## Limitations connues

- **Ruby système sur macOS** : `/usr/bin/gem update` nécessite `sudo` ou échoue avec une erreur de permissions. Utiliser Ruby via Homebrew (`brew install ruby`), rbenv ou asdf.
- **`rdoc` : erreur de permissions** : `rdoc` est un *default gem* fourni avec Ruby Homebrew. Sa mise à jour peut échouer si le dossier `plugins/` de Ruby n'est pas accessible en écriture. Solution : `sudo chown -R $(whoami) $(gem env gemdir)`, ou l'épingler dans `gem_pinned=rdoc`.
- **`gem outdated` lent** : avec de nombreux gems installés, `gem outdated` peut prendre plusieurs secondes (vérification des versions sur le registre). C'est normal et non lié au script.
- **Pas de sélection des gems pinned** : les gems dans `gem_pinned` sont complètement exclus, y compris de l'affichage fzf. Pour les mettre à jour ponctuellement, les retirer temporairement de `gem_pinned`.
- **`gem_no_document` appliqué globalement** : l'option `--no-document` s'applique à tous les gems mis à jour. Il n'est pas possible de la désactiver pour un gem spécifique via `kymsu.cfg`.
