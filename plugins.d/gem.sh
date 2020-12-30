#!/usr/bin/env bash

# gem plugin for KYMSU (install local package)
# https://github.com/welcoMattic/kymsu
# https://guides.rubygems.org/what-is-a-gem/

# No distract mode
no_distract=false

if [[ $1 == "--nodistract" ]]; then
	no_distract=true
fi

echo -e "\033[1m 💍  Gem (Ruby) \033[0m"

echo ""

gem_outdated=$(gem outdated --local)
upd=$(echo "$gem_outdated" | awk '{print $1}')

if [ -n "$upd" ]; then
	nb=$(echo "$upd" | wc -w | xargs)
	
	echo -e "\\033[1;41m $nb \033[0m \033[4mavailables updates:\033[0m"
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
	echo -e "\033[4mNo gem updates.\033[0m"
fi
