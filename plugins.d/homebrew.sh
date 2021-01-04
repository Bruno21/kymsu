#!/usr/bin/env bash

# Homebrew plugin for KYMSU
# https://github.com/welcoMattic/kymsu

###############################################################################################
#
# Settings:

# Display info on updated pakages / casks
display_info=true

# Casks don't have pinned cask. So add Cask to the do_not_update array for prevent to update.
# Also add package for prevent to update whitout pin it.
# declare -a do_not_update=("xnconvert" "yate")
declare -a cask_to_not_update=("xld" "webpquicklook")

# No distract mode (no user interaction)(Casks with 'latest' version number won't be updated)
no_distract=false

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

if [[ $1 == "--nodistract" ]]; then no_distract=true; fi
if [[ $1 == "--latest" ]]; then latest=true; fi

get_info_cask() {
	info="$1"
	app="$2"
	l1=""
	nom=""
	
	token=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.token)')
	name=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.name)' | jq -r '.[0]')
	homepage=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.homepage)')
	url=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.url)')
	desc=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.desc)')
	version=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.version)')
	auto_updates=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.auto_updates)')
	caveats=$(echo "$info" | jq -r '.[] | select(.token == "'${app}'") | (.caveats)')

	installed_versions=$(echo "$upd_cask" | jq -r '.[] | select(.name == "'${app}'") | (.installed_versions)')
	current_version=$(echo "$upd_cask" | jq -r '.[] | select(.name == "'${app}'") | (.current_version)')
	
	if [[ ! " ${casks_not_pinned} " =~ " ${token} " ]]; then
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
	l1=""
	
	name=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.name)')
	full_name=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.full_name)')
	desc=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.desc)')
	homepage=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.homepage)')
	
	#urls=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.urls)' | jq -r '.stable | .url')
	keg_only=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.keg_only)')
	caveats=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.caveats)')
	stable=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.versions)' | jq -r '.stable')
	installed=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.installed)' | jq -r '.[].version')
	pinned=$(echo "$info" | jq -r '.[] | select(.name == "'${pkg}'") | (.pinned)')

	if [ "$pinned" = "true" ]; then 	
		pinned_v=$(echo "$upd_package" | jq -r '.[] | select(.name == "'${pkg}'") | (.pinned_version)')
	
		l1+="${red}$name: installed: $installed stable: $stable [pinned at $pinned_v]"
		[ "$keg_only" = true ] && l1+=" [keg-only]"
		l1+="${reset}\n"
	else 
		l1+="${bold}$name: installed: $installed stable: $stable"
		[ "$keg_only" = true ] && l1+=" [keg-only]"
		l1+="${reset}\n"
	fi
	if [ "$desc" != "null" ]; then l1+="$desc\n"; fi;
	l1+="$homepage"
	
	echo -e "$l1\n"
}

echo -e "${bold}🍺  Homebrew ${reset}"

echo -e "\n🍺 ${underline}Updating brew...${reset}\n"
#brew update

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
upd_pkgs=$(echo "$upd_pkgs" | sed 's/.$//')
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
		#echo $upd_pkgs_info | jq
		for row in $upd_pkgs;
		do
			get_info_pkg "$upd_pkgs_info" "$row"
		done
	else
		#a="available package update"
		#array=($a)
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
echo -e "\n🍺 ${underline}Updating packages...${reset}\n"
[ -n "$upd_pkg_notpinned" ] && echo -e "${red}Pinned: $upd_pkg_pinned . It won't be updated!'${reset}\n"

