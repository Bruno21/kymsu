#!/usr/bin/env bash

# wp-cli plugin for KYMSU
# https://github.com/welcoMattic/kymsu
# https://make.wordpress.org/cli/handbook/

#version: pip ou pip3
#version=pip3
#user: "" or "--user"
#user=""
# Répertoire WordPress
rep_wordpress=/Users/bruno/Sites/wordpress
# No distract mode
no_distract=false
#add module to do_not_update array
declare -a do_not_update=()

if [[ $1 == "--nodistract" ]]; then
	no_distract=true
fi

if ! [ -x "$(command -v wp)" ]; then
	echo "Error: wp-cli is not installed." >&2
	exit 1
fi

echo -e "\033[1mWP wp-cli \033[0m"

echo ""

cd $rep_wordpress

#echo $(pwd)


# *** plugins ***

if [ "$no_distract" = false ]; then
	
	# *** core update ***
	echo "Search for core update..."
	core_cu=$(wp core check-update)
	if ! [[ $core_cu = *"latest version"* ]]; then
  		echo "New version available!"
 
 		z=$(echo -e "Do you wanna \033[1m upgrade WordPress\033[0m? (y/n)")
		read -p "$z" choice
		case "$choice" in
			y|Y ) wp core update && wp core update-db ;;
  		  	n|N ) echo "Ok, let's continue";;
    		* ) echo "invalid";;
		esac
		# pas testé
 		
  	else
  		echo "WordPress is up to date!"
  		# test ok
	fi
	echo ""
	
	# *** plugins ***
	echo "Search for all plugins update..."
	plugin_cu_all=$(wp plugin update --all --dry-run)

	a=$(echo "$plugin_cu_all" | sed '1,2d' | awk '{print $1}')
	if [ -z "$a" ]; then
		echo "No plugins update available !"
	else
		echo "$a" | awk '{print $1}' | xargs -p -n 1 wp plugin update  --dry-run
	fi
	# test ok
	echo ""
	
	# *** themes ***
	echo "Search for all themes update..."
	theme_cu_all=$(wp theme update --all --dry-run)

	b=$(echo "$theme_cu_all" | sed '1,2d' | awk '{print $1}')
	if [ -z "$b" ]; then
		echo "No themes update available !"
	else
		echo "$b" | awk '{print $1}' | xargs -p -n 1 wp theme update  --dry-run
	fi
	echo "pas testé"
	# pas testé
	echo ""
	
	# *** languages core ***
	echo "Search for languages core update..."
	list_lang_core_upd=$(wp language core list --update=available --all --format=csv)
	
	c=$(echo "$list_lang_core_upd" | sed '1d' | awk '{print $1}')
	if [ -z "$c" ]; then
		echo "No languages core update available !"
	else
		echo "$c"
	fi
	echo ""
	
	# *** languages plugin ***
	echo "Search for languages plugins update..."
	list_lang_plugin_upd=$(wp language plugin list --update=available --all --format=csv)
	
	d=$(echo "$list_lang_plugin_upd" | sed '1d' | awk '{print $1}')
	if [ -z "$d" ]; then
		echo "No languages plugins update available !"
	else
		echo "$d"
	fi
	echo ""
	
	# *** languages theme ***
	echo "Search for languages themes update..."
	list_lang_theme_upd=$(wp language theme list --update=available --all --format=csv)
	
	e=$(echo "$list_lang_theme_upd" | sed '1d' | awk '{print $1}')
	if [ -z "$e" ]; then
		echo "No languages themes update available !"
	else
		echo "$e"
	fi
	
else
	echo "No distract"
	# *** core update ***
	#wp core update
	#wp core update-db
	
	# *** plugins ***
	#wp plugin update --all
	
	# *** themes ***
	#wp theme update --all
	
	# *** languages core ***
	#wp language core update
	
	# *** languages plugin ***
	#wp language plugin update --all
	
	# *** languages theme ***
	# wp language theme update --all

fi

echo ""
