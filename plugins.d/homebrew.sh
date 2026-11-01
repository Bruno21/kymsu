#!/usr/bin/env bash

# Homebrew plugin for KYMSU
# https://github.com/welcoMattic/kymsu


#########################################
#
# Settings:
#  - use kymsu.cfg for configuring options

#SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/.kymsu/plugins.d}"

# shellcheck source=/dev/null
source "$SCRIPTS_DIR/config.shlib"	# load the config library functions

# Display info on updated packages / casks
display_info=true

# Casks don't have pinned cask. So add Cask to the do_not_update array for prevent to update.
pinned_cask="$(config_get pinned_cask)"
read -r -a cask_to_not_update <<< "$pinned_cask"

# No distract mode (no user interaction)(Casks with 'latest' version number won't be updated)
# kymsu2 -s homebrew.sh -n => no_distract=true (false sans l'option)

# Some Casks have auto_updates true or version :latest. Homebrew Cask cannot track versions of those apps.
# 'latest=true' force Homebrew to update those apps.
latest=false

no_distract=false
cleanup=false
OPTIND=1
while getopts "phncs:a-:" opt; do
  case $opt in
    n) no_distract=true;;
    c) cleanup=true;;
    -) case "$OPTARG" in
         nodistract) no_distract=true;;
         cleanup)    cleanup=true;;
         *) ;;
       esac;;
    p|h|s|a) ;;   # gérées par kymsu2, ignorées ici
    *) ;;         # option inconnue : ignorée
  esac
done

bold="$(config_get bold)"
italic="$(config_get italic)"
underline="$(config_get underline)"
red="$(config_get red)"
redbox="$(config_get redbox)"
reset="$(config_get reset)"

###############################################################################################
#
# Require software (brew install):
#	-jq (Lightweight and flexible command-line JSON processor)
#
# Recommended software (brew install):
#	-terminal-notifier (Send macOS User Notifications from the command-line)
#
###############################################################################################

command -v terminal-notifier >/dev/null 2>&1 || { echo -e "You should install ${bold}terminal-notifier${reset} for notification ${italic}(brew install terminal-notifier)${reset}.\n"; }
command -v jq >/dev/null 2>&1 || { echo -e "${bold}kymsu2${reset} requires ${bold}jq${reset} but it's not installed.\nRun ${italic}(brew install jq)${reset}\nAborting..." >&2; exit 1; }

# Internet connection test
if ! curl -fsI --max-time 5 -o /dev/null https://www.apple.com; then
  echo -e "\n${red}No Internet connection !${reset}"
  echo -e "Exit !"
  exit 1
fi

notification() {
	local sound title message image
	sound="Basso"
	title="Homebrew"
	#subtitle="Attention !!!"
	message="$1"
	image="$SCRIPTS_DIR/error.png"

	if [[ "$OSTYPE" == "darwin"* ]] && [ -x "$(command -v terminal-notifier)" ]; then
    	terminal-notifier -title "$title" -message "$message" -sound "$sound" -contentImage "$image"
	fi
}

skip_bash() {
	[ "$1" = "bash" ] || return 1
	echo -e "\nBash update available ! Run ${bold}brew upgrade bash${reset} in another terminal.\n"
}

