#!/usr/bin/env bash

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo -e "\033[93m\033[1maltKymsu\033[0m"
  echo ""
  echo "alt Keep Your macOs Stuff Updated"
  echo "a fork from kymsu https://github.com/welcoMattic/kymsu"
  echo
  echo "USAGE: kymsu2"
  echo
  echo "Commandes: "
  echo "   -h, --help     display this help"
  echo "   --nodistract   no distract mode (no user interaction)"
  echo "   --cleanup      removing any older versions of installed formulae and clearing old downloads from the Homebrew download-cache"
  echo "   --npm_cleanup  cleaning npm cache"
  echo "   --all          run all scripts (by default, all except those start by _)"
  echo
  echo "Tips:"
  echo " -prefix the plugin with _ to ignore it"
  echo " -see Settings section on top of each plug-in"
  echo
  exit 0
fi

echo "Please, grab a ☕️, KYMSU keep your working environment up to date!"

SCRIPTS_DIR=$HOME/.kymsu/plugins.d

[[ $@ =~ "--all" ]] && all_plugins=true || all_plugins=false
if [ "$all_plugins" = false ]; then
	# Tous sauf commençant par _ (les fichiers commençant par '_' ne sont pas pris en compte) "_*.sh"
	list_plugins=$(find $SCRIPTS_DIR -maxdepth 1 -type f ! -name "_*" -a -name "*.sh" -a -perm +111 | sort)
else
	# Tous (-a = ET; -perm +111 = exec)
	list_plugins=$(find $SCRIPTS_DIR -maxdepth 1 -type f -name "*.sh" -a -perm +111 | sort)
fi

cd "$SCRIPTS_DIR"

for script in $list_plugins; do
         # le $@ permet de passer à chaque script les arguments passés à *ce* script
         $script $@
done
