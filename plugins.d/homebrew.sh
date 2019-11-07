#!/usr/bin/env bash

# Homebrew plugin for KYMSU
# https://github.com/welcoMattic/kymsu

# Error: Cask 'onyx' definition is invalid: invalid 'depends_on macos' value: :snow_leopard
#	Supprimer manuellement onyx de /Applications
# 	rm -rvf "$(brew --prefix)/Caskroom/onyx"
# ou
# /usr/bin/find "$(brew --prefix)/Caskroom/"*'/.metadata' -type f -name '*.rb' -print0 | /usr/bin/xargs -0 /usr/bin/perl -i -0pe 's/depends_on macos: \[.*?\]//gsm;s/depends_on macos: .*//g'

#########################################
#
# Settings:

# Display info on updated pakages 
display_info=true

#add module to do_not_update array
declare -a do_not_update=('')

# No distract mode (no user interaction)(Casks with 'latest' version number won't be updated)
no_distract=false
#
#########################################

notification() {
    sound="Basso"
    title="Homebrew"
    #subtitle="Attention !!!"
	message="$1"
	image="error.png"

	if [[ "$OSTYPE" == "darwin"* ]] && [ -x "$(command -v terminal-notifier)" ]; then
    	terminal-notifier -title "$title" -message "$message" -sound "$sound" -contentImage "$image"
	fi
}


if [[ $1 == "--nodistract" ]]; then
	no_distract=true
fi

echo -e "\033[1m🍺  Homebrew \033[0m"

brew update

echo ""

brew_outdated=$(brew outdated)
upd3=$(echo "$brew_outdated" | awk '{print $1}')

#nb=$(echo $upd3 | wc -w)

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
	
	touch /tmp/checkpoint
	
	if [ "$no_distract" = false ]; then
	
		a=$(echo -e "Do you wanna run \033[1mbrew upgrade "$upd3"\033[0m? (y/n)")
		read -p "$a" choice
		#case "$choice" in
		#	y|Y ) echo "$brew_outdated" | awk '{print $1}' | xargs -p -n 1 brew upgrade ;;
  		#  	n|N ) echo "Ok, let's continue";;
    	#	* ) echo "invalid";;
		#esac
		
		if [ "$choice" == "y" ]; then
		
			for i in $upd3
			do	
				FOUND=`echo ${do_not_update[*]} | grep "$i"`
				if [ "${FOUND}" = "" ]; then
					echo "$i" | awk '{print $1}' | xargs -p -n 1 brew upgrade
				fi
			done
		else
			echo "Ok, let's continue"		
		fi
		
	else
	
		echo "$brew_outdated" | awk '{print $1}' | xargs -n 1 brew upgrade
		
	fi
	
	echo ""
fi

echo "🍺  Casks upgrade."

cask_outdated=$(brew cask outdated --greedy --verbose)

outdated=$(echo "$cask_outdated" | grep -v '(latest)')
if [ -n "$outdated" ]; then

	# don't stop multiples updates if one block (bad checksum, not compatible with OS version (Onyx))
	sea=$(echo "$outdated" | awk '{print $1}')
	
	for i in $sea
	do
		FOUND=`echo ${do_not_update[*]} | grep "$i"`
		
		if [ "${FOUND}" == "" ]; then
			echo "$i" | xargs brew cask reinstall
		fi
	done
	
else
	echo -e "\033[4mNo availables Cask updates.\033[0m"
fi

echo ""
latest=$(echo "$cask_outdated" | grep '(latest)')

if [ -n "$latest" ] && [ "$no_distract" = false ]; then
	echo -e "\033[4mCasks (latest):\033[0m"
	echo "$latest" | cut -d " " -f1,2
	echo ""
	
	read -p "Do you wanna run Cask (latest) upgrade? (y/n)" choice

	if [ "$choice" == "y" ]; then
		for i in "$latest"
		do	
			echo "$i" | awk '{print $1}' | xargs -p -n 1 brew cask upgrade --greedy
			echo $?
		done
	else
		echo "Ok, let's continue"		
	fi

fi
echo ""

# Test if Apache conf file has been modified by Homebrew (Apache, PHP or Python updates)

v_apa=$(httpd -V | grep 'SERVER_CONFIG_FILE')
conf_apa=$(echo "$v_apa" | awk -F "\"" '{print $2}')
dir=$(dirname $conf_apa)
name=$(basename $conf_apa)
notif1="$dir has been modified in the last 5 minutes"

test=$(find $dir -name "$name" -mmin -5 -maxdepth 1)
[ ! -z $test ] && echo -e "\033[1;31m❗️ ️$notif1\033[0m"
[ ! -z $test ] && notification "$notif1"

# Test if PHP.ini file has been modified by Homebrew (PECL)

php_versions=$(ls /usr/local/etc/php/)
for php in $php_versions
do 	
	# file modified since it was last read
	#if [ -N /usr/local/etc/php/$php/php.ini ]; then echo "modified"; fi
	
	php_modified=$(find /usr/local/etc/php/$php/ -name php.ini -newer /tmp/checkpoint)
	php_ini=/usr/local/etc/php/$php/php.ini
	notif2="$php_ini has been modified"
	
	[ ! -z $php_modified ] && echo -e "\033[1;31m❗️ ️$notif2\033[0m"
	[ ! -z $php_modified ] && notification "$notif2"
	
done
echo ""

# Doctor

echo "🍺  ️The Doc is checking that everything is ok."
brew doctor
brew missing
echo ""

# Homebrew 2.0.0+ run a cleanup every 30 days

if [[ $1 == "--cleanup" ]]; then
  echo "🍺  Cleaning brewery"
  ##brew cleanup -s
  # keep 30 days
  brew cleanup --prune=30
  ##brew cask cleanup: deprecated - merged with brew cleanup
  #brew cask cleanup --outdated
  echo ""
fi

echo ""
