#!/usr/bin/env bash

# Perl plugin for KYMSU
# https://github.com/welcoMattic/kymsu

SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/.kymsu/plugins.d}"

# shellcheck source=/dev/null
if [ ! -r "$SCRIPTS_DIR/config.shlib" ]; then
	echo "config.shlib not found in $SCRIPTS_DIR (set SCRIPTS_DIR or check the KYMSU installation)." >&2
	exit 1
fi
# shellcheck source=/dev/null
source "$SCRIPTS_DIR/config.shlib"	# load the config library functions

# true : affiche ce qui serait mis à jour sans rien installer
dry_run="$(config_get perl_dry_run)"

# Modules à ne pas mettre à jour (noms exacts, ex: 'Foo::Bar')
do_not_update=('DBD::CSV' 'Alien::cmake3' 'App::Cpan' 'DBD::CSV' 'DBD::SQLite')

# Couleurs
bold="$(config_get bold)"
underline="$(config_get underline)"
red="$(config_get red)"
reset="$(config_get reset)"

is_excluded() {
	local m
	for m in "${do_not_update[@]}"; do
		[[ "$m" == "$1" ]] && return 0
	done
	return 1
}

# Internet connection test
if ! check_internet; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi

echo -e "${bold}🐪 Perl ${reset}"
echo

[[ "$dry_run" == "true" ]] && echo -e "${red}DRY-RUN: nothing will be installed${reset}\n"

if ! perl_app=$(command -v perl); then
	echo -e "${red}Perl not found !${reset}"
	exit 1
fi
perl_v=$(perl -v | sed -n '2p')

echo -e "${underline}Perl:${reset} $perl_app"
echo -e "${underline}Version:${reset} $perl_v"
echo ""

# Prérequis : App::cpanoutdated (fournit la commande cpan-outdated)
module="App::cpanoutdated"
if ! perl "-M$module" -e 1 2>/dev/null; then
	echo -e "${underline}Requirement:${reset} module $module is not installed"

	read -r -p "$(echo -e "Do you wanna run ${bold}cpan -i $module${reset} ? (y/n) ")" choice
	if [[ "${choice,,}" == "y" ]]; then
		cpan -i "$module"
		if ! perl "-M$module" -e 1 2>/dev/null; then
			echo -e "${red}Installation of $module failed !${reset}"
			exit 1
		fi
	else
		echo "Bye"
		exit 0
	fi
fi

# Un seul appel : module, version installée, version disponible, distribution
: '
verbose=$(cpan-outdated --verbose | sort -u)
mapfile -t outdated < <(awk '{print $1}' <<<"$verbose")
nb=${#outdated[@]}

if (( nb == 0 )); then
	echo -e "${underline}All Perl modules are up to date.${reset}"
	exit 0
fi

printf '%s\n' "${outdated[@]}" | column -c "$(tput cols)"

read -r -p "$(echo -e "\nDo you wanna update ${bold}${nb} outdated${reset} modules ? (y=choose/a=all/n) ")" choice
'

# Un seul appel : module, version installée, version disponible, distribution
all=$(cpan-outdated --verbose | sort -u)

# Séparer les modules pinned (do_not_update) des autres
verbose=""
pinned=""
while read -r name rest; do
	[[ -n "$name" ]] || continue
	if is_excluded "$name"; then
		pinned+="$name $rest"$'\n'
	else
		verbose+="$name $rest"$'\n'
	fi
done <<<"$all"

#mapfile -t outdated < <(awk '{print $1}' <<<"$verbose")
mapfile -t outdated < <(awk 'NF {print $1}' <<<"$verbose")
nb=${#outdated[@]}

if [[ -n "$pinned" ]]; then
	echo -e "${underline}Pinned (skipped):${reset}"
	#awk '{printf "  %-30s %s → %s\n", $1, $2, $3}' <<<"$pinned"
	awk 'NF {printf "  %-30s %s → %s\n", $1, $2, $3}' <<<"$pinned"
	echo ""
fi

if (( nb == 0 )); then
	echo -e "${underline}All Perl modules are up to date.${reset}"
	exit 0
fi

printf '%s\n' "${outdated[@]}" | column -c "$(tput cols)"

read -r -p "$(echo -e "\nDo you wanna update ${bold}${nb} outdated${reset} modules ? (y=choose/a=all/n) ")" choice

case "${choice,,}" in
	a)
		selected=("${outdated[@]}")
		;;
	y)
		if ! command -v fzf >/dev/null; then
			echo -e "${red}fzf not found${reset} (brew install fzf)"
			exit 1
		fi

		mapfile -t selected < <(
			fzf --multi --height=80% --reverse \
				--header 'Tab: select | Ctrl-A: all | Enter: validate | Esc: cancel' \
				--bind 'ctrl-a:select-all' \
				--preview 'printf "Module:    %s\nInstalled: %s\nAvailable: %s\nDist:      %s\nDoc:       https://metacpan.org/pod/%s\n" {1} {2} {3} {4} {1}' \
				--preview-window=right:40%:wrap \
				<<<"$verbose" | awk '{print $1}'
		)
		if (( ${#selected[@]} == 0 )); then
			echo "Nothing selected. Bye"
			exit 0
		fi
		;;
	*)
		echo "Bye"
		exit 0
		;;
esac

# Une chose à vérifier : cpan -i en mode a peut poser des questions interactives (dépendances, tests 
# qui échouent). Si tu veux éviter ça, lance-le avec PERL_MM_USE_DEFAULT=1 cpan -i "$m", 
# qui accepte les réponses par défaut.

# --- Installation ---
failed=()
for m in "${selected[@]}"; do
	is_excluded "$m" && continue

	if [[ "$dry_run" == "true" ]]; then
		echo -e "\n${bold}install $m (dry-run)${reset}"
	else
		echo -e "\n${bold}Install $m${reset}"
		PERL_MM_USE_DEFAULT=1 cpan -i "$m" || failed+=("$m")	# ne pas poser de questions pendant l’installation et d’accepter toutes les valeurs par défaut.
	fi
done

# --- Retry sans tests pour les échecs (faux positifs COW, etc.) ---
if (( ${#failed[@]} > 0 )); then
	echo -e "\n${bold}Retrying failed modules without tests:${reset}"
	failed_notest=()
	for m in "${failed[@]}"; do
		echo -e "\n${bold}Install $m (--notest)${reset}"
		PERL_MM_USE_DEFAULT=1 cpan -i -T "$m" || failed_notest+=("$m")
	done

	if (( ${#failed_notest[@]} > 0 )); then
		echo -e "\n${red}Still failed:${reset} ${failed_notest[*]}"
	else
		echo -e "\n${underline}All retried modules installed successfully.${reset}"
	fi
fi