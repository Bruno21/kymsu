#!/usr/bin/env bash

# gem plugin for KYMSU (install local package)
# https://github.com/welcoMattic/kymsu
# fork https://github.com/Bruno21/kymsu
# Verified by Claude

# https://guides.rubygems.org/what-is-a-gem/
# Ne pas générer la doc de façon permanente pour tous tes gem install et gem update :
# echo 'gem: --no-document' >> ~/.gemrc

#########################################
#
# Settings:
#  - use kymsu.cfg for configuring options

SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/.kymsu/plugins.d}"

# shellcheck source=/dev/null
if [ ! -r "$SCRIPTS_DIR/config.shlib" ]; then
	echo "config.shlib not found in $SCRIPTS_DIR (set SCRIPTS_DIR or check the KYMSU installation)." >&2
	exit 1
fi
# shellcheck source=/dev/null
source "$SCRIPTS_DIR/config.shlib"	# load the config library functions

# true : affiche ce qui serait mis à jour sans rien installer
dry_run="$(config_get gem_dry_run)"

# Gems à ne pas mettre à jour (noms exacts, ex: 'bundler')
gem_pinned="$(config_get gem_pinned)"
read -r -a do_not_update <<< "$gem_pinned"

# Couleurs
bold="$(config_get bold)"
underline="$(config_get underline)"
red="$(config_get red)"
redbox="$(config_get redbox)"
reset="$(config_get reset)"

# Option kymsu.cfg : gem_no_document (true par défaut si absente)
gem_flags=()
[[ "$(config_get gem_no_document)" != "false" ]] && gem_flags+=(--no-document)
#
#########################################

###############################################################################################
#
# Require software (brew install):
#	-fzf (Command-line fuzzy finder written in Go) (https://junegunn.github.io/fzf/)
#   -gem (part of Ruby)
#
###############################################################################################

is_excluded() {
	local m
	for m in "${do_not_update[@]}"; do
		[[ "$m" == "$1" ]] && return 0
	done
	return 1
}

echo -e "${bold} 💍  Gem (Ruby) ${reset}"
echo ""

# Internet connection test
if ! check_internet; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi

if ! command -v gem >/dev/null; then
	echo -e "${red}gem not found !${reset}"
	exit 1
fi

[[ "$dry_run" == "true" ]] && echo -e "\n${red}DRY-RUN: nothing will be installed${reset}\n"

echo -e "${underline}Gem:${reset} $(command -v gem)"
echo -e "${underline}Version:${reset} $(gem -v)"
echo ""

# Format de gem outdated : "nom (installée < disponible)"
# -> "nom installée disponible" (colonnes pour fzf)
# Format de gem outdated : "nom (installée < disponible)"
# -> "nom installée disponible" (colonnes pour fzf)
all=$(gem outdated --local 2>/dev/null |
	sed -E 's/^([^ ]+) \((.*) < (.*)\)$/\1 \2 \3/' |
	sort -u)

# Séparer les gems pinned (do_not_update) des autres
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

mapfile -t outdated < <(awk 'NF {print $1}' <<<"$verbose" | sort -u)
nb=${#outdated[@]}

if [[ -n "$pinned" ]]; then
	echo -e "${underline}Pinned (skipped):${reset}"
	column -t <<<"$pinned" | sed 's/$/  (pinned)/'
	echo ""
fi

if (( nb == 0 )); then
	echo -e "${underline}No gem updates.${reset}\n\n"
	exit 0
fi

echo -e "${redbox} $nb ${reset} ${underline}available updates:${reset}"
column -t <<<"$verbose"

read -r -p "$(echo -e "\nDo you wanna update ${bold}${nb} outdated${reset} gems ? (y=choose/a=all/n) ")" choice

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
				--preview 'printf "Gem:       %s\nInstalled: %s\nAvailable: %s\nDoc:       https://rubygems.org/gems/%s\n" {1} {2} {3} {1}' \
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

for m in "${selected[@]}"; do
	is_excluded "$m" && continue

	if [[ "$dry_run" == true ]]; then
		echo -e "\n${bold}update $m (dry-run)${reset}"
	else
		echo -e "\n${bold}Update $m${reset}"
		# no-document
		gem update "${gem_flags[@]}" "$m"
	fi
done

echo ""
echo ""