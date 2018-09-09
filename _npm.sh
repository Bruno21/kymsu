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

doctor=false

# Local install
local_path=/Users/bruno/Sites/node_modules/

echo -e "\033[1m🌿  npm \033[0m"
echo ""

# version courante de node.js
node_v=$(node -v)
echo -e "\033[4m🌿  node.js\033[0m (current version): $node_v"

# version courante de npm
npm_v=$(npm -v)
echo -e "\033[4m🌿  npm\033[0m (current version): $npm_v"

# versions installées de node.js
nvm_installed=$(brew info nvm | grep Cellar)
if [ -n "$nvm_installed" ]; then
	source $(brew --prefix nvm)/nvm.sh
	node_install=$(nvm list)
	echo -e "\033[4m🌿  node.js\033[0m (installed versions): \n$node_install"
fi
echo

# Local packages
if [ -d "$local_path" ]; then
	cd $local_path
	echo -e "\033[4m🌿  Local installed scripts:\033[0m"
	npm ls
	outdated=$(npm outdated)
	if [ -n "$outdated" ]; then
		echo "$outdated"
		echo "$outdated" | awk '{print $1}' | xargs npm update
	else
		echo -e "\033[4mNo local packages updates.\033[0m"
	fi
fi
	
echo ""

# Global packages
echo -e "\033[4m🌿  Global installed scripts:\033[0m"
npm list -g --depth=0
g_outdated=$(npm outdated -g)
# update -> wanted ; install -> latest
if [ -n "$g_outdated" ]; then
	if [ "$no_distract" = false ]; then
		echo "$g_outdated"
		#echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -p -n 1  npm install -g 
		echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -p -n 1  npm update -g 
	else
		#echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -n 1  npm install -g
		echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -n 1  npm update -g
	fi
else
	echo -e "\033[4mNo global packages updates.\033[0m"
fi

echo 

# Maintenance
if [ "$doctor" = true ]; then
	echo "🌿  The Doc is checking that everything is ok."
	npm doctor
fi

if [[ $1 == "--npm_cleanup" ]]; then
	echo "🌿  Cleaning npm cache"
	npm cache clean
	echo ""
fi

echo ""




