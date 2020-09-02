#!/usr/bin/env bash

# pecl plugin for KYMSU
# https://github.com/welcoMattic/kymsu

# https://pecl.php.net

#########################################
#
# Settings:

# No distract mode (no user interaction)
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

echo -e "\033[1m🐘 pecl \033[0m"

echo ""

echo -e "\033[1m❗️ plugin en test (beta) \033[0m"
echo ""

pecl_upgrade=$(pecl list-upgrades)

if [ -n "$pecl_upgrade" ]; then
	
	echo -e "\033[4mExtensions update:\033[0m"
	
	echo ""
	echo "$pecl_upgrade"

	echo ""
	available=$(echo "$pecl_upgrade" | grep -v 'No upgrades available' | grep 'kB')
	
	if [ -n "$available" ]; then
		while read ligne 
		do 
			echo "$ligne"
			
			# Channel pear.php.net
			a=$(echo "$ligne" | grep "pear")
			if [ -n "$a" ]; then
				pecl channel-update pear.php.net
			fi
			
			# Channel pecl.php.net
			b=$(echo "$ligne" | grep "pecl")
			if [ -n "$b" ]; then
				pecl channel-update pecl.php.net
				
				#(pecl or doc) update available
				b=$(echo "$ligne" | awk '{print $2}')
				pecl info "$b"
				echo ""
				if [ "$no_distract" = false ]; then
					echo "$b" | xargs -p -n 1 pecl upgrade
				else
					echo "$b" | xargs -n 1 pecl upgrade
				fi
			fi
			echo ""
			
		done <<< "$available"
	fi
fi

# si modif des extensions, les .ini dans conf.d/ ne sont pas modifiés, juste le php.ini

# php.ini a été modifié il y a moins de 5mn
v_php=$(php --info | grep -E 'usr.*ini')
conf_php=$(echo "$v_php" | grep 'Loaded Configuration File' | awk '{print $NF}')
dir=$(dirname "$conf_php")
name=$(basename "$conf_php")
notif2="$conf_php was modified in the last 5 minutes"

test=$(find "$dir" -name "$name" -mmin -5 -maxdepth 1)

if [ -n "$test" ]; then
	echo -e "\033[1;31m❗️ ️$notif2\033[0m"
	notification "$notif2"
	echo ""
	
	a=$(echo -e "Do you want to edit \033[1m$conf_php\033[0m file ? (y/n)")
	read -p "$a" choice
	if [ "$choice" == "y" ]; then
		$EDITOR "$conf_php"
	fi
fi

echo ""
echo ""

# WARNING: channel "pear.php.net" has updated its protocols, 
#   use "pecl channel-update pear.php.net" to update