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

#########################################
#
# Settings:

# No distract mode (no user interaction)
no_distract=false

if [[ $1 == "--nodistract" ]]; then
	no_distract=true
fi

# Set doctor=true to run 'npm doctor' and 'npm cache verify' each time
doctor=true

# Local install
local_path=$HOME/Sites/node_modules/

#########################################

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

if [ -f "$NVM_DIR/nvm.sh" ]; then
	source $NVM_DIR/nvm.sh
	# version courante de nvm
	nvm_v=$(nvm --version)
	echo -e "\033[4m🌿  nvm install is:\033[0m $NVM_DIR/nvm.sh"
	echo "nvm $nvm_v is installed from https://github.com/nvm-sh/nvm"
	
	node_install=$(nvm list)
	echo -e "\033[4m🌿  node.js\033[0m (installed versions): \n$node_install"

elif [ -f "/usr/local/opt/nvm/nvm.sh" ]; then
	source $(brew --prefix nvm)/nvm.sh
	# version courante de nvm
	nvm_v=$(nvm --version)
	echo -e "\033[4m🌿  nvm install is:\033[0m /usr/local/opt/nvm/nvm.sh"
	echo "nvm $nvm_v is installed from homebrew"
	
	node_install=$(nvm list)
	echo -e "\033[4m🌿  node.js\033[0m (installed versions): \n$node_install"

fi

echo

# Local packages
if [ -d "$local_path" ]; then
	cd "$local_path" || return
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

# => npm ERR! Cannot read property 'length' of undefined -> https://stackoverflow.com/questions/55172700/npm-outdated-g-error-cannot-read-property-length-of-undefined
# /Users/bruno/.nvm/versions/node/v10.16.2/lib/node_modules/npm/lib/outdated.js
# /usr/local/lib/node_modules/npm/lib/outdated.js

# update -> wanted ; install -> latest
if [ -n "$g_outdated" ]; then
	if [ "$no_distract" = false ]; then
		echo "$g_outdated"
		#echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -p -n 1  npm install -g 
		echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -p -n 1 npm update -g
	else
		#echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -n 1  npm install -g
		echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -n 1 npm update -g
	fi
else
	echo -e "\033[4mNo global packages updates.\033[0m"
fi

echo ""

# Maintenance
if [ "$doctor" = true ]; then
	echo "🌿  The Doc is checking that everything is ok."
	npm doctor
	echo ""
	
    echo "🔍   Verifying npm cache"
    npm cache verify
    echo ""
fi

#if [[ $1 == "--npm_cleanup" ]]; then
if [[ $1 == "--cleanup" ]]; then
	echo "npm cache clean"
	# As of npm@5, the npm cache self-heals from corruption issues and data extracted from the cache is guaranteed to be valid. 
	# If you want to make sure everything is consistent, use 'npm cache verify' instead. 
	# On the other hand, if you're debugging an issue with the installer, you can use `npm install --cache /tmp/empty-cache` to use a temporary cache instead of nuking the actual one.
	# If you're sure you want to delete the entire cache, rerun this command with --force.

    if printf '%s\n%s\n' "$(npm --version)" 5.0.0 | sort --version-sort --check=silent; then
        echo "🌿  Cleaning npm cache"
    	npm cache clean
    fi
	echo ""
fi

echo ""