get_info_cask() {
	local info="$1" app="$2" l1=""
	local token name homepage desc installed_versions current_version

	#token=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.token)')
	#name=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.name)' | jq -r '.[0]')
	#homepage=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.homepage)')
	#url=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.url)')
	#desc=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.desc)')
	#version=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.version)')
	#auto_updates=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.auto_updates)')
	#caveats=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.caveats)')
	#installed_versions=$(echo "$upd_cask" | jq -r '.[] | select(.name == "'${app}'") | (.installed_versions)' | jq -r '.[]')
	#current_version=$(echo "$upd_cask" | jq -r '.[] | select(.name == "'${app}'") | (.current_version)')

	#auto_updates=$(jq -r --arg app "$app" '.[] | select(.token == $app) | .auto_updates' <<< "$info")
	#caveats=$(jq -r --arg app "$app" '.[] | select(.token == $app) | .caveats' <<< "$info")
	token=$(jq -r --arg app "$app" '.[] | select(.token == $app) | .token' <<< "$info")
	name=$(jq -r --arg app "$app" '.[] | select(.token == $app) | .name[0]' <<< "$info")
	homepage=$(jq -r --arg app "$app" '.[] | select(.token == $app) | .homepage' <<< "$info")
	#url=$(jq -r --arg app "$app" '.[] | select(.token == $app) | .url' <<< "$info")
	desc=$(jq -r --arg app "$app" '.[] | select(.token == $app) | .desc' <<< "$info")
	#version=$(jq -r --arg app "$app" '.[] | select(.token == $app) | .version' <<< "$info")
	current_version=$(jq -r --arg app "$app" '.[] | select(.name == $app) | .current_version' <<< "$upd_cask")
	installed_versions=$(jq -r --arg app "$app" '.[] | select(.name == $app) | .installed_versions | join(", ")' <<< "$upd_cask")

	[[ "$desc" = "null" ]] && desc="${italic}No description${reset}"

	if [[ " ${casks_not_pinned} " != *" ${token} "* ]] && [[ " ${casks_latest_not_pinned} " != *" ${token} "* ]]; then
		l1+="${red}$name ($token): installed: $installed_versions current: $current_version  [Do not update]${reset}\n"
	else
		l1+="${bold}$name ($token): installed: $installed_versions current: $current_version${reset}\n"
	fi
	l1+="$desc\n"
	l1+="$homepage"

	echo -e "$l1\n"
}


get_info_pkg() {
	local info="$1" pkg2="$2" pkg="${2##*/}" l1=""
	local name desc homepage keg_only pinned installed current_version pinned_v

	#urls=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.urls)' | jq -r '.stable | .url')
	#stable=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.versions)' | jq -r '.stable')
	#installed=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.installed)' | jq -r '.[].version')

	#name=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.name)')
	#full_name=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.full_name)')
	#desc=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.desc)')
	#homepage=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.homepage)')
	#keg_only=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.keg_only)')
	#caveats=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.caveats)')
	#pinned=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.pinned)')
	#installed_versions=$(echo "$upd_package" | jq -r '.[] | select(.name == "'${pkg2}'") | (.installed_versions)' | jq -r '.[]')
	#current_version=$(echo "$upd_package" | jq -r '.[] | select(.name == "'${pkg2}'") | (.current_version)')

	#urls=$(jq -r --arg pkg "$pkg" '.[] | select(.name == $pkg) | .urls' | jq -r '.stable | .url' <<< "$info")
	#stable=$(jq -r --arg pkg "$pkg" '.[] | select(.name == $pkg) | .versions' | jq -r '.stable' <<< "$info")
	#installed=$(jq -r --arg pkg "$pkg" '.[] | select(.name == $pkg) | .installed' | jq -r '.[].version' <<< "$info")

	name=$(jq -r --arg pkg "$pkg" '.[] | select(.name == $pkg) | .name' <<< "$info")
	#full_name=$(jq -r --arg pkg "$pkg" '.[] | select(.name == $pkg) | .full_name' <<< "$info")
	desc=$(jq -r --arg pkg "$pkg" '.[] | select(.name == $pkg) | .desc' <<< "$info")
	homepage=$(jq -r --arg pkg "$pkg" '.[] | select(.name == $pkg) | .homepage' <<< "$info")
	keg_only=$(jq -r --arg pkg "$pkg" '.[] | select(.name == $pkg) | .keg_only' <<< "$info")
	#caveats=$(jq -r --arg pkg "$pkg" '.[] | select(.name == $pkg) | .caveats' <<< "$info")
	pinned=$(jq -r --arg pkg "$pkg" '.[] | select(.name == $pkg) | .pinned' <<< "$info")
	installed=$(jq -r --arg pkg "$pkg2" '.[] | select(.name == $pkg) | .installed_versions[-1]' <<< "$upd_package")
	current_version=$(jq -r --arg pkg "$pkg2" '.[] | select(.name == $pkg) | .current_version' <<< "$upd_package")

	if [ "$pinned" = "true" ]; then
		#pinned_v=$(echo "$upd_package" | jq -r '.[] | select(.name == "'${pkg}'") | (.pinned_version)')
		pinned_v=$(jq -r --arg pkg "$pkg2" '.[] | select(.name == $pkg) | .pinned_version' <<< "$upd_package")

		l1+="${red}$name: installed: $installed stable: $current_version [pinned at $pinned_v]"
		[ "$keg_only" = true ] && l1+=" [keg-only]"
		l1+="${reset}\n"
	else
		l1+="${bold}$name: installed: $installed stable: $current_version"
		[ "$keg_only" = true ] && l1+=" [keg-only]"
		l1+="${reset}\n"
	fi
	if [ "$desc" != "null" ]; then l1+="$desc\n"; fi
	l1+="$homepage"

	echo -e "$l1\n"
}


