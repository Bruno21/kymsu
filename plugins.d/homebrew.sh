#!/usr/bin/env bash

# Homebrew plugin for KYMSU
# https://github.com/welcoMattic/kymsu

# Error: Cask 'onyx' definition is invalid: invalid 'depends_on macos' value: :snow_leopard
#	Supprimer manuellement onyx de /Applications
# 	rm -rvf "$(brew --prefix)/Caskroom/onyx"
# ou
# /usr/bin/find "$(brew --prefix)/Caskroom/"*'/.metadata' -type f -name '*.rb' -print0 | /usr/bin/xargs -0 /usr/bin/perl -i -0pe 's/depends_on macos: \[.*?\]//gsm;s/depends_on macos: .*//g'

###############################################################################################
#
# Settings:

# Display info on updated pakages 
display_info=true

# Casks don't have pinned cask. So add Cask to the do_not_update array for prevent to update.
# Also add package for prevent to update whitout pin it.
declare -a do_not_update=('')

# No distract mode (no user interaction)(Casks with 'latest' version number won't be updated)
no_distract=false
#
###############################################################################################
#
# Recommended software (brew install):
#	-jq (Lightweight and flexible command-line JSON processor)
#	-terminal-notifier (Send macOS User Notifications from the command-line)
#
###############################################################################################

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

# Pinned packages

brew_pinned=$(brew list --pinned | xargs)
#brew_pinned=`echo $brew_pinned | sed 's/ *$//g'`
#brew_pinned=`echo $brew_pinned | xargs`

if [ -n "$brew_pinned" ]; then

	nbp=$(echo "$brew_pinned" | wc -w | xargs)

	echo -e "\033[4mList of\033[0m \033[1;41m $nbp \033[0m \033[4mpinned packages:\033[0m"
	echo -e "\033[1;31m$brew_pinned\033[0m"
	echo "To update a pinned package, you need to un-pin it manually (brew unpin <formula>)"
	echo ""

fi

# A pinned package is in 'brew outdated'

declare -A array_info

if [ -x "$(command -v jq)" ]; then
	brew_outdated=$(brew outdated --json)	
	upd_json=$(echo "$brew_outdated" )
	
	for row in $(jq -c '.[]' <<< "$upd_json");
	do
		name=$(echo "$row" | jq -j '.name, "\n"'); 
		upd3+="$name "
	done
	upd3=$(echo "$upd3" | sed 's/.$//')
	
	echo "upd3:$upd3:"
	if [ -n "$upd3" ]; then
		# Only 1 request 'brew info' for all updated packages
		info=$(brew info --json=v1 $upd3)
	
		i=0
		for row in $(echo "${info}" | jq -r '.[] | @base64');
		do
		    _jq() {
		     echo ${row} | base64 --decode | jq -r ${1}
	    	}

			name=$(_jq '.name')
			homepage=$(_jq '.homepage')
			# encoding to base64 to prevent errors with some characters (')
			desc=$(_jq '.desc' | base64 --break=0)	# BSD: break=0 GNU: wrap=0
			pinned=$(_jq '.pinned')
			installed_v=$(_jq '.installed[].version')
			stable=$(_jq '.versions.stable')
			#linked=$(_jq '.linked_keg')

			eval "declare -a array_info$i=($name $homepage $desc $pinned $installed_v $stable)"

			((i++))
		done
		nb=$i
		i=0
	fi
