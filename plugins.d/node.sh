#!/usr/bin/env bash

# npm plugin for KYMSU (install local package)
# https://github.com/welcoMattic/kymsu

#########################################
#
# Settings:

# Display info on updated pakages / casks
display_info=true

# No distract mode (no user interaction)

[[ $@ =~ "--nodistract" ]] && no_distract=true || no_distract=false

# Set ls_color to '' for output nvm list in default colors, else '--no-colors'
# ls_color='--no-colors'
# ls_color='BrGcm' for custom colors
# export NVM_COLORS='BrGcm' in .zshrc for persistant custom colors

# Set doctor=true to run 'npm doctor' and 'npm cache verify' each time
doctor=true

# Local install:
# run 'npm init' in local_path to create package.json
local_path=$HOME/Sites/

#########################################

: <<'END_COMMENT'
blabla
END_COMMENT

italic="\033[3m"
underline="\033[4m"
ita_under="\033[3;4m"
bgd="\033[1;4;31m"
red="\033[1;31m"
bold="\033[1m"
bold_ita="\033[1;3m"
box="\033[1;41m"
reset="\033[0m"

upd_nvm() {(
  cd "$NVM_DIR"
  git fetch --tags origin
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
) && \. "$NVM_DIR/nvm.sh"
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


echo -e "${bold}🌿  npm ${reset}"
echo ""

# version courante de node.js
node_v=$(node -v)
node_ins=$(which node)
echo -e "${underline}🌿  node.js:${reset}"
echo -e "     - current version: ${italic}$node_v${reset}"
echo -e "     - install path: ${italic}$node_ins${reset}"

# version courante de npm
npm_v=$(npm -v)
npm_ins=$(which npm)
echo -e "\n${underline}🌿  npm:${reset}"
echo -e "     - current version: ${italic}$npm_v${reset}"
echo -e "     - install path: ${italic}$npm_ins${reset}"

# version installée de nvm par Homebrew
# nvm_installed=$(brew info nvm | grep Cellar)

# version actuelle de nvm sur GitHub
version_nvm=$(git ls-remote --tags --refs --sort="v:refname" git://github.com/nvm-sh/nvm.git | tail -n1 | sed 's/.*\///' | sed 's/v//')

# nvm from github
if [ -f "$NVM_DIR/nvm.sh" ]; then
	source $NVM_DIR/nvm.sh

	# version courante de nvm
	nvm_v=$(nvm --version)
		
	echo -e "\n${underline}🌿  nvm install is:${reset} $NVM_DIR/nvm.sh"
	echo "     - nvm $nvm_v is installed from https://github.com/nvm-sh/nvm"

	if [ -n "$version_nvm" ]; then
		if [ "$nvm_v" != "$version_nvm" ]; then
			echo "Current nvm version on GitHub: $version_nvm"
			echo "Current nvm installed version: $nvm_v"
		
			read -p "Do you want to update nvm from GitHub repo? (y/n)" choice

			if [ "$choice" == "y" ]; then
				echo "Updating nvm from GitHub..."
				#curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v"$version_nvm"/install.sh | bash
			
				upd_nvm
				#curl: native on Catalina, wget installed by homebrew
				#wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
				#curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
			fi
		fi
	fi
	
	node_install=$(nvm list "$ls_color")
	echo -e "\n${underline}🌿  node.js${reset} (installed versions): \n$node_install"

# nvm from homebrew
elif [ -f "/usr/local/opt/nvm/nvm.sh" ]; then
	source $(brew --prefix nvm)/nvm.sh

	# version courante de nvm
	nvm_v=$(nvm --version)
		
	echo -e "\n${underline}🌿  nvm install is:${reset} /usr/local/opt/nvm/nvm.sh"
	echo "nvm $nvm_v is installed from homebrew"

	if [ "$nvm_v" != "$version_nvm" ]; then
		echo "Current nvm version on GitHub: $version_nvm"
		echo "Current nvm installed version: $nvm_v"
		
		echo -e "nvm is outdated ! You should run \033[1;3mbrew update && brew upgrade nvm\033[0m"
		echo -e "or run \033[1;3mKymsu's homebrew.sh script.${reset}"
	fi
		
	node_install=$(nvm list "$ls_color")
	echo -e "\n${underline}🌿  node.js${reset} (installed versions): \n$node_install"

fi

echo -e "${italic}Note:"
echo -e "N/A: version \"10.18.0 -> N/A\" is not yet installed."
echo -e "You need to run \"nvm install 10.18.0\" to install it before using it.${reset}"

echo ""

##################
# Local packages #
##################

if [ -d "$local_path" ]; then
	cd "$local_path" || return
	echo -e "${underline}🌿  Local installed scripts:${reset}"
	
	if [ "$display_info" = true ]; then
		ll=$(npm ls --long  | grep -v 'git$')

		while IFS= read -r line
		do 
			if [[ "${line}" =~ "──" ]] || [[ "${line}" =~ "─┬" ]]; then 
				echo -e "${bold}${line}${reset}"
			else
				echo -e "${line}"
			fi
		done <<< "$ll"
	else
		npm ls
	fi
	

	echo -e "\n${underline}🌿 Search for local packages update...${reset}\n"	
	outdated=$(npm outdated --long | sed '1d')
	if [ -n "$outdated" ]; then
		nb_update=$(echo "outdated" | wc -l | xargs)
		a="available package update"
		array=($a)
		[ "$nb_update" -gt 1 ] && echo -e "${box} $nb_update ${reset} ${array[@]/%/s}:\n" || echo -e "${box} $nb_update ${reset} ${array[@]}:\n"
	
		echo -e "\n${underline}🌿 Updating local packages...${reset}\n"

		if [ "$no_distract" = false ]; then
			echo "$outdated" | awk '{print $1}' | xargs -p -n 1 npm update
		else
			echo "$outdated" | awk '{print $1}' | xargs -n 1 npm update
		fi
		
	else
		echo -e "${italic}No local packages updates.${reset}"
	fi
fi
	
echo ""

###################
# Global packages #
###################

echo -e "${underline}🌿  Global installed scripts:${reset}"

if [ "$display_info" = true ]; then
	lg=$(npm list -g --depth=0 --long | grep -v 'git$')

	while IFS= read -r line
	do 
		if [[ "${line}" =~ "──" ]]; then 
			echo -e "${bold}${line}${reset}"
		else
			echo -e "${line}"
		fi
	done <<< "$lg"
else
	npm list -g --depth=0
fi


#Packages update	
echo -e "\n${underline}🌿 Search for global packages update...${reset}\n"

glong_outdated=$(npm outdated -g --long | sed '1d')

if [ -n "$glong_outdated" ]; then
	nb_update_global=$(echo "$glong_outdated" | wc -l | xargs)
	a="available package update"
	array=($a)
	[ "$nb_update_global" -gt 1 ] && echo -e "${box} $nb_update_global ${reset} ${array[@]/%/s}:\n" || echo -e "${box} $nb_update_global ${reset} ${array[@]}:\n"

	echo -e "$glong_outdated\n"
	echo -e "\n${underline}🌿 Updating global packages...${reset}\n"
	
	# Disable: Would you like to share anonymous usage data with the Angular Team at Google ?
	if [[ " $glong_outdated " =~ "angular" ]]; then 
		export NG_CLI_ANALYTICS="false"
	fi
	# 15 packages are looking for funding
	
	
	while IFS= read -r line
	do 
		pkg=$(echo "$line" | awk '{print $1}')
		vers=$(echo "$line" | awk '{print $4}')
		outdated="$pkg@$vers"

		# TEST
		#version=$(echo "$line" | awk '{print $1 "@" $4}')
		#echo "$version"
		# /test
		
		if [ "$no_distract" = false ]; then
			echo "$outdated" | xargs -p -n 1 npm -g install
			echo ""
		else
			echo "$outdated" | xargs -n 1 npm -g install
			echo ""
		fi

	done <<< "$glong_outdated"

else
	echo -e "${italic}No global packages updates.${reset}"
fi

echo ""

###############
# Maintenance #
###############

if [ "$doctor" = true ]; then
	echo -e "${underline}🌿  The Doc is checking that everything is ok.${reset}\n"
	#npm doctor
	doc=$(npm doctor)

	echo -e "$doc\n"

	npm_v=$(echo "$doc" | grep 'npm -v')
	node_v=$(echo "$doc" | grep 'node -v')

	if [[ " $node_v " =~ " not ok " ]]; then
		no=$(grep -o -E "v([0-9]{1,2}\.){2}[0-9]{1,2}" <<< "$node_v")
		new_node=$(echo "${no:1}" | sed -n '1p')
		old_node=$(echo "${no:1}" | sed -n '$p')
	
		if [ "$new_node" != "$old_node" ]; then

			b=$(echo -e "\nCurrent node: $old_node. Update ${bold}node${reset} to ${bold}$new_node${reset} [y/n] ? ")
			read -e -p "$b" rep2
			if [ "$rep2" == "y" ] || [ "$rep2" == "Y" ]; then
				. $HOME/.nvm/nvm.sh
				echo -e "\n${bold}Updating node to v$new_node...${reset}"
				nvm install $new_node
				echo -e "\n${bold}Updating npm...${reset}"
				npm -g install npm
				#
				nvm use $new_node
				echo -e "\n${bold}Reinstall packages from v$old_node...${reset}"
				nvm reinstall-packages $old_node
			fi
		fi
	fi

	if [[ " $npm_v " =~ " not ok " ]]; then
		np=$(grep -o -E "v([0-9]{1,2}\.){2}[0-9]{1,2}" <<< "$npm_v")
		new_npm=$(echo "${np:1}" | sed -n '1p')
		old_npm=$(echo "${np:1}" | sed -n '$p')

		if [ "$new_npm" != "$old_npm" ]; then
			echo -e "${underline}Udpate available for npm.${reset} You should run:"
			echo -e "  - ${bold}nnpm -g install npm${reset}"
		fi
	fi

	echo ""
	
    echo -e "🔍   Verifying npm cache\n"
    npm cache verify
    echo ""
fi

echo ""
