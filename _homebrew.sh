#!/usr/bin/env bash

# Homebrew plugin for KYMSU
# https://github.com/welcoMattic/kymsu

# Display info on updated pakages 
display_info=true

# No distract mode
no_distract=false

echo "🍺  Homebrew"
brew update

echo ""

brew_outdated=$(brew outdated)
upd3=$(echo "$brew_outdated" | awk '{print $1}')

if [ -n "$upd3" ]; then
	
	if [ "$display_info" = true ]; then
		echo -e "\033[4mInfo on updated packages:\033[0m"
		for pkg in $upd3
		do
			
			# if jq (https://stedolan.github.io/jq/) is installed
			if [ -x "$(command -v jq)" ]; then
				info_pkg=$(brew info --json=v1 "$pkg")
				current=$(echo "$info_pkg" | jq -r .[].installed[].version | tail -n 1 | awk '{print $1}')
				stable=$(echo "$info_pkg" | jq -r .[].versions.stable)
				homepage=$(echo "$info_pkg" | jq -r .[].homepage)
				desc=$(echo "$info_pkg" | jq -r .[].desc)

				echo -e "\033[1m$pkg:\033[0m current: $current last: $stable"		
				echo "$desc"
				echo "$homepage"		

			else
				info=$(brew info $pkg | head -n 4)
				ligne1=$(echo "$info" | head -n 1)
				
				echo -e "\033[1m$ligne1\033[0m"					
				echo "$info" | sed -n -e '2,3p'
			
			fi

			echo ""
		done
	fi
	
	a=$(echo -e "Do you wanna run \033[1mbrew upgrade "$upd3"\033[0m? (y/n)")
	read -p "$a" choice
	case "$choice" in
		y|Y ) echo "$brew_outdated" | awk '{print $1}' | xargs -p -n 1 brew upgrade ;;
    	n|N ) echo "Ok, let's continue";;
    	* ) echo "invalid";;
	esac
	echo ""
fi

echo "🍺  Casks upgrade."
#brew cask outdated --greedy --verbose | grep -v '(latest)' | awk '{print $1}' | xargs brew cask reinstall
cask_outdated=$(brew cask outdated --greedy --verbose)

outdated=$(echo "$cask_outdated" | grep -v '(latest)')
if [ -n "$outdated" ]; then
	echo "$outdated"
	
	echo "$outdated" | awk '{print $1}' | awk '{print $1}' | xargs brew cask reinstall
else
	echo -e "\033[4mNo availables Cask updates.\033[0m"
fi

echo ""
latest=$(echo "$cask_outdated" | grep '(latest)')
if [ -n "$latest" ]; then
	echo -e "\033[4mCasks (latest):\033[0m"
	echo "$latest" | cut -d " " -f1,2
	echo ""
	
	read -p "Do you wanna run Cask (latest) upgrade? (y/n)" choice
  	case "$choice" in
    	y|Y|o ) echo "$latest" | awk '{print $1}' | xargs -p -n 1 brew cask upgrade --greedy ;;
    	n|N ) echo "Ok, let's continue";;
    	* ) echo "invalid";;
  	esac

fi
echo ""

echo "🍺  ️The Doc is checking that everything is ok."
brew doctor
brew missing
echo ""

if [[ $1 == "cleanup" ]]; then
  echo "🍺  Cleaning brewery"
  #brew cleanup -s
  brew cleanup --prune=30
  #brew cask cleanup
  brew cask cleanup --outdated
fi
