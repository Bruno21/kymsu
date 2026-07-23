#!/usr/bin/env bash

italic="\033[3m"
underline="\033[4m"
ita_under="\033[3;4m"
bgd="\033[1;4;31m"
red="\033[1;31m"
greenbold="\033[1;32m"
bold="\033[1m"
box="\033[1;41m"
reset="\033[0m"

echo -e "\n${bold}🦀 Rust${reset}\n"

curl -Is https://www.apple.com | head -1 | grep 200 1>/dev/null
if [[ $? -eq 1 ]]; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi

if hash rustup 2>/dev/null; then

	echo -e "🦀 ${underline}rustup check${reset}\n"
	#rustup check
	check=$(rustup check)
	#check=$(echo "$check" | sed 's/Up\ to\ date/${bold}Up\ to\ dateee${reset}/g')
	#echo ${check/Up to date/\{greenbold\}Up to dateee\{reset\}\}
	#Update available
	echo -e "$check\n"
	
	if [[ "$check" =~ "update\ available" ]]; then 
		echo -e "🦀 ${underline}rustup update${reset}\n"
		rustup update
	fi
	
	#if [[ ! $(which rustup-init) =~ "homebrew" ]]; then 
    #	echo -e "\n🦀 ${underline}Upgrading rustup itself !${reset}\n"
    #	rustup self update
    #fi
    
    echo -e "\n🦀 ${underline}Upgrading rust toolchains !${reset}\n"
    check_rust=$(echo "$check" | awk 'NR==1' | awk -F" - " '{print $2}')
    
    if [[ $check_rust =~ "Update available" ]]; then
    	echo "$check_rust"
    	rustup update 	
    elif [[ $check_rust =~ "Up to date" ]]; then
    	rust_version=$(echo "$check_rust" |  awk -F" : " '{print $2}')
    	echo -e "${greenbold}Rust is up to date!${reset}"" ($rust_version)"
    fi
    
    # si erreur rustup update => rustup toolchain uninstall stable && rustup toolchain install stable
    
    echo ""
fi

if hash cargo 2>/dev/null; then

	echo -e "\n🦀 ${underline}Update cargo packages !${reset}\n"
	if hash ggrep 2>/dev/null; then
		cargo install $(cargo install --list | ggrep -E '^[a-z0-9_-]+ v[0-9.]+:$' | cut -f1 -d' ')
	else
		cargo install $(cargo install --list | egrep '^[a-z0-9_-]+ v[0-9.]+:$' | cut -f1 -d' ')
	fi
		
	echo ""
fi

echo ""