if [ -n "$upd_pkg_notpinned" ]; then

	if [ "$no_distract" = false ]; then
		a=$(echo -e "Do you wanna run \033[1mbrew upgrade "$upd_pkg_notpinned"\033[0m ? (y/n/a) ")
		# yes/no/all
		read -p "$a" choice

		if [ "$choice" == "y" ] || [ "$choice" == "Y" ] || [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
			for i in $upd_pkg_notpinned;
			do
				if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
					echo "$i" | xargs -p -n 1 brew upgrade --dry-run 
				elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
					echo "$i" | xargs -n 1 brew upgrade --dry-run
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

#############
### Casks ###
#############

#Casks update	
echo -e "\n🍺 ${underline}Casks...${reset}"
upd_cask=$(echo "$brew_outdated" | jq '{casks} | .[]')
#echo "$upd_cask"

#i=0	
for row in $(jq -c '.[]' <<< "$upd_cask");
do
	name=$(echo "$row" | jq -j '.name')
	installed_versions=$(echo "$row" | jq -j '.installed_versions')
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
	
	echo -e "\n${underline}List of${reset} ${box} $nbp ${reset} ${underline}'do not update' packages:${reset}"
	echo -e "${red}${cask_to_not_update[*]}${reset}"
	echo -e "To remove package from this list, you need to edit the ${italic}do_not_update${reset} array."
	echo ""

	casks_not_pinned=""
	for i in $upd_casks
	do
		#echo "$i"
		if [[ ! " ${cask_to_not_update[@]} " =~ " ${i} " ]]; then
			#echo "$i"
   			casks_not_pinned+="$i "
		fi
	done
	casks_not_pinned=$(echo "$casks_not_pinned" | sed 's/.$//')

	casks_latest_not_pinned=""
	for i in $upd_casks_latest
	do
		#echo "$i"
		if [[ ! " ${cask_to_not_update[@]} " =~ " ${i} " ]]; then
			#echo "$i"
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

# Find infos about updated casks
nb_casks_upd=$(echo "$upd_casks" | wc -w | xargs)
if [ "$nb_casks_upd" -gt 0 ]; then
	a="available cask update"
	array=($a)
	if [ "$display_info" = true ]; then
		[ "$nb_casks_upd" -gt 1 ] && echo -e "${box} $nb_casks_upd ${reset} ${array[@]/%/s}:\n" || echo -e "${box} $nb_casks_upd ${reset} ${array[@]}:\n"
		upd_casks_info=$(brew info --json=v2 $upd_casks | jq '{casks} | .[]')
		#echo "$upd_casks_info" | jq
		for row in $upd_casks;
		do
			get_info_cask "$upd_casks_info" "$row"
		done
	else
		[ "$nb_casks_upd" -gt 1 ] && echo -e "${box} $nb_casks_upd ${reset} ${array[@]/%/s}: ${bold}$upd_casks${reset}" || echo -e "${box} $nb_casks_upd ${reset} ${array[@]}: ${bold}$upd_casks${reset}"
	fi
fi

# Updating casks
echo -e "\n🍺 ${underline}Updating casks...${reset}\n"
[ -n "$casks_not_pinned" ] && echo -e "${red}Do not update: ${cask_to_not_update[@]} . It won't be updated!'${reset}\n"
[ -n "$casks_latest_not_pinned" ] && echo -e "Some Casks have ${italic}auto_updates true${reset} or ${italic}version :latest${reset}. Homebrew Cask cannot track versions of those apps."
[ -n "$casks_latest_not_pinned" ] && echo -e "Edit this script and change the setting ${italic}latest=false${reset} to ${italic}true${reset}\n"


if [ -n "$casks_not_pinned" ]; then

	if [ "$no_distract" = false ]; then
		a=$(echo -e "Do you wanna run ${bold}brew upgrade $casks_not_pinned${reset} ? (y/n/a) ")
		# yes/no/all
		read -p "$a" choice

		if [ "$choice" == "y" ] || [ "$choice" == "Y" ] || [ "$choice" == "a" ] || [ "$choice" == "A" ]; then		
			for i in $casks_not_pinned;
			do
				if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
					echo "$i" | xargs -p -n 1 brew upgrade --dry-run
					echo ""
				elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
					echo "$i" | xargs -n 1 brew upgrade --dry-run
					echo ""
				fi
			done
		else
			echo -e "OK, let's continue..."
		fi
	else
		#echo "No distract"
		echo "$casks_not_pinned" | xargs -n 1 brew upgrade --dry-run
	fi

else
	echo -e "\n${italic}No update cask available...${reset}\n"
fi


# Updating casks latest
if [ -n "$casks_latest_not_pinned" ] && [ "$latest" == true ]; then
	echo -e "\n🍺 ${underline}Updating casks with 'latest' as version...${reset}\n"
	echo -e "Some Casks have ${italic}auto_updates true${reset} or ${italic}version :latest${reset}. Homebrew Cask cannot track versions of those apps."
	echo -e "Here you can force Homebrew to upgrade those apps.\n"
	
	if [ "$no_distract" = false ]; then
		q=$(echo -e "Do you wanna run ${bold}brew upgrade $casks_latest_not_pinned${reset} ? (y/n/a) ")
		read -p "$q" choice

		if [ "$choice" == "y" ] || [ "$choice" == "Y" ] || [ "$choice" == "a" ] || [ "$choice" == "A" ]; then

			for i in $casks_latest_not_pinned
			do
				if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
					echo "$i" | xargs -p -n 1 brew upgrade --dry-run
					echo ""
				elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
					echo "$i" | xargs -n 1 brew upgrade --dry-run
					echo ""
				fi
			done

		else
			echo -e "OK, let's continue..."
		fi

	else
		#echo "No distract"
		echo -e "Running ${bold}brew upgrade $casks_latest_not_pinned${reset}..."
		echo "$casks_latest_not_pinned" | xargs -n 1 brew upgrade --dry-run
	fi
fi

##############
### Doctor ###
##############

echo -e "\n🍺 ${underline}The Doc is checking that everything is ok...${reset}\n"

#brew doctor

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
