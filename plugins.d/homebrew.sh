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
# declare -a do_not_update=("xnconvert" "yate")
declare -a do_not_update=()

# No distract mode (no user interaction)(Casks with 'latest' version number won't be updated)
no_distract=false

latest=false
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

if [[ $1 == "--latest" ]]; then
	latest=true
fi

echo -e "\033[1m🍺  Homebrew \033[0m"
echo ""

brew update

echo ""
echo "Search for packages update..."
echo ""

declare -A array_info 	# bash 5
declare -A array_info_cask

if [ -x "$(command -v jq)" ]; then

	### Recherche des mises-à-jour ###
	
	brew_outdated2=$(brew outdated --greedy --json=v2)
	upd_json=$(echo "$brew_outdated2")
	
	upd_package=$(echo "$upd_json" | jq '{formulae} | .[]')

	upd_cask=$(echo "$upd_json" | jq '{casks} | .[]')

	
	### Liste des mises-à-jour (paquets et casks) ###
		
	for row in $(jq -c '{formulae} | .[] | .[]' <<< "$upd_json");
	do
		name=$(echo "$row" | jq -j '.name')
		pinned=$(echo "$row" | jq -j '.pinned')
		
		upd_pkg+="$name "
		if [ "$pinned" = true ]; then
			upd_pkg_pinned+="$name "
		fi
	done
	upd_pkg=$(echo "$upd_pkg" | sed 's/.$//')
	upd_pkg_pinned=$(echo "$upd_pkg_pinned" | sed 's/.$//')
	
	pkg_pinned=$(brew list --pinned | xargs)


	### Recherche des infos sur les paquets ###

	if [ -n "$upd_pkg" ]; then
		# Only 1 request 'brew info' for all updated packages
		info=$(brew info --json=v1 $upd_pkg)
	
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
			
			eval "declare -a array_info$i=($name $homepage $desc $pinned $installed_v $stable)"
			((i++))
		done
		nb_upd_pkg=$i
		i=0
	fi

