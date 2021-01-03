#!/usr/bin/env bash

# Homebrew plugin for KYMSU
# https://github.com/welcoMattic/kymsu

###############################################################################################
#
# Settings:

# Display info on updated pakages 
display_info=true

# Casks don't have pinned cask. So add Cask to the do_not_update array for prevent to update.
# Also add package for prevent to update whitout pin it.
# declare -a do_not_update=("xnconvert" "yate")
declare -a cask_to_not_update=("xld" "webpquicklook")

# No distract mode (no user interaction)(Casks with 'latest' version number won't be updated)
no_distract=false

# Some Casks have auto_updates true or version :latest. Homebrew Cask cannot track versions of those apps.
# 'latest=true' force Homebrew to update those apps.
latest=true
#
###############################################################################################
#
# Recommended software (brew install):
#	-jq (Lightweight and flexible command-line JSON processor)
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


echo -e "${bold}🍺  Homebrew ${reset}"

echo -e "\n🍺 ${underline}Updating brew...${reset}"
#brew update

echo ""
brew_outdated=$(brew outdated --greedy --json=v2)
	
#echo "\nSearch for brew update...\n"
upd_json=$(echo "$brew_outdated")
#echo "$upd_json"

################
### Packages ###
################

# Packages update:
echo -e "\n🍺 ${underline}Search for packages update...${reset}\n"
upd_package=$(echo "$brew_outdated" | jq '{formulae} | .[]')
#echo "$upd_package"

for row in $(jq -c '.[]' <<< "$upd_package");
do
	name=$(echo "$row" | jq -j '.name')
	installed_versions=$(echo "$row" | jq -j '.installed_versions' | jq -r '.[]')
	current_version=$(echo "$row" | jq -j '.current_version')
	pinned=$(echo "$row" | jq -j '.pinned')
	pinned_version=$(echo "$row" | jq -j '.pinned_version')
		
	echo "$name - $installed_versions - $current_version - $pinned - $pinned_version"
		
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

# Pinned packages
pkg_pinned=$(brew list --formulae --pinned | xargs)
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
					echo "$i"
				elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
					echo "$i"
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
echo -e "\n🍺 ${underline}Search for casks update...${reset}\n"
upd_cask=$(echo "$brew_outdated" | jq '{casks} | .[]')
#echo "$upd_cask"

#i=0	
for row in $(jq -c '.[]' <<< "$upd_cask");
do
	name=$(echo "$row" | jq -j '.name')
	installed_versions=$(echo "$row" | jq -j '.installed_versions')
	current_version=$(echo "$row" | jq -j '.current_version')
	
	#upd_casks+="$name "
	echo "$name - $installed_versions - $current_version"
	
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
	echo -e "To remove package from this list, you need to edit the do_not_update array."
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

# Updating casks
echo -e "\n🍺 ${underline}Updating casks...${reset}\n"
[ -n "$casks_not_pinned" ] && echo -e "${red}Do not update: ${cask_to_not_update[@]} . It won't be updated!'${reset}\n"

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
