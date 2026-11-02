#!/usr/bin/env bash

# Rust plugin for KYMSU
# https://github.com/welcoMattic/kymsu


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


bold="$(config_get bold)"
italic="$(config_get italic)"
underline="$(config_get underline)"
greenbold="$(config_get greenbold)"
red="$(config_get red)"
reset="$(config_get reset)"

#########################################


echo -e "\n${bold}🦀 Rust${reset}\n"

# Nothing to do without rustup or cargo: no need to test the network
if ! hash rustup 2>/dev/null && ! hash cargo 2>/dev/null; then
	echo -e "${red}Neither rustup nor cargo is installed (or in the PATH) !${reset}"
	exit 1
fi

# Internet connection test
if ! curl -fsI --max-time 5 -o /dev/null https://www.apple.com; then
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
		while IFS= read -r line
		do
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
	cargo_before=$(cargo_registry_list)
	installed=$(cut -f1 -d' ' <<< "$cargo_before")
	cargo_changed=false

	if [ -n "$installed" ]; then
		# One package at a time: an error on one of them does not hide the others
		# (fd 3 for the list, so that cargo can never read it from stdin)
		while IFS= read -r -u 3 pkg
		do
			[ -n "$pkg" ] || continue
			echo -e "${bold}$pkg${reset}"
			if cargo install "$pkg"; then
				cargo_changed=true
			else
				echo -e "${red}cargo install $pkg failed.${reset}"
				echo -e "${italic}Tip: try ${bold}cargo install --locked $pkg${reset}${italic} (uses the dependency versions tested by the author).${reset}"
			fi
			echo ""
		done 3<<< "$installed"
	fi

	echo ""

	echo -e "\n🦀 ${underline}Cargo packages list !${reset}\n"

	# Versions may have changed only if a package was installed: otherwise the first list is reused
	if [ "$cargo_changed" = true ]; then
		cargo_after=$(cargo_registry_list)
	else
		cargo_after="$cargo_before"
	fi
	if [ -n "$cargo_after" ]; then
		awk -F":" '{print $1}' <<< "$cargo_after"
	fi

fi

echo ""
echo ""