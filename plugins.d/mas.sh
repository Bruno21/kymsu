#!/usr/bin/env bash

# Mac Appstore plugin for KYMSU
# https://github.com/welcoMattic/kymsu

# No distract mode (no user interaction)
[[ $@ =~ "--nodistract" ]] && no_distract=true || no_distract=false

italic="\033[3m"
underline="\033[4m"
ita_under="\033[3;4m"
bold="\033[1m"
bold_under="\033[1;4m"
redbox="\033[1;41m"
redbold="\033[1;31m"
red="\033[31m"
yellow="\033[33m"
reset="\033[0m"


echo -e "${bold}🍏  Mac App Store updates come fast as lightning ${reset}"

echo -e "https://github.com/mas-cli/mas"

# On teste si mas est installé
if hash mas 2>/dev/null; then

	massy=$(mas outdated)
	echo ""
	echo "$massy"

	if [ -n "$(mas outdated)" ]; then
		echo -e "${underline}Availables updates:${reset}"
		echo "$massy" | cut -d " " -f2-5
		echo ""
	
		if [ "$no_distract" = false ]; then
	
			a=$(echo -e "Do you wanna run \033[1mmas upgrade${reset} ? (y/n)")
			read -pr "$a" choice
			case "$choice" in
				y|Y|o ) mas upgrade;;
	 		   	n|N ) echo "Ok, let's continue";;
	    		* ) echo "invalid";;
			esac
	
		else
			mas upgrade
		fi
	
	else
		echo -e "${italic}No availables mas updates.${reset}"
	fi
else
	echo -e "Please install mas: ${italic}brew install mas${reset}"
fi

echo ""
echo ""
