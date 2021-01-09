#!/usr/bin/env bash

# gem plugin for KYMSU (install local package)
# https://github.com/welcoMattic/kymsu
# https://guides.rubygems.org/what-is-a-gem/

# No distract mode
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

echo -e "${bold} 💍  Gem (Ruby) ${reset}"

echo ""

gem_outdated=$(gem outdated --local)
upd=$(echo "$gem_outdated" | awk '{print $1}')

if [ -n "$upd" ]; then
	nb=$(echo "$upd" | wc -w | xargs)
	
	echo -e "${redbox} $nb ${reset} ${underline}availables updates:${reset}"
	echo "$gem_outdated"
	echo ""
	
	for i in $upd
		do
	
			if [ "$no_distract" = false ]; then
				echo "$i" | xargs -n 1 gem info
				echo "$i" | xargs -p -n 1 gem update
				echo -e "\n"
			else
				echo "$i" | xargs -n 1 gem update
				echo -e "\n"
			fi
		done	
else
	echo -e "${underline}No gem updates.${reset}"
fi
