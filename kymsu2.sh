#!/usr/bin/env bash

# altKYMSU
# https://github.com/welcoMattic/kymsu
# fork https://github.com/Bruno21/kymsu
# Verified by Claude

#########################################
#
# Settings:
#  - use kymsu.cfg for configuring options

all_plugins=false
KYMSU_HOME="$HOME/.kymsu"
SCRIPTS_DIR=$HOME/.kymsu/plugins.d
export SCRIPTS_DIR

# shellcheck source=/dev/null
if [ ! -r "$SCRIPTS_DIR/config.shlib" ]; then
	echo "config.shlib not found in $SCRIPTS_DIR (set SCRIPTS_DIR or check the KYMSU installation)." >&2
	exit 1
fi
# shellcheck source=/dev/null
source "$SCRIPTS_DIR/config.shlib"	# load the config library functions

italic="$(config_get italic)"
bold="$(config_get bold)"
reset="$(config_get reset)"
#
#########################################

showHelp() {
	echo -e "\033[93m\033[1maltKymsu\033[0m"
	echo ""
	echo "alt Keep Your macOs Stuff Updated"
	echo "a fork from kymsu https://github.com/welcoMattic/kymsu"
	echo
	echo "USAGE: kymsu2 [options]"
	echo
	echo "Options:"
	echo "   -h, --help         display this help"
	echo "   -n, --nodistract   no distract mode (no user interaction)"
	echo "   -c, --cleanup      remove older versions of installed formulae"
	echo "   -m, --modules      activate / deactivate plugins"
	echo "   -p, --pref         open kymsu.cfg in \$EDITOR"
	echo "   -s <script>        run only the given script"
	echo "   -u, --uninstall    uninstall altKYMSU"
	echo "   -a, --all          run all scripts including disabled ones (prefixed by _)"
	echo
	echo "Tips:"
	echo "  - prefix a plugin with _ to disable it"
	echo "  - see Settings section on top of each plugin"
	echo "  - edit preferences with kymsu -p/--pref. The kymsu.cfg file is commented."
	echo
}

# activer / désactiver les plugins
activate_plugins() {
	local f i rep

	echo -e "\n${bold}Activate / Deactivate plugins${reset}\n"

	local has_active=false
	for f in "$SCRIPTS_DIR"/*.sh; do
		[[ -e "$f" ]] || continue
		i="${f##*/}"
		[[ "$i" == 00* ]] && continue

		has_active=true
		read -r -p "$(echo -e "Deactivate ${bold}$i${reset} ? [y/n] ")" rep
		if [[ "${rep,,}" == "y" ]]; then
			mv "$f" "$SCRIPTS_DIR/_$i" && echo -e "  ${bold}$i${reset} deactivated"
		fi
	done
	[[ "$has_active" == false ]] && echo -e "  No active plugins."

	echo -e "\n${bold}Disabled plugins:${reset}\n"

	local has_disabled=false
	for f in "$SCRIPTS_DIR"/_*.sh; do
		[[ -e "$f" ]] || continue
		i="${f##*/}"

		has_disabled=true
		read -r -p "$(echo -e "Re-enable ${bold}${i#_}${reset} ? [y/n] ")" rep
		if [[ "${rep,,}" == "y" ]]; then
			mv "$f" "$SCRIPTS_DIR/${i#_}" && echo -e "  ${bold}${i#_}${reset} enabled"
		fi
	done
	[[ "$has_disabled" == false ]] && echo -e "  No disabled plugins."
	echo ""
}

run_uninstall() {
	local uninstall_script
	uninstall_script="$(cat "$KYMSU_HOME/path")/uninstall.sh"

	if [[ ! -x "$uninstall_script" ]]; then
		echo -e "${red}uninstall.sh not found or not executable:${reset} $uninstall_script" >&2
		exit 1
	fi

	bash "$uninstall_script"
}

preferences() {
	"${EDITOR:-vi}" "$SCRIPTS_DIR/kymsu.cfg"
}

while getopts "pumhncs:a-:" opt; do
	case $opt in
		-) case "${OPTARG}" in
			help)       showHelp; exit 0 ;;
			pref)       preferences; exit 0 ;;
			modules)    activate_plugins; exit 0 ;;
			uninstall)  run_uninstall; exit 0 ;;
			nodistract) : ;;
			cleanup)    : ;;
			all)        all_plugins=true ;;
			*)
				echo "Unknown option '--${OPTARG}'" >&2
				exit 1 ;;
		esac ;;
		p) preferences; exit 0 ;;
		m) activate_plugins; exit 0 ;;
		u) run_uninstall; exit 0 ;;
		h) showHelp; exit 0 ;;
		n) : ;;					# transmis aux plugins via "$@"
		c) : ;;					# transmis aux plugins via "$@"
		s) one_script="${OPTARG}" ;;
		a) all_plugins=true ;;
		*)
			echo "Unknown option '-$opt'" >&2
			exit 1 ;;
	esac
done

# un script
if [ -n "$one_script" ]; then
	list_plugins=$(find "$SCRIPTS_DIR" -maxdepth 1 -type f \
		\( -name "$one_script" -o -name "_$one_script" \) -a -perm -u+x)
	[[ -z "$list_plugins" ]] && echo -e "❗️ No named plugin ${italic}$one_script${reset}" && exit 1

# tous les scripts
elif [[ "$all_plugins" == false ]]; then
	list_plugins=$(find "$SCRIPTS_DIR" -maxdepth 1 -type f \
		! -name "_*" -a -name "*.sh" -a -perm -u+x | sort)
	[[ -z "$list_plugins" ]] && echo -e "❗️ No plugin in ${italic}$SCRIPTS_DIR${reset}" && exit 1

# scripts sélectionnés (voir option -m)
else
	list_plugins=$(find "$SCRIPTS_DIR" -maxdepth 1 -type f \
		-name "*.sh" -a -perm -u+x | sort)
	[[ -z "$list_plugins" ]] && echo -e "❗️ No plugin in ${italic}$SCRIPTS_DIR${reset}" && exit 1
fi

cd "$SCRIPTS_DIR" || exit 1

echo "Please, grab a ☕️, KYMSU keeps your working environment up to date!"
echo ""

# fd 3 : les plugins gardent stdin pour leurs propres "read"
while IFS= read -r -u 3 script; do
	"$script" "$@"
done 3<<<"$list_plugins"
