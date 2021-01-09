#!/usr/bin/env bash

# pecl plugin for KYMSU
# https://github.com/welcoMattic/kymsu

# https://pecl.php.net

#########################################
#
# Settings:

# No distract mode (no user interaction)
[[ $@ =~ "--nodistract" ]] && no_distract=true || no_distract=false
#
#########################################

italic="\033[3m"
underline="\033[4m"
ita_under="\033[3;4m"
bgd="\033[1;4;31m"
red="\033[1;31m"
bold="\033[1m"
box="\033[1;41m"
reset="\033[0m"

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


echo -e "${bold}🐘 pecl ${reset}"

echo ""

echo -e "${bold}❗️ plugin en test (beta) ${reset}"
echo ""

# /usr/local/Cellar/php/7.4.11/bin/pecl
# /usr/local/Cellar/php@7.3/7.3.23/bin/pecl
# /usr/local/Cellar/php@7.2/7.2.33/bin/pecl

#pecl_upgrade=$(pecl list-upgrades)

version=$(php --info | grep 'PHP Version' | sed -n '1p' | awk -F" " '{print $NF}')
v=${version:0:3}

if [ "$v" = "7.3" ]; then
	php_path=$(brew --prefix)/opt/php@7.3/bin
elif [ "$v" = "7.2" ]; then	
	php_path=$(brew --prefix)/opt/php@7.2/bin
elif [ "$v" = "7.4" ]; then	
	php_path=$(brew --prefix)/opt/php/bin
fi

pecl_upgrade=$($php_path/pecl list-upgrades)


if [ -n "$pecl_upgrade" ]; then
	
	echo -e "${underline}Extensions update:${reset}"
	
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
				#pecl channel-update pear.php.net
				$php_path/pecl channel-update pear.php.net
			fi
			
			# Channel pecl.php.net
			b=$(echo "$ligne" | grep "pecl")
			if [ -n "$b" ]; then
				#pecl channel-update pecl.php.net
				$php_path/pecl channel-update pecl.php.net
				
				#(pecl or doc) update available
				b=$(echo "$ligne" | awk '{print $2}')
				#pecl info "$b"
				$php_path/pecl info "$b"
				echo ""
				if [ "$no_distract" = false ]; then
					#echo "$b" | xargs -p -n 1 pecl upgrade
					echo "$b" | xargs -p -n 1 $php_path/pecl upgrade
				else
					#echo "$b" | xargs -n 1 pecl upgrade
					echo "$b" | xargs -n 1 $php_path/pecl upgrade
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
	echo -e "${red}❗️ ️$notif2${reset}"
	notification "$notif2"
	echo ""
	
	a=$(echo -e "Do you want to edit ${bold}$conf_php${reset} file ? (y/n)")
	read -p "$a" choice
	if [ "$choice" == "y" ]; then
		$EDITOR "$conf_php"
	fi
fi

echo ""
echo ""

# WARNING: channel "pear.php.net" has updated its protocols, 
#   use "pecl channel-update pear.php.net" to update