else
	brew_outdated=$(brew outdated)	
	upd_pkg=$(echo "$brew_outdated" | awk '{print $1}')
	
	if [ -n "$upd_pkg" ]; then
		info=$(brew info $upd_pkg)
		for i in $upd_pkg
		do
			a=$(grep -A 3 "$i: stable" <<< "$info")
			array_info["$i"]="$a"
		done
		nb_upd_pkg=${#array_info[@]}
	fi
fi


### Display pinned packages ##

if [ -n "$pkg_pinned" ]; then

	nbp=$(echo "$pkg_pinned" | wc -w | xargs)

	echo -e "\033[4mList of\033[0m \033[1;41m $nbp \033[0m \033[4mpinned packages:\033[0m"
	echo -e "\033[1;31m$pkg_pinned\033[0m"
	echo "To update a pinned package, you need to un-pin it manually (brew unpin <formula>)"
	echo ""

fi


### Display infos for all updated packages ##

if [ -n "$upd_pkg" ]; then
		
	# Display info on outdated packages
	
	if [ "$display_info" = true ]; then
		echo -e "\033[4mInfo on\033[0m \033[1;41m $nb_upd_pkg \033[0m \033[4mupdated packages:\033[0m"
		
		if [ -x "$(command -v jq)" ]; then
		# ok avec jq installé
		
			i=0
			for row in $(jq -c '.[]' <<< "$upd_package");
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
				
				#echo "$name - $homepage - $desc"
				
				#info_pkg=$(brew info --json=v1 "$name")
				#homepage=$(echo "$info_pkg" | jq -r .[].homepage)
				#desc=$(echo "$info_pkg" | jq -r .[].desc)
				#current=$(echo "$info_pkg" | jq -r .[].installed[].version | tail -n 1 | awk '{print $1}')
				#stable=$(echo "$info_pkg" | jq -r .[].versions.stable)
				#pined=$(echo "$info_pkg" | jq -r .[].pinned)
				
				if [ "$pinned" = "true" ]; then 
					l1+="\033[1;31m$name: installed: $installed_v stable: $current_v [pinned at $pinned_v]\033[0m\n";
				else 
					l1+="\033[1;37m$name: installed: $installed_v stable: $current_v\033[0m\n";
				fi
				if [ "$desc" != "null" ]; then l1+="$desc\n"; fi;
				l1+="\033[4m$homepage\033[0m\n"
				l1+="\n"

				((i++))
			done
			
			echo -e "$l1"
		else
		# ok sans jq
		
			for pkg in $upd_pkg
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


	### Usefull for notify recent modification of apache/mysql/php conf files. ###
	touch /tmp/checkpoint


	### Remove pinned packages from outdated packages list ###

	not_pinned=""
	for i in $upd_pkg
	do
		if [[ ! " ${upd_pkg_pinned[@]} " =~ " ${i} " ]]; then
   			# whatever you want to do when array doesn't contain value
   			not_pinned+="$i "
		fi

	done
	not_pinned=$(echo "$not_pinned" | sed 's/.$//')


	### Update outdated packages ###
	
	if [ "$no_distract" = false ]; then
	
		if [ -n "$not_pinned" ]; then
		
			a=$(echo -e "Do you wanna run \033[1mbrew upgrade "$not_pinned"\033[0m ? (y/n/a)")
			# yes/no/all
			read -p "$a" choice
		
			if [ "$choice" == "y" ] || [ "$choice" == "Y" ] || [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
		
				for i in $not_pinned
				do	
					FOUND=`echo ${do_not_update[*]} | grep "$i"`
					if [ "${FOUND}" = "" ]; then
						if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
							echo "$i" | awk '{print $1}' | xargs -p -n 1 brew upgrade
							echo ""
						elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
							echo "$i" | awk '{print $1}' | xargs -n 1 brew upgrade
							echo ""
						fi
					fi
				done
			else
				echo "Ok, let's continue"		
			fi
		fi
		
	else	# no distract = true
	
		if [ -n "$not_pinned" ]; then
			echo "$not_pinned" | awk '{print $1}' | xargs -n 1 brew upgrade
			echo ""
		fi
		
	fi
	
	
	echo ""

else
	echo -e "\033[4mNo package to update.\033[0m"
fi

echo ""

#################
##### CASKS #####
#################

echo -e "\033[1m🍺  Casks upgrade \033[0m"
echo ""

if (( ${#do_not_update[@]} )); then

	nbp=${#do_not_update[*]}
	
	echo -e "\033[4mList of\033[0m \033[1;41m $nbp \033[0m \033[4m'do not update' packages:\033[0m"
	echo -e "\033[1;31m${do_not_update[*]}\033[0m"
	echo "To remove package from this list, you need to edit the do_not_update array."
	echo ""

fi

echo "Search for Casks update..."
echo ""

i=0
for row in $(jq -c '.[]' <<< "$upd_cask");
do
	name=$(echo "$row" | jq -j '.name')
	installed_versions=$(echo "$row" | jq -j '.installed_versions')
	current_version=$(echo "$row" | jq -j '.current_version')
		
	if [ "$current_version" != "latest" ]; then
		upd_casks+="$name "
		
		eval "declare -a array_info_cask$i=($name $installed_versions $current_version)"
		((i++))
		
	elif [ "$current_version" == "latest" ]; then
		upd_casks_latest+="$name "
	fi

done

upd_casks=$(echo "$upd_casks" | sed 's/.$//')	
upd_casks_latest=$(echo "$upd_casks_latest" | sed 's/.$//')	

nb_upd_casks=$(echo "$upd_casks" | wc -w | xargs)
nb_upd_casks_latest=$(echo "$upd_casks_latest" | wc -w | xargs)


if [ -z "$upd_casks" ] && [ -z "$upd_casks_latest" ]; then

	echo -e "\033[4mNo availables Cask updates.\033[0m"
	
else

	if [ -n "$upd_casks" ]; then

		echo -e "\033[1;41m $nb_upd_casks \033[0m \033[4mAvailables Casks updates:\033[0m"
		
		# Display info on outdated packages
	
		if [ "$display_info" = true ]; then

			info_cask=$(brew cask info $upd_casks)

			for i in $upd_casks
			do
				b=$(grep -A 1 "$i:" <<< "$info_cask")
				bb=$(echo "$b" | tail -n 1)
				array_info_cask["$i"]="$bb"
			done

			l1=""
			for row in $(jq -c '.[]' <<< "$upd_cask");
			do		
				installed_versions=$(echo "$row" | jq -j '.installed_versions')
				if [ "$installed_versions" != "latest" ]; then
					name=$(echo "$row" | jq -j '.name')
					current_version=$(echo "$row" | jq -j '.current_version')
					url=${array_info_cask[$name]}
					
					if [[ ! " ${do_not_update[@]} " =~ " ${name} " ]]; then
						l1+="\033[1;37m$name: installed: $installed_versions current: $current_version\033[0m\n"
					else
						l1+="\033[1;31m$name: installed: $installed_versions current: $current_version [Do not update]\033[0m\n"
					fi					
					l1+="$url\n\n"
				fi
			done
			
			echo -e "$l1" | sed ':a;N;$!ba;s/\n//g'

		fi
		
		echo ""
		
		#brew cask info betterzip

		##########
		if [ "$no_distract" = false ]; then
		
			a=$(echo -e "Do you wanna run \033[1;37mbrew upgrade homebrew/cask/$upd_casks\033[0m ? (y/n/a)")
			# yes/no/all
			read -p "$a" choice
		
			if [ "$choice" == "y" ] || [ "$choice" == "Y" ] || [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
		
				# boucle for: don't stop multiples updates if one block (bad checksum, not compatible with OS version (Onyx))

				for i in $upd_casks
				do
					FOUND=`echo ${do_not_update[*]} | grep "$i"`
		
					if [ "${FOUND}" == "" ]; then
				#echo "$i" | xargs brew cask reinstall
				#echo "$i" | xargs -p -n 1 brew reinstall
				#echo "$i" | xargs -p -n 1 brew upgrade --cask

						#b=$(echo -e "Do you wanna run \033[1;37mbrew upgrade homebrew/cask/$i\033[0m ? (y/n)")
  						#read -p "$b" choice				

						if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
							echo "$i" | awk '{print $1}' | xargs -p -n 1 brew upgrade homebrew/cask/$i
							retCode=$?
							echo "code retour: $retCode"
							echo ""
						elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
							brew upgrade homebrew/cask/$i
							retCode=$?
							echo "code retour: $retCode"
							echo ""
						fi
				
					fi
				done
			else
				echo "Ok, let's continue"		
			fi
		else	# no distract = true
			echo "no distract"
		
		fi
		#########
	fi
	
	echo ""
	
	if [ -n "$upd_casks_latest" ] && [ "$latest" == true ]; then

		echo -e "\033[1;41m $nb_upd_casks_latest \033[0m \033[4mCasks (latest) updates:\033[0m"

		# Display info on outdated packages
	
		if [ "$display_info" = true ]; then

			info_cask_latest=$(brew cask info $upd_casks_latest)
			
			for i in $upd_casks_latest
			do
				c=$(grep -A 1 "$i:" <<< "$info_cask_latest")
				cc=$(echo "$c" | tail -n 1)
				array_info_cask["$i"]="$cc"
			done

			l2=""
			for row in $(jq -c '.[]' <<< "$upd_cask");
			do		
				installed_versions=$(echo "$row" | jq -j '.installed_versions')
				if [ "$installed_versions" = "latest" ]; then
					name=$(echo "$row" | jq -j '.name')
					current_version=$(echo "$row" | jq -j '.current_version')
					url=${array_info_cask[$name]}

					if [[ ! " ${do_not_update[@]} " =~ " ${name} " ]]; then
						l2+="\033[1;37m$name: installed: $installed_versions current: $current_version\033[0m\n"
				    else
						l2+="\033[1;31m$name: installed: $installed_versions current: $current_version [Do not update]\033[0m\n"	    
					fi
					l2+="$url\n\n"
				fi
			done
			
			echo -e "$l2" | sed ':a;N;$!ba;s/\n//g'
			
		fi
		
		echo ""
	
		q=$(echo -e "Do you wanna run \033[1;37mbrew upgrade --cask --greedy <cask>\033[0m ? (y/n/a)")
		read -p "$q" choice

		if [ "$choice" == "y" ] || [ "$choice" == "Y" ] || [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
			for i in $upd_casks_latest
			do
				FOUND=`echo ${do_not_update[*]} | grep "$i"`
		
				if [ "${FOUND}" == "" ]; then
				
					if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
						echo "$i" | xargs -p -n 1 brew upgrade --cask --greedy
						echo ""
					elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
						echo "$i" | xargs -n 1 brew upgrade --cask --greedy
						echo ""
					fi
				fi
			done
		else
			echo "Ok, let's continue..."		
		fi

	fi

fi

echo ""


### Test if Apache conf file has been modified by Homebrew (Apache, PHP or Python updates) ###

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
	if [ -n "$upd_pkg" ]; then

		# file modified since it was last read
	
		php_modified=$(find /usr/local/etc/php/$php/ -name php.ini -newer /tmp/checkpoint)
		php_ini=/usr/local/etc/php/$php/php.ini
		notif2="$php_ini has been modified"
	
		echo "$php_modified"
	
		[ ! -z $php_modified ] && echo -e "\033[1;31m❗️ ️$notif2\033[0m"
		[ ! -z $php_modified ] && notification "$notif2"
		
	fi
	
done
echo ""


##############
### Doctor ###
##############

echo "🍺  ️The Doc is checking that everything is ok."
echo ""

brew doctor

brew missing
status=$?
if [ $status -ne 0 ]; then brew missing --verbose; fi
echo ""

# Homebrew 2.0.0+ run a cleanup every 30 days

if [[ $1 == "--cleanup" ]]; then
  echo "🍺  Cleaning brewery"
  
  #HOMEBREW_NO_INSTALL_CLEANUP
  
  brew cleanup --prune=30
  echo ""
fi

echo ""
