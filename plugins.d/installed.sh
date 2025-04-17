#!/usr/bin/env bash

# List of brew, cask, mas, python, npm, pecl installed...

#########################################
#
# Settings:

# npm local install
local_path=$HOME/Sites/node_modules/
# folder contains Brewfile and Installer.md
#chemin=$(pwd)
chemin=$HOME/Documents/kymsu
#version: pip ou pip3
pip_version=pip3
#
# https://github.com/atom/apm/tags
apm=false
#########################################

#if [ ! -d chemin ]; then mkdir $chemin; fi
mkdir -p $chemin

now=$(date +"%d-%m-%Y_%T" | sed 's/://g')
mac=$(hostname -s)
file=$mac"@"$now
filename="Installed_$file"

echo -e "\033[1m🛠  Installed \033[0m"

echo ''

Installed=$(find $chemin -name 'Installed*.md' -maxdepth 1)
if [ -n "$Installed" ]; then
	echo -e "A file \033[93mInstalled*.md\033[0m already exist! We remove it."
	a=$(echo "$Installed" | xargs rm)
fi


if [ -f $chemin/Brewfile ]; then
	echo -e "The \033[93mBrewfile\033[0m already exist! We rename it."
	find $chemin -name 'Brewfile_*' -maxdepth 1 -print0 | xargs rm
	d=$(date -r $chemin/Brewfile  "+%d-%m-%Y_%H:%M:%S")
	
	mv "$chemin/Brewfile" "$chemin/Brewfile_$mac@$d"
fi

{
echo '# Apps, package, scripts installed:'
echo "*$mac@$now*"
echo ''

echo '[TOC]'
echo ''

# Homebrew

echo '## 🍺  Homebrew'
echo ''
}  >> $chemin/Installed.md

echo -e "🍺  Get Homebrew \033[3m\033[93mtap\033[0m list"

echo '### Tap:' >> $chemin/Installed.md
tap=$(brew tap)
{
echo "\`\`\`bash"
echo "$tap"
echo "\`\`\`"
echo ""
echo ''
} >> $chemin/Installed.md

echo -e "🍺  Get Homebrew \033[3m\033[93mpackages\033[0m installed list"
	
echo '### Packages:' >> $chemin/Installed.md
brew=$(brew list --formula)
{
echo "\`\`\`bash"
echo "$brew"
echo "\`\`\`"
echo ""
echo ''
} >> $chemin/Installed.md

echo -e "🍺  Get Homebrew \033[3m\033[93mCask\033[0m installed list"

echo '### Casks:' >> $chemin/Installed.md
cask=$(brew list --cask)
{
echo "\`\`\`bash"
echo "$cask"
echo "\`\`\`"
echo ""
echo ''
} >> $chemin/Installed.md

# liste des apps de l'Appstore installées (nom & numéro)

echo -e "🍏  Get mas \033[3m\033[93mApp Store applications\033[0m list"

echo '## 🍏  mas (Mac App Store)' >> $chemin/Installed.md
echo '' >> $chemin/Installed.md

appfrommas=$(mas list | sort -k2)
#echo "$appfrommas"
#declare -a appstore
echo "\`\`\`bash" >> $chemin/Installed.md
# todo: trier la liste par nom
while read -r line; do
	number=$(echo "$line" | awk '{print $1}')
	#name=$(echo "$line" | awk -F  "(" '{print $1}' | awk {'first = $1; $1=""; print $0'} | sed 's/^ //g')
	name=$(echo "$line" | awk -F  "(" '{print $1}' | awk '{first = $1; $1=""; print $0}' | sed 's/^ //g')
	echo "$name ($number)" >> $chemin/Installed.md
	#echo " " >> Installed.md
	#appstore["$name"]="${number}"
done <<< "$appfrommas"
{
echo "\`\`\`"
echo ""
echo ''
} >> $chemin/Installed.md

# Extensions PHP PECL

echo -e "🐘  Get PECL \033[3m\033[93mPHP extensions\033[0m list"

echo '## 🐘  PECL extensions' >> $chemin/Installed.md
echo '' >> $chemin/Installed.md

