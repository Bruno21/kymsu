#!/usr/bin/env bash

# pipx plugin for KYMSU
# https://github.com/welcoMattic/kymsu

# No distract mode (no user interaction)
[[ $@ =~ "-nodistract" || $@ =~ "-n" ]] && no_distract=true || no_distract=false

# Upgrade --include-injected
injected=true

# Add module to the do_not_update array for prevent to update.
#declare -a do_not_update=()

italic="\033[3m"
underline="\033[4m"
ita_under="\033[3;4m"
bgd="\033[1;4;31m"
red="\033[1;31m"
bold="\033[1m"
box="\033[1;41m"
reset="\033[0m"


echo -e "${bold}🛠  pipx (Python 3) ${reset}"

if ! command -v pipx &> /dev/null
then
    echo -e "${bold}pipx${reset} could not be found !\n"
    echo -e "You should install ${bold}pipx${reset}:\n"
    echo -e "  - brew install pipx"
    echo -e "  - pipx ensurepath"
    echo -e "or"
    echo -e "  - python3 -m pip install --user pipx"
    echo -e "  - python3 -m pipx ensurepath"
    exit
fi

list=$(pipx list --include-injected)		# pipx list --quiet
echo -e "\n${underline}List installed packages:${reset}"
echo "$list"

curl -Is https://www.apple.com | head -1 | grep 200 1>/dev/null
if [[ $? -eq 1 ]]; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi

pipx-outdated() {
	echo -e "\n${underline}Outdated Packages:${reset}"
	while read -sr pyPkgName pyPkyVersion; do
		local pypi_latest="$(curl -sS https://pypi.org/simple/${pyPkgName}/ | grep -o '>.*</' | tail -n 1 | grep -o -E '[0-9]([0-9]|[-._])*[0-9]')"
		#[ "$pyPkyVersion" != "$pypi_latest" ] && printf "%s\tCurrent: %s\tLatest: %s\n" "$pyPkgName" "$pyPkyVersion" "$pypi_latest"
		if [ "$pyPkyVersion" != "$pypi_latest" ]; then
			printf "%s\tCurrent: %s\tLatest: %s\n" "$pyPkgName" "$pyPkyVersion" "$pypi_latest"
			outdated+="$pyPkgName "
		fi
		
	done < <( pipx list | grep -o 'package.*,' | tr -d ',' | cut -d ' ' -f 2- )
}

# https://github.com/avantrec/soco-cli/blob/master/CHANGELOG.txt

pipx-outdated

outdated=$(echo "$outdated" | sed 's/.$//')

if [ -n "$outdated" ]; then

	nb=$(echo "$outdated" | wc -w | xargs)
	echo -e "${redbox} $nb ${reset} availables updates:"


		a=$(echo -e "\nDo you wanna run ${bold}pipx upgrade "$outdated"${reset} ? (y/n/a) ")
		# yes/no/all
		read -p "$a" choice

		if [ "$choice" == "y" ] || [ "$choice" == "Y" ] || [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
			for i in $outdated;
			do
				if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
					if [ "$injected" = true ]; then
						echo "$i" | xargs -p -n 1 pipx upgrade --include-injected
					else
						echo "$i" | xargs -p -n 1 pipx upgrade
					fi
				elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
					if [ "$injected" = true ]; then
						pipx upgrade-all --include-injected
					else
						pipx upgrade-all
					fi
				fi
			done
		else
			echo -e "OK, let's continue..."
		fi

else
	echo "No update available !"
fi

echo ""
echo ""