echo -e "${bold}🍺  Homebrew ${reset}"

echo -e "\n🍺 ${underline}Updating brew...${reset}\n"
brew update

echo ""
brew_outdated=$(brew outdated --greedy --json=v2) || exit 1


################
### Packages ###
################

# Packages update:
echo -e "\n🍺 ${underline}Search for packages update...${reset}\n"
upd_package=$(echo "$brew_outdated" | jq '{formulae} | .[]')


upd_package=$(jq '{formulae} | .[]' <<< "$brew_outdated")
upd_pkgs=$(jq -r '[.[].name] | join(" ")' <<< "$upd_package")
upd_pkg_pinned=$(jq -r '[.[] | select(.pinned == true) | .name] | join(" ")' <<< "$upd_package")
upd_pkg_notpinned=$(jq -r '[.[] | select(.pinned == false) | .name] | join(" ")' <<< "$upd_package")
nb_pkg_upd=$(jq 'length' <<< "$upd_package")



# Find infos about updated packages
label="available package update"
[ "$nb_pkg_upd" -gt 1 ] && label+="s"

if [ "$nb_pkg_upd" -gt 0 ]; then
	if [ "$display_info" = true ]; then
		echo -e "${redbox} $nb_pkg_upd ${reset} ${label}:\n"
		# shellcheck disable=SC2086
		upd_pkgs_info=$(brew info --json=v2 $upd_pkgs | jq '{formulae} | .[]')
		for row in $upd_pkgs;
		do
			get_info_pkg "$upd_pkgs_info" "$row"
		done
	else
		echo -e "${redbox} $nb_pkg_upd ${reset} ${label}: ${bold}$upd_pkgs${reset}"
	fi
fi

# Pinned packages
pkg_pinned=$(brew list --pinned | xargs)
if [ -n "$pkg_pinned" ]; then

	nbp=$(echo "$pkg_pinned" | wc -w | xargs)

	echo -e "\n${underline}List of${reset} ${redbox} $nbp ${reset} ${underline}pinned packages:${reset}"
	echo -e "${red}$pkg_pinned${reset}"
	echo "To update a pinned package, you need to un-pin it manually (brew unpin <formula>)"
	echo ""

fi

### Usefull for notify recent modification of apache/mysql/php conf files. ###
touch "${TMPDIR:-/tmp}/kymsu_checkpoint"

# Updating packages
if [ -n "$upd_pkg_notpinned" ]; then

	echo -e "\n🍺 ${underline}Updating packages...${reset}\n"

	[ -n "$upd_pkg_pinned" ] && echo -e "${red}Pinned: $upd_pkg_pinned . It won't be updated!${reset}\n"

	if [ "$no_distract" = false ]; then
		a=$(echo -e "Do you wanna run ${bold}brew upgrade $upd_pkg_notpinned${reset} ? (y/n/a) ")
		# yes/no/all
		read -r -p "$a" choice

		case "$choice" in
			[yYaA])
				for i in $upd_pkg_notpinned; do
					skip_bash "$i" && continue
					case "$choice" in
						[yY]) echo "$i" | xargs -p -n 1 brew upgrade ;;   # confirmation paquet par paquet
						[aA]) brew upgrade "$i" ;;
					esac
				done
				;;
			*)
				echo -e "OK, let's continue..."
				;;
		esac
	else
		#echo "No distract"
		echo -e "Running ${bold}brew upgrade $upd_pkg_notpinned${reset}..."
		for i in $upd_pkg_notpinned; do
			skip_bash "$i" && continue
			brew upgrade "$i"
		done
	fi

else
	echo -e "\n${italic}No update package available...${reset}\n"
fi

echo ""




#############
### Casks ###
#############

#Casks update
echo -e "\n🍺 ${underline}Casks...${reset}\n"
upd_cask=$(echo "$brew_outdated" | jq '{casks} | .[]')

