#!/usr/bin/env bash

# pecl plugin for KYMSU
# https://github.com/welcoMattic/kymsu

# https://pecl.php.net

# No distract mode
no_distract=false

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
			#echo "$ligne"
			a=$(echo "$ligne" | grep "pear")
			if [ -n "$a" ]; then
				pecl channel-update pear.php.net
			else
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
		done <<< "$available"
	fi
fi

echo ""
echo ""

# WARNING: channel "pear.php.net" has updated its protocols, 
#   use "pecl channel-update pear.php.net" to update