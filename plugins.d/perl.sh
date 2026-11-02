#!/usr/bin/env bash

# Perl plugin for KYMSU
# https://github.com/welcoMattic/kymsu

SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/.kymsu/plugins.d}"

# shellcheck source=/dev/null
source "$SCRIPTS_DIR/config.shlib"	# load the config library functions

# Modules à ne pas mettre à jour (noms exacts, ex: 'Foo::Bar')
do_not_update=()


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

# Modules obsolètes (un nom par ligne)
# Un seul appel : module, version installée, version disponible, distribution
verbose=$(cpan-outdated --verbose | sort -u)
mapfile -t outdated < <(awk '{print $1}' <<<"$verbose")
nb=${#outdated[@]}

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
	;;	*)
		echo "Bye"
		exit 0
		;;
esac


# Une chose à vérifier : cpan -i en mode a peut poser des questions interactives (dépendances, tests 
# qui échouent). Si tu veux éviter ça, lance-le avec PERL_MM_USE_DEFAULT=1 cpan -i "$m", 
# qui accepte les réponses par défaut.

for m in "${selected[@]}"; do
	is_excluded "$m" && continue

	echo -e "\n\n${bold}install $m ${reset}\n"

	cpan -i "$m"
done
