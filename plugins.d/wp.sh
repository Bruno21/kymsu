#!/usr/bin/env bash

# wp-cli plugin for KYMSU
# https://github.com/welcoMattic/kymsu
# fork https://github.com/Bruno21/kymsu
# https://make.wordpress.org/cli/handbook/

###############################################################################################
#
# Require software:
#   -wp-cli (WordPress command-line interface) (https://wp-cli.org/)
#   -fzf (Command-line fuzzy finder) (https://junegunn.github.io/fzf/)
#
###############################################################################################

# TODO:
#  - Rapports: ajouter les opérations de maintenance faites (utile ??)
#  - Créer le README.md (insister sur la sécurité pour GPG)
#  - Support de plusieurs installations WordPress (à voir si possible en ssh, sinon non)


#########################################
#
# Settings:
#  - use kymsu.cfg for configuring options

SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/.kymsu/plugins.d}"

if [ ! -r "$SCRIPTS_DIR/config.shlib" ]; then
	echo "config.shlib not found in $SCRIPTS_DIR (set SCRIPTS_DIR or check the KYMSU installation)." >&2
	exit 1
fi
# shellcheck source=/dev/null
source "$SCRIPTS_DIR/config.shlib"

bold="$(config_get bold)"
underline="$(config_get underline)"
greenbold="$(config_get greenbold)"
red="$(config_get red)"
reset="$(config_get reset)"

# WordPress installation path
#rep_wordpress=$(config_get wp_rep_wordpress)
#rep_wordpress="${rep_wordpress/#\$HOME/$HOME}"; rep_wordpress="${rep_wordpress/#\~/$HOME}"
#rep_wordpress="${rep_wordpress:-$HOME/Sites/blog}"   # default if wp_rep_wordpress is not set in kymsu.cfg

# Multi WordPress installation path
read -r -a wp_sites_arr <<< "$(config_get wp_sites)"
wp_sites_arr=("${wp_sites_arr[@]/#\$HOME/$HOME}")
wp_sites_arr=("${wp_sites_arr[@]/#\~/$HOME}")
[[ ${#wp_sites_arr[@]} -eq 0 ]] && wp_sites_arr=("$rep_wordpress")

# Encryptage asymétrique
recipient=$(config_get wp_gpg_recipient)
[[ "$recipient" == "__UNDEFINED__" ]] && recipient=""
# Encryptage symétrique
passphrase_file=$(config_get wp_passphrase_file)
[[ "$passphrase_file" == "__UNDEFINED__" ]] && passphrase_file=""
passphrase_file="${passphrase_file/#\$HOME/$HOME}"
passphrase_file="${passphrase_file/#\~/$HOME}"

# Maintenance options
maint=true
transient=true
database=true
backup=true
backup_keep=$(config_get wp_backup_keep)	# number of database backups to keep
[[ "$backup_keep" == "__UNDEFINED__" || -z "$backup_keep" ]] && backup_keep=5
removespam=true
emptytrash=true
rev=true
revisions=3        # requires trepmal/wp-revisions-cli
back=true          # trackback & pingback (dry-run)
admin=false

# --- Rapport final ---
report_core=""
report_plugins_updated=()
report_plugins_failed=()
report_plugins_skipped=()
report_themes_updated=()
report_themes_failed=()
report_themes_skipped=()
report_langs_updated=()
report_failed=()

# Mode
no_distract=false
OPTIND=1
while getopts "phncs:a-:" opt; do
	case $opt in
		n) no_distract=true ;;
		-) case "$OPTARG" in
			nodistract) no_distract=true ;;
			*) ;;
		esac ;;
		c|p|h|s|a) ;;
		*) ;;
	esac
done

#
#########################################

# --- Checks ---

# Définition de la commande avec la gestion des erreurs PHP et le chemin de wp
if ! wp_bin=$(command -v wp); then
	echo -e "${red}wp-cli not found !${reset}"
	exit 1
fi
export WP_CLI_PHP_ARGS="-d error_reporting=E_ALL\&~E_DEPRECATED"

