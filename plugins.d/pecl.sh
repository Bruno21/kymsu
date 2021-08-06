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
# Display PHP informations
display_info=true
# Open PHP info in Safari
php_info=false
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


# Airbook
#❯ echo $(brew --prefix)
#/opt/homebrew

#❯ which -a php
#/opt/homebrew/bin/php
#/usr/bin/php

#/opt/homebrew/opt/php

#❯ php --info | grep 'PHP Version'
#PHP Version => 7.3.24-(to be removed in future macOS)
#PHP Version => 7.3.24-(to be removed in future macOS)

# Silberbook
#❯ echo $(brew --prefix)
#/usr/local

#❯ which -a php
#/usr/local/bin/php
#/usr/bin/php

#/usr/local/opt/php


version=$(php --info | grep 'PHP Version' | sed -n '1p' | awk -F" " '{print $NF}')
v=${version:0:3}
echo -e "Current PHP version: ${bold}$version${reset}\n"

if [ "$v" = "7.3" ]; then
	php_path=$(brew --prefix)/opt/php@7.3/bin
elif [ "$v" = "7.2" ]; then	
	php_path=$(brew --prefix)/opt/php@7.2/bin
elif [ "$v" = "7.4" ]; then	
	php_path=$(brew --prefix)/opt/php@7.4/bin
elif [ "$v" = "8.0" ]; then	
	php_path=$(brew --prefix)/opt/php/bin
fi

# Note that all public channels can be synced using "update-channels"
echo -e "${underline}Updating all channels...${reset}"
$php_path/pecl update-channels

#pecl channel-update pecl.php.net
#pecl channel-update pear.php.net


# List Installed Packages In The Default Channel
#pecl_list=$($php_path/pecl list)
# List installed packages from all channels
pecl_list=$($php_path/pecl list -a)
echo -e "\n$pecl_list\n"

# Installation imagick:
# https://github.com/Imagick/imagick
#git clone https://github.com/Imagick/imagick
#cd imagick
#phpize && ./configure
#make
#make install


pecl_upgrade=$($php_path/pecl list-upgrades)


if [ -n "$pecl_upgrade" ]; then
	
	echo -e "${underline}Extensions update:${reset}"
	
	echo ""
	echo "$pecl_upgrade"

	echo ""
	available=$(echo "$pecl_upgrade" | grep -v 'No upgrades available' | grep 'kB')
	#echo "available: $available"
	
	if [ -n "$available" ]; then
		while read ligne 
		do 
			#echo "$ligne"
			
			# Channel pear.php.net
			a=$(echo "$ligne" | grep "pear")
			#echo "a: $a"
			if [ -n "$a" ]; then
				#pecl channel-update pear.php.net
				$php_path/pecl channel-update pear.php.net
			fi
			
			# Channel pecl.php.net
			b=$(echo "$ligne" | grep "pecl")
			#echo "b: $b"
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
					php_info=true
				else
					#echo "$b" | xargs -n 1 pecl upgrade
					echo "$b" | xargs -n 1 $php_path/pecl upgrade
					php_info=true
				fi
			fi
			echo ""
			
		done <<< "$available"
	fi
fi

echo "php_info: $php_info"

# si modif des extensions, les .ini dans conf.d/ ne sont pas modifiés, juste le php.ini

# php.ini a été modifié il y a moins de 5mn
#v_php=$(php --info | grep -E 'usr.*ini')
v_php=$(php --ini)

conf_php=$(echo "$v_php" | grep 'Loaded Configuration File' | awk '{print $NF}')
dir=$(dirname "$conf_php")
name=$(basename "$conf_php")
notif2="$conf_php was modified in the last 5 minutes"

if [ "$display_info" = true ]; then
	echo -e "php.ini path: ${bold}$conf_php${reset}"
	echo -e "Additionnals ini files:\n$(ls $dir/conf.d/*.ini)"
	echo -e "\nTo change php version: ${italic}$ sphp 7.4${reset}"
	echo -e "${italic}https://gist.github.com/rhukster/f4c04f1bf59e0b74e335ee5d186a98e2${reset}\n"
	
	host=$(hostname)
	[ "$php_info" = true ] && echo -e "Opening PHP info in Safari..." && open "https://$host.local/info.php"
fi

test=$(find "$dir" -name "$name" -mmin -5 -maxdepth 1)

if [ -n "$test" ]; then
	echo -e "${red}❗️ ️$notif2${reset}"
	notification "$notif2"
	echo ""
	
	if [ -n "$available" ]; then
		a=$(echo -e "Do you want to edit ${bold}$conf_php${reset} file ? (y/n)")
		read -p "$a" choice
		if [ "$choice" == "y" ]; then
			$EDITOR "$conf_php"
		fi
	fi
fi

echo ""
echo ""
