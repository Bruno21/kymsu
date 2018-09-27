#!/usr/bin/env bash

# wp-cli plugin for KYMSU
# https://github.com/welcoMattic/kymsu
# https://make.wordpress.org/cli/handbook/
test=false

# Répertoire WordPress
rep_wordpress=/Users/bruno/Sites/wordpress
# No distract mode
no_distract=false
# Maintenance
maint=true
# Nombre de révisions à conserver:
# Package trepmal/wp-revisions-cli requis !
revisions=3
# Effacer Pingback et Trackback
back=true
# Effacer les spams
removespam=true
# Effacer les révisions
rev=true
# Vider la corbeille
emptytrash=true
# Sauvegarde de la base
backup=true
# Maintenance de la base (optimize & repair)
database=false
# Effacer les transients expirés
transient=true
# Ouvrir la page d'aministration
admin=false

#add module to do_not_update array
declare -a do_not_update=()

if [[ $1 == "--nodistract" ]] || [[ $no_distract == true ]]; then
	no_distract=true
	prompt=
elif [[ $no_distract == false ]]; then
	no_distract=false
	prompt="-p"
fi

if ! [ -x "$(command -v wp)" ]; then
	echo "Error: wp-cli https://wp-cli.org/fr/ is not installed." >&2
	exit 1
fi

echo -e "\033[1mWP wp-cli \033[0m"

echo ""

cd $rep_wordpress

#echo $(pwd)


# *** plugins ***

if [ "$test" = true ]; then
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
  	else
  		echo "WordPress is up to date!"
	fi
	echo ""
	
	# *** plugins ***
	echo "Search for all plugins update..."
	plugin_cu_all=$(wp plugin update --all --dry-run)

	plugins_outdated=$(echo "$plugin_cu_all" | sed '1,2d' | awk '{print $1}')
	if [ -z "$plugins_outdated" ]; then
		echo "No plugins update available !"
	else
		for i in "$plugins_outdated"
		do
 			echo "$i" | xargs $prompt -n 1 wp plugin update
		done
	fi
	echo ""
	
	# *** themes ***
	echo "Search for all themes update..."
	theme_cu_all=$(wp theme update --all --dry-run)

	themes_outdated=$(echo "$theme_cu_all" | sed '1,2d' | awk '{print $1}')
	if [ -z "$themes_outdated" ]; then
		echo "No themes update available !"
	else
		for i in "$themes_outdated"
		do
 			echo "$i" | xargs -p -n 1 wp theme update
		done
	fi
	echo ""
	
	# *** languages core ***
	echo "Search for languages core update..."
	list_lang_core_upd=$(wp language core list --update=available --all --format=csv)
	
	lang_core_outdated=$(echo "$list_lang_core_upd" | sed '1d' | awk '{print $1}')
	if [ -z "$lang_core_outdated" ]; then
		echo "No languages core update available !"
	else
		for i in "$lang_core_outdated"
		do
 			echo "$i" | xargs -p -n 1 wp language core update
		done
	fi
	echo ""
	
	# *** languages plugin ***
	echo "Search for languages plugins update..."
	list_lang_plugin_upd=$(wp language plugin list --update=available --all --format=csv)
	
	lang_plugin_outdated=$(echo "$list_lang_plugin_upd" | sed '1d' | awk '{print $1}')
	if [ -z "$lang_plugin_outdated" ]; then
		echo "No languages plugins update available !"
	else
		for i in "$lang_plugin_outdated"
		do
 			echo "$i" | xargs -p -n 1 wp language plugin update
		done
	fi
	echo ""
	
	# *** languages theme ***
	echo "Search for languages themes update..."
	list_lang_theme_upd=$(wp language theme list --update=available --all --format=csv)
	
	lang_theme_outdated=$(echo "$list_lang_theme_upd" | sed '1d' | awk '{print $1}')
	if [ -z "$lang_theme_outdated" ]; then
		echo "No languages themes update available !"
	else
		for i in "$lang_theme_outdated"
		do
 			echo "$i" | xargs -p -n 1 wp language theme update
		done
	fi

