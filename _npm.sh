#!/usr/bin/env bash

# npm plugin for KYMSU (install local package)
# https://github.com/welcoMattic/kymsu

# Fixing npm On Mac OS X for Homebrew Users
# https://gist.github.com/rcugut/c7abd2a425bb65da3c61d8341cd4b02d
# https://gist.github.com/DanHerbert/9520689

# brew install node
# node -v => 9.11.1
# npm -v => 5.6.0

# npm install -g npm
# npm -v => 5.8.0

# https://github.com/npm/npm/issues/17744

# No distract mode
no_distract=false

local_path=/Users/bruno/Sites/node_modules/

echo -e "\033[1m🌿  npm \033[0m"
echo ""

# Local packages
#cd /Users/bruno/Sites/node_modules/
cd $local_path
echo -e "\033[4mLocal installed scripts:\033[0m"
npm ls
outdated=$(npm outdated)
if [ -n "$outdated" ]; then
	echo "$outdated"
	echo "$outdated" | awk '{print $1}' | xargs npm update
else
	echo -e "\033[4mNo local packages updates.\033[0m"
fi
	
echo ""

# Global packages
echo -e "\033[4mGlobal installed scripts:\033[0m"
npm list -g --depth=0
g_outdated=$(npm outdated -g --depth=0)
if [ -n "$g_outdated" ]; then
	if [ "$no_distract" = false ]; then
		echo "$g_outdated"
		echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -p -n 1  npm install -g 
	else
		echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -n 1  npm install -g
	fi
else
	echo -e "\033[4mNo global packages updates.\033[0m"
fi

if [[ $1 == "--npm_cleanup" ]]; then
	echo "🌬  Cleaning npm cache"
	npm cache clean
	echo ""
fi

echo ""