ext_pecl=$(pecl list | sed '1,3d' | awk '{print $1}')
{
echo "\`\`\`bash"
echo "$ext_pecl"
echo "\`\`\`"
echo ""
echo ''
} >> $chemin/Installed.md

# Python packages (pip)

echo -e "🐍  Get pip \033[3m\033[93mPython 3 packages\033[0m installed list"
echo '## 🐍  Python packages' >> $chemin/Installed.md
echo '' >> $chemin/Installed.md

pip_packages=$($pip_version list | sed '1,2d' | awk '{print $1}')
{
echo "\`\`\`bash"
echo "$pip_packages"
echo "\`\`\`"
echo ""
echo ''
} >> $chemin/Installed.md

# atom

if [ "$apm" = "true" ]; then
	echo -e "⚛️   Get \033[3m\033[93mAtom editor packages\033[0m installed list"
	atom=$(apm list | grep 'Community Packages' -A 100 | sed '1,1d')
	{
	echo '## ⚛️ Atom packages'
	echo ''
	echo "\`\`\`bash"

	while read -r line; do
		a=$(echo "$line" | awk -F "@" '{print $1}' | awk '{print $2}' )
		#atom_pkg=${a:4}
		echo "$a"	
	done <<< "$atom"

	echo "\`\`\`"
	echo ""
	echo ''
	} >> $chemin/Installed.md
fi
# Node.js packages (npm)

echo -e "🌿  Get npm \033[3m\033[93m node global packages\033[0m installed scripts"
pkg_global_npm=$(npm list -g --depth=0 --silent | sed '1d' | awk '{print $2}' | awk -F  "@" '{print $1}')

{
echo '## 🌿 Node.js packages'
echo ''

echo '### Global:'

echo "\`\`\`bash"
echo "$pkg_global_npm"
echo "\`\`\`"
} >> $chemin/Installed.md

if [ -d "$local_path" ]; then
	cd "$local_path" || exit

	echo -e "🌿  Get npm \033[3m\033[93m node local packages\033[0m installed scripts"
	echo '### Local:' >> "$chemin/Installed.md"

	pkg_local=$(npm ls | sed '1d' | grep -v 'deduped')

	{
	echo "\`\`\`bash"
	while read -r line; do
		pkg_local_npm=$(echo "$line" | sed 's/[│ └──├┬]//g' | awk -F  "@" '{print $1}')
		echo "$pkg_local_npm"
	done <<< "$pkg_local"
	echo "\`\`\`"
	} >> "$chemin/Installed.md"
	
	
	cd "$chemin" || exit
fi

echo "" >> $chemin/Installed.md

# gem

echo -e "💍  Get \033[3m\033[93mgem\033[0m installed list"
gems=$(gem list --no-versions)
{
echo '## 💍 Gem packages'
echo ''
echo "\`\`\`bash"

while read -r line; do
	a=$(echo "$line")
	echo "$a"	
done <<< "$gems"

echo "\`\`\`"
echo ""
echo ''
} >> $chemin/Installed.md

echo ''


# Create a Brewfile
echo -e "🍺  Create a \033[3m\033[93mBrewfile\033[0m:"
echo "list all  of the installed brew packages, cask applications, and Mac App Store applications currently on the machine..."
brew bundle dump
echo -e "To restore everything listed in that file, run \033[3m\033[93m'brew bundle'\033[0m in folder that contains the Brewfile."
echo ''

mv $chemin/Brewfile "$chemin/Brewfile_$file".md
y=$(find . -type f -name 'Brewfile*' -mtime +10 -maxdepth 1)
if [ -n "$y" ]; then
	nb=$(echo "$y" | wc -l)
	echo "$y" | xargs rm
	[ $? ] && echo -e "\033[93m$nb Brewfile_*\033[0m files removed !"
fi

#iconv -f macroman -t utf-8  Installed.md > Installed-utf8.md
#mv Installed-utf8.md "$filename".md
#rm Installed.md

mv $chemin/Installed.md "$chemin/$filename".md

open "$chemin/$filename".md