upd_casks=$(jq -r '[.[] | select(.current_version != "latest") | .name] | join(" ")' <<< "$upd_cask")
upd_casks_latest=$(jq -r '[.[] | select(.current_version == "latest") | .name] | join(" ")' <<< "$upd_cask")

# Do not update casks
if (( ${#cask_to_not_update[@]} )); then

	# cask_to_not_update contient 1 cask ET/OU 1 latest

	nbp=${#cask_to_not_update[*]}

	echo -e "${underline}List of${reset} ${redbox} $nbp ${reset} ${underline}'do not update' casks:${reset}"
	echo -e "${red}${cask_to_not_update[*]}${reset}"
	echo -e "To add/remove an app from this list, you need to edit the ${italic}pinned_cask${reset} variable in kymsu.cfg file."
	echo ""

	casks_not_pinned=""
	for i in $upd_casks
	do
		if [[ " ${cask_to_not_update[*]} " != *" ${i} "* ]]; then
   			casks_not_pinned+="$i "
		fi
	done
	casks_not_pinned="${casks_not_pinned% }"

	casks_latest_not_pinned=""
	for i in $upd_casks_latest
	do
		if [[ " ${cask_to_not_update[*]} " != *" ${i} "* ]]; then
   			casks_latest_not_pinned+="$i "
		fi
	done
	casks_latest_not_pinned="${casks_latest_not_pinned% }"

else
	casks_not_pinned=$upd_casks
	casks_latest_not_pinned=$upd_casks_latest
fi

#Casks update
echo -e "🍺 ${underline}Search for casks update...${reset}\n"

[ -n "$casks_latest_not_pinned" ] && echo -e "Some Casks have ${italic}auto_updates true${reset} or ${italic}version :latest${reset}. Homebrew Cask cannot track versions of those apps."
[ -n "$casks_latest_not_pinned" ] && echo -e "Edit this script and change the setting ${italic}latest=false${reset} to ${italic}true${reset}\n"

# Find infos about updated casks
nb_casks_upd=$(echo "$upd_casks" | wc -w | xargs)
label="available cask update"
[ "$nb_casks_upd" -gt 1 ] && label+="s"

if [ "$nb_casks_upd" -gt 0 ]; then
	if [ "$display_info" = true ]; then
		echo -e "${redbox} $nb_casks_upd ${reset} ${label}:\n"
		# shellcheck disable=SC2086
		upd_casks_info=$(brew info --cask --json=v2 $upd_casks | jq '{casks} | .[]')
		for row in $upd_casks;
		do
			get_info_cask "$upd_casks_info" "$row"
		done
	else
		echo -e "${redbox} $nb_casks_upd ${reset} ${label}: ${bold}$upd_casks${reset}"
	fi


	# Updating casks
	echo -e "\n🍺 ${underline}Updating casks...${reset}\n"

	[ "${#cask_to_not_update[*]}" -gt 0 ] && echo -e "${red}Do not update: ${cask_to_not_update[*]} . It won't be updated!${reset}\n"


	if [ -n "$casks_not_pinned" ]; then

		if [ "$no_distract" = false ]; then
			a=$(echo -e "Do you wanna run ${bold}brew upgrade $casks_not_pinned${reset} ? (y/n/a) ")
			# yes/no/all
			read -r -p "$a" choice

			case "$choice" in
			[yYaA])
				for i in $casks_not_pinned; do
					# --cask required for Cask like 'docker'. It can be a formula or a cask.
					case "$choice" in
						[yY]) echo "$i" | xargs -p -n 1 brew upgrade --cask ;;   # confirmation cask par cask
						[aA]) brew upgrade --cask "$i" ;;
					esac
					echo ""
				done
				;;
			*)
				echo -e "OK, let's continue..."
				;;
			esac

		else
			echo "$casks_not_pinned" | xargs -n 1 brew upgrade --cask
		fi
	fi

else
	echo -e "\n${italic}No update cask available...${reset}\n"
fi


