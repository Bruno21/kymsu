#!/usr/bin/env bash

# Rust plugin for KYMSU
# https://github.com/welcoMattic/kymsu
# fork https://github.com/Bruno21/kymsu
# Verified by Claude

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

# true : réessaie avec --locked si cargo install échoue
locked="$(config_get rust_locked)"
locked="${locked:-true}"

# true : affiche ce qui serait mis à jour sans rien installer
dry_run="$(config_get rust_dry_run)"

# Paquets cargo à ne pas mettre à jour
pinned_rust="$(config_get rust_pinned)"
read -r -a cargo_do_not_update <<< "$pinned_rust"

bold="$(config_get bold)"
underline="$(config_get underline)"
greenbold="$(config_get greenbold)"
red="$(config_get red)"
redbold="$(config_get redbold)"
redbox="$(config_get redbox)"
reset="$(config_get reset)"
#
#########################################

###############################################################################################
#
# Require software:
#   -rustup (Rust toolchain installer) (https://rust-lang.github.io/rustup/)
#   -cargo (part of Rust)
#
###############################################################################################

echo -e "\n${bold}🦀 Rust${reset}\n"

# Nothing to do without rustup or cargo: no need to test the network
if ! hash rustup 2>/dev/null && ! hash cargo 2>/dev/null; then
	echo -e "${red}Neither rustup nor cargo is installed (or in the PATH) !${reset}"
	exit 1
fi

# Internet connection test
if ! check_internet; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi

if hash rustup 2>/dev/null; then

	echo -e "🦀 ${underline}rustup check${reset}\n"

	rustup_version=$(rustup -V 2>&1 | head -n 1)
	echo -e "${greenbold}$rustup_version${reset}\n"

	rustup show
	echo

	check=$(rustup check 2>&1)
	# Remove ANSI color codes and carriage returns, if any: they would split the words searched below
	# shellcheck disable=SC2001  # regex needed (repeated character class): ${var//pattern/repl} only takes globs
	check=$(sed $'s/\x1b\\[[0-9;]*[A-Za-z]//g' <<< "$check" | tr -d '\r')

	echo -e "\n🦀 ${underline}Upgrading rust toolchains !${reset}\n"

	# rustup check prints one line per toolchain, plus rustup itself, e.g.:
	#   stable-aarch64-apple-darwin - update available: 1.99.0 (b940084d7 2026-09-28) -> 1.99.1 (58cf8f9c3 2026-10-13)
	#   (older rustup: "Update available : 1.82.0 -> 1.83.0" / "Up to date : 1.27.1", hence the case-insensitive search)
	if grep -qiE 'up to date|update available' <<< "$check"; then
		while IFS= read -r line; do
			if grep -qi 'update available' <<< "$line"; then
				echo -e "${red}$line${reset}"
			elif grep -qi 'up to date' <<< "$line"; then
				echo -e "${greenbold}$line${reset}"
			else
				echo "$line"
			fi
		done <<< "$check"
		echo ""

		# One "Update available" line, on any toolchain or on rustup itself, is enough
		if grep -qi 'update available' <<< "$check"; then
			if ! rustup update; then
				echo -e "${red}rustup update failed.${reset}"
			fi
		else
			echo -e "${greenbold}Rust is up to date!${reset}"
		fi
	else
		echo -e "${red}Could not read the result of rustup check (raw output, control characters shown):${reset}"
		cat -v <<< "$check"
	fi

	# if rustup update fails => rustup toolchain uninstall stable && rustup toolchain install stable

	echo ""
fi

# Packages installed from crates.io, one "name vX.Y.Z:" line each
# (git and path packages have a "(...)" before the colon: they are ignored)
cargo_registry_list() {
	cargo install --list | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+:'
}

