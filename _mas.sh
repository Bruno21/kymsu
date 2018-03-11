#!/usr/bin/env bash

# Mac Appstore plugin for KYMSU
# https://github.com/welcoMattic/kymsu

echo "🍏  Mac App Store updates come fast as lightning"
#mas outdated
massy=`mas outdated`
echo ""

if [ -n "$massy" ]; then
#if [ "$massy" != 0 ]; then
	echo -e "\033[4mAvailables updates:\033[0m"
	echo "$massy" | cut -d " " -f2-5
	echo ""
	
	a=$(echo -e "Do you wanna run \033[1mmas upgrade\033[0m ? (y/n)")
	read -p "$a" choice
	case "$choice" in
		y|Y|o ) mas upgrade;;
    	n|N ) echo "Ok, let's continue";;
    	* ) echo "invalid";;
	esac
	
else
	echo -e "\033[4mNo availables mas updates.\033[0m"
fi

echo ""