fi	
echo ""


# *** Maintenance ***

if [ "$maint" = true ]; then
    echo -e "\n"
    echo -e "\n\033[1;31mMaintenance...\033[0m"

    #On récupère la liste des packages installés
    packages_list=$(wp package list | sed -n '1!p' | awk '{print $1'})
echo "$packages_list"

    if [ "$transient" = true ]; then
        echo -e "\n\033[1mRemove expired transients...\033[0m"

        wp transient delete --expired --path=$path
    fi

    if [ "$database" = true ]; then
        echo -e "\n\033[1mDatabase maintenance...\033[0m"

        wp db optimize --quiet --path=$path
        
        #wp db repair --quiet --path=$path
    fi

    if [ "$backup" = true ]; then
        echo -e "\n\033[1mDatabase backup...\033[0m"

        DATE=`date +%Y-%m-%d_%H:%M:%S`
        file="wp-$blogname-$DATE.sql"

        wp db export "$file" --add-drop-table --path=$path
        mv "$file" "../$file"
    fi

    if [ "$removespam" = true ]; then
        echo -e "\n\033[1mRemove spam comments...\033[0m"

        #spam=$($wp_exec comment list --status=spam --format=ids --path=$path)
        echo "$spam"
        if [ -n "$spam" ]; then
        	echo "$spam"
            #wp comment delete "$spam" --path=$path
            wp comment delete $($wp_exec comment list --status=spam --format=ids --path=$path) --path=$path --dry-run
        else
            echo "No SPAM"
        fi
    fi

    if [ "$emptytrash" = true ]; then
       echo -e "\n\033[1mRemove comments in trash and comment from deleted posts...\033[0m"

        trashed=$(wp comment list --status=trash,post-trashed --format=ids --path=$path) 
        if [ -n "$trashed" ]; then
            wp comment delete "$trashed" --path=$path
            echo $?
            
        else
            echo "No trashed post"
        fi
    fi

    #if [[ "$($wp_exec cli has-command 'revisions' --path=$path && echo $?)" -eq 0 ]] && [[ "$rev" = true ]]; then
    if [[ -n "$(echo "$packages_list" | awk '$1 ~ /trepmal\/wp-revisions-cli/')" ]] && [[ "$rev" = true ]]; then
        echo -e "\n\033[1mKeep only $revisions revisions...\033[0m"
        wp revisions clean $revisions --path=$path --dry-run

    elif [ "$rev" = true ]; then
    	printf "Voulez-vous installer wp-revisions-cli ? (y/n)"
    	read choice
  		case "$choice" in
    		y|Y|o) wp package install trepmal/wp-revisions-cli || exit 1 
    			;;
    		n|N) echo "Ok, on continue"
    			;;
    		*) echo "invalide"
    			;;
  		esac
    fi

    if [ "$back" = true ]; then
        echo -e "\n\033[1mTrackback list...\033[0m"

        trackback=$(wp comment list --type=trackback --format=ids --path=$path)
        if [ -n "$trackback" ]; then
            wp comment delete "$trackback" --path=$path --dry-run
        else
            echo "No trackback post"
        fi

        echo -e "\n\033[1mPingback list...\033[0m"

        pingback=$(wp comment list --type=pingback --format=ids --path=$path)
        if [ -n "$pingback" ]; then
            wp comment delete "$pingback" --path=$path --dry-run
        else
            echo "No pingback post"
        fi
    fi


    # Ouvrir le tableau de bord dans un navigateur:
    # Nécéssite le paquet admin-command (sera installé si nécessaire)

    if [[ -n "$(echo "$packages_list" | awk '$1 ~ /wp-cli\/admin-command/')" ]] && [[ "$admin" = true ]]; then
        echo -e "\n\033[1mOpen wp-admin/ page in browser...\033[0m"
        wp admin --path=$path
    elif [ "$admin" = true ]; then
        wp package install wp-cli/admin-command
        echo ""
        echo -e "\n\033[1mOpen wp-admin/ page in browser...\033[0m"
        wp admin --path=$path
    fi


fi
