#!/usr/bin/env bash

# Venv plugin for KYMSU
# https://github.com/welcoMattic/kymsu
# fork https://github.com/Bruno21/kymsu
# Verified by Claude

#########################################
#
# Settings:
#  - use kymsu.cfg for configuring options

#SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/.kymsu/plugins.d}"

if [ ! -r "$SCRIPTS_DIR/config.shlib" ]; then
	echo "config.shlib not found in $SCRIPTS_DIR (set SCRIPTS_DIR or check the KYMSU installation)." >&2
	exit 1
fi
# shellcheck source=/dev/null
source "$SCRIPTS_DIR/config.shlib"	# load the config library functions


bold="$(config_get bold)"
underline="$(config_get underline)"
red="$(config_get red)"
reset="$(config_get reset)"

# Liste des apps:
# 	- le venv doit avoir le même nom que l'app
apps=("mkdocs")

# Liste des extensions pour Mkdocs
mkdocs_ext=("mkdocs-material" "mkdocs-material-extensions" "mkdocs-git-revision-date-localized-plugin" "mkdocs-minify-plugin" "fontawesome_markdown" "mkdocs-pdf-export-plugin")

declare -A before
#
#########################################

###############################################################################################
#
# Require software:
#   -python (Interpreted, interactive, object-oriented programming language) (https://www.python.org/)
#   -pip (part of Python)
#
###############################################################################################


echo -e "${bold}🐍  Update apps in Python virtuals environments ${reset}\n"

# Emplacement des venv selon l'OS
case "$OSTYPE" in
	darwin*)          v="$HOME/Documents/venv" ;;   # macOS
	linux-gnueabihf*) v="$HOME/venv" ;;             # Raspberry Pi
	linux-gnu*)       v="$HOME/Applications" ;;     # Solus, etc.
	*)
		echo -e "${red}Unsupported OS: $OSTYPE${reset}"
		exit 1
		;;
esac

# Internet connection test
if ! check_internet; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi

echo -e "Venv directory: $v\n"

for app in "${apps[@]}"
do
	echo -e "${bold}Update $app${reset}"

	if [[ ! -f "$v/$app/bin/activate" ]]; then
		echo -e "${red}Venv not found: $v/$app${reset}\n"
		continue
	fi

	pushd "$v/$app" >/dev/null || continue
	# shellcheck source=/dev/null
	source bin/activate

	python -V
	python -m pip install -U pip setuptools

	pkgs=("$app")
	[[ "$app" == "mkdocs" ]] && pkgs+=("${mkdocs_ext[@]}")

	before=()
	# Versions avant
	for p in "${pkgs[@]}"; do
		before[$p]=$(python -m pip show "$p" 2>/dev/null | awk '/^Version:/ {print $2}')
	done

	if python -m pip install -U "${pkgs[@]}"; then
		echo ""
		for p in "${pkgs[@]}"; do
			after=$(python -m pip show "$p" 2>/dev/null | awk '/^Version:/ {print $2}')
			if [[ -z "${before[$p]}" ]]; then
				echo -e "${bold}$p${reset}: installed ($after)"
			elif [[ "${before[$p]}" != "$after" ]]; then
				echo -e "${bold}$p${reset}: ${before[$p]} → $after"
			else
				echo -e "${underline}$p${reset}: up to date ($after)"
			fi
		done
		echo ""
	else
		echo -e "${red}Update failed for $app${reset}"
	fi
	
	# Résumé : première ligne soulignée
	info=$(python -m pip show "$app")
	echo -e "${underline}$(sed -n '1p' <<<"$info")${reset}"
	sed '1d' <<<"$info"

	deactivate
	popd >/dev/null || true
	echo ""

done
