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

#add Cask to do_not_update array
declare -a do_not_update=('')

# No distract mode (no user interaction)(Casks with 'latest' version number won't be updated)
no_distract=false
#
#########################################
#
# Recommended software (brew install):
#	-jq
#	-terminal-notifier
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

#brew update

echo ""

# pinned

brew_pinned=$(brew list --pinned)

if [ -n "$brew_pinned" ]; then

	echo -e "\033[4mList of pinned packages:\033[0m"

	pinned=$(echo "$brew_pinned" | tr '\n' ' ')
	echo -e "\033[1;31m️$pinned\033[0m"
	echo "To update a pinned package, you need to un-pin it manually (brew unpin <formula>)"
	echo ""

fi

# Un paquet pinned est dans 'brew outdated'

if [ -x "$(command -v jqs)" ]; then
	brew_outdated=$(brew outdated --json)
	
	upd3=$(echo "$brew_outdated" )
	
else
	brew_outdated=$(brew outdated)
	
	upd3=$(echo "$brew_outdated" | awk '{print $1}')
	
fi

#upd3=$(echo "$brew_outdated" | awk '{print $1}')
#upd3=$(echo "$brew_outdated" )

echo "$upd3"

if [ -n "$upd3" ]; then
		
	# Display info on outdated packages
	
	if [ "$display_info" = true ]; then
		echo -e "\033[4mInfo on updated packages:\033[0m"
		
		if [ -x "$(command -v jqs)" ]; then
		# ok avec jq installé
		
			for row in $(jq -c '.[]' <<< "$upd3");
			do
			
     			#echo ${row} # = echo "$row"
			
				if [ -x "$(command -v jq)" ]; then
					name=$(echo "$row" | jq -j '.name, "\n"'); 
					pinned=$(echo "$row" | jq -j '.pinned, "\n"');
					pinned_v=$(echo "$row" | jq -j '.pinned_version, "\n"');
					iv=$(echo "$row" | jq -j '.installed_versions, "\n"');
					installed_v=$(echo "$iv" | jq -j '.[]');
					#echo "$iv"
					current_v=$(echo "$row" | jq -j '.current_version, "\n"');
	
					#info_pkg=$(brew info --json=v1 "$name")
					homepage=$(echo "$info_pkg" | jq -r .[].homepage)
					desc=$(echo "$info_pkg" | jq -r .[].desc)
					#current=$(echo "$info_pkg" | jq -r .[].installed[].version | tail -n 1 | awk '{print $1}')
					#stable=$(echo "$info_pkg" | jq -r .[].versions.stable)
					#pined=$(echo "$info_pkg" | jq -r .[].pinned)
					
					if [ "$pinned" = "true" ]; then echo -e "\033[1;31m$name: installed: $installed_v stable: $current_v [pinned at $pinned_v]\033[0m";
					else echo -e "\033[1;37m$name: installed: $installed_v stable: $current_v\033[0m";
					fi
					echo "$desc"
					echo "$homepage"
					echo ""
				fi
			done
		else

			# test sans jq
		
			for pkg in "$upd3"
			do
				echo "$pkg"
				echo "---"
				#info=$(brew info "$pkg")
				#echo "$info"

<<COMMENT			
				#if [ -x "$(command -v nano)" ]; then
				name=$(echo "$pkg" | grep '\"name\":' | awk -F "," '{print $1}' | awk -F ":" '{print $2}' | sed 's/\"//g')
				pinned=$(echo "$pkg" | grep '\"pinned\":true' | awk -F "," '{print $4}' | awk -F ":" '{print $2}')
				pinned_v=$(echo "$pkg" | grep '\"pinned_version\":' | awk -F "," '{print $5}' | awk -F ":" '{print $2}' | sed 's/\"//g')
				# installed_v : voir cas avec plusieurs versions installées
				installed_v=$(echo "$pkg" | grep '\"installed_versions\":' | awk -F "," '{print $2}' | awk -F ":" '{print $2}' | sed 's/\"//g')
				current_v=$(echo "$pkg" | grep '\"current_version\":' | awk -F "," '{print $3}' | awk -F ":" '{print $2}' | sed 's/\"//g')
				
				#info=$(brew info "$name" | head -n 4)
				ligne1=$(echo "$info" | head -n 1)
				
				if [ "$pinned" = "true" ]; then echo -e "\033[1;31m$ligne1\033[0m"
				else echo -e "\033[1m$ligne1\033[0m"
				fi					
				echo "$info" | sed -n -e '2,3p'
			
				#fi

				echo ""
COMMENT
			done
		fi
			
