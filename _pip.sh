#!/usr/bin/env bash

# pip plugin for KYMSU
# https://github.com/welcoMattic/kymsu

echo "🐍  pip"
echo ""

echo "🐍  update pip3 (Python 3)(Homebrew)"
echo ""
pip3 install --upgrade pip
#pip3 install --upgrade mkdocs
#pip3 install --upgrade mkdocs-material
echo ""

pip3_outdated=$(pip3 list --outdated --format=freeze)
upd3=$(echo $pip3_outdated | tr [:space:] '\n' | awk -F== '{print $1}')

if [ -n "$upd3" ]; then

	echo -e "\033[4mAvailables updates:\033[0m"
	echo $pip3_outdated | tr [:space:] '\n'
	echo ""
	a=$(echo -e "Do you wanna run \033[1mpip3 install --upgrade "$upd3"\033[0m ? (y/n)")

  	read -p "$a" choice
  	case "$choice" in
    	y|Y|o ) echo $upd3 | xargs -p -n 1 pip3 install --upgrade ;;
    	n|N ) echo "Ok, let's continue";;
    	* ) echo "invalid";;
  	esac
  	
else
	echo -e "\033[4mNo availables updates.\033[0m"
fi

echo ""
