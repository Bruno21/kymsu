#!/usr/bin/env bash

# Homebrew plugin for KYMSU
# https://github.com/welcoMattic/kymsu

###############################################################################################
#
# Settings:

# Display info on updated pakages / casks
display_info=true

# Casks don't have pinned cask. So add Cask to the do_not_update array for prevent to update.
# declare -a do_not_update=("xnconvert" "yate")
declare -a cask_to_not_update=()

# No distract mode (no user interaction)(Casks with 'latest' version number won't be updated)
#[[ $@ =~ "--nodistract" ]] && no_distract=true || no_distract=false
[[ $@ =~ "-nodistract" || $@ =~ "-n" ]] && no_distract=true || no_distract=false

# Some Casks have auto_updates true or version :latest. Homebrew Cask cannot track versions of those apps.
# 'latest=true' force Homebrew to update those apps.
latest=false
#
###############################################################################################
#
# Require software (brew install):
#	-jq (Lightweight and flexible command-line JSON processor)
#
# Recommended software (brew install):
#	-terminal-notifier (Send macOS User Notifications from the command-line)
#
###############################################################################################

: <<'END_COMMENT'
blabla
END_COMMENT

italic="\033[3m"
underline="\033[4m"
ita_under="\033[3;4m"
bgd="\033[1;4;31m"
red="\033[1;31m"
bold="\033[1m"
box="\033[1;41m"
reset="\033[0m"

command -v terminal-notifier >/dev/null 2>&1 || { echo -e "You shoud intall ${bold}terminal-notifier${reset} for notification ${italic}(brew install terminal-notifier)${reset}.\n"; }
command -v jq >/dev/null 2>&1 || { echo -e "${bold}kymsu2${reset} require ${bold}jq${reset} but it's not installed.\nRun ${italic}(brew install jq)${reset}\nAborting..." >&2; exit 1; }

notification() {
    sound="Basso"
    title="Homebrew"
    #subtitle="Attention !!!"
	message="$1"
	image="error.png"

	if [[ "$OSTYPE" == "darwin"* ]] && [ -x "$(command -v terminal-notifier)" ]; then
    	terminal-notifier -title "$title" -message "$message" -sound "$sound" -contentImage "$image"
	fi
}

get_info_cask() {
	info="$1"
	app="$2"
	l1=""
	
	token=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.token)')
	name=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.name)' | jq -r '.[0]')
	homepage=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.homepage)')
	url=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.url)')
	desc=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.desc)')
	version=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.version)')
	#auto_updates=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.auto_updates)')
	#caveats=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.caveats)')

	installed_versions=$(echo "$upd_cask" | jq -r '.[] | select(.name == "'${app}'") | (.installed_versions)' | jq -r '.[]')
	current_version=$(echo "$upd_cask" | jq -r '.[] | select(.name == "'${app}'") | (.current_version)')
	
	[[ "$desc" = "null" ]] && desc="${italic}No description${reset}"
	
	if [[ ! " ${casks_not_pinned} " =~ " ${token} " ]] && [[ ! " ${casks_latest_not_pinned} " =~ " ${token} " ]]; then
		l1+="${red}$name ($token): installed: $installed_versions current: $current_version  [Do not update]${reset}\n"
	else
		l1+="${bold}$name ($token): installed: $installed_versions current: $current_version${reset}\n"	
	fi
	l1+="$desc\n"
	l1+="$homepage"
	
	echo -e "$l1\n"
}

get_info_pkg() {
	info="$1"
	pkg="$2"
	pkg2="$2"
	l1=""
	
	#echo "pkg: $pkg"
	if [[ " ${pkg} " =~ "/" ]]; then
		pkg=$(echo "$pkg" | awk -F"/" '{print $NF}')
	fi
	#echo "pkg: $pkg"
	
	name=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.name)')
	#name=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'")')
	full_name=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.full_name)')
	desc=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.desc)')
	homepage=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.homepage)')
	
	#urls=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.urls)' | jq -r '.stable | .url')
	keg_only=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.keg_only)')
	caveats=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.caveats)')
	#stable=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.versions)' | jq -r '.stable')
	#installed=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.installed)' | jq -r '.[].version')
	pinned=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.pinned)')
	#echo -e "installed: $installed\n"
	
	installed_versions=$(echo "$upd_package" | jq -r '.[] | select(.name == "'${pkg2}'") | (.installed_versions)' | jq -r '.[]')
	
	current_version=$(echo "$upd_package" | jq -r '.[] | select(.name == "'${pkg2}'") | (.current_version)')
	#echo -e "installed_versions: $installed_versions\n"
	#echo "stable: $current_version"
	
	#echo "name: $name"
	#echo "desc: $desc"
	
	# Python@3.9 : multiples versions
	ins=""
	for i in $installed_versions
	do
		ins=$i
	done
	installed=$ins

	if [ "$pinned" = "true" ]; then 	
		pinned_v=$(echo "$upd_package" | jq -r '.[] | select(.name == "'${pkg}'") | (.pinned_version)')
	
		l1+="${red}$name: installed: $installed stable: $current_version [pinned at $pinned_v]"
		[ "$keg_only" = true ] && l1+=" [keg-only]"
		l1+="${reset}\n"
	else 
		l1+="${bold}$name: installed: $installed stable: $current_version"
		[ "$keg_only" = true ] && l1+=" [keg-only]"
		l1+="${reset}\n"
	fi
	if [ "$desc" != "null" ]; then l1+="$desc\n"; fi;
	l1+="$homepage"
	
	echo -e "$l1\n"
}

