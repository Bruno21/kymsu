#!/usr/bin/env bash

# pecl plugin for KYMSU
# https://github.com/welcoMattic/kymsu

# https://pecl.php.net
# Verified by Claude
# The format of the `pecl list-upgrades` command when an update is available has not yet been confirmed: 
# if the output looks incorrect to you at that point, please send me the output.

#########################################
#
# Settings:
#  - use kymsu.cfg for configuring options

#SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/.kymsu/plugins.d}"

# shellcheck source=/dev/null
if [ ! -r "$SCRIPTS_DIR/config.shlib" ]; then
	echo "config.shlib not found in $SCRIPTS_DIR (set SCRIPTS_DIR or check the KYMSU installation)." >&2
	exit 1
fi
# shellcheck source=/dev/null
source "$SCRIPTS_DIR/config.shlib"	# load the config library functions

# No distract mode (no user interaction)
#[[ $@ =~ "--nodistract" ]] && no_distract=true || no_distract=false

# Display PHP informations
display_info=true

# Open PHP info in Safari
#php_info=false

php_info="$(config_get pecl_php_info)"

italic="$(config_get italic)"
ita_under="$(config_get ita_under)"
red="$(config_get red)"
blue="$(config_get blue)"
bold="$(config_get bold)"
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
		c|p|h|s|a) ;;	# managed by kymsu2: ignored here
		*) ;;			# unknown option: ignored
	esac
done

#########################################


notification() {
	local sound="Basso"
	local title="pecl"
	#subtitle="Attention !!!"
	local message="$1"
	local image="error.png"
	local -a args

	if [[ "$OSTYPE" == "darwin"* ]] && [ -x "$(command -v terminal-notifier)" ]; then
		args=(-title "$title" -message "$message" -sound "$sound")
		# the image is optional: only used if the file exists
		[ -f "$image" ] && args+=(-contentImage "$image")
		terminal-notifier "${args[@]}"
	fi
}


# Required commands
for cmd in php pecl brew; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo -e "${red}$cmd is not installed (or not in PATH) !${reset}"
		exit 1
	fi
done

echo -e "${bold}🐘 pecl ${reset}"

echo ""

echo -e "${bold}❗️ plugin en test (beta) ${reset}"
echo ""


version=$(php -r 'echo PHP_VERSION;')	# 8.4.27
v=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')	# 8.4 (short version)
echo -e "${ita_under}${blue}Current PHP version:${reset} ${bold}$version${reset}\n"

# Installed PHP versions (several can coexist, only one is active)
brew_prefix="$(brew --prefix)"
echo -e "${ita_under}${blue}Installed PHP versions:${reset}"
for d in "$brew_prefix"/opt/php "$brew_prefix"/opt/php@*; do
	[ -e "$d" ] || continue
	formula=$(basename "$d")
	if [ "$formula" = "php" ]; then
		# unversioned formula: its version is in the Cellar path (../Cellar/php/8.5.1_1 -> 8.5)
		short=$(basename "$(readlink "$d")")
		short="${short%.*}"
		label="$formula ($short)"
	else
		short="${formula#php@}"
		label="$formula"
	fi
	if [ "$short" = "$v" ]; then
		echo -e "  ${bold}$label [active]${reset}"
	else
		echo "  $label"
	fi
done
echo ""

pecl version


# Internet connection test
if ! curl -fsI --max-time 5 -o /dev/null https://www.apple.com; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi

# Note that all public channels can be synced using "update-channels"
echo -e "\n${ita_under}${blue}Updating all channels...${reset}"
pecl update-channels

#pecl channel-update pecl.php.net
#pecl channel-update pear.php.net


# List Installed Packages In The Default Channel
#pecl_list=$($php_path/pecl list)
# List installed packages from all channels
pecl_list=$(pecl list -a)
echo -e "\n$pecl_list\n"

# Installation imagick:
# https://github.com/Imagick/imagick
#git clone https://github.com/Imagick/imagick
#cd imagick
#phpize && ./configure
#make
#make install

# Installation OpenSwoole
#fatal error: 'pcre2.h' file not found
#ln -s /opt/homebrew/opt/pcre2/include/pcre2.h /opt/homebrew/opt/php@8.4/include/php/ext/pcre/
#ln -s /opt/homebrew/opt/pcre2/include/pcre2.h /opt/homebrew/opt/php@8.5/include/php/ext/pcre/


# true only when at least one extension has really been upgraded
extensions_updated=false

pecl_upgrade=$(pecl list-upgrades)

# Upgrade rows only: first field is a channel ("pecl.php.net"), followed by package,
# local, remote and size. Title, header and "No upgrades available" lines are ignored.
available=$(awk '$1 ~ /^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$/ && NF >= 5' <<< "$pecl_upgrade")

