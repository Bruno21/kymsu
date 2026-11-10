#!/usr/bin/env bash

# Uninstall script for KYMSU
# https://github.com/welcoMattic/kymsu
# fork https://github.com/Bruno21/kymsu

bold='\033[1m'
green='\033[32m'
red='\033[31m'
reset='\033[0m'

read -r -p "$(echo -e "\n${bold}Do you want to uninstall altKYMSU ?${reset} (y/n) ")" choice

if [[ "${choice,,}" == "y" ]]; then

	kymsu2_path="$(command -v kymsu2)"
	if [[ -n "$kymsu2_path" ]]; then
		rm -rf "$kymsu2_path"
		echo -e "Removed: $kymsu2_path"
	else
		echo -e "${red}kymsu2 not found in PATH, skipping.${reset}"
	fi

	if [[ -d "$HOME/.kymsu" ]]; then
		rm -rf "$HOME/.kymsu"
		echo -e "Removed: $HOME/.kymsu"
	else
		echo -e "${red}$HOME/.kymsu not found, skipping.${reset}"
	fi

	echo -e "\n${green}altKYMSU has been uninstalled.${reset}\n"
	exit 0

else
	echo -e "\nUninstall cancelled."
	exit 0
fi
