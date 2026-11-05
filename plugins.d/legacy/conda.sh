#!/usr/bin/env bash

# conda plugin for KYMSU
# https://github.com/welcoMattic/kymsu

# If you'd prefer that conda's base environment not be activated on startup, set the auto_activate_base parameter to false:
#   conda config --set auto_activate_base false

# In order to initialize after the installation process is done, 
#   first run source <path to conda>/bin/activate and then run conda init.


# Update conda

echo -e "\033[1m🦎 conda \033[0m"

path_to_conda=$(conda config --show | grep 'root_prefix' | awk '{print $2}')

cd $path_to_conda
#conda update conda
# conda update -n base -c defaults conda
#upd=$(conda update --all)
#echo $upd

#avail_update=$(echo $upd | grep '$ conda update -n base -c defaults conda')
#avail_update=$(conda update --all | grep '$ conda update -n base -c defaults conda')
#avail_update=$(conda update --all)
conda update --all


avail_update="$(conda update --all 2>&1 > /dev/null)"


# Proceed ([y]/n)? n

echo "---"

if echo "$avail_update" | grep -q "$ conda update -n base -c defaults conda"
then
	echo "need update"
fi

echo ""



# If you want to update to a newer version of Anaconda, type:
#
# $ conda update --prefix /Users/bruno/miniconda3 anaconda


# Initialisation

# source $HOME/miniconda3/bin/activate
# source $path_to_conda/bin/activate
# conda init


# Configuration

#conda config --help
#conda config --set auto_update_conda False


# Packages installés dans l'environnement conda

echo -e "\033[4mInstalled packages in conda environment:\033[0m"
echo ""
conda list