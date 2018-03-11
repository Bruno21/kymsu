#!/usr/bin/env bash

# Homebrew plugin for KYMSU
# https://github.com/welcoMattic/kymsu

if [[ "${1}" == "latest" ]]; then
	echo "toto"
fi

echo "🍺  Homebrew"
brew update

echo ""

brew_outdated=$(brew outdated)
upd3=$(echo "$brew_outdated" | awk '{print $1}')
#brewsy=$(echo "$brew_outdated" | wc -l | awk {'print $1'})
echo ":$upd3:"

#if [ "$upd3" != "" ]; then
if [ -n "$upd3" ]; then
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

#if [[ $1 == "latest" ]]; then
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
#fi
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