<<COMMENT
		
		for pkg in $upd3
		do
			# if jq (https://stedolan.github.io/jq/) is installed
			if [ -x "$(command -v jq)" ]; then
				name=$(echo "$pkg" | jq -r '.[].name')
				pinned=$(echo "$pkg" | jq -r '.[].pinned')
				pinned_v=$(echo "$pkg" | jq -r '.[].pinned_version')
				installed_v=$(echo "$pkg" | jq -r '.[].installed_versions' | tr -d '\n' | sed 's/\"//g;s/\[//g;s/\]//g;s/ //g')
				current_v=$(echo "$pkg" | jq -r '.[].current_version')
				
				info_pkg=$(brew info --json=v1 "$name")
				homepage=$(echo "$info_pkg" | jq -r .[].homepage)
				desc=$(echo "$info_pkg" | jq -r .[].desc)
				#current=$(echo "$info_pkg" | jq -r .[].installed[].version | tail -n 1 | awk '{print $1}')
				#stable=$(echo "$info_pkg" | jq -r .[].versions.stable)
				#pined=$(echo "$info_pkg" | jq -r .[].pinned)
				
				#if [[ "$pkg" == *"$brew_pinned"* ]]; then echo -e "\033[1;31m$pkg:\033[0;31m current: $current last: $stable pinned\033[0m";
				if [ "$pinned" = "true" ]; then echo -e "\033[1;31m$name: installed: $installed_v stable: $current_v [pinned at $pinned_v]\033[0m";
				else echo -e "\033[31m$name: installed: $installed_v stable: $current_v\033[0m";
				fi
				echo "$desc"
				echo "$homepage"
			#fi
			else
			#echo "----"
			#if [ -x "$(command -v nano)" ]; then
				name=$(echo "$pkg" | grep '\"name\":' | awk -F "," '{print $1}' | awk -F ":" '{print $2}' | sed 's/\"//g')
				pinned=$(echo "$pkg" | grep '\"pinned\":true' | awk -F "," '{print $4}' | awk -F ":" '{print $2}')
				pinned_v=$(echo "$pkg" | grep '\"pinned_version\":' | awk -F "," '{print $5}' | awk -F ":" '{print $2}' | sed 's/\"//g')
				# installed_v : voir cas avec plusieurs versions installées
				installed_v=$(echo "$pkg" | grep '\"installed_versions\":' | awk -F "," '{print $2}' | awk -F ":" '{print $2}' | sed 's/\"//g')
				current_v=$(echo "$pkg" | grep '\"current_version\":' | awk -F "," '{print $3}' | awk -F ":" '{print $2}' | sed 's/\"//g')
				
				info=$(brew info "$name" | head -n 4)
				ligne1=$(echo "$info" | head -n 1)
				
				if [ "$pinned" = "true" ]; then echo -e "\033[1;31m$ligne1\033[0m"
				else echo -e "\033[1m$ligne1\033[0m"
				fi					
				echo "$info" | sed -n -e '2,3p'
			
			fi

			echo ""
		done
COMMENT

	fi
	
	touch /tmp/checkpoint

	# Remove pinned packages from outdated packages list
	
	not_pinned=""
	for i in $upd3
	do
		pinned=$(echo "$i" | grep '\"pinned\"' | awk -F "," '{print $4}' | awk -F ":" '{print $2}')
		name=$(echo "$i" | grep '\"name\":' | awk -F "," '{print $1}' | awk -F ":" '{print $2}' | sed 's/\"//g')
		if [ "$pinned" = "false" ]; then 
			not_pinned .= "$name "
		fi	
	done
	not_pinned=$(echo "$not_pinned" | sed 's/.$//')
	echo "Not pinned: $not_pinned"

	
	# Update outdated packages
	
	if [ "$no_distract" = false ]; then
	
		#if [ -n "$upd4" ]; then
		if [ -n "$not_pinned" ]; then
		
			#a=$(echo -e "Do you wanna run \033[1mbrew upgrade "$upd4"\033[0m? (y/n)")
			a=$(echo -e "Do you wanna run \033[1mbrew upgrade "$not_pinned"\033[0m? (y/n)")
			read -p "$a" choice
			#case "$choice" in
			#	y|Y ) echo "$brew_outdated" | awk '{print $1}' | xargs -p -n 1 brew upgrade ;;
  			#  	n|N ) echo "Ok, let's continue";;
    		#	* ) echo "invalid";;
			#esac
		
			if [ "$choice" == "y" ]; then
		
				#for i in $upd4
				for i in $not_pinned
				do	
					FOUND=`echo ${do_not_update[*]} | grep "$i"`
					if [ "${FOUND}" = "" ]; then
						#if [[ "$i" != *"$brew_pinned"* ]]; then
							#echo "$i" | awk '{print $1}' | xargs -p -n 1 brew upgrade
							echo "Package to update"
						#fi
					fi
				done
			else
				echo "Ok, let's continue"		
			fi
		else
			echo "No package to update"
		fi
		
	else	# no distract = true
	
		if [ -n "$not_pinned" ]; then
			#echo "$not_pinned" | awk '{print $1}' | xargs -n 1 brew upgrade
			echo "Package to update"
		else
			echo "No package to update"
		fi
		
	fi
	
	echo ""
fi

# Casks

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
echo $?
brew missing
status=$?
if [ $status -ne 0 ]; then brew missing --verbose; fi
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
