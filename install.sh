#!/usr/bin/env bash

italic="\033[3m"
underline="\033[4m"
bold="\033[1m"
reset="\033[0m"

KYMSU_PATH=`pwd`

# Make Kymsu accessible in PATH
echo -e "\nInstalling ${bold}kymsu2${reset} in ${bold}/usr/local/bin${reset} ..."
sudo ln -fs "${KYMSU_PATH}"/kymsu2.sh /usr/local/bin/kymsu2

# Store Kymsu stuff in home directory
mkdir -p $HOME/.kymsu && echo "${KYMSU_PATH}" > $HOME/.kymsu/path

pluginpath=$HOME/.kymsu/plugins.d/

if [ ! -d $pluginpath ]; then new_install=true; fi

# Backup disabled plugins
disabled=$(ls $pluginpath | grep ^_  | sed 's/^_//')

# Delete plugins folder
rm -rf  $pluginpath

# Install new plugins
echo -e "Copying plugins in ${bold}$pluginpath${reset} ..."
cp -R "${KYMSU_PATH}/plugins.d" $HOME/.kymsu

if [ -n "$disabled" ]; then

	echo -e "Disabling previous disabled plugins ..."
	# Disable previous disabled plugins
	for i in $(ls $pluginpath)
	do 
		[[ $disabled =~ $i ]] && mv "$pluginpath$i" "$pluginpath"_"$i"
	done
	
fi

echo -e "\n${bold}altKYMSU${reset} has been installed. Run ${bold}kymsu2${reset} command!"
echo -e "It's a fork from ${italic}https://github.com/welcoMattic/kymsu${reset}"
echo -e "All credits to ${underline}welcoMattic${reset}\n"

# If NEW install, we choose to desactivate some plugins
if [ "$new_install" = true ]; then
	read -p "Do you want to activate / deactivate some plugins ? [y/n]" deactivate
	echo ""
	
	if [[ "$deactivate" == "y" || "$deactivate" == "Y" ]]; then

		for i in $(ls $pluginpath)
		do 
			
			if [[ ${i: -3} == ".sh" ]] && [[ ! ${i:0:2} == "00" ]] && [[ ! ${i:0:1} == "_" ]]; then
			
				a=$(echo -e "Do you want to deactivate ${bold}$i${reset} plugins ? [y/n]")
				read -p "$a" rep
			
				if [[ "$rep" == "y" || "$rep" == "Y" ]]; then
					mv "$pluginpath$i" "$pluginpath"_"$i" && echo -e "${bold}$i${reset} deactivated !"
				fi
			
			fi
			
		done
		
	fi
fi