echo -e "${bold}🍺  Homebrew ${reset}"

curl -Is https://www.apple.com | head -1 | grep 200 1>/dev/null
if [[ $? -eq 1 ]]; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi

echo -e "\n🍺 ${underline}Updating brew...${reset}\n"
brew update

echo ""
brew_outdated=$(brew outdated --greedy --json=v2)
	
#echo "\nSearch for brew update...\n"
upd_json=$(echo "$brew_outdated")

################
### Packages ###
################

# Packages update:
echo -e "\n🍺 ${underline}Search for packages update...${reset}\n"
upd_package=$(echo "$brew_outdated" | jq '{formulae} | .[]')

for row in $(jq -c '.[]' <<< "$upd_package");
do
	name=$(echo "$row" | jq -j '.name')
	installed_versions=$(echo "$row" | jq -j '.installed_versions' | jq -r '.[]')
	current_version=$(echo "$row" | jq -j '.current_version')
	pinned=$(echo "$row" | jq -j '.pinned')
	#pinned_version=$(echo "$row" | jq -j '.pinned_version')
		
	upd_pkgs+="$name "
	if [ "$pinned" = true ]; then
		upd_pkg_pinned+="$name "
	elif [ "$pinned" = false ]; then
		upd_pkg_notpinned+="$name "
	fi	
done

#echo "$upd_pkgs"
upd_pkgs=$(echo "$upd_pkgs" | sed 's/.$//')
#echo "$upd_pkgs"
upd_pkg_pinned=$(echo "$upd_pkg_pinned" | sed 's/.$//')
upd_pkg_notpinned=$(echo "$upd_pkg_notpinned" | sed 's/.$//')

# Find infos about updated packages
nb_pkg_upd=$(echo "$upd_pkgs" | wc -w | xargs)
if [ "$nb_pkg_upd" -gt 0 ]; then
	a="available package update"
	array=($a)
	if [ "$display_info" = true ]; then
		[ "$nb_pkg_upd" -gt 1 ] && echo -e "${box} $nb_pkg_upd ${reset} ${array[@]/%/s}:\n" || echo -e "${box} $nb_pkg_upd ${reset} ${array[@]}:\n"
		upd_pkgs_info=$(brew info --json=v2 $upd_pkgs | jq '{formulae} | .[]')
		#echo "$upd_pkgs_info"
		for row in $upd_pkgs;
		do
			#echo "$row"
			get_info_pkg "$upd_pkgs_info" "$row"
		done
	else
		[ "$nb_pkg_upd" -gt 1 ] && echo -e "${box} $nb_pkg_upd ${reset} ${array[@]/%/s}: ${bold}$upd_pkgs${reset}" || echo -e "${box} $nb_pkg_upd ${reset} ${array[@]}: ${bold}$upd_pkgs${reset}"
	fi
fi

# Pinned packages
pkg_pinned=$(brew list --pinned | xargs)
if [ -n "$pkg_pinned" ]; then

	nbp=$(echo "$pkg_pinned" | wc -w | xargs)

	echo -e "\n${underline}List of${reset} ${box} $nbp ${reset} ${underline}pinned packages:${reset}"
	echo -e "${red}$pkg_pinned${reset}"
	echo "To update a pinned package, you need to un-pin it manually (brew unpin <formula>)"
	echo ""

fi

### Usefull for notify recent modification of apache/mysql/php conf files. ###
touch /tmp/checkpoint

