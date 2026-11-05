#!/usr/bin/env bash

# pipx plugin for KYMSU
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

# No distract mode (no user interaction)
# kymsu2 -s pipx.sh -n => no_distract=true (false without the option)
# In this mode, all the outdated packages are upgraded without any question.

# Upgrade --include-injected
injected="$(config_get pipx_injected)"

# Number of parallel requests to PyPI
pypi_jobs=8

italic="$(config_get italic)"
underline="$(config_get underline)"
red="$(config_get red)"
bold="$(config_get bold)"
redbox="$(config_get redbox)"
reset="$(config_get reset)"

no_distract=false
OPTIND=1
while getopts "phncs:a-:" opt; do
	case $opt in
		n) no_distract=true;;
		-) case "$OPTARG" in
			nodistract) no_distract=true;;
			*) ;;
		esac;;
		c|p|h|s|a) ;;	# handled by kymsu2, ignored here
		*) ;;			# unknown option: ignored
	esac
done
#
#########################################

###############################################################################################
#
# Require software:
#   -jq (Lightweight and flexible command-line JSON processor) (https://jqlang.github.io/jq/)
#   -pipx (Execute binaries from Python packages in isolated environments) (https://pipx.pypa.io)
#
###############################################################################################

# Fetch the PyPI info of several packages in parallel.
# usage: fetch_pypi_info <dir> <package>...  ->  <dir>/<package>.json (no file if PyPI does not know the package)
fetch_pypi_info() {
	local dir="$1"
	shift
	[ $# -gt 0 ] || return 0
	# The script given to "sh -c" must be expanded by that inner shell, not by this one
	# shellcheck disable=SC2016
	printf '%s\n' "$@" | xargs -P "$pypi_jobs" -I{} sh -c \
		'curl -fsSL --max-time 10 "https://pypi.org/pypi/$1/json" -o "$2/$1.json" 2>/dev/null || rm -f "$2/$1.json"' _ {} "$dir"
}

# Read the cached PyPI info of a package: sets pypi_version, pypi_summary and pypi_url
# (all empty if PyPI does not know the package). The texts are written by the package authors:
# control characters are removed before they are displayed.
read_pypi_info() {
	local file="$info_dir/$1.json" row
	pypi_version=""
	pypi_summary=""
	pypi_url=""
	[ -s "$file" ] || return 1
	row=$(jq -r '[(.info.version // ""), ((.info.summary // "") | gsub("\\s+"; " ")), (.info.project_urls.Homepage // .info.project_urls.Source // .info.home_page // "")] | join("\u001f")' "$file" 2>/dev/null) || return 1
	IFS=$'\x1f' read -r pypi_version pypi_summary pypi_url <<< "$row"
	pypi_version="${pypi_version//[[:cntrl:]]/}"
	pypi_summary="${pypi_summary//[[:cntrl:]]/}"
	pypi_url="${pypi_url//[[:cntrl:]]/}"
}

# True if version $1 is older than version $2
version_lt() {
	[ "$1" = "$2" ] && return 1
	[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1)" = "$1" ]
}

# usage: check_package <label> <name on PyPI> <installed version> <pinned: true|false> <package to upgrade>
# Prints the package if a newer version exists, and queues it in "outdated" unless it is pinned.
check_package() {
	local label="$1" pypi_name="$2" version="$3" is_pinned="$4" target="$5"

	checked=$((checked + 1))
	read_pypi_info "$pypi_name"

	# No answer from PyPI (network error, package not on PyPI...): never consider it outdated
	if [ -z "$pypi_version" ]; then
		printf '%b%s\tCurrent: %s\tLatest: unknown (no answer from PyPI)%b\n' "$italic" "$label" "$version" "$reset"
		unknown=$((unknown + 1))
		return 0
	fi

	version_lt "$version" "$pypi_version" || return 0

	if [ "$is_pinned" = true ]; then
		printf '%b%s\tCurrent: %s\tLatest: %s (pinned)%b\n' "$red" "$label" "$version" "$pypi_version" "$reset"
	else
		printf '%s\tCurrent: %s\tLatest: %s\n' "$label" "$version" "$pypi_version"
		[[ " ${outdated[*]} " == *" $target "* ]] || outdated+=("$target")
	fi
}

pipx_outdated() {
	local name version is_pinned main inj_pinned main_pinned

	echo -e "\n${underline}Outdated Packages:${reset}"

	while IFS=$'\t' read -r name version is_pinned; do
		[ -n "$name" ] || continue
		check_package "$name" "$name" "$version" "$is_pinned" "$name"
	done <<< "$main_rows"

	# An outdated injected package is upgraded with its main package (pipx upgrade --include-injected)
	if [ -n "$injected_rows" ]; then
		while IFS=$'\t' read -r main name version inj_pinned main_pinned; do
			[ -n "$name" ] || continue
			if [ "$inj_pinned" = true ] || [ "$main_pinned" = true ]; then
				is_pinned=true
			else
				is_pinned=false
			fi
			check_package "$main (injected: $name)" "$name" "$version" "$is_pinned" "$main"
		done <<< "$injected_rows"
	fi
}

upgrade_package() {
	if [ "$injected" = true ]; then
		pipx upgrade --include-injected "$1"
	else
		pipx upgrade "$1"
	fi
}


echo -e "${bold}🛠  pipx (Python 3) ${reset}"

if ! command -v pipx &> /dev/null
then
	echo -e "${bold}pipx${reset} could not be found !\n"
	echo -e "You should install ${bold}pipx${reset}:\n"
	echo -e "  - brew install pipx"
	echo -e "  - pipx ensurepath"
	echo -e "or"
	echo -e "  - python3 -m pip install --user pipx"
	echo -e "  - python3 -m pipx ensurepath"
	exit 1
fi

if ! command -v jq &> /dev/null
then
	echo -e "${bold}jq${reset} could not be found !\n"
	echo -e "You should install ${bold}jq${reset}: brew install jq"
	exit 1
fi

# Internet connection test
if ! check_internet; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi


# Installed packages (JSON output of pipx is stable, its text output is made for humans)
json=$(pipx list --json 2>/dev/null)

# One line per main package: name <TAB> version <TAB> pinned
main_rows=$(jq -r '.venvs[].metadata.main_package | [.package, (.package_version // "?"), (.pinned // false | tostring)] | @tsv' <<< "$json") || {
	echo -e "${red}Could not read the output of pipx list --json !${reset}"
	exit 1
}

if [ -z "$main_rows" ]; then
	echo -e "\n${italic}No package installed with pipx.${reset}"
	exit 0
fi

# One line per injected package: main package <TAB> name <TAB> version <TAB> pinned <TAB> main package pinned
injected_rows=""
if [ "$injected" = true ]; then
	injected_rows=$(jq -r '.venvs[].metadata | .main_package as $m | (.injected_packages // {}) | to_entries[] | [$m.package, .key, (.value.package_version // "?"), (.value.pinned // false | tostring), ($m.pinned // false | tostring)] | @tsv' <<< "$json") || {
		echo -e "${red}Could not read the injected packages of pipx list --json !${reset}"
		exit 1
	}
fi

# PyPI info of all the packages, fetched once and in parallel
info_dir=$(mktemp -d)
trap 'rm -rf "$info_dir"' EXIT

names=$(
	{
		cut -f1 <<< "$main_rows"
		[ -n "$injected_rows" ] && cut -f2 <<< "$injected_rows"
	} | sed '/^$/d' | sort -u
)
echo -e "\n${italic}Fetching the packages info from PyPI...${reset}"
# shellcheck disable=SC2086
fetch_pypi_info "$info_dir" $names


list=$(pipx list --include-injected)		# pipx list --quiet
echo -e "\n${underline}List installed packages:${reset}"
#echo "$list"

# "   package black 24.10.0, installed using Python 3.13.2"
re_package_line='^[[:space:]]*package[[:space:]]+([^[:space:]]+)[[:space:]][^,]*,'

while IFS= read -r line; do

	if [[ "$line" =~ $re_package_line ]]; then
		read_pypi_info "${BASH_REMATCH[1]}"
		printf '\n%b%s%b\n' "$bold" "$line" "$reset"
		[ -z "$pypi_summary" ] || printf '   %s\n' "$pypi_summary"
		[ -z "$pypi_url" ] || printf '   %b%s%b\n' "$italic" "$pypi_url" "$reset"
	else
		printf '%s\n' "$line"
	fi

done <<< "$list"


pinned=$(pipx list --pinned)
echo -e "\n${underline}Pinned packages:${reset}"
echo "$pinned"
echo -e "To unpin, please enter ${italic}pipx unpin <package>${reset}"

# curl -s https://pypi.org/pypi/mkdocs/json | jq -r '.info.summary'
# curl -s https://pypi.org/pypi/mkdocs/json | jq -r '.info.version'
# curl -s https://pypi.org/pypi/mkdocs/json | jq -r '.info.project_url'


outdated=()
unknown=0
checked=0
pipx_outdated

if [ "$unknown" -gt 0 ]; then
	if [ "$unknown" -eq "$checked" ]; then
		echo -e "\n${red}PyPI did not answer for any package: network problem? Updates could not be checked.${reset}"
	else
		echo -e "\n${italic}$unknown package(s) could not be checked (not on PyPI, or no answer).${reset}"
	fi
fi

nb=${#outdated[@]}

if [ "$nb" -gt 0 ]; then

	label="available update"
	[ "$nb" -ne 1 ] && label+="s"
	echo -e "\n${redbox} $nb ${reset} ${label}:"

	# yes (one by one) / all / no
	mode=none
	if [ "$no_distract" = true ]; then
		echo -e "${italic}No distract mode: upgrading ${outdated[*]} without asking.${reset}"
		mode=all
	else
		read -r -p "$(echo -e "\nDo you wanna run ${bold}pipx upgrade ${outdated[*]}${reset} ? (y = one by one / a = all / n = no) ")" choice
		case "$choice" in
			[yY]) mode=ask ;;
			[aA]) mode=all ;;
			*) echo -e "OK, let's continue..." ;;
		esac
	fi

	if [ "$mode" != none ]; then
		upgraded=0
		failed=0
		for pkg in "${outdated[@]}"; do
			if [ "$mode" = ask ]; then
				read -r -p "$(echo -e "Upgrade ${bold}$pkg${reset} ? (y/n) ")" answer
				if [[ ! "$answer" =~ ^[yY]$ ]]; then
					echo "Skipped."
					continue
				fi
			fi
			if upgrade_package "$pkg"; then
				upgraded=$((upgraded + 1))
			else
				failed=$((failed + 1))
				echo -e "${red}pipx upgrade $pkg failed.${reset}"
			fi
		done
		echo -e "\n${italic}$upgraded upgraded, $failed failed.${reset}"
	fi

else
	echo "No update available !"
fi

echo ""
echo ""
