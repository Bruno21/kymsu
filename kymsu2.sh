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
  echo "   --npm_cleanup    cleaning npm cache"
  echo
  echo "Tips:"
  echo " -prefix the plugin with _ to ignore it"
  echo " -see Settings section on top of each plug-in"
  echo
  exit 0
fi

echo "Please, grab a ☕️, KYMSU keep your working environment up to date!"

SCRIPTS_DIR=$HOME/.kymsu/plugins.d
#SCRIPTS_DIR=$(cat ~/.kymsu/path)/plugins.d

cd "$SCRIPTS_DIR"

# On boucle sur tous les fichiers du répertoire 
# (seuls les fichiers commençant par '_' ou '0' sont pris en compte)
#for script in $(find . -name '[_0]*' -maxdepth 1 | sort); do
for script in $(find . -maxdepth 1 ! -name _\*.sh | sort); do
    # si le fichier est exécutable et n'est pas un dossier
    if [ -x "$SCRIPTS_DIR/$script" ] && [ -f "$SCRIPTS_DIR/$script" ]; then
         # on l’exécute ; le $@ permet de passer à chaque
         # script les arguments passés à *ce* script
         $SCRIPTS_DIR/$script $@
    fi
done