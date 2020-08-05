#!/usr/bin/env bash

# Antibody plugin for KYMSU
# https://github.com/welcoMattic/kymsu
# https://github.com/getantibody/antibody

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
    title="Antibody"
    #subtitle="Attention !!!"
	message="$1"
	image_err="error.png"
	image_ok="success.png"

	if [[ "$OSTYPE" == "darwin"* ]] && [ -x "$(command -v terminal-notifiera)" ]; then
    	terminal-notifier -title "$title" -message "$message" -sound "$sound" -contentImage "$image_ok"
 	elif [[ "$OSTYPE" == "darwin"* ]] && [ -n "$(which alerter)" ]; then
    	alerter -title "$title" -subtitle "" -message "$message" -sound "$sound" -contentImage "$image_ok" -timeout 3
	fi
}


if [[ $1 == "--nodistract" ]]; then
	no_distract=true
fi

echo -e "\033[1m🙏 Antibody \033[0m"
echo ""

update=$(antibody update 2>&1)

installed=$(echo "$update" | grep "updating")
updated=$(echo "$update" | grep "updated")

if [ -n "$installed" ]; then
	echo -e "\033[4mAntibody modules installed:\033[0m"
	#echo "$installed"

	IFS=$'\n'
	#for i in $(echo "$update" | grep "updating")
	for i in $(echo "$installed")
	do
		url=$(echo "$i" | awk '{print $3}')
		module=$(echo "$i" | awk -F "/" '{print $NF}')
		echo -e "\033[1m$module\033[0m ($url)"
	done
else
	echo -e "\033[4mNo Antibody modules installed.\033[0m"
fi

<<COMMENT
antibody: updating: https://github.com/zsh-users/zsh-history-substring-search
antibody: updating: https://github.com/zsh-users/zsh-completions
antibody: updating: https://github.com/zsh-users/zsh-autosuggestions
antibody: updating: https://github.com/mafredri/zsh-async
antibody: updating: https://github.com/zdharma/fast-syntax-highlighting
antibody: updating: https://github.com/sindresorhus/pure
antibody: updating: https://github.com/marzocchi/zsh-notify
COMMENT

echo ""

if [ -n "$updated" ]; then
	echo -e "\033[4mAntibody modules to update:\033[0m"
	#echo "$updated"

	IFS=$'\n'
	for j in $(echo "$updated")
	do
		url=$(echo "$j" | awk '{print $3}')
		module=$(echo "$j" | awk -F "/" '{print $NF}' | awk '{print $1}')
		commit=$(echo "$j" | awk -F "$url" '{print $NF}')
		last_commit=$(echo "$commit" | awk '{print $NF}')
		echo -e "\033[1m$module\033[0m ($url)"
		echo "Commits: $commit"
		echo "Last commit: "$url"/commits/"$last_commit
		# https://github.com/zsh-users/zsh-completions/commits/
		
		notif="$module has been updated"
		notification "$notif"
	done
else
	echo -e "\033[4mNo Antibody modules to update.\033[0m"
	echo ""	
fi

<<COMMENT
antibody: updated: https://github.com/mafredri/zsh-async 95c2b15 -> 490167c
antibody: updated: https://github.com/marzocchi/zsh-notify 4eea098 -> 8a4abe7
antibody: updated: https://github.com/sindresorhus/pure 0a92b02 -> 3a5355b
antibody: updated: https://github.com/zdharma/fast-syntax-highlighting 303eeee -> 865566c
antibody: updated: https://github.com/zsh-users/zsh-completions ed0c7a7 -> 16b8947
COMMENT
