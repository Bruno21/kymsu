#!/usr/bin/env bash

# npm plugin for KYMSU (local and global packages)
# https://github.com/welcoMattic/kymsu
# fork https://github.com/Bruno21/kymsu
# Polished by Claude

#########################################
#
# Settings:
#  - use kymsu.cfg for configuring options
#

#SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/.kymsu/plugins.d}"

# shellcheck source=/dev/null
if [ ! -r "$SCRIPTS_DIR/config.shlib" ]; then
	echo "config.shlib not found in $SCRIPTS_DIR (set SCRIPTS_DIR or check the KYMSU installation)." >&2
	exit 1
fi
# shellcheck source=/dev/null
source "$SCRIPTS_DIR/config.shlib"	# load the config library functions

# Display info on updated packages / casks
display_info="$(config_get npm_display_info)"

# Add module to the do_not_update array for prevent to update.
pinned_npm="$(config_get pinned_npm)"
read -r -a npm_do_not_update <<< "$pinned_npm"

# No distract mode (no user interaction)
# kymsu2 -s nodejs.sh -n => no_distract=true (false without the option)

# Set ls_color to '' for output nvm list in default colors, else '--no-colors'
# ls_color='--no-colors'
# ls_color='BrGcm' for custom colors
# export NVM_COLORS='BrGcm' in .zshrc for persistant custom colors
ls_color=''

# Set doctor=true to run 'npm doctor' and 'npm cache verify' each time
doctor="$(config_get npm_doctor)"

# Set update_node to true to update node.
update_node="$(config_get npm_update_node)"

# Local install:
# run 'npm init' in local_path to create package.json file
# run 'npm install jquery' to install package (this create node_modules folder and update package.json)
#local_path=$HOME/Sites
# config_get npm_local_path -> $HOME not evaluated
local_path=$(config_get npm_local_path)
local_path="${local_path/#\$HOME/$HOME}"; local_path="${local_path/#\~/$HOME}"
local_path="${local_path:-$HOME/Sites}"   # default if npm_local_path is not set in kymsu.cfg
# Lines of "npm view" output shown under each package (3,4 = description + homepage)
npm_view_range='3,4p'
# Number of parallel "npm view" requests when npm_display_info is true
npm_view_jobs=8

italic="$(config_get italic)"
underline="$(config_get underline)"
red="$(config_get red)"
bold="$(config_get bold)"
green="$(config_get green)"
bold_ita="$(config_get bold_ita)"
redbold="$(config_get redbold)"
redbox="$(config_get redbox)"
reset="$(config_get reset)"
cyan="$(config_get cyan)"
[ -n "$bold_ita" ] || bold_ita='\033[1;3m'
[ -n "$cyan" ] || cyan='\033[36m'	# fallback if kymsu.cfg / config.shlib has no "cyan"

no_distract=false
OPTIND=1
while getopts "pmhncs:a-:" opt; do
	case $opt in
		n) no_distract=true;;
		-) case "$OPTARG" in
			nodistract) no_distract=true;;
			*) ;;
		esac;;
		m|c|p|h|s|a) ;;	# handled by kymsu2, ignored here
		*) ;;			# unknown option: ignored
	esac
done
#
#########################################

###############################################################################################
#
# Require software (brew install):
#	-jq (Lightweight and flexible command-line JSON processor)
#
###############################################################################################

# npm outdated reports "git" / "linked" (or nothing) for packages that do not
# come from the registry: they cannot be updated with "npm install pkg@version"
skip_version() {
	case "$1" in
		git|linked|N/A|"") return 0 ;;
	esac
	return 1
}

# Number of lines of an "npm outdated" list whose package is not pinned
count_updatable() {
	local n=0 l pkg
	while IFS= read -r l; do
		pkg="${l%% *}"
		[ -z "$pkg" ] && continue
		[[ " ${npm_do_not_update[*]} " == *" $pkg "* ]] || n=$((n + 1))
	done <<< "$1"
	echo "$n"
}

# Package name of a line of an "npm ls" tree: "│ └── @scope/pkg@1.2.3 deduped" -> "@scope/pkg"
pkg_of_line() {
	local l="$1"
	l="${l#"${l%%[A-Za-z0-9@]*}"}"	# strip the tree glyphs
	l="${l%% *}"
	echo "${l%@*}"
}

# Package names found in an "npm ls" tree (unique, one per line)
tree_pkg_names() {
	local line
	while IFS= read -r line; do
		if [[ "$line" == *"──"* || "$line" == *"─┬"* ]]; then
			pkg_of_line "$line"
		fi
	done <<< "$1" | sort -u
}