# Pour wp package list uniquement (Deprecated: sur stdout)
WP_PKG=(php -d 'error_reporting=E_ALL & ~E_DEPRECATED' "$wp_bin")

if ! check_internet; then
	echo -e "\n${red}No Internet connection !${reset}"
	echo -e "Exit !"
	exit 1
fi

for rep_wordpress in "${wp_sites_arr[@]}"; do

	cd "$rep_wordpress" || { echo -e "${red}WordPress path not found: $rep_wordpress${reset}"; exit 1; }

	echo -e "\n${bold}🟦 WordPress${reset}\n"

	[[ "$no_distract" == true ]] && echo -e "${greenbold}No-distract mode: all updates will be applied automatically.${reset}\n"

	# --- WP --info ---
	echo -e "${greenbold}📰 WP --info...${reset}\n"
	wp_info=$("${WP_PKG[@]}" --info)
	echo "$wp_info"

	wp_version=$("${WP_PKG[@]}" core version)
	echo "WordPress version: $wp_version"
	echo ""

	echo ""
	echo -e "${greenbold}🔧 Updates${reset}\n"

	# --- Core update ---
	echo -e "${bold}Checking core update... (current: $wp_version)${reset}"
	core_cu=$("${WP_PKG[@]}" core check-update 2>/dev/null)
	if [[ "$core_cu" != *"latest version"* ]]; then
		echo -e "New WordPress version available!\n"
		if [[ "$no_distract" == true ]]; then
			if "${WP_PKG[@]}" core update && "${WP_PKG[@]}" core update-db; then
				report_core="updated"
			else
				report_core="failed"
				report_failed+=("core")
			fi
		else
			read -r -p "$(echo -e "Do you wanna upgrade ${bold}WordPress core${reset} ? (y/n) ")" choice
			if [[ "${choice,,}" == "y" ]]; then
				if "${WP_PKG[@]}" core update && "${WP_PKG[@]}" core update-db; then
					report_core="updated"
				else
					report_core="failed"
					report_failed+=("core")
				fi
			else
				echo "Skipped."
				report_core="skipped"
			fi
		fi
	else
		echo "WordPress core is up to date!"
	fi
	echo ""

	# --- Plugins update ---
	echo -e "${bold}Checking plugins update...${reset}"

	echo -e "\n${bold}Installed plugins:${reset}"
	"${WP_PKG[@]}" plugin list --format=table --fields=name,status,version 2>/dev/null
	echo ""

	plugins_outdated=$("${WP_PKG[@]}" plugin list --update=available --format=csv --fields=name,version,update_version | tail -n +2)

	if [[ -z "$plugins_outdated" ]]; then
		echo "No plugin update available!"
	else
		nb=$(echo "$plugins_outdated" | wc -l | tr -d ' ')
		echo -e "$nb plugin(s) to update:\n"

		col_name=$(echo "$plugins_outdated" | awk -F',' '{print length($1)}' | sort -n | tail -1)
		col_name=$(( col_name > 4 ? col_name : 4 ))
		col_ver=$(echo "$plugins_outdated" | awk -F',' '{print length($2)}' | sort -n | tail -1)
		col_ver=$(( col_ver > 9 ? col_ver : 9 ))

		printf "${bold}%-*s  %-*s  %s${reset}\n" "$col_name" "Name" "$col_ver" "Installed" "Available"
		echo "$plugins_outdated" | awk -F',' -v cn="$col_name" -v cv="$col_ver" \
			'{printf "%-*s  %-*s  →  %s\n", cn, $1, cv, $2, $3}'
		echo ""

		if [[ "$no_distract" == true ]]; then
			mapfile -t selected_plugins < <(echo "$plugins_outdated" | awk -F',' '{print $1}')
		else
			read -r -p "$(echo -e "Do you wanna update ${bold}${nb} plugin(s)${reset} ? (y=choose/a=all/n) ")" choice

			case "${choice,,}" in
				a)
					mapfile -t selected_plugins < <(echo "$plugins_outdated" | awk -F',' '{print $1}')
					;;
				y)
					if ! command -v fzf >/dev/null; then
						echo -e "${red}fzf not found${reset} (brew install fzf)"
						exit 1
					fi
					formatted=$(echo "$plugins_outdated" | awk -F',' -v cn="$col_name" -v cv="$col_ver" \
						'{printf "%-*s  %-*s  →  %s\n", cn, $1, cv, $2, $3}')
					mapfile -t selected_plugins < <(
						printf '%s\n' "$formatted" |
						fzf --multi --height=80% --reverse \
							--header $'Name  Installed  →  Available\nTab: select | Ctrl-A: all | Enter: validate | Esc: cancel\n' \
							--bind 'ctrl-a:select-all' \
							--preview-window=hidden \
						| awk '{print $1}'
					)
					if (( ${#selected_plugins[@]} == 0 )); then
						echo "Nothing selected."
						selected_plugins=()
					fi
					;;
				*)
					echo "Skipped."
					selected_plugins=()
					;;
			esac
		fi

		for plugin in "${selected_plugins[@]}"; do
			[[ -n "$plugin" ]] || continue
			echo -e "\n${bold}Updating plugin: $plugin${reset}"
			if "${WP_PKG[@]}" plugin update "$plugin"; then
				report_plugins_updated+=("$plugin")
			else
				report_plugins_failed+=("$plugin")
				report_failed+=("plugin:$plugin")
			fi
		done

		# Plugins disponibles mais non sélectionnés
		mapfile -t all_plugins < <(echo "$plugins_outdated" | awk -F',' '{print $1}')
		for plugin in "${all_plugins[@]}"; do
			[[ " ${selected_plugins[*]} " == *" $plugin "* ]] || report_plugins_skipped+=("$plugin")
		done
	fi
	echo ""

	# --- Themes update ---
	echo -e "${bold}Checking themes update...${reset}"

	echo -e "\n${bold}Installed themes:${reset}"
	"${WP_PKG[@]}" theme list --format=table --fields=name,status,version 2>/dev/null
	echo ""

	themes_outdated=$("${WP_PKG[@]}" theme list --update=available --format=csv --fields=name,version,update_version 2>/dev/null | tail -n +2)

	if [[ -z "$themes_outdated" ]]; then
		echo "No theme update available!"
	else
		nb=$(echo "$themes_outdated" | wc -l | tr -d ' ')
		echo -e "$nb theme(s) to update:\n"

		col_name=$(echo "$themes_outdated" | awk -F',' '{print length($1)}' | sort -n | tail -1)
		col_name=$(( col_name > 4 ? col_name : 4 ))
		col_ver=$(echo "$themes_outdated" | awk -F',' '{print length($2)}' | sort -n | tail -1)
		col_ver=$(( col_ver > 9 ? col_ver : 9 ))

		printf "${bold}%-*s  %-*s  %s${reset}\n" "$col_name" "Name" "$col_ver" "Installed" "Available"
		echo "$themes_outdated" | awk -F',' -v cn="$col_name" -v cv="$col_ver" \
			'{printf "%-*s  %-*s  →  %s\n", cn, $1, cv, $2, $3}'
		echo ""

		if [[ "$no_distract" == true ]]; then
			mapfile -t selected_themes < <(echo "$themes_outdated" | awk -F',' '{print $1}')
		else
			read -r -p "$(echo -e "Do you wanna update ${bold}${nb} theme(s)${reset} ? (y=choose/a=all/n) ")" choice

			case "${choice,,}" in
				a)
					mapfile -t selected_themes < <(echo "$themes_outdated" | awk -F',' '{print $1}')
					;;
				y)
					if ! command -v fzf >/dev/null; then
						echo -e "${red}fzf not found${reset} (brew install fzf)"
						exit 1
					fi
					formatted=$(echo "$themes_outdated" | awk -F',' -v cn="$col_name" -v cv="$col_ver" \
						'{printf "%-*s  %-*s  →  %s\n", cn, $1, cv, $2, $3}')
					mapfile -t selected_themes < <(
						printf '%s\n' "$formatted" |
						fzf --multi --height=80% --reverse \
							--header $'Name  Installed  →  Available\nTab: select | Ctrl-A: all | Enter: validate | Esc: cancel\n' \
							--bind 'ctrl-a:select-all' \
							--preview-window=hidden \
						| awk '{print $1}'
					)
					if (( ${#selected_themes[@]} == 0 )); then
						echo "Nothing selected."
						selected_themes=()
					fi
					;;
				*)
					echo "Skipped."
					selected_themes=()
					;;
			esac
		fi

		for theme in "${selected_themes[@]}"; do
			[[ -n "$theme" ]] || continue
			echo -e "\n${bold}Updating theme: $theme${reset}"
			if "${WP_PKG[@]}" theme update "$theme"; then
				report_themes_updated+=("$theme")
			else
				report_themes_failed+=("$theme")
				report_failed+=("theme:$theme")
			fi
		done

		# Thèmes disponibles mais non sélectionnés
		mapfile -t all_themes < <(echo "$themes_outdated" | awk -F',' '{print $1}')
		for theme in "${all_themes[@]}"; do
			[[ " ${selected_themes[*]} " == *" $theme "* ]] || report_themes_skipped+=("$theme")
		done
	fi
	echo ""

	# --- Languages update ---
	for lang_type in core plugin theme; do
		echo -e "${bold}Checking $lang_type language update...${reset}"
		lang_outdated=$("${WP_PKG[@]}" language "$lang_type" list --update=available --all --format=csv \
			--fields=language,status,update 2>/dev/null | tail -n +2)

		if [[ -z "$lang_outdated" ]]; then
			echo "No $lang_type language update available!"
		else
			nb=$(echo "$lang_outdated" | wc -l | tr -d ' ')
			echo -e "$nb language(s) to update:"
			echo "$lang_outdated" | awk -F',' '{print "  " $1}'
			echo ""

			if [[ "$no_distract" == true ]]; then
				if "${WP_PKG[@]}" language "$lang_type" update --all; then
					report_langs_updated+=("$lang_type")
				else
					report_failed+=("language:$lang_type")
				fi
			else
				read -r -p "$(echo -e "Do you wanna update ${bold}${nb} $lang_type language(s)${reset} ? (y/n) ")" choice
				if [[ "${choice,,}" == "y" ]]; then
					if "${WP_PKG[@]}" language "$lang_type" update --all; then
						report_langs_updated+=("$lang_type")
					else
						report_failed+=("language:$lang_type")
					fi
				else
					echo "Skipped."
				fi
			fi
		fi
		echo ""
	done


	# --- Maintenance ---
	if [[ "$maint" == true ]]; then

		echo ""
		echo -e "${greenbold}🧹 Maintenance${reset}\n"

		# Installed packages
		echo -e "${bold}Installed packages:${reset}"
		packages_list=$("${WP_PKG[@]}" package list | tail -n +2 | awk '{print $1}')

		if [[ -z "$packages_list" ]]; then
			echo "No packages installed."
		else
			echo "$packages_list"
		fi
		echo ""

		# Transients
		if [[ "$transient" == true ]]; then
			echo -e "${bold}Removing expired transients...${reset}"
			"${WP_PKG[@]}" transient delete --expired --path="$rep_wordpress"
		fi

		# Database
		if [[ "$database" == true ]]; then
			echo -e "\n${bold}Database maintenance...${reset}"
			if "${WP_PKG[@]}" db optimize --quiet --path="$rep_wordpress" >/dev/null 2>&1; then
				echo "Database optimized."
			else
				echo -e "${red}Database optimization failed.${reset}"
			fi
		fi

		# Backup
		if [[ "$backup" == true ]]; then
			GPG_TTY=$(tty)
			export GPG_TTY
			echo -e "\n${bold}Database backup...${reset}"
			blogname=$("${WP_PKG[@]}" option get blogname --path="$rep_wordpress" 2>/dev/null | tr ' ' '_')
			blogname="${blogname:-wordpress}"
			date_backup=$(date +%Y-%m-%d_%H-%M-%S)
			file="wp-${blogname}-${date_backup}.sql"

			if [ -n "$recipient" ]; then
				# 1. Export en utilisant une clé publique (chiffrement asymétrique)
				if "${WP_PKG[@]}" db export - --add-drop-table --path="$rep_wordpress" | gpg --batch --yes --encrypt --recipient "$recipient" -o "../${file}.gpg"; then
					echo "Saved: ../${file}.gpg"
				else
					echo -e "${red}Backup failed!${reset}"
					report_failed+=("backup")
				fi
			elif [ -n "$passphrase_file" ]; then
				# 2. Export direct vers GPG (chiffrement symétrique AES-256)
				if "${WP_PKG[@]}" db export - --add-drop-table --path="$rep_wordpress" | gpg --batch --yes --symmetric --cipher-algo AES256 --passphrase-file "$passphrase_file" -o "../${file}.gpg"; then
					echo "Saved: ../${file}.gpg"
				else
					echo -e "${red}Backup failed!${reset}"
					report_failed+=("backup")
				fi
			else
				# 3. Export .sql (non crypté)
				if "${WP_PKG[@]}" db export "$file" --add-drop-table --path="$rep_wordpress"; then
					mv "$file" "../$file"
					echo "Saved: ../$file"
				else
					echo -e "${red}Backup failed!${reset}"
					report_failed+=("backup")
				fi
			fi

			# Conserver uniquement les backup_keep sauvegardes les plus récentes dans le dossier parent
			pushd "../" >/dev/null

			#ls -t *.sql *.sql.gpg 2>/dev/null | tail -n +6 | while IFS= read -r file; do
			#	echo "$file"
			#done

			#find . -maxdepth 1 \( -name "*.sql" -o -name "*.sql.gpg" \) -type f -print0 | xargs -0 ls -t 2>/dev/null | tail -n +6 | xargs rm -f
			#find . -maxdepth 1 \( -name "wp-${blogname}-*.sql" -o -name "wp-${blogname}-*.sql.gpg" \) -type f -print0 | xargs -0 ls -t 2>/dev/null | tail -n +6 | xargs rm -f

			to_delete=$(find . -maxdepth 1 \( -name "wp-${blogname}-*.sql" -o -name "wp-${blogname}-*.sql.gpg" \) \
				-type f -print0 | xargs -0 ls -t 2>/dev/null | tail -n +"$((backup_keep + 1))")
			[[ -n "$to_delete" ]] && echo "$to_delete" | xargs rm -f
			popd >/dev/null || true
		fi

		# Spam
		if [[ "$removespam" == true ]]; then
			echo -e "\n${bold}Removing spam comments... (dry-run)${reset}"
			spam=$("${WP_PKG[@]}" comment list --status=spam --format=ids --path="$rep_wordpress")
			if [[ -n "$spam" ]]; then
				echo "Found: $spam"
				"${WP_PKG[@]}" comment delete "$spam" --path="$rep_wordpress" --dry-run
			else
				echo "No spam found."
			fi
		fi

		# Trash
		if [[ "$emptytrash" == true ]]; then
			echo -e "\n${bold}Removing trashed comments... (dry-run)${reset}"
			trashed=$("${WP_PKG[@]}" comment list --status=trash,post-trashed --format=ids --path="$rep_wordpress")
			if [[ -n "$trashed" ]]; then
				echo "Found: $trashed"
				"${WP_PKG[@]}" comment delete "$trashed" --path="$rep_wordpress" --dry-run
			else
				echo "No trashed comments."
			fi
		fi

		# Revisions
		if [[ "$rev" == true ]]; then
			if echo "$packages_list" | grep -q 'trepmal/wp-revisions-cli'; then
				echo -e "\n${bold}Keeping only $revisions revisions... (dry-run)${reset}"
				"${WP_PKG[@]}" revisions clean "$revisions" --path="$rep_wordpress" --dry-run
			else
				if [[ "$no_distract" == false ]]; then
					echo -e "\n${underline}wp-revisions-cli not installed.${reset}"
					read -r -p "Do you want to install trepmal/wp-revisions-cli ? (y/n) " choice
					if [[ "${choice,,}" == "y" ]]; then
						"${WP_PKG[@]}" package install trepmal/wp-revisions-cli || exit 1
					fi
				else
					echo -e "\n${underline}wp-revisions-cli not installed, skipping revisions.${reset}"
				fi
			fi
		fi

		# Trackback & Pingback
		if [[ "$back" == true ]]; then
			for type in trackback pingback; do
				echo -e "\n${bold}Removing ${type}s... (dry-run)${reset}"
				ids=$("${WP_PKG[@]}" comment list --type="$type" --format=ids --path="$rep_wordpress")
				if [[ -n "$ids" ]]; then
					echo "Found: $ids"
					"${WP_PKG[@]}" comment delete "$ids" --path="$rep_wordpress" --dry-run
				else
					echo "No ${type} found."
				fi
			done
		fi

		# Admin
		if [[ "$admin" == true ]]; then
			if echo "$packages_list" | grep -q 'wp-cli/admin-command'; then
				echo -e "\n${bold}Opening wp-admin/...${reset}"
				"${WP_PKG[@]}" admin --path="$rep_wordpress"
			else
				echo "Installing wp-cli/admin-command."
				"${WP_PKG[@]}" package install wp-cli/admin-command
				"${WP_PKG[@]}" admin --path="$rep_wordpress"
			fi
		fi

		echo ""
	fi

	# --- Rapport final ---
	echo ""
	echo -e "${greenbold}📋 Summary${reset}\n"

	# Core
	if [[ "$core_cu" == *"latest version"* ]]; then
		echo -e "  Core:      up to date"
	elif [[ "$report_core" == "updated" ]]; then
		echo -e "  Core:      ${greenbold}updated${reset}"
	elif [[ "$report_core" == "failed" ]]; then
		echo -e "  Core:      ${red}failed${reset}"
	elif [[ "$report_core" == "skipped" ]]; then
		echo -e "  Core:      skipped"
	fi

	# Plugins
	if [[ -z "$plugins_outdated" ]]; then
		echo -e "  Plugins:   up to date"
	else
		if (( ${#report_plugins_updated[@]} > 0 )); then
			echo -e "  Plugins:   ${greenbold}updated:${reset} ${report_plugins_updated[*]}"
		fi
		if (( ${#report_plugins_failed[@]} > 0 )); then
			echo -e "  Plugins:   ${red}failed:${reset} ${report_plugins_failed[*]}"
		fi
		if (( ${#report_plugins_skipped[@]} > 0 )); then
			echo -e "  Plugins:   skipped: ${report_plugins_skipped[*]}"
		fi
	fi

	# Themes
	if [[ -z "$themes_outdated" ]]; then
		echo -e "  Themes:    up to date"
	else
		if (( ${#report_themes_updated[@]} > 0 )); then
			echo -e "  Themes:    ${greenbold}updated:${reset} ${report_themes_updated[*]}"
		fi
		if (( ${#report_themes_failed[@]} > 0 )); then
			echo -e "  Themes:    ${red}failed:${reset} ${report_themes_failed[*]}"
		fi
		if (( ${#report_themes_skipped[@]} > 0 )); then
			echo -e "  Themes:    skipped: ${report_themes_skipped[*]}"
		fi
	fi

	# Languages
	if (( ${#report_langs_updated[@]} > 0 )); then
		echo -e "  Languages: ${greenbold}updated:${reset} ${report_langs_updated[*]}"
	else
		echo -e "  Languages: up to date"
	fi

	# Echecs globaux
	if (( ${#report_failed[@]} > 0 )); then
		echo ""
		echo -e "  ${red}Failed:${reset} ${report_failed[*]}"
	fi

	echo ""
done
