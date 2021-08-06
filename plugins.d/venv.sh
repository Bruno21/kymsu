#!/usr/bin/env bash

# Perl plugin for KYMSU
# https://github.com/welcoMattic/kymsu

###############################################################################################
#
# Settings:

# Liste des apps:
# 	- le venv doit avoir le même nom que l'app
declare -a apps=("soco-cli" "mkdocs")

# Liste des extensions pour Mkdocs
mkdocs_ext=("mkdocs-material" "mkdocs-material-extensions" "mkdocs-git-revision-date-localized-plugin" "mkdocs-minify-plugin" "fontawesome_markdown" "mkdocs-pdf-export-plugin")

echo -e "${bold}🐍  Update apps in Python virtuals environments ${reset}\n"

# Où sont stockés les environnements virtuels:
# macos: silverbook / airbook
if [[ "$OSTYPE" == "darwin"* ]]; then
	v=$HOME/Documents/venv

# rpi4: linux_gnueabihf
# rpi3:
# solus: linux-gnu

elif [[ "$OSTYPE" == "linux_gnu" ]]; then
	v=$HOME/Applications

elif [[ "$OSTYPE" == "linux_gnueabihf" ]]; then
	v=$HOME/venv
fi
#
###############################################################################################

italic="\033[3m"
underline="\033[4m"
ita_under="\033[3;4m"
bgd="\033[1;4;31m"
red="\033[1;31m"
bold="\033[1m"
box="\033[1;41m"
reset="\033[0m"

for app in ${apps[*]}
do
	echo -e "${bold}Update $app${reset}";
	cd "$v/$app"

	source bin/activate
	python3 -V
	pip3 install -U pip setuptools
	
	pip3 install -U "$app"
	ret=$?
	
	# pas d'update: ret=0
	#[ $ret -eq 0 ] && echo -e "${underline}\nNo update available !\n${reset}"

	if [ $ret -eq 0 ]; then
		echo -e "${underline}\nNo update available !\n${reset}"
	fi
	
	info=$(pip3 show "$app")
	l1=$(echo "$info" | sed -n '1p')
	l1="\\\033[4m$l1\\\033[0m"
	info=$(echo "$info" | sed "1s/.*/$l1/")
	echo -e "$info"
	
<<COMMENT
	# Update all modules:
	pip_outdated=$(pip3 list --outdated --format columns)
	upd=$(echo "$pip_outdated" | sed '1,2d' | awk '{print $1}')
	outdated=""
	for i in $upd
	do
		outdated+="$i "
	done
	outdated=$(echo "$outdated" | sed 's/.$//')
COMMENT
	
	# Update mkdocs plugins & themes:
	if [ $app == "mkdocs" ]; then
		for i in ${mkdocs_ext[*]}
		do
			echo -e "\n${bold}Update $i:${reset}" && pip3 install -U $i
		done
	fi
	deactivate
	
	echo ""
done