# Updating packages
if [ -n "$upd_pkg_notpinned" ]; then

	echo -e "\n🍺 ${underline}Updating packages...${reset}\n"

	[ -n "$pkg_pinned" ] && echo -e "${red}Pinned: $upd_pkg_pinned . It won't be updated!'${reset}\n"

	if [ "$no_distract" = false ]; then
		a=$(echo -e "Do you wanna run ${bold}brew upgrade "$upd_pkg_notpinned"${reset} ? (y/n/a) ")
		# yes/no/all
		read -p "$a" choice

		if [ "$choice" == "y" ] || [ "$choice" == "Y" ] || [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
			for i in $upd_pkg_notpinned;
			do
				if [ "$i" == "bash" ]; then
					echo -e "\nBash update available !"
					echo -e "You should run ${bold}brew upgrade bash${reset} in another terminal !\n"
					continue
				fi
				if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
					echo "$i" | xargs -p -n 1 brew upgrade 
				elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
					echo "$i" | xargs -n 1 brew upgrade
				fi
			done
		else
			echo -e "OK, let's continue..."
		fi
	else
		#echo "No distract"
		echo -e "Running ${bold}brew upgrade $upd_pkg_notpinned${reset}..."
		echo "$upd_pkg_notpinned" | xargs -n 1 brew upgrade
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
# erreur avec PureVPN et plusieurs versions installées.
# parse error: Unfinished string at EOF at line 2, column 0
# parse error: Invalid numeric literal at line 1, column 7

#echo "$upd_cask"

for row in $(jq -c '.[]' <<< "$upd_cask");
do
	name=$(echo "$row" | jq -j '.name')
	installed_versions=$(echo "$row" | jq -j '.installed_versions | .[]')
	current_version=$(echo "$row" | jq -j '.current_version')
	
	if [ "$current_version" != "latest" ]; then
		upd_casks+="$name "
	elif [ "$current_version" == "latest" ]; then
		upd_casks_latest+="$name "
	fi
done
upd_casks=$(echo "$upd_casks" | sed 's/.$//')
upd_casks_latest=$(echo "$upd_casks_latest" | sed 's/.$//')

# Do not update casks
if (( ${#cask_to_not_update[@]} )); then

	# cask_to_not_update contient 1 cask ET/OU 1 latest

	nbp=${#cask_to_not_update[*]}
	
	echo -e "${underline}List of${reset} ${box} $nbp ${reset} ${underline}'do not update' casks:${reset}"
	echo -e "${red}${cask_to_not_update[*]}${reset}"
	echo -e "To remove an app from this list, you need to edit the ${italic}do_not_update${reset} array."
	echo ""

	casks_not_pinned=""
	for i in $upd_casks
	do
		if [[ ! " ${cask_to_not_update[@]} " =~ " ${i} " ]]; then
   			casks_not_pinned+="$i "
		fi
	done
	casks_not_pinned=$(echo "$casks_not_pinned" | sed 's/.$//')

	casks_latest_not_pinned=""
	for i in $upd_casks_latest
	do
		if [[ ! " ${cask_to_not_update[@]} " =~ " ${i} " ]]; then
   			casks_latest_not_pinned+="$i "
		fi
	done
	casks_latest_not_pinned=$(echo "$casks_latest_not_pinned" | sed 's/.$//')

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
if [ "$nb_casks_upd" -gt 0 ]; then
	a="available cask update"
	array=($a)
	if [ "$display_info" = true ]; then
		[ "$nb_casks_upd" -gt 1 ] && echo -e "${box} $nb_casks_upd ${reset} ${array[@]/%/s}:\n" || echo -e "${box} $nb_casks_upd ${reset} ${array[@]}:\n"
		upd_casks_info=$(brew info --cask --json=v2 $upd_casks | jq '{casks} | .[]')
		for row in $upd_casks;
		do
			get_info_cask "$upd_casks_info" "$row"
		done
	else
		[ "$nb_casks_upd" -gt 1 ] && echo -e "${box} $nb_casks_upd ${reset} ${array[@]/%/s}: ${bold}$upd_casks${reset}" || echo -e "${box} $nb_casks_upd ${reset} ${array[@]}: ${bold}$upd_casks${reset}"
	fi


	# Updating casks
	echo -e "\n🍺 ${underline}Updating casks...${reset}\n"

	[ "${#cask_to_not_update[@]}" -gt 0 ] && echo -e "${red}Do not update: ${cask_to_not_update[@]} . It won't be updated!'${reset}\n"


	if [ -n "$casks_not_pinned" ]; then

		if [ "$no_distract" = false ]; then
			a=$(echo -e "Do you wanna run ${bold}brew upgrade $casks_not_pinned${reset} ? (y/n/a) ")
			# yes/no/all
			read -p "$a" choice

			if [ "$choice" == "y" ] || [ "$choice" == "Y" ] || [ "$choice" == "a" ] || [ "$choice" == "A" ]; then		
				echo ""
				for i in $casks_not_pinned;
				do
					if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
						# --cask required for Cask like 'docker'. It can be a formula or a cask.
						echo "$i" | xargs -p -n 1 brew upgrade --cask
						echo ""
					elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
						echo "$i" | xargs -n 1 brew upgrade --cask
						echo ""
					fi
				done
			else
				echo -e "OK, let's continue..."
			fi
		else
			echo "$casks_not_pinned" | xargs -n 1 brew upgrade --cask
		fi
	fi

else
	echo -e "\n${italic}No update cask available...${reset}\n"
fi


# Updating casks latest
if [ -n "$casks_latest_not_pinned" ] && [ "$latest" == true ]; then
	echo -e "\n🍺 ${underline}Updating casks with 'latest' as version...${reset}\n"
	#echo -e "Some Casks have ${italic}auto_updates true${reset} or ${italic}version :latest${reset}. Homebrew Cask cannot track versions of those apps."
	#echo -e "Here you can force Homebrew to upgrade those apps.\n"

	# Find infos about updated casks
	nb_casks_latest_upd=$(echo "$upd_casks_latest" | wc -w | xargs)
	if [ "$nb_casks_latest_upd" -gt 0 ]; then
		a="available cask update"
		array=($a)
		if [ "$display_info" = true ]; then
			[ "$nb_casks_latest_upd" -gt 1 ] && echo -e "${box} $nb_casks_latest_upd ${reset} ${array[@]/%/s}:\n" || echo -e "${box} $nb_casks_latest_upd ${reset} ${array[@]}:\n"

			upd_casks_latest_info=$(brew info --cask --json=v2 $upd_casks_latest | jq '{casks} | .[]')
			for row in $upd_casks_latest;
			do
				get_info_cask "$upd_casks_latest_info" "$row"
			done
		
		else
			[ "$nb_casks_latest_upd" -gt 1 ] && echo -e "${box} $nb_casks_latest_upd ${reset} ${array[@]/%/s}: ${bold}$upd_casks_latest${reset}" || echo -e "${box} $nb_casks_upd ${reset} ${array[@]}: ${bold}$upd_casks_latest${reset}"
		fi
	
	fi
	
	if [ "$no_distract" = false ]; then
		q=$(echo -e "Do you wanna run ${bold}brew upgrade $casks_latest_not_pinned${reset} ? (y/n/a) ")
		read -p "$q" choice

		if [ "$choice" == "y" ] || [ "$choice" == "Y" ] || [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
			echo ""
			for i in $casks_latest_not_pinned
			do
				if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
					echo "$i" | xargs -p -n 1 brew upgrade --cask
					echo ""
				elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
					echo "$i" | xargs -n 1 brew upgrade --cask
					echo ""
				fi
			done

		else
			echo -e "OK, let's continue..."
		fi

	else
		echo -e "Running ${bold}brew upgrade $casks_latest_not_pinned${reset}..."
		echo "$casks_latest_not_pinned" | xargs -n 1 brew upgrade
	fi
fi


###############################################################
### Test if Apache conf file has been modified by Homebrew  ###
###                   (Apache, PHP or Python updates)       ###
###############################################################

v_apa=$(httpd -V | grep 'SERVER_CONFIG_FILE')
conf_apa=$(echo "$v_apa" | awk -F "\"" '{print $2}')
dir=$(dirname $conf_apa)
name=$(basename $conf_apa)
notif1="$dir has been modified in the last 5 minutes"

test=$(find $dir -maxdepth 1 -name "$name" -mmin -5)

echo "$test"

[ ! -z $test ] && echo -e "\033[1;31m❗️ ️$notif1\033[0m"
[ ! -z $test ] && notification "$notif1"

# Test if PHP.ini file has been modified by Homebrew (PECL)

# Fichier php.ini courant
# php -i | grep 'Loaded Configuration File' | awk '{print $NF}'

php_versions=$(ls $(brew --prefix)/etc/php/ 2>/dev/null)
for php in $php_versions
do 	
	if [ -n "$upd_pkg" ]; then

		# file modified since it was last read	
		php_modified=$(find $(brew --prefix)/etc/php/$php/ -name php.ini -newer /tmp/checkpoint)
		php_ini=$(brew --prefix)/etc/php/$php/php.ini
		notif2="$php_ini has been modified"
	
		echo "$php_modified"
	
		[ ! -z $php_modified ] && echo -e "\033[1;31m❗️ ️$notif2\033[0m"
		[ ! -z $php_modified ] && notification "$notif2"
		
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

if [[ $1 == "--cleanup" ]]; then
  echo -e "🍺  Cleaning brewery..."
  
  #HOMEBREW_NO_INSTALL_CLEANUP
  
  brew cleanup --prune=30
  echo ""
fi

echo ""
