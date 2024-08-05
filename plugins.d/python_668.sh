#!/usr/bin/env bash

# pip plugin for KYMSU
# https://github.com/welcoMattic/kymsu

# upgrade pip:
# python -m pip install --upgrade pip

# Configurer pip3:
# pip config edit

#########################################
#
# Settings:

# Display info on updated pakages / casks
#[[ $@ =~ "--info" ]] && display_info=false || display_info=true
display_info=true

# No distract mode (no user interaction)
[[ $@ =~ "-nodistract" || $@ =~ "-n" ]] && no_distract=true || no_distract=false

# Display dependancies on updated pakages / casks
#[[ $@ =~ "--depend" ]] && display_depend=false || display_depend=true
display_depend=true

#version: pip ou pip3
# pip: python3.8 - pip3: python3.9
pip_version=pip3
#user: "" or "--user"
user=""

# Add module to the do_not_update array for prevent to update.
#declare -a do_not_update=()
#declare -a do_not_update=("parso" "asgiref")
declare -a do_not_update=("pyee")
#
#########################################

: <<'END_COMMENT'
blabla
END_COMMENT

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

command -v pipdeptree >/dev/null 2>&1 || { echo -e "You shoud intall ${bold}pipdeptree${reset} for checking packages dependancies ${italic}($pip_version install pipdeptree)${reset}.\n"; }
command -v $pip_version >/dev/null 2>&1 || { echo -e "${bold}$pip_version${reset} is not installed." && exit 1; }

echo -e "${bold}🐍  $pip_version (Python 3) ${reset}"

echo ""

echo -e "Current ${underline}Python3${reset} version: $(python3 -V | awk '{print $2}')"
echo -e "Current ${underline}pip3${reset} version: $(pip3 -V)"

#$pip_version install --upgrade pip > /dev/null
echo ""

# Do not update packages
if (( ${#do_not_update[@]} )); then

	nbp=${#do_not_update[*]}
	
	echo -e "${underline}List of${reset} ${redbox} $nbp ${reset} ${underline}'do not update' packages:${reset}"
	echo -e "${redbold}${do_not_update[*]}${reset}"
	echo -e "To remove package from this list, you need to edit the ${italic}do_not_update${reset} array."
	echo ""

fi


curl -Is https://www.apple.com | head -1 | grep 200 1>/dev/null
if [[ $? -eq 1 ]]; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi

#Packages update	
echo -e "🐍 ${underline}Search for packages update...${reset}\n"

pip_outdated=$($pip_version list --outdated --format columns)
upd=$(echo "$pip_outdated" | sed '1,2d' | awk '{print $1}')