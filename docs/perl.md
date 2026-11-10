# perl.sh — README

Nov 7, 2026 · @clicclac

## Description

`perl.sh` est un plugin pour [altKYMSU](https://github.com/Bruno21/kymsu), un fork de [KYMSU](https://github.com/welcoMattic/kymsu). Il détecte les modules Perl obsolètes via [App::cpanoutdated](https://metacpan.org/pod/App::cpanoutdated) et propose de les mettre à jour de façon interactive, avec sélection dans fzf, gestion des modules épinglés (pinned), et retry automatique sans tests en cas d'échec.

## Prérequis

- **altKYMSU** installé et configuré (`config.shlib`, `kymsu.cfg`)
- **Perl** disponible dans le `PATH` — le script vérifie sa présence au démarrage
- **App::cpanoutdated** : installé automatiquement par le script si absent (fournit la commande `cpan-outdated`)
- **cpan** : inclus avec Perl
- **fzf** : `brew install fzf` (requis uniquement pour le mode `y=choose`)

## Installation

Copier `perl.sh` dans le dossier des plugins de kymsu :

```bash
cp perl.sh ~/.kymsu/plugins.d/
chmod +x ~/.kymsu/plugins.d/perl.sh
```

Ou laisser `install.sh` le copier automatiquement depuis le dépôt.

Ajouter les clés suivantes dans `kymsu.cfg` :

```ini
perl_dry_run=false
perl_pinned=
```

`App::cpanoutdated` est installé automatiquement au premier lancement si absent. Il fournit la commande `cpan-outdated` qui détecte les modules obsolètes.

## Configuration (`kymsu.cfg`)

| Clé | Valeur par défaut | Description |
| --- | --- | --- |
| `perl_dry_run` | `false` | `true` : affiche les modules à mettre à jour sans rien installer |
| `perl_pinned` | *(vide)* | Noms exacts des modules à ne jamais mettre à jour, séparés par des espaces |

Exemple :

```ini
perl_dry_run=false
perl_pinned=DBD::SQLite Alien::cmake3
```

Les noms doivent correspondre exactement à ce que `cpan-outdated` retourne (ex : `DBD::SQLite`, pas `DBD-SQLite`).

## Utilisation

Le script est lancé automatiquement par kymsu :

```bash
kymsu2
```

Ou directement :

```bash
~/.kymsu/plugins.d/perl.sh
```

Le script est interactif. Il effectue dans l'ordre :

1. Vérifie la connexion Internet et la présence de Perl.
2. Installe `App::cpanoutdated` si absent.
3. Lance `cpan-outdated --verbose` et sépare les modules pinned des autres.
4. Affiche les modules épinglés s'il y en a.
5. Affiche la liste des modules obsolètes avec versions installée, disponible et distribution.
6. Propose trois modes :

| Choix | Comportement |
| --- | --- |
| `a` (all) | Met à jour tous les modules listés |
| `y` (choose) | Ouvre fzf pour sélectionner module par module |
| `n` | Quitte sans rien faire |

## Fonctionnement détaillé

### Modules épinglés (pinned)

Les modules listés dans `perl_pinned` sont exclus de la mise à jour et affichés séparément avec leur version installée et disponible. Utile pour les modules dont une version précise est requise par un projet, ou ceux qui échouent systématiquement à l'installation (`DBD::SQLite`, `Alien::cmake3`, etc.).

### Mode fzf (`y`)

- `Tab` / `Shift-Tab` : sélectionner / désélectionner un module
- `Ctrl-A` : tout sélectionner
- `Entrée` : valider la sélection
- `Échap` : annuler et quitter

Le panneau de prévisualisation (droite, 40 %) affiche pour chaque module surligné : son nom, les versions installée et disponible, la distribution CPAN, et le lien vers sa page [metacpan.org](https://metacpan.org).

### `PERL_MM_USE_DEFAULT=1`

Tous les appels `cpan -i` sont précédés de `PERL_MM_USE_DEFAULT=1`. Cette variable dit à `ExtUtils::MakeMaker` de ne pas poser de questions pendant l'installation et d'accepter toutes les réponses par défaut, équivalent du `-y` de `apt`. Sans elle, `cpan` peut se bloquer en attendant une saisie.

Pour les modules utilisant `Module::Build` au lieu de `MakeMaker`, ajouter `PERL_MB_OPT="--quiet"` si des questions interactives apparaissent.

### Retry automatique sans tests (`--notest`)

Si `cpan -i` échoue pour un module (tests qui échouent, notamment sur les modules liés à Copy-On-Write comme `Clone`), le script réessaie automatiquement avec `cpan -i -T` (`--notest`). Cette option saute complètement les tests.

Trois cas possibles :

1. `cpan -i` réussit → module installé normalement.
2. `cpan -i` échoue, `cpan -i -T` réussit → module installé sans tests (faux positif de test).
3. `cpan -i -T` échoue aussi → module affiché dans `Still failed` en fin de script.

### Mode dry-run

Si `perl_dry_run=true` dans `kymsu.cfg`, le script affiche les modules qui seraient mis à jour sans rien installer. La recherche des modules obsolètes via `cpan-outdated` est quand même effectuée.

## Limitations connues

- **`cpan-outdated` lent** : `cpan-outdated --verbose` lit l'index CPAN complet à chaque appel. Sur une connexion lente ou un index non mis en cache, cela peut prendre plusieurs secondes avant l'affichage de la liste.
- **Tests Perl fragiles** : certains modules échouent leurs tests sur une version récente de Perl (`Clone`, modules liés à COW) même si le module fonctionne correctement. Le retry avec `--notest` gère ces faux positifs automatiquement.
- **Modules `Module::Build`** : `PERL_MM_USE_DEFAULT=1` ne couvre que `ExtUtils::MakeMaker`. Un module qui utilise `Module::Build` peut encore poser des questions interactives. Ajouter `PERL_MB_OPT="--quiet"` dans l'environnement si nécessaire.
- **Perl système sur macOS** : `/usr/bin/perl` est le Perl Apple fourni avec macOS. `cpan -i` installe dans `~/Library/Perl` ou `~/.cpan` selon la configuration, ce qui peut créer des conflits avec un Perl Homebrew. Vérifier que `perl` dans le `PATH` pointe bien vers le bon interpréteur (`which perl`).
- **Pas de liste d'exclusion dans fzf** : les modules dans `perl_pinned` n'apparaissent pas dans fzf. Pour les mettre à jour ponctuellement, les retirer temporairement de `perl_pinned`.
- **Code commenté** : un ancien bloc de code est présent sous forme de here-doc `: '...'`. Il n'affecte pas le fonctionnement mais peut être supprimé.
