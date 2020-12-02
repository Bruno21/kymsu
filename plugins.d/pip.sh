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

#version: pip ou pip3
# pip: python3.8 - pip3: python3.9
pip_version=pip
#user: "" or "--user"
user=""
# No distract mode
no_distract=false
#add module to do_not_update array
#declare -a do_not_update=()
declare -a do_not_update=("parso" "asgiref")
#
#########################################

if [[ $1 == "--nodistract" ]]; then
	no_distract=true
fi

if ! [ -x "$(command -v $pip_version)" ]; then
	echo "Error: $pip_version is not installed." >&2
	exit 1
fi

echo -e "\033[1m🐍  $pip_version (Python 3) \033[0m"

echo ""
$pip_version install --upgrade pip
echo ""

if (( ${#do_not_update[@]} )); then

	nbp=${#do_not_update[*]}
	
	echo -e "\033[4mList of\033[0m \033[1;41m $nbp \033[0m \033[4m'do not update' packages:\033[0m"
	echo -e "\033[1;31m${do_not_update[*]}\033[0m"
	echo "To remove package from this list, you need to edit the do_not_update array."
	echo ""

fi

pip_outdated=$($pip_version list --outdated --format columns)
upd=$(echo "$pip_outdated" | sed '1,2d' | awk '{print $1}')

if [ -n "$upd" ]; then

	nb=$(echo "$upd" | wc -w | xargs)

	echo -e "\\033[1;41m $nb \033[0m \033[4mavailables updates:\033[0m"
	#echo $pip3_outdated_freeze | tr [:space:] '\n'
	echo "$pip_outdated"
	echo ""
	
	for i in $upd
		do
			info=$($pip_version show "$i")
			#info=$($pip_version show $i | sed -n 4q)
			#info=$($pip_version show $i | head -5)
			#info=$($pip_version show $i | tail -n +5)
			echo "$info" | head -4
			echo ""
			#echo "$i"
		done

	if [ -x "$(command -v pipdeptree)" ]; then
		echo -e "\033[4mCheck dependancies:\033[0m"
		echo "Be carefull!! This updates can be a dependancie for some modules. Check for any incompatible version."
	fi
	echo ""
	for i in $upd
		do
			if [ -x "$(command -v pipdeptree)" ]; then
				dependencies=$(echo "$i" | xargs pipdeptree -r -p | grep "$upd")
				
				#asgiref==3.2.10
  				#	- Django==3.1.2 [requires: asgiref~=3.2.10]
  				
  				#parso==0.7.1
 				#	 - jedi==0.17.2 [requires: parso>=0.7.0,<0.8.0]

				z=0
				while read -r line; do
					if [[ $line = *"<"* ]]; then
						echo -e "\033[31m$line\033[0m"
					elif [[ $line = *"~="* ]]; then
						echo -e "\033[33m$line\033[0m"
					else
						if [ "$z" -eq 0 ]; then
							echo -e "\033[3m$line\033[0m"
						else
							echo "$line"
						fi
						z=$((z+1))
					fi
				done <<< "$dependencies"
				echo ""
				
			else
				c=$(echo -e "Do you want to install pipdeptree to check dependancies ? (y/n)")
  				read -pr "$c" choice
  				case "$choice" in
    				y|Y|o ) $pip_version install $user pipdeptree ;;
    				n|N ) echo "Ok, let's continue";;
    				* ) echo "invalid";;
  				esac
			
			fi
			
			# If the update is not in the do_not_update array, we install it.
			
			FOUND=`echo ${do_not_update[*]} | grep "$i"`
			if [ "${FOUND}" = "" ] && [ "$no_distract" = false ]; then
			
				b=$(echo -e "Do you wanna run \033[1m$pip_version install $user --upgrade $i\033[0m ? (y/n)")
  				read -p "$b" choice
  				case "$choice" in
    				y|Y|o ) echo "$i" | xargs $pip_version install $user --upgrade ;;
    				n|N ) echo "Ok, let's continue";;
    				* ) echo "invalid";;
  				esac
  				echo ""

			elif  [ "${FOUND}" = "" ]; then
			
				echo "$i" | xargs $pip_version install $user --upgrade
				
			fi			
		done

else
	echo -e "\033[4mNo availables updates.\033[0m"
fi


echo ""
echo -e "🐍  Running \033[1mpip check\033[0m for checking that everything is ok."

$pip_version check

echo ""
echo ""
