#!/usr/bin/env bash

italic="\033[3m"
underline="\033[4m"
ita_under="\033[3;4m"
bgd="\033[1;4;31m"
red="\033[1;31m"
bold="\033[1m"
bold_ita="\033[1;3m"
box="\033[1;41m"
reset="\033[0m"

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
  echo "   -s $script         run only the script given in argument"
  echo "   -a, --all          run all scripts (by default, all except those start by _)"
  echo
  echo "Tips:"
  echo " -prefix the plugin with _ to ignore it"
  echo " -see Settings section on top of each plug-in"
  echo
#  exit 0
}

all_plugins=false
no_distract=false
brew_cleanup=false
SCRIPTS_DIR=$HOME/.kymsu/plugins.d

while getopts "hncs: a-:" opt
do
	case $opt in
		-) case "${OPTARG}" in
			help) showHelp; exit;;
			nodistract) no_distract=true;;
			cleanup) brew_cleanup=true;;
			all) all_plugins=true;;
			*)
				echo "Unknow option '--${OPTARG}'" >&2
				exit -1;;
			esac;;
		h) showHelp; exit;;
		n) no_distract=true;;
		c) brew_cleanup=true;;
		s) one_script="${OPTARG}";;
		a) all_plugins=true;;
		*)
			echo "Unknow option '-$opt'" >&2
			exit -1;;
	esac
done
		
#shift "$((OPTIND-1))"


# -n : non vide
if [ -n "$one_script" ]; then
	# Un seul script
	#list_plugins=$(find $SCRIPTS_DIR -maxdepth 1 -type f -name "*$one_script" -a -perm +111)
	list_plugins=$(find $SCRIPTS_DIR -maxdepth 1 -type f -name "$one_script" -o -name "_$one_script" -a -perm +111)
	[ -z "$list_plugins" ] && echo -e "❗️ No named plugin ${italic}$one_script${reset}" && exit -1
	
# [[ $@ =~ "--all" ]] && all_plugins=true || all_plugins=false
elif [ "$all_plugins" = false ]; then
	# Tous sauf commençant par _ (les fichiers commençant par '_' ne sont pas pris en compte) "_*.sh"
	list_plugins=$(find $SCRIPTS_DIR -maxdepth 1 -type f ! -name "_*" -a -name "*.sh" -a -perm +111 | sort)
	[ -z "$list_plugins" ] && echo -e "❗️ No plugin in ${italic}$SCRIPTS_DIR${reset}" && exit -1
else
	# Tous (-a = ET; -perm +111 = exec)
	list_plugins=$(find $SCRIPTS_DIR -maxdepth 1 -type f -name "*.sh" -a -perm +111 | sort)
	[ -z "$list_plugins" ] && echo -e "❗️ No plugin in ${italic}$SCRIPTS_DIR${reset}" && exit -1
fi


cd "$SCRIPTS_DIR"

<<COMMENT
echo "$list_plugins"

echo "all args: $@"
echo ""
echo "script: $one_script"
echo ""
COMMENT


echo "Please, grab a ☕️, KYMSU keep your working environment up to date!"
echo ""

for script in $list_plugins; do
         # le $@ permet de passer à chaque script les arguments passés à *ce* script
         $script $@
         #echo "$script"
done

shift "$((OPTIND-1))"