# Fetch the "npm view" info of several packages in parallel.
# usage: fetch_pkg_info <dir> <pkg>...  ->  <dir>/<pkg with "/" replaced by "_">
fetch_pkg_info() {
	local dir="$1"
	shift
	[ $# -gt 0 ] || return 0
	# The script given to "sh -c" must be expanded by that inner shell, not by this one
	# shellcheck disable=SC2016
	printf '%s\n' "$@" | xargs -P "$npm_view_jobs" -I{} sh -c \
		'npm view "$1" 2>/dev/null | sed -n "$2" > "$3/$(printf "%s" "$1" | tr / _)"' _ {} "$npm_view_range" "$dir"
}

# Latest nvm version on GitHub (only called when nvm is installed).
# Bounded in time so that a slow network cannot freeze the script.
latest_nvm_version() {
	local t=""
	if command -v timeout >/dev/null 2>&1; then
		t="timeout 10"
	elif command -v gtimeout >/dev/null 2>&1; then
		t="gtimeout 10"
	fi
	# shellcheck disable=SC2086
	GIT_TERMINAL_PROMPT=0 GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=10 \
		$t git ls-remote --tags --refs --sort="v:refname" https://github.com/nvm-sh/nvm.git 2>/dev/null \
		| tail -n1 | sed 's/.*\///; s/^v//'
}

upd_nvm() {
	(
		cd "$NVM_DIR" || exit 1
		git fetch --tags origin
		git checkout "$(git describe --abbrev=0 --tags --match "v[0-9]*" "$(git rev-list --tags --max-count=1)")"
	) || return 1
	# shellcheck source=/dev/null
	\. "$NVM_DIR/nvm.sh"
}

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# shellcheck source=/dev/null
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if ! command -v node >/dev/null 2>&1; then
	echo -e "${red}node.js is not installed (or nvm is not loaded) !${reset}"
	exit 1
fi

echo -e "${bold}🌿  npm ${reset}"
echo ""

# current node.js version
node_v=$(node -v)
node_ins=$(command -v node)
echo -e "${underline}🌿  node.js:${reset}"
echo -e "     - current version: ${italic}$node_v${reset}"
echo -e "     - install path: ${italic}$node_ins${reset}"

# current npm version
npm_v=$(npm -v)
npm_ins=$(command -v npm)
old_npm="$npm_v"
echo -e "\n${underline}🌿  npm:${reset}"
echo -e "     - current version: ${italic}$npm_v${reset}"
echo -e "     - install path: ${italic}$npm_ins${reset}"


# Internet connection test
if ! check_internet; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi


# nvm version installed by Homebrew
# nvm_installed=$(brew info nvm | grep Cellar)

# nvm from github
if [ -f "$NVM_DIR/nvm.sh" ]; then
	#source "$NVM_DIR/nvm.sh"

	# current nvm version
	nvm_v=$(nvm --version)

	echo -e "\n${underline}🌿  nvm install is:${reset} $NVM_DIR/nvm.sh"
	echo "     - nvm $nvm_v is installed from https://github.com/nvm-sh/nvm"

	# latest nvm version on GitHub
	version_nvm=$(latest_nvm_version)

	if [ -n "$version_nvm" ]; then
		if [ "$nvm_v" != "$version_nvm" ]; then
			echo "Current nvm version on GitHub: $version_nvm"
			echo "Current nvm installed version: $nvm_v"

			if [ "$no_distract" = false ]; then
				read -r -p "Do you want to update nvm from GitHub repo? (y/n) " choice
				if [ "$choice" = "y" ]; then
					echo "Updating nvm from GitHub..."
					upd_nvm
				fi
			fi
		fi
	fi

	node_install=$(nvm list ${ls_color:+"$ls_color"})
	echo -e "\n${underline}🌿  node.js${reset} (installed versions): \n$node_install"

# nvm from homebrew
elif brew_nvm="$(brew --prefix nvm 2>/dev/null)/nvm.sh"; [ -f "$brew_nvm" ]; then
	# shellcheck source=/dev/null
	source "$brew_nvm"

	# current nvm version
	nvm_v=$(nvm --version)

	echo -e "\n${underline}🌿  nvm install is:${reset} $brew_nvm"
	echo "nvm $nvm_v is installed from homebrew"

	# latest nvm version on GitHub
	version_nvm=$(latest_nvm_version)

	if [ -n "$version_nvm" ] && [ "$nvm_v" != "$version_nvm" ]; then
		echo "Current nvm version on GitHub: $version_nvm"
		echo "Current nvm installed version: $nvm_v"

		echo -e "nvm is outdated ! You should run ${bold_ita}brew update && brew upgrade nvm${reset}"
		echo -e "or run ${bold_ita}Kymsu's homebrew.sh script.${reset}"
	fi

	node_install=$(nvm list ${ls_color:+"$ls_color"})
	echo -e "\n${underline}🌿  node.js${reset} (installed versions): \n$node_install"

fi


echo -e "${italic}Note:"
echo -e "N/A: version \"10.18.0 -> N/A\" is not yet installed."
echo -e "You need to run \"nvm install 10.18.0\" to install it before using it.${reset}"

echo ""


# Do not update packages

if [ ${#npm_do_not_update[@]} -gt 0 ]; then

	nbp="${#npm_do_not_update[*]}"

	echo -e "${underline}🌿  List of${reset} ${redbox} $nbp ${reset} ${underline}'do not update' packages:${reset}"
	echo -e "${redbold}${npm_do_not_update[*]}${reset}"
	echo -e "To remove package from this list, you need to edit the ${italic}pinned_npm${reset} variable in ${italic}kymsu.cfg${reset} file."
	echo ""
fi

##################
# Local packages #
##################

# 1. Create package.json file with 'npm init'
#	 or copy packagejson in $local_path
# 2. Install node modules with 'npm install' in $local_path\node_modules

# Local folder exist and not empty (modules installed)
#if [ -d "$local_path/node_modules" ] && [ -n "$(ls -A "$local_path/node_modules")" ]; then


#if find "$local_path/node_modules" -mindepth 1 -maxdepth 1 | read; then
# Subshell: the cd stays local and a failure only skips this section
(
if find "$local_path/node_modules" -mindepth 1 -maxdepth 1 2>/dev/null | read -r _; then

	echo -e "${underline}🌿  Local installed packages:${reset}"

	cd "$local_path" || { echo -e "${red}Cannot enter $local_path !${reset}"; exit 1; }

	if [ "$display_info" = true ]; then
		ll=$(npm ls --long  | grep -v 'git$')
		info_dir=$(mktemp -d)
		# shellcheck disable=SC2046
		fetch_pkg_info "$info_dir" $(tree_pkg_names "$ll")
		x=""

		while IFS= read -r line
		do
			if [[ "$line" == *"──"* ]] || [[ "$line" == *"─┬"* ]]; then
				local_pkg=$(pkg_of_line "$line")
				info_pkg=$(cat "$info_dir/${local_pkg//\//_}" 2>/dev/null)
				q="|     ${info_pkg//$'\n'/$'\n'|     }"	# prefix every line
				x+="${bold}${line}${reset}\n"
				[ -n "$info_pkg" ] && x+="$q\n"
			else
				x+="${line}\n"
			fi
		done <<< "$ll"

		printf '%b\n' "$x"
		rm -rf "$info_dir"

	else
		npm ls
	fi


	echo -e "\n${underline}🌿 Search for local packages update...${reset}\n"
	outdated=$(npm outdated --long | sed '1d')
	if [ -n "$outdated" ]; then
		nb_total=$(echo "$outdated" | wc -l | xargs)
		nb_update=$(count_updatable "$outdated")
		nb_pinned=$((nb_total - nb_update))
		label="available package update"
		[ "$nb_update" -ne 1 ] && label+="s"
		pinned_note=""
		[ "$nb_pinned" -gt 0 ] && pinned_note=" (+ $nb_pinned pinned)"
		echo -e "${redbox} $nb_update ${reset} ${label}${pinned_note}:\n"
		printf '%s\n' "$outdated"

		echo -e "\n${underline}🌿 Updating local packages...${reset}\n"

		while IFS= read -r i
		do
		package=$(echo "$i" | awk '{print $1}')
		current=$(echo "$i" | awk '{print $2}')		# 2.8.3
		wanted=$(echo "$i" | awk '{print $3}')		# 2.8.3
		latest=$(echo "$i" | awk '{print $4}')		# 2.9.0-beta.1

		j=$(echo "$current" | awk -F "." '{print $1}')
		k=$(echo "$latest" | awk -F "." '{print $1}')

		# Package installed from git / linked: not updatable from the registry
		if skip_version "$current" || skip_version "$wanted" || skip_version "$latest"; then
			echo -e "${italic}$package: installed from git/link (current: ${current:-?}, latest: ${latest:-?}), skipped.${reset}"
			continue
		fi

		if [[ " ${npm_do_not_update[*]} " != *" $package "* ]]; then

			# Update major version 1.x.y to 2.x.y
			if [ "$current" = "$wanted" ] && [ "$j" -lt "$k" ] 2>/dev/null; then
				if [ "$no_distract" = false ]; then
					echo "$package@latest" | xargs -p npm install
				else
					echo "$package@latest" | xargs npm install
					#npm install "$package@latest"
				fi
			# Update minor or patch version
			else
				if [ "$no_distract" = false ]; then
					echo "$package" | xargs -p npm update
				else
					echo "$package" | xargs npm update
				fi
			fi

		else
			echo -e "${redbold}$package is pinned to version $current !${reset} Don't update !"
		fi

		done <<< "$outdated"

	else
		echo -e "${italic}No local packages updates.${reset}"
	fi
else
	if [ ! -d "$local_path" ]; then
		echo -e "${italic}No local folder: $local_path does not exist.${reset}"
	else
		echo -e "${italic}No local packages installed in $local_path (node_modules missing or empty).${reset}"
	fi
fi
)

echo ""


###################
# Global packages #
###################

echo -e "${underline}🌿  Global installed packages:${reset}"

if [ "$display_info" = true ]; then
	lg=$(npm list --location=global --depth=0 --long | grep -v 'git$')
	info_dir=$(mktemp -d)
	# shellcheck disable=SC2046
	fetch_pkg_info "$info_dir" $(tree_pkg_names "$lg")
	x=""
	q=""

	while IFS= read -r line
	do
		if [[ "$line" == *"──"* ]]; then
			global_pkg=$(pkg_of_line "$line")
			info_pkg=$(cat "$info_dir/${global_pkg//\//_}" 2>/dev/null)
			q="|     ${info_pkg//$'\n'/$'\n'|     }"	# prefix every line
			x+="${bold}${line}${reset}\n"
			[ -n "$info_pkg" ] && x+="$q\n"
		fi
	done <<< "$lg"

	printf '%b\n' "$x"
	rm -rf "$info_dir"
else
	npm list --location=global --depth=0
fi


#Packages update
echo -e "\n${underline}🌿 Search for global packages update...${reset}\n"

glong_outdated=$(npm outdated --location=global --long | sed '1d')

if [ -n "$glong_outdated" ]; then
	nb_total_global=$(echo "$glong_outdated" | wc -l | xargs)
	nb_update_global=$(count_updatable "$glong_outdated")
	nb_pinned_global=$((nb_total_global - nb_update_global))
	label="available package update"
	[ "$nb_update_global" -ne 1 ] && label+="s"
	pinned_note=""
	[ "$nb_pinned_global" -gt 0 ] && pinned_note=" (+ $nb_pinned_global pinned)"
	echo -e "${redbox} $nb_update_global ${reset} ${label}${pinned_note}:\n"

	printf '%s\n\n' "$glong_outdated"
	echo -e "\n${underline}🌿 Updating global packages...${reset}\n"

	# Disable: Would you like to share anonymous usage data with the Angular Team at Google ?
	if [[ "$glong_outdated" == *angular* ]]; then
		export NG_CLI_ANALYTICS="false"
	fi
	# 15 packages are looking for funding


	while IFS= read -r line
	do
		pkg=$(echo "$line" | awk '{print $1}')
		curr=$(echo "$line" | awk '{print $2}')
		vers=$(echo "$line" | awk '{print $4}')
		outdated_global="$pkg@$vers"

		# Package installed from git / linked: not updatable from the registry
		if skip_version "$curr" || skip_version "$vers"; then
			echo -e "${italic}$pkg: installed from git/link (current: ${curr:-?}, latest: ${vers:-?}), skipped.${reset}"
			continue
		fi

		if [[ " ${npm_do_not_update[*]} " != *" $pkg "* ]]; then

			if [ "$no_distract" = false ]; then
				echo "$outdated_global" | xargs -p -n 1 npm --location=global install
				echo ""
			else
				echo "$outdated_global" | xargs -n 1 npm --location=global install
				echo ""
			fi

		else
			echo -e "${redbold}$pkg is pinned to version $curr !${reset} Don't update !"

		fi

	done <<< "$glong_outdated"

else
	echo -e "${italic}No global packages updates.${reset}"
fi

echo ""


###############
# Maintenance #
###############

if [ "$doctor" = true ]; then
	echo -e "${underline}🌿  The Doc is checking that everything is ok.${reset}\n"

	# If $local_path is not usable, npm doctor runs from the current directory
	doc=$(cd "$local_path" 2>/dev/null || true; npm doctor --no-color)

	# Two output formats exist:
	#  - sections:  "Checking npm version" / "Ok" or "Not ok" / message  (npm 12 and old npm)
	#  - table:     "npm -v   ok|not ok   message"                         (npm 8 to 10)
	re_notok='(^|[[:space:]])[Nn]ot[[:space:]]ok([[:space:]]|$)'
	re_ok='(^|[[:space:]])[Oo]k([[:space:]]|$)'
	while IFS= read -r line
	do
		if [[ "$line" =~ $re_notok ]]; then
			printf '%b%s%b\n' "$red" "$line" "$reset"
		elif [[ "$line" =~ $re_ok ]]; then
			printf '%b%s%b\n' "$green" "$line" "$reset"
		elif [[ "$line" =~ ^Use[[:space:]] ]]; then
			printf '%b%s%b\n' "$cyan" "$line" "$reset"
		else
			printf '%s\n' "$line"
		fi
	done <<< "$doc"


	# Blocks of the npm / node version checks, e.g.:
	#   Checking node version / Not ok / Use node v22.1.0 (current: v22.0.0)   (sections)
	#   node -v   not ok   Use node v22.1.0 (current: v22.0.0)                   (table)
	npm_row=$(grep -A2 'Checking npm version' <<< "$doc"; grep -E '^[[:space:]]*npm -v[[:space:]]' <<< "$doc")
	node_row=$(grep -A2 'Checking node version' <<< "$doc"; grep -E '^[[:space:]]*node -v[[:space:]]' <<< "$doc")
	re_node='[Nn]ot[[:space:]]ok[[:space:]]+Use[[:space:]]node[[:space:]]+v?([0-9][0-9.]*)[[:space:]]+\(current:[[:space:]]*v?([0-9][0-9.]*)\)'
	re_npm='[Nn]ot[[:space:]]ok[[:space:]]+Use[[:space:]]npm[[:space:]]+v?([0-9][0-9.]*)'

	if [[ "$node_row" =~ $re_node ]]; then
		new_node="${BASH_REMATCH[1]}"
		old_node="${BASH_REMATCH[2]}"

		if [ "$new_node" != "$old_node" ] && [ "$update_node" = true ]; then


			if [ "$no_distract" = false ]; then
				echo -e "\nCurrent node: v$old_node. Press \"u\" to update ${bold}node${reset} to ${bold}v$new_node${reset}"
				read -r -s -n 1 c
				if [[ "$c" == [uU] ]]; then
					# List global packages BEFORE switching node (independent of display_info),
					# without npm/corepack, scoped packages included.
					all_global_pkgs=$(npm ls --location=global --depth=0 --json 2>/dev/null | node -e '
						let s = "";
						process.stdin.on("data", d => s += d).on("end", () => {
							try {
								const deps = Object.keys(JSON.parse(s).dependencies || {});
								console.log(deps.filter(p => !["npm", "corepack"].includes(p)).join(" "));
							} catch (e) {}
						});')
					sleep 3

					echo -e "\n${bold}Updating node to v$new_node...${reset}"
					nvm install "$new_node"
					echo -e "\n${bold}Updating npm...${reset}"
					npm --location=global install npm
					#
					nvm use "$new_node"
					echo -e "\n${bold}Reinstall packages from v$old_node...${reset}"
					echo "$all_global_pkgs"
					# nvm reinstall-packages hangs on thumbsup/thumbsup (better-sql)
					# thumbsup is a fork installed from GitHub: see pinned_npm
					#nvm reinstall-packages "$old_node"

					for i in $all_global_pkgs
					do
						if [[ " ${npm_do_not_update[*]} " == *" $i "* ]]; then
							echo -e "${redbold}$i is pinned: reinstall it manually.${reset}"
							continue
						fi
						echo -e "${bold}Reinstalling $i...${reset}"
						npm --location=global install "$i"
					done
				fi
			else
				echo -e "\nNode v$new_node available (current: v$old_node). Not updated in no-distract mode."
			fi

		fi
	fi

	if [[ "$npm_row" =~ $re_npm ]]; then
		new_npm="${BASH_REMATCH[1]}"

		if [ "$new_npm" != "$old_npm" ]; then
			echo -e "${underline}\nUpdate available for npm.${reset}"
			echo -e " - Current: ${red}v$old_npm${reset}"
			echo -e " - Update: ${green}v$new_npm${reset}"
			echo -e "You should run:"
			echo -e " - ${bold}npm --location=global install npm${reset}"
		fi
	fi

	echo ""

	echo "Troubleshooting:"
	echo "https://github.com/nvm-sh/nvm#macos-troubleshooting"
	echo ""

	echo -e "🔍   Verifying npm cache\n"
	npm cache verify
	echo ""
fi

echo ""
