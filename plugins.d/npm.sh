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

# version installée de nvm par Homebrew
nvm_installed=$(brew info nvm | grep Cellar)
# version actuelle de nvm sur GitHub
version_nvm=$(git ls-remote --tags --refs --sort="v:refname" git://github.com/nvm-sh/nvm.git | tail -n1 | sed 's/.*\///' | sed 's/v//')

# github
if [ -f "$NVM_DIR/nvm.sh" ]; then
	source $NVM_DIR/nvm.sh
	# version courante de nvm
	nvm_v=$(nvm --version)
	#echo "$nvm_v,$version_nvm" | tr ',' '\n' | sort -V
	
	echo -e "\033[4m🌿  nvm install is:\033[0m $NVM_DIR/nvm.sh"
	echo "nvm $nvm_v is installed from https://github.com/nvm-sh/nvm"

	if [ "$nvm_v" != "$version_nvm" ]; then
		echo "Current nvm version on GitHub: $version_nvm"
		echo "Current nvm installed version: $nvm_v"
		
		read -p "Do you want to update nvm from GitHub repo? (y/n)" choice

		if [ "$choice" == "y" ]; then
			echo "Updating nvm from GitHub..."
			#curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v"$version_nvm"/install.sh | bash
			
			#curl: native on Catalina, wget installed by homebrew
			#wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
			#curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
		fi
	fi
	
	node_install=$(nvm list)
	echo -e "\033[4m🌿  node.js\033[0m (installed versions): \n$node_install"

# homebrew
elif [ -f "/usr/local/opt/nvm/nvm.sh" ]; then
	source $(brew --prefix nvm)/nvm.sh
	# version courante de nvm
	nvm_v=$(nvm --version)
	echo -e "\033[4m🌿  nvm install is:\033[0m /usr/local/opt/nvm/nvm.sh"
	echo "nvm $nvm_v is installed from homebrew"

	if [ "$nvm_v" != "$version_nvm" ]; then
		echo "Current nvm version on GitHub: $version_nvm"
		echo "Current nvm installed version: $nvm_v"
		
		echo -e "nvm is outdated ! You should run \033[1;3mbrew update && brew upgrade nvm\033[0m"
		echo -e "or run \033[1;3mKymsu's homebrew.sh script\033[0m."
	fi
		
	node_install=$(nvm list)
	echo -e "\033[4m🌿  node.js\033[0m (installed versions): \n$node_install"

fi

echo -e "\033[3mNote:"
echo -e "N/A: version \"10.18.0 -> N/A\" is not yet installed."
echo -e "You need to run \"nvm install 10.18.0\" to install it before using it.\033[0m"

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

#g_outdated=$(npm outdated -g)
g_outdated=$(npm outdated -g --parseable=true)

# => npm ERR! Cannot read property 'length' of undefined -> https://stackoverflow.com/questions/55172700/npm-outdated-g-error-cannot-read-property-length-of-undefined
# /Users/bruno/.nvm/versions/node/v10.16.2/lib/node_modules/npm/lib/outdated.js
# /usr/local/lib/node_modules/npm/lib/outdated.js

# update -> wanted ; install -> latest
if [ -n "$g_outdated" ]; then
	if [ "$no_distract" = false ]; then
		#echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -p -n 1  npm install -g 
		#echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -p -n 1 npm update -g --verbose
		# npm verb outdated not updating @angular/cli because it's currently at the maximum version that matches its specified semver range

		echo "$g_outdated" | cut -d : -f 4 | xargs -p -n 1 npm -g install
		
	else
		#echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -n 1  npm install -g
		#echo "$g_outdated" | sed '1d' | awk '{print $1}' | xargs -n 1 npm update -g
		
		echo "$g_outdated" | cut -d : -f 4 | xargs -n 1 npm -g install
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