if hash cargo 2>/dev/null; then

	echo -e "\n🦀 ${underline}Update cargo packages !${reset}\n"

	[[ "$dry_run" == "true" ]] && echo -e "${red}DRY-RUN: nothing will be installed${reset}\n"

	cargo_before=$(cargo_registry_list)

	# Récupérer la version disponible sur crates.io pour chaque paquet (un appel par paquet)
	echo -e "Checking available versions on crates.io..."
	all_verbose=""
	# shellcheck disable=SC2001  # regex needed: $ anchor not available in bash glob replacement
	while IFS= read -r line; do
		[[ -n "$line" ]] || continue
		name=$(awk '{print $1}' <<< "$line")
		installed=$(awk '{print $2}' <<< "$line" | tr -d 'v:')
		available=$(cargo search --limit 1 "$name" 2>/dev/null \
			| grep -E "^$name " \
			| grep -oE '[0-9]+\.[0-9]+\.[0-9]+' \
			| head -1)
		available="${available:-?}"
		all_verbose+="$name $installed $available"$'\n'
	done < <(echo "$cargo_before" | sed 's/:$//')

	# All outdated packages including pinned (for display)
	outdated_verbose=$(awk '$2 != $3 && $3 != "?" {print}' <<< "$all_verbose")

	# Non-pinned outdated packages: candidates for update
	mapfile -t pkgs < <(
		awk '$2 != $3 && $3 != "?" {print $1}' <<< "$all_verbose" | while IFS= read -r p; do
			[[ " ${cargo_do_not_update[*]} " == *" $p "* ]] || echo "$p"
		done
	)
	nb=${#pkgs[@]}
	echo

	# Display pinned packages if any
	if [ ${#cargo_do_not_update[@]} -gt 0 ]; then
		nb_pinned="${#cargo_do_not_update[*]}"
		echo -e "${underline}🦀  List of${reset} ${redbox} $nb_pinned ${reset} ${underline}'do not update' packages:${reset}"
		echo -e "${redbold}${cargo_do_not_update[*]}${reset}"
		echo ""
	fi

	if [ -z "$outdated_verbose" ]; then
		echo -e "${greenbold}All cargo packages are up to date.${reset}"
	else
		# Afficher tous les paquets obsolètes (les épinglés sont signalés mais non mis à jour)

		col_name=$(awk '{print length($1)}' <<< "$outdated_verbose" | sort -n | tail -1)
		col_name=$(( col_name > 7 ? col_name : 7 ))
		col_ver=$(awk '{print length($2)}' <<< "$outdated_verbose" | sort -n | tail -1)
		col_ver=$(( col_ver > 9 ? col_ver : 9 ))

		printf "${bold}%-*s  %-*s  %s${reset}\n" "$col_name" "Package" "$col_ver" "Installed" "Available"
		awk -v cn="$col_name" -v cv="$col_ver" -v pinned="${cargo_do_not_update[*]}" \
			'BEGIN { n=split(pinned,a," "); for(i=1;i<=n;i++) p[a[i]]=1 }
			 NF { tag=(p[$1]) ? "  (pinned)" : ""; printf "%-*s  %-*s  →  %s%s\n", cn, $1, cv, $2, $3, tag }' \
			<<< "$outdated_verbose"

		if (( nb == 0 )); then
			echo -e "\n${redbold}All outdated packages are pinned. Nothing to update.${reset}"
		else

		read -r -p "$(echo -e "\nDo you wanna update ${bold}${nb} outdated${reset} packages ? (y=choose/a=all/n) ")" choice

		case "${choice,,}" in
			a)
				selected=("${pkgs[@]}")
				;;
			y)
				if ! command -v fzf >/dev/null; then
					echo -e "${red}fzf not found${reset} (brew install fzf)"
					exit 1
				fi

				formatted=$(awk -v cn="$col_name" -v cv="$col_ver" -v pinned="${cargo_do_not_update[*]}" \
					'BEGIN { n=split(pinned,a," "); for(i=1;i<=n;i++) p[a[i]]=1 }
					 NF && !p[$1] { printf "%-*s  %-*s  →  %s\n", cn, $1, cv, $2, $3 }' \
					<<< "$outdated_verbose")

				mapfile -t selected < <(
					printf '%s\n' "$formatted" |
					fzf --multi --height=80% --reverse \
						--header $'Package  Installed  →  Available\nTab: select | Ctrl-A: all | Enter: validate | Esc: cancel' \
						--bind 'ctrl-a:select-all' \
						--preview "printf 'Package:   %s\nInstalled: %s\nAvailable: %s\nDoc:       https://crates.io/crates/%s\n' {1} {2} {3} {1}" \
						--preview-window=right:40%:wrap \
					| awk '{print $1}'
				)
				if (( ${#selected[@]} == 0 )); then
					echo "Nothing selected. Bye"
					selected=()
				fi
				;;
			*)
				echo "Bye"
				selected=()
				;;
		esac

		cargo_changed=false
		failed_locked=()

		for pkg in "${selected[@]}"; do
			[ -n "$pkg" ] || continue
			if [[ "$dry_run" == "true" ]]; then
				echo -e "\n${bold}cargo install $pkg (dry-run)${reset}"
			else
				echo -e "\n${bold}$pkg${reset}"
				if cargo install "$pkg"; then
					cargo_changed=true
				else
					if [[ "$locked" == "true" ]]; then
						echo -e "${red}cargo install $pkg failed. Retrying with --locked...${reset}"
						if cargo install --locked "$pkg"; then
							cargo_changed=true
						else
							echo -e "${red}cargo install --locked $pkg failed.${reset}"
							failed_locked+=("$pkg")
						fi
					else
						echo -e "${red}cargo install $pkg failed.${reset}"
						failed_locked+=("$pkg")
					fi
				fi
				echo ""
			fi
		done

		if (( ${#failed_locked[@]} > 0 )); then
			echo -e "\n${red}Still failed:${reset} ${failed_locked[*]}"
		fi

		echo -e "\n🦀 ${underline}Cargo packages list !${reset}\n"

		if [ "$cargo_changed" = true ]; then
			cargo_after=$(cargo_registry_list)
		else
			cargo_after="$cargo_before"
		fi
		if [ -n "$cargo_after" ]; then
			awk -F":" '{print $1}' <<< "$cargo_after"
		fi

		fi	# end if nb > 0
	fi

fi
echo ""
