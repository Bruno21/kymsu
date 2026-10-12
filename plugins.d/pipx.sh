#!/usr/bin/env bash

# pipx plugin for KYMSU
# https://github.com/welcoMattic/kymsu
#

source config.shlib; # load the config library functions

# No distract mode (no user interaction)
[[ $@ =~ "-nodistract" || $@ =~ "-n" ]] && no_distract=true || no_distract=false

# Upgrade --include-injected
injected=true

# Add module to the do_not_update array for prevent to update.
#declare -a do_not_update=()

italic="$(config_get italic)"
underline="$(config_get underline)"
ita_under="$(config_get ita_under)"
bgd="$(config_get bgd)"
red="$(config_get red)"
bold="$(config_get bold)"
box="$(config_get box)"
green="$(config_get green)"
bold_ita="$(config_get bold_ita)"
redbold="$(config_get redbold)"
redbox="$(config_get redbox)"
reset="$(config_get reset)"


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

curl -Is https://www.apple.com | head -1 | grep 200 1>/dev/null
if [[ $? -eq 1 ]]; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi


list=$(pipx list --include-injected)		# pipx list --quiet
echo -e "\n${underline}List installed packages:${reset}"
#echo "$list"

while IFS= read -r line; do
				
	if grep -q 'package.*,' <<< "${line}"
	then
		pyPkgName=$(echo "${line}" | awk -F" " '{print $2}' )

		infoPkg=$(curl -s https://pypi.org/pypi/${pyPkgName}/json | jq -r '.info')
		summaryPkg=$(echo "$infoPkg"  | jq -r '.summary')
		srcUrl=$(echo "$infoPkg"  | jq -r '.project_urls' | jq -r '.Homepage')
		if [ "$srcUrl" == "null" ]; then
			srcUrl=$(echo "$infoPkg"  | jq -r '.project_urls' | jq -r '.Source')
		fi
		inf="$summaryPkg\n""   ${italic}$srcUrl${reset}"	
		echo -e "\n${bold}${line}${reset}\n   ${inf}"	
	else
		echo -e "${line}"
	fi
					
done <<< "$list"


pinned=$(pipx list --pinned)
echo -e "\n${underline}Pinned packages:${reset}"
echo "$pinned"
echo -e "To unpin, please enter ${italic}pipx unpin <package>${reset}"

# curl -s https://pypi.org/pypi/mkdocs/json | jq -r '.info.summary'
# curl -s https://pypi.org/pypi/mkdocs/json | jq -r '.info.version'
# curl -s https://pypi.org/pypi/mkdocs/json | jq -r '.info.project_url'

pipx-outdated() {
	echo -e "\n${underline}Outdated Packages:${reset}"
	while read -sr pyPkgName pyPkyVersion; do
		local pypi_latest="$(curl -sS https://pypi.org/simple/${pyPkgName}/ | grep -o '>.*</' | tail -n 1 | grep -o -E '[0-9]([0-9]|[-._])*[0-9]')"
		#[ "$pyPkyVersion" != "$pypi_latest" ] && printf "%s\tCurrent: %s\tLatest: %s\n" "$pyPkgName" "$pyPkyVersion" "$pypi_latest"
		if [ "$pyPkyVersion" != "$pypi_latest" ]; then
			if [[ "$pinned" == *"$pyPkgName"* ]]; then
				printf "${red}%s\tCurrent: %s\tLatest: %s (pinned)${reset}\n" "$pyPkgName" "$pyPkyVersion" "$pypi_latest"
			else
				printf "%s\tCurrent: %s\tLatest: %s\n" "$pyPkgName" "$pyPkyVersion" "$pypi_latest"
				outdated+="$pyPkgName "
			fi
		fi
		
	done < <( pipx list | grep -o 'package.*,' | tr -d ',' | cut -d ' ' -f 2- )
}


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
