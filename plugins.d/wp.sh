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
database=true
# Effacer les transients expirés
transient=true
# Ouvrir la page d'aministration
admin=false

: <<'END_COMMENT'
blabla
END_COMMENT

italic="\033[3m"
underline="\033[4m"
ita_under="\033[3;4m"
bgd="\033[1;4;31m"
redbold="\033[1;31m"
bold="\033[1m"
box="\033[1;41m"
reset="\033[0m"

#add module to do_not_update array
declare -a do_not_update=()

#[[ $@ =~ "-nodistract" || $@ =~ "-n" ]] && no_distract=true || no_distract=false

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

echo -e "${redbold}Updates${reset}"

echo ""

cd $rep_wordpress || exit

#echo $(pwd)


# *** plugins ***

#if [ "$test" = true ]; then

#: <<'END_COMMENT2'

	# *** core update ***
	echo -e "${bold}Search for core update...${reset}"
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
	echo -e "${bold}Search for all plugins update...${reset}"
	wp plugin list --format=table # --update=available
	plugin_update=$(wp plugin list --format=table --update=available) 
	echo
	plugins_outdated=$(echo "$plugin_update" | sed '/^+/d' | sed '1d' | awk '{print $1}')
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
	echo -e "${bold}Search for all themes update...${reset}"
	wp theme list --format=table #--update=available
	theme_update=$(wp theme list --format=table --update=available)
	echo
	themes_outdated=$(echo "$theme_update" | sed '/^+/d' | sed '1d' | awk '{print $1}')
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
	echo -e "${bold}Search for languages core update...${reset}"
	wp language core list --update=available --all --format=table
	list_lang_core_upd=$(wp language core list --update=available --all --format=table)
	
	lang_core_outdated=$(echo "$list_lang_core_upd" | sed '/^+/d' | sed '1d' | awk '{print $1}')
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
	echo -e "${bold}Search for languages plugins update...${reset}"
	wp language plugin list --update=available --all --format=table
	list_lang_plugin_upd=$(wp language plugin list --update=available --all --format=table)
	lang_plugin_outdated=$(echo "$list_lang_plugin_upd" | sed '/^+/d' | sed '1d' | awk '{print $1}')
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
	echo -e "${bold}Search for languages themes update...${reset}"
	wp language theme list --update=available --all --format=table
	list_lang_theme_upd=$(wp language theme list --update=available --all --format=table)
	
	lang_theme_outdated=$(echo "$list_lang_theme_upd" | sed '/^+/d' | sed '1d' | awk '{print $1}')
	if [ -z "$lang_theme_outdated" ]; then
		echo "No languages themes update available !"
	else
		for i in "$lang_theme_outdated"
		do
 			echo "$i" | xargs -p -n 1 wp language theme update
		done
	fi

#fi	
echo ""

#END_COMMENT2

# *** Maintenance ***

if [ "$maint" = true ]; then
    echo -e "\n"
    echo -e "\n\033[1;31mMaintenance...\033[0m"

    #On récupère la liste des packages installés
    echo -e "\n\033[1mInstalled package list...\033[0m"
    packages_list=$(wp package list | sed -n '1!p' | awk '{print $1'})
	echo "$packages_list"

    if [ "$transient" = true ]; then
        echo -e "\n\033[1mRemove expired transients...\033[0m"

        wp transient delete --expired --path=$rep_wordpress
    fi

    if [ "$database" = true ]; then
        echo -e "\n\033[1mDatabase maintenance...\033[0m"

        wp db optimize --quiet --path=$rep_wordpress
        
        #wp db repair --quiet --path=$path
    fi

    if [ "$backup" = true ]; then
        echo -e "\n\033[1mDatabase backup...\033[0m"

        DATE=`date +%Y-%m-%d_%H:%M:%S`
        file="wp-$blogname-$DATE.sql"

        wp db export "$file" --add-drop-table --path=$rep_wordpress
        mv "$file" "../$file"
    fi

    if [ "$removespam" = true ]; then
        echo -e "\n\033[1mRemove spam comments...\033[0m"

        spam=$(wp comment list --status=spam --format=ids --path=$rep_wordpress)
        echo "$spam"
        if [ -n "$spam" ]; then
        	echo "$spam"
            #wp comment delete "$spam" --path=$path
            wp comment delete $(wp comment list --status=spam --format=ids --path=$rep_wordpress) --path=$rep_wordpress --dry-run
        else
            echo "No SPAM"
        fi
    fi

    if [ "$emptytrash" = true ]; then
       echo -e "\n\033[1mRemove comments in trash and comment from deleted posts...\033[0m"

        trashed=$(wp comment list --status=trash,post-trashed --format=ids --path=$rep_wordpress) 
        if [ -n "$trashed" ]; then
            wp comment delete "$trashed" --path=$rep_wordpress
            echo $?
            
        else
            echo "No trashed post"
        fi
    fi

    #if [[ "$($wp_exec cli has-command 'revisions' --path=$path && echo $?)" -eq 0 ]] && [[ "$rev" = true ]]; then
    if [[ -n "$(echo "$packages_list" | awk '$1 ~ /trepmal\/wp-revisions-cli/')" ]] && [[ "$rev" = true ]]; then
        echo -e "\n\033[1mKeep only $revisions revisions...\033[0m"
        wp revisions clean $revisions --path=$rep_wordpress --dry-run

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

        trackback=$(wp comment list --type=trackback --format=ids --path=$rep_wordpress)
        if [ -n "$trackback" ]; then
            wp comment delete "$trackback" --path=$rep_wordpress --dry-run
        else
            echo "No trackback post"
        fi

        echo -e "\n\033[1mPingback list...\033[0m"

        pingback=$(wp comment list --type=pingback --format=ids --path=$rep_wordpress)
        if [ -n "$pingback" ]; then
            wp comment delete "$pingback" --path=$rep_wordpress --dry-run
        else
            echo "No pingback post"
        fi
    fi


    # Ouvrir le tableau de bord dans un navigateur:
    # Nécéssite le paquet admin-command (sera installé si nécessaire)

    if [[ -n "$(echo "$packages_list" | awk '$1 ~ /wp-cli\/admin-command/')" ]] && [[ "$admin" = true ]]; then
        echo -e "\n\033[1mOpen wp-admin/ page in browser...\033[0m"
        wp admin --path=$rep_wordpress
    elif [ "$admin" = true ]; then
        wp package install wp-cli/admin-command
        echo ""
        echo -e "\n\033[1mOpen wp-admin/ page in browser...\033[0m"
        wp admin --path=$rep_wordpress
    fi


fi
