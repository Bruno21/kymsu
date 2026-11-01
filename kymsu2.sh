#!/usr/bin/env bash


# Configuration
all_plugins=false
SCRIPTS_DIR=$HOME/.kymsu/plugins.d
export SCRIPTS_DIR


function showHelp() {
  echo -e "\033[93m\033[1maltKymsu\033[0m"
  echo ""
  echo "alt Keep Your macOs Stuff Updated"
  echo "a fork from kymsu https://github.com/welcoMattic/kymsu"
  echo
  echo "USAGE: kymsu2"
  echo
  echo "Commandes: "
  echo "   -h, --help         display this help"
  echo "   -n, --nodistract   no distract mode (no user interaction)"
  echo "   -c, --cleanup      removing any older versions of installed formulae and clearing old downloads from the Homebrew download-cache"
  #echo "   --npm_cleanup  cleaning npm cache"
  echo "   -p, --pref         open configuration file kymsu.cfg in your editor"
  echo "   -s <script>        run only the script given in argument"
  echo "   -a, --all          run all scripts (by default, all except those start by _)"
  echo
  echo "Tips:"
  echo " -prefix the plugin with _ to ignore it"
  echo " -see Settings section on top of each plug-in"
  echo
#  exit 0
}

function preferences() {
	"${EDITOR:-vi}" "$SCRIPTS_DIR/kymsu.cfg"
}


while getopts "phncs:a-:" opt
do
	case $opt in
		-) case "${OPTARG}" in
			help) showHelp; exit;;
			pref) preferences; exit;;
			nodistract) : ;;			# transmis aux plugins via "$@" => no_distract=true
			cleanup) : ;;				# transmis aux plugins via "$@" => cleanup=true
			all) all_plugins=true;;
			*)
				echo "Unknown option '--${OPTARG}'" >&2
				exit 1;;
			esac;;
		p) preferences; exit;;
		h) showHelp; exit;;
		n) : ;;							# transmis aux plugins via "$@" => no_distract=true
		c) : ;;							# transmis aux plugins via "$@" => cleanup=true
		s) one_script="${OPTARG}";;
		a) all_plugins=true;;
		*)
			echo "Unknown option '-$opt'" >&2
			exit 1;;
	esac
done


# shellcheck source=/dev/null
source "$SCRIPTS_DIR/config.shlib"	# load the config library functions

# Style
italic="$(config_get italic)"
reset="$(config_get reset)"


# -n : non vide
if [ -n "$one_script" ]; then
	# Un seul script (commençant ou non par _)
	list_plugins=$(find "$SCRIPTS_DIR" -maxdepth 1 -type f -a \( -name "$one_script" -o -name "_$one_script" \) -a -perm -u+x)
	[ -z "$list_plugins" ] && echo -e "❗️ No named plugin ${italic}$one_script${reset}" && exit 1
	
elif [ "$all_plugins" = false ]; then
	# Tous sauf commençant par _ (les fichiers commençant par '_' ne sont pas pris en compte) "_*.sh"
	list_plugins=$(find "$SCRIPTS_DIR" -maxdepth 1 -type f ! -name "_*" -a -name "*.sh" -a -perm -u+x | sort)
	[ -z "$list_plugins" ] && echo -e "❗️ No plugin in ${italic}$SCRIPTS_DIR${reset}" && exit 1
else
	# Tous (-a = ET; -perm -u+x = exec)
	list_plugins=$(find "$SCRIPTS_DIR" -maxdepth 1 -type f -name "*.sh" -a -perm -u+x | sort)
	[ -z "$list_plugins" ] && echo -e "❗️ No plugin in ${italic}$SCRIPTS_DIR${reset}" && exit 1
fi


cd "$SCRIPTS_DIR" || exit 1


echo "Please, grab a ☕️, KYMSU keep your working environment up to date!"
echo ""

while IFS= read -r script; do
    # le $@ permet de passer à chaque script les arguments passés à *ce* script
  	"$script" "$@"
done <<< "$list_plugins"