else
	brew_outdated=$(brew outdated)	
	upd3=$(echo "$brew_outdated" | awk '{print $1}')
	
	if [ -n "$upd3" ]; then
		info=$(brew info $upd3)
		for i in $upd3
		do
			a=$(grep -A 3 "$i: stable" <<< "$info")
			array_info["$i"]="$a"
		done
		nb=${#array_info[@]}
	fi
fi

# Get infos for all updated packages

if [ -n "$upd3" ]; then
		
	# Display info on outdated packages
	
	if [ "$display_info" = true ]; then
		echo -e "\033[4mInfo on\033[0m \033[1;41m $nb \033[0m \033[4mupdated packages:\033[0m"
		
		if [ -x "$(command -v jq)" ]; then
		# ok avec jq installé
		
			i=0
			for row in $(jq -c '.[]' <<< "$upd_json");
			do
			
				name=$(echo "$row" | jq -j '.name, "\n"'); 
				pinned=$(echo "$row" | jq -j '.pinned, "\n"');
				pinned_v=$(echo "$row" | jq -j '.pinned_version, "\n"');
				iv=$(echo "$row" | jq -j '.installed_versions, "\n"');
				installed_v=$(echo "$iv" | jq -j '.[]');
				current_v=$(echo "$row" | jq -j '.current_version, "\n"');

				#n="array_info$i[0]"
				#name=$(echo ${!n})
				h="array_info$i[1]"
				homepage=$(echo ${!h})
				d="array_info$i[2]"
				desc=$(echo ${!d} | base64 --decode)
				
				#info_pkg=$(brew info --json=v1 "$name")
				#homepage=$(echo "$info_pkg" | jq -r .[].homepage)
				#desc=$(echo "$info_pkg" | jq -r .[].desc)
				#current=$(echo "$info_pkg" | jq -r .[].installed[].version | tail -n 1 | awk '{print $1}')
				#stable=$(echo "$info_pkg" | jq -r .[].versions.stable)
				#pined=$(echo "$info_pkg" | jq -r .[].pinned)
				
				upd+="$name "
					
				if [ "$pinned" = "true" ]; then echo -e "\033[1;31m$name: installed: $installed_v stable: $current_v [pinned at $pinned_v]\033[0m";
				else echo -e "\033[1;37m$name: installed: $installed_v stable: $current_v\033[0m";
				fi
				if [ "$desc" != "null" ]; then echo "$desc"; fi;
				echo -e "\033[4m$homepage\033[0m"
				echo ""
				
				((i++))
			done
			upd3=$upd
		else
		# ok sans jq
		
			for pkg in $upd3
			do
				info_pkg="${array_info[$pkg]}"
				ligne1=$(echo "$info_pkg" | head -n 1)
				desc=$(echo "$info_pkg"| sed '1d')
				
				if [[ $ligne1 =~ "pinned" ]]; then # same as if [[ $ligne1 == *"pinned"* ]]; then
					echo -e "\033[1;31m$ligne1\033[0m"
				else
					echo -e "\033[1m$ligne1\033[0m"		
				fi
				
				echo "$desc"
				echo ""
			done
		fi

	fi
	
	# Usefull for notify recent modification of apache/mysql/php conf files.
	touch /tmp/checkpoint

	# Remove pinned packages from outdated packages list

	not_pinned=""
	for i in $upd3
	do
		if [[ $brew_pinned != *"$i"* ]]; then
		not_pinned+="$i "
		fi
	done
	not_pinned=$(echo "$not_pinned" | sed 's/.$//')
	
	echo "np:$not_pinned:"

	# Update outdated packages
	
	if [ "$no_distract" = false ]; then
	
		if [ -n "$not_pinned" ]; then
		
			a=$(echo -e "Do you wanna run \033[1mbrew upgrade "$not_pinned"\033[0m ? (y/n)")
			read -p "$a" choice
			#case "$choice" in
			#	y|Y ) echo "$brew_outdated" | awk '{print $1}' | xargs -p -n 1 brew upgrade ;;
  			#  	n|N ) echo "Ok, let's continue";;
    		#	* ) echo "invalid";;
			#esac
		
			if [ "$choice" == "y" ]; then
		
				for i in $not_pinned
				do	
					FOUND=`echo ${do_not_update[*]} | grep "$i"`
					if [ "${FOUND}" = "" ]; then
							echo "$i" | awk '{print $1}' | xargs -p -n 1 brew upgrade
							#echo "Running update package $i "
						#fi
					fi
				done
			else
				echo "Ok, let's continue"		
			fi
		#else
		#	echo "No package to update"
		fi
		
	else	# no distract = true
	
		if [ -n "$not_pinned" ]; then
			echo "$not_pinned" | awk '{print $1}' | xargs -n 1 brew upgrade
			#echo "Running update package $not_pinned"
		#else
		#	echo "No package to update"
		fi
		
	fi
	
	echo ""

else
	echo -e "\033[4mNo package to update.\033[0m"
fi

echo ""

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

echo "$test"

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
	
	echo "$php_modified"
	
	[ ! -z $php_modified ] && echo -e "\033[1;31m❗️ ️$notif2\033[0m"
	[ ! -z $php_modified ] && notification "$notif2"
	
done
echo ""

# Doctor

echo "🍺  ️The Doc is checking that everything is ok."
brew doctor
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