# Updating casks latest
if [ -n "$casks_latest_not_pinned" ] && [ "$latest" = true ]; then
	echo -e "\n🍺 ${underline}Updating casks with 'latest' as version...${reset}\n"
	#echo -e "Some Casks have ${italic}auto_updates true${reset} or ${italic}version :latest${reset}. Homebrew Cask cannot track versions of those apps."
	#echo -e "Here you can force Homebrew to upgrade those apps.\n"

	# Find infos about updated casks
	nb_casks_latest_upd=$(echo "$upd_casks_latest" | wc -w | xargs)

	if [ "$nb_casks_latest_upd" -gt 0 ]; then
		label="available cask update"
		[ "$nb_casks_latest_upd" -gt 1 ] && label+="s"
		if [ "$display_info" = true ]; then
			echo -e "${redbox} $nb_casks_latest_upd ${reset} ${label}:\n"
			# shellcheck disable=SC2086
			upd_casks_latest_info=$(brew info --cask --json=v2 $upd_casks_latest | jq '{casks} | .[]')
			for row in $upd_casks_latest;
			do
				get_info_cask "$upd_casks_latest_info" "$row"
			done

		else
			echo -e "${redbox} $nb_casks_latest_upd ${reset} ${label}: ${bold}$upd_casks_latest${reset}"
		fi
	fi

	if [ "$no_distract" = false ]; then
		q=$(echo -e "Do you wanna run ${bold}brew upgrade $casks_latest_not_pinned${reset} ? (y/n/a) ")
		read -r -p "$q" choice

			case "$choice" in
			[yYaA])
				for i in $casks_latest_not_pinned; do
					# --cask required for Cask like 'docker'. It can be a formula or a cask.
					case "$choice" in
						[yY]) echo "$i" | xargs -p -n 1 brew upgrade --cask ;;   # confirmation cask par cask
						[aA]) brew upgrade --cask "$i" ;;
					esac
					echo ""
				done
				;;
			*)
				echo -e "OK, let's continue..."
				;;
			esac

	else
		echo -e "Running ${bold}brew upgrade $casks_latest_not_pinned${reset}..."
		echo "$casks_latest_not_pinned" | xargs -n 1 brew upgrade --cask
	fi
fi


###############################################################
### Test if Apache conf file has been modified by Homebrew  ###
###                   (Apache, PHP or Python updates)       ###
###############################################################

if command -v httpd >/dev/null 2>&1; then
	v_apa=$(httpd -V 2>/dev/null | grep 'SERVER_CONFIG_FILE')
	conf_apa=$(echo "$v_apa" | awk -F '"' '{print $2}')
	apa_dir=$(dirname "$conf_apa")
	apa_name=$(basename "$conf_apa")
	notif1="$apa_dir has been modified in the last 5 minutes"

	apa_modified=$(find "$apa_dir" -maxdepth 1 -name "$apa_name" -mmin -5)

	#echo "$test"

	[ -n "$apa_modified" ] && echo -e "\033[1;31m❗️ ️$notif1\033[0m"
	[ -n "$apa_modified" ] && notification "$notif1"
fi

# Test if PHP.ini file has been modified by Homebrew (PECL)

# Fichier php.ini courant
# php -i | grep 'Loaded Configuration File' | awk '{print $NF}'

php_versions=$(ls "$(brew --prefix)"/etc/php/ 2>/dev/null)
for php in $php_versions
do
	if [ -n "$upd_pkgs" ]; then

		# file modified since it was last read
		php_modified=$(find "$(brew --prefix)"/etc/php/"$php"/ -name php.ini -newer "${TMPDIR:-/tmp}/kymsu_checkpoint")
		php_ini="$(brew --prefix)/etc/php/$php/php.ini"
		notif2="$php_ini has been modified"

		#echo "$php_modified"

		[ -n "$php_modified" ] && echo -e "\033[1;31m❗️ ️$notif2\033[0m"
		[ -n "$php_modified" ] && notification "$notif2"

	fi
done
echo ""


##############
### Doctor ###
##############

echo -e "\n🍺 ${underline}The Doc is checking that everything is ok...${reset}\n"

brew doctor

echo "python-cryptography required by certbot"
echo "python-certifi required by certbot and yt-dlp"
echo "numpy required ffmpeg and openvin"
# suprimer: python-packaging python-argcomplete

brew missing
status=$?
if [ $status -ne 0 ]; then brew missing --verbose; fi
echo ""

# Homebrew 2.0.0+ run a cleanup every 30 days

if [ "$cleanup" = true ]; then
  echo -e "🍺  Cleaning brewery..."

  #HOMEBREW_NO_INSTALL_CLEANUP

  brew cleanup --prune=30
  echo ""
fi

echo ""
