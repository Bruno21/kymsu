#!/usr/bin/env bash

# pecl plugin for KYMSU
# https://github.com/welcoMattic/kymsu



echo -e "\033[1m🐘 pecl \033[0m"

echo ""

#upd=$(echo "$pip_outdated" | sed '1,2d' | awk '{print $1}')

list=$(pecl list | sed '1,3d')
pecl_list=$(echo "$list")

if [ -n "$pecl_list" ]; then

	echo -e "\033[4mInstalled extensions:\033[0m"
	echo ""
	echo "$pecl_list"
	
	echo "Installed PECL extensions:" > $HOME/installations.txt
	echo "$pecl_list" >> $HOME/installations.txt
	echo " " >> $HOME/installations.txt
fi

echo ""

upgrade=$(pecl list-upgrades)
pecl_upgrade=$(echo "$upgrade")

if [ -n "$pecl_upgrade" ]; then
	
	echo -e "\033[4mExtensions update:\033[0m"
	echo ""
	echo "$pecl_upgrade"
fi

echo ""