if [ -n "$available" ]; then

	echo -e "${ita_under}${blue}Extensions update:${reset}\n"
	echo "$pecl_upgrade"
	echo ""

	# Each line: channel, package, local, remote, size (read splits the fields)
	while read -r -u 3 channel pkg _
	do
		# Channels are already refreshed by "pecl update-channels" above
		if [ "$channel" = "pecl.php.net" ]; then
			pecl info "$pkg" </dev/null
			echo ""

			do_upgrade=true
			if [ "$no_distract" = false ]; then
				do_upgrade=false
				read -r -p "$(echo -e "Upgrade ${bold}$pkg${reset} ? (y/n) ")" choice
				[ "$choice" = "y" ] && do_upgrade=true
			fi

			if [ "$do_upgrade" = true ]; then
				# </dev/null: pecl takes the default answers, it never waits for input
				if pecl upgrade "$pkg" </dev/null; then
					extensions_updated=true
				else
					echo -e "${red}pecl upgrade $pkg failed.${reset}"
				fi
			else
				echo "Skipped."
			fi
		else
			# Option A (current): only extensions of pecl.php.net are upgraded.
			#
			# Option B (not enabled, untested): also upgrade the PEAR packages of pear.php.net.
			# Replace this message by the same prompt / upgrade block as above, with the
			# package prefixed by its channel:
			#     pecl upgrade "pear/$pkg"
			# (PEAR itself, "pear/PEAR", would deserve its own check.)
			echo -e "${italic}$channel/$pkg: not handled by this script (only pecl.php.net extensions are upgraded).${reset}"
		fi
		echo ""
	done 3<<< "$available"
else
	# warnings or errors printed by pecl (anything but "No upgrades available") stay visible
	other=$(grep -v 'No upgrades available' <<< "$pecl_upgrade")
	[ -z "$other" ] || echo "$other"
	echo -e "${italic}No extensions updates.${reset}\n"
fi


# if extensions are modified, the .ini files in conf.d/ are not modified, only php.ini.

# php.ini was modified less than 5 minutes ago
#v_php=$(php --info | grep -E 'usr.*ini')
v_php=$(php --ini)

conf_php=$(echo "$v_php" | grep 'Loaded Configuration File' | awk '{print $NF}')
dir=$(dirname "$conf_php")
ini_name=$(basename "$conf_php")
notif2="$conf_php was modified in the last 5 minutes"

if [ "$display_info" = true ]; then
	echo -e "${ita_under}${blue}PHP ini files:${reset}"
	echo -e "php.ini path: ${bold}$conf_php${reset}"
	echo -e "Additional ini files:\n$(ls "$dir"/conf.d/*.ini)"
	echo -e "\n${ita_under}${blue}To change php version:${reset} ${italic}$ sphp 7.4${reset}"
	echo -e "  ${italic}•mod-php: https://gist.github.com/rhukster/f4c04f1bf59e0b74e335ee5d186a98e2${reset}"
	echo -e "  ${italic}•php-fpm: https://gist.github.com/rozsival/10289d1e2006c68009ace0478306ecd2${reset}\n"

	if [ "$no_distract" = true ]; then
		# no-distract mode: never open a browser
		[ "$extensions_updated" = true ] && echo -e "Some extensions have been updated (PHP info not opened in no-distract mode).\n"
	elif [ "$extensions_updated" = true ] || [ "$php_info" = true ]; then
		if [ "$extensions_updated" = true ]; then
			echo -e "Some extensions have been updated. Opening PHP info in the browser..."
		else
			echo -e "Opening PHP info in the browser..."
		fi
		open "https://$(hostname)/info.php"
	fi
fi

ini_recent=$(find "$dir" -maxdepth 1 -name "$ini_name" -mmin -5)

if [ -n "$ini_recent" ]; then
	echo -e "${red}❗️ ️$notif2${reset}"
	notification "$notif2"
	echo ""

	if [ -n "$available" ] && [ "$no_distract" = false ]; then
		prompt=$(echo -e "Do you want to edit ${bold}$conf_php${reset} file ? (y/n)")
		read -r -p "$prompt" choice
		if [ "$choice" == "y" ]; then
			# EDITOR may contain arguments (e.g. "code -w") and may be unset
			read -r -a editor_cmd <<< "${EDITOR:-vi}"
			if command -v "${editor_cmd[0]}" >/dev/null 2>&1; then
				"${editor_cmd[@]}" "$conf_php"
			else
				echo -e "${red}Editor '${editor_cmd[0]}' not found. Set the EDITOR variable.${reset}"
			fi
		fi
	fi
fi

echo ""
echo ""
