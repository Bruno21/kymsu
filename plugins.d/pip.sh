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
[[ $@ =~ "--nodistract" ]] && no_distract=true || no_distract=false

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
declare -a do_not_update=("lunr")
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


#Packages update	
echo -e "🐍 ${underline}Search for packages update...${reset}\n"

pip_outdated=$($pip_version list --outdated --format columns)
upd=$(echo "$pip_outdated" | sed '1,2d' | awk '{print $1}')

# Find infos about updated packages
if [ -n "$upd" ]; then

	nb=$(echo "$upd" | wc -w | xargs)

	echo -e "${redbox} $nb ${reset} ${underline}availables updates:${reset}"
	echo -e "\n$pip_outdated"
	echo ""
	
	for i in $upd
	do
		info=$($pip_version show "$i")
		
		l=$(echo "$info" | sed -n '1p')
		
		if [[ ! " ${do_not_update[@]} " =~ " ${i} " ]]; then
			m=$(sed "1s/.*/\\${bold}$l\\${reset}/" <<< "$info")
		else
			m=$(sed "1s/.*/\\${redbold}$l\\${reset}/" <<< "$info")
		fi
		echo -e "$m"  | head -4
		echo ""
		
		z+="$i "
		
	done
	# z = asgiref setuptools lunr

	# Check dependancies
	if [ -x "$(command -v pipdeptree)" ] && [ "$display_depend" == true ]; then
	
		echo -e "🐍 ${underline}Check dependancies:${reset}\n"
		echo -e "Be carefull!! This updates can be a dependancie for some modules. Check for any incompatible version.\n"
		
		# packages dont on recherche les dépendances (x = asgiref,setuptools,lunr)
		x=$(echo "$z" | sed 's/.$//' | sed 's/ /,/g')
		# on filtre les lignes (y = asgiref|setuptools|lunr)
		y=$(echo "$z" | sed 's/.$//' | sed 's/ /|/g')

		dependencies=$(echo "$x" | xargs pipdeptree -r -p | grep -E $y)
		# if [[ $line =~ $y ]]; then
		
		while IFS= read -r line; do
			z=$(echo "${line}" | grep -i ^[a-z])
			if [ -n "$z" ] ; then
			
				if [[ " ${do_not_update[@]} " =~ " ${line} " ]]; then
					echo -e "\n${bold}${line}${reset}"
				else
					echo -e "\n${redbold}${line}${reset}"
				fi
				
			elif [[ "${line}" = *"<"* ]]; then
				echo -e "${red}${line}${reset}"
			elif [[ "${line}" = *"~="* ]]; then
				echo -e "${yellow}${line}${reset}"
			else
				echo "${line}"
			fi
		done <<< "$dependencies"

	fi


	# Updating packages
	echo -e "\n🐍 ${underline}Updating packages...${reset}\n"

	[ "${#do_not_update[@]}" -gt 0 ] && echo -e "${redbold}Do not update: ${underline}${do_not_update[@]}${reset}${redbold} . It won't be updated!'${reset}\n"
	
	for i in $upd
	do
		if [[ ! " ${do_not_update[@]} " =~ " ${i} " ]]; then
			if [ "$no_distract" = false ]; then

		 		b=$(echo -e "Do you wanna run ${bold}$pip_version install $user --upgrade $i${reset} ? (y/n)")
  				read -p "$b" choice
  				case "$choice" in
    				y|Y|o ) echo "$i" | xargs $pip_version install $user --upgrade ;;
	    			n|N ) echo "Ok, let's continue";;
    				* ) echo "invalid";;
  				esac
  				echo ""

		 	else
				echo "$i" | xargs $pip_version install $user --upgrade
			fi
		fi
	done
	
else
	echo -e "${underline}No availables updates.${reset}"
fi


echo ""
echo -e "🐍 ${underline}Running ${reset}${bold_under}pip check${reset}${underline} for checking that everything is ok...${reset}\n"

$pip_version check

echo ""
echo ""
