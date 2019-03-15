#!/usr/bin/env bash

# pecl plugin for KYMSU
# https://github.com/welcoMattic/kymsu



echo -e "\033[1m🐘 pecl \033[0m"

echo ""

echo -e "\033[1m❗️ plugin en test (beta) \033[0m"
echo ""

upgrade=$(pecl list-upgrades)
pecl_upgrade=$(echo "$upgrade")

if [ -n "$pecl_upgrade" ]; then
	
	echo -e "\033[4mExtensions update:\033[0m"
	
	echo ""
	echo "$pecl_upgrade"

	echo ""
	available=$(echo "$upgrade" | grep -v 'No upgrades available' | grep 'kB')
	# pecl.php.net APCu    5.1.16 (stable) 5.1.17 (stable) 93kB

	while read ligne 
	do 
		#echo "$ligne"
		a=$(echo "$ligne" | grep "pear")
		if [ -n "$a" ]; then
			echo "pear update available"
			# pecl channel-update pear.php.net
		else
			#echo "(pecl or doc) update available"
			#pecl=true
			b=$(echo "$ligne" | awk '{print $2}')
			pecl info "$b"
			echo ""
			echo "$b" | xargs -p -n 1 pecl upgrade

		fi
	done <<< "$available"

fi

echo ""
echo ""

#channels=$(pecl list-channels | sed '1,3d;$d' | grep -E '.com|.net' | awk '{print $1}')
#for i in $channels
#do
#	echo "$i"
	# pecl channel-update $i
#done

# WARNING: channel "pear.php.net" has updated its protocols, 
#   use "pecl channel-update pear.php.net" to update