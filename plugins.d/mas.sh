#!/usr/bin/env bash

# Mac Appstore plugin for KYMSU
# https://github.com/welcoMattic/kymsu

echo -e "\033[1m🍏  Mac App Store updates come fast as lightning \033[0m"

# No distract mode (no user interaction)
no_distract=false

if [[ $1 == "--nodistract" ]]; then
	no_distract=true
fi

# On teste si mas est installé
if hash mas 2>/dev/null; then

	massy=$(mas outdated)
	echo ""
	echo "$massy"

	if [ -n "$(mas outdated)" ]; then
		echo -e "\033[4mAvailables updates:\033[0m"
		echo "$massy" | cut -d " " -f2-5
		echo ""
	
		if [ "$no_distract" = false ]; then
	
			a=$(echo -e "Do you wanna run \033[1mmas upgrade\033[0m ? (y/n)")
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
		echo -e "\033[4mNo availables mas updates.\033[0m"
	fi
else
	echo "Please install mas: brew install mas"
fi

echo ""
echo ""
