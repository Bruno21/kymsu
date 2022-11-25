#!/usr/bin/env bash

italic="\033[3m"
underline="\033[4m"
ita_under="\033[3;4m"
bgd="\033[1;4;31m"
red="\033[1;31m"
bold="\033[1m"
box="\033[1;41m"
reset="\033[0m"

echo -e "\n${bold}🦀 Rust${reset}\n"

if hash rustup 2>/dev/null; then

	echo -e "🦀 ${underline}rustup check${reset}\n"
	rustup check
	
	
	if [[ ! $(which rustup-init) =~ "homebrew" ]]; then 
    	echo -e "\n🦀 ${underline}Upgrading rustup itself !${reset}\n"
    	rustup self update
    fi
    
    echo -e "\n🦀 ${underline}Upgrading rust toolchains !${reset}\n"
    rustup update
    
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
