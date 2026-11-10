#!/usr/bin/env bash

# Mac Appstore plugin for KYMSU
# https://github.com/welcoMattic/kymsu
# fork https://github.com/Bruno21/kymsu
# https://github.com/mas-cli/mas
# Polished by Claude

#########################################
#
# Settings:
#  - use kymsu.cfg for configuring options
#

SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/.kymsu/plugins.d}"

# shellcheck source=/dev/null
if [ ! -r "$SCRIPTS_DIR/config.shlib" ]; then
	echo "config.shlib not found in $SCRIPTS_DIR (set SCRIPTS_DIR or check the KYMSU installation)." >&2
	exit 1
fi
# shellcheck source=/dev/null
source "$SCRIPTS_DIR/config.shlib"

# Mode dry-run. true : affiche ce qui serait mis à jour sans rien installer
dry_run="$(config_get mas_dry_run)"

# Apps à ne pas mettre à jour (IDs exacts, ex: '497799835')
pinned_mas="$(config_get pinned_mas)"
read -r -a do_not_update <<< "$pinned_mas"

bold="$(config_get bold)"
underline="$(config_get underline)"
red="$(config_get red)"
reset="$(config_get reset)"

store_country="$(config_get mas_store_country)"
store_country="${store_country:-$(defaults read -g AppleLocale 2>/dev/null | cut -d'_' -f2 | tr '[:upper:]' '[:lower:]')}"
store_country="${store_country:-us}"
#
#########################################

###############################################################################################
#
# Require software:
#   -mas (Mac App Store command-line interface) (https://github.com/mas-cli/mas)
#   -fzf (Command-line fuzzy finder written in Go) (https://junegunn.github.io/fzf/)
#
###############################################################################################

is_excluded() {
	local id
	for id in "${do_not_update[@]}"; do
		[[ "$id" == "$1" ]] && return 0
	done
	return 1
}

echo -e "${bold} 🛍️  Mac App Store ${reset}"
echo ""

# Internet connection test
if ! check_internet; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi

if ! command -v mas >/dev/null; then
	echo -e "${red}mas not found !${reset} (brew install mas)"
	exit 1
fi

echo -e "${underline}mas:${reset} $(command -v mas)"
echo -e "${underline}Version:${reset} $(mas version)"
echo ""

[[ "$dry_run" == "true" ]] && echo -e "${red}DRY-RUN: nothing will be installed${reset}\n"

# Format mas outdated : "ID  Nom  (installée -> disponible)"
# -> "ID|Nom|installée|disponible" (séparateur | pour gérer les noms multi-mots)
verbose=$(mas outdated 2>/dev/null |
	sed -E 's/^([0-9]+)[[:space:]]+(.+)[[:space:]]+\(([^ ]+)[[:space:]]*->[[:space:]]*([^ )]+)\)$/\1|\2|\3|\4/' |
	sort -u)

# Séparer les apps pinned des autres
all_verbose=""
pinned=""
while IFS='|' read -r id rest; do
	[[ -n "$id" ]] || continue
	if is_excluded "$id"; then
		pinned+="$id|$rest"$'\n'
	else
		all_verbose+="$id|$rest"$'\n'
	fi
done <<<"$verbose"

mapfile -t outdated < <(awk -F'|' 'NF {print $1}' <<<"$all_verbose")
nb=${#outdated[@]}

if [[ -n "$pinned" ]]; then
	echo -e "${underline}Pinned (skipped):${reset}"
	awk -F'|' 'NF {printf "  %-12s %-30s %s → %s\n", $1, $2, $3, $4}' <<<"$pinned"
	echo ""
fi

if (( nb == 0 )); then
	echo -e "${underline}All App Store apps are up to date.${reset}"
	exit 0
fi

col_id=$(awk -F'|' 'NF {print length($1)}' <<<"$all_verbose" | sort -n | tail -1)
col_id=$(( col_id > 2 ? col_id : 2 ))
col_name=$(awk -F'|' 'NF {print length($2)}' <<<"$all_verbose" | sort -n | tail -1)
col_name=$(( col_name > 3 ? col_name : 3 ))
col_ver=$(awk -F'|' 'NF {print length($3)}' <<<"$all_verbose" | sort -n | tail -1)
col_ver=$(( col_ver > 9 ? col_ver : 9 ))

echo -e "${underline}$nb available update(s):${reset}"
echo ""
printf "${bold}%-*s  %-*s  %-*s  %s${reset}\n" \
	"$col_id" "ID" "$col_name" "App" "$col_ver" "Installed" "Available"
awk -F'|' -v ci="$col_id" -v cn="$col_name" -v cv="$col_ver" \
	'NF {printf "%-*s  %-*s  %-*s  %s\n", ci, $1, cn, $2, cv, $3, $4}' <<<"$all_verbose"

read -r -p "$(echo -e "\nDo you wanna update ${bold}${nb} outdated${reset} apps ? (y=choose/a=all/n) ")" choice

case "${choice,,}" in
	a)
		selected=("${outdated[@]}")
		;;
	y)
		if ! command -v fzf >/dev/null; then
			echo -e "${red}fzf not found${reset} (brew install fzf)"
			exit 1
		fi

		formatted=$(awk -F'|' -v ci="$col_id" -v cn="$col_name" -v cv="$col_ver" \
			'NF {printf "%-*s  %-*s  %-*s  →  %s\n", ci, $1, cn, $2, cv, $3, $4}' \
			<<<"$all_verbose")

		tmp_verbose=$(mktemp)
		printf '%s\n' "$all_verbose" > "$tmp_verbose"

		mapfile -t selected < <(
			printf '%s\n' "$formatted" |
			fzf --multi --height=80% --reverse \
				--header 'Tab: select | Ctrl-A: all | Enter: validate | Esc: cancel' \
				--bind 'ctrl-a:select-all' \
				--preview "grep -m1 '^{1}|' '$tmp_verbose' | awk -F'|' '{printf \"ID:        %s\nApp:       %s\nInstalled: %s\nAvailable: %s\nStore:     https://apps.apple.com/${store_country}/app/id%s\n\", \$1, \$2, \$3, \$4, \$1}'" \
				--preview-window=right:40%:wrap \
				| awk '{print $1}'
		)
		rm -f "$tmp_verbose"

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

failed=()
for id in "${selected[@]}"; do
	is_excluded "$id" && continue

	name=$(awk -F'|' -v id="$id" '$1 == id {print $2}' <<<"$all_verbose")

	if [[ "$dry_run" == "true" ]] ; then
		echo -e "\n${bold}upgrade $name ($id) (dry-run)${reset}"
	else
		echo -e "\n${bold}Upgrade $name ($id)${reset}"
		mas upgrade "$id" || failed+=("$name ($id)")
	fi
done

if (( ${#failed[@]} > 0 )); then
	echo -e "\n${red}Failed:${reset} ${failed[*]}"
fi

echo
echo
