#!/usr/bin/env bash

# List of brew, cask, mas, python, npm, pecl installed...

#########################################
#
# Settings:

# npm local install
local_path=/Users/bruno/Sites/node_modules/
chemin=$(pwd)
#version: pip ou pip3
version=pip3
#
#########################################

now=$(date +"%d-%m-%Y_%T")
mac=$(hostname -s)
file=$mac"@"$now
#echo "$file"
filename="Installed_$file"

echo -e "\033[1m🛠  Installed \033[0m"

echo ''

Installed=$(find . -name 'Installed*.md' -maxdepth 1)
if [ -n "$Installed" ]; then
	echo -e "A file \033[93mInstalled*.md\033[0m already exist! We remove it."
	a=$(echo "$Installed" | xargs rm)
fi


if [ -f Brewfile ]; then
	echo -e "The \033[93mBrewfile\033[0m already exist! We rename it."
	bf=$(find . -name 'Brewfile_*' -maxdepth 1 | xargs rm)
	d=$(date -r Brewfile  "+%m-%d-%Y_%H:%M:%S")
	
	mv Brewfile "Brewfile_$mac@$d"
fi

echo '# Apps, package, scripts installed:' > Installed.md
echo "<u>"$mac"@"$now"</u>" >> Installed.md
echo '' >> Installed.md

echo '[TOC]' >> Installed.md
echo '' >> Installed.md

# Homebrew

echo '## Homebrew' >> Installed.md
echo '' >> Installed.md

echo -e "🍺  Get Homebrew \033[3m\033[93mtap\033[0m list"

echo '### Tap:' >> Installed.md
tap=$(brew tap)
echo "\`\`\`bash" >> Installed.md
echo "$tap" >> Installed.md
echo "\`\`\`" >> Installed.md
echo "" >> Installed.md

echo -e "🍺  Get Homebrew \033[3m\033[93mpackages\033[0m installed list"
	
echo '### Packages:' >> Installed.md
brew=$(brew list)
echo "\`\`\`bash" >> Installed.md
echo "$brew" >> Installed.md
echo "\`\`\`" >> Installed.md
echo "" >> Installed.md

echo -e "🍺  Get Homebrew \033[3m\033[93mCask\033[0m installed list"

echo '### Casks:' >> Installed.md
cask=$(brew cask list)
echo "\`\`\`bash" >> Installed.md
echo "$cask" >> Installed.md
echo "\`\`\`" >> Installed.md
echo "" >> Installed.md


# liste des apps de l'Appstore installées (nom & numéro)

echo -e "🍏  Get mas \033[3m\033[93mApp Store applications\033[0m list"

echo '## mas (Mac App Store)' >> Installed.md
echo '' >> Installed.md

appfrommas=$(mas list)
#echo "$appfrommas"
#declare -a appstore
echo "\`\`\`bash" >> Installed.md
# todo: trier la liste par nom
while read -r line; do
	number=$(echo "$line" | awk '{print $1}')
	name=$(echo "$line" | awk -F  "(" '{print $1}' | awk {'first = $1; $1=""; print $0'} | sed 's/^ //g')
	echo "$name ($number)" >> Installed.md
	#echo " " >> Installed.md
	#appstore["$name"]="${number}"
done <<< "$appfrommas"
echo "\`\`\`" >> Installed.md
echo "" >> Installed.md


# Extensions PHP PECL

echo -e "🐘  Get PECL \033[3m\033[93mPHP extensions\033[0m list"

echo '## PECL extensions' >> Installed.md
echo '' >> Installed.md

ext_pecl=$(pecl list | sed '1,3d' | awk '{print $1}')
echo "\`\`\`bash" >> Installed.md
echo "$ext_pecl" >> Installed.md
echo "\`\`\`" >> Installed.md
echo "" >> Installed.md


# Python packages (pip)

echo -e "🐍  Get pip \033[3m\033[93mPython 3 packages\033[0m installed list"
echo '## Python packages' >> Installed.md
echo '' >> Installed.md

pip_packages=$($version list | sed '1,2d' | awk '{print $1}')
echo "\`\`\`bash" >> Installed.md
echo "$pip_packages" >> Installed.md
echo "\`\`\`" >> Installed.md
echo '' >> Installed.md


# atom

echo -e "⚛️   Get \033[3m\033[93mAtom editor packages\033[0m installed list"
echo '## Atom packages' >> Installed.md
echo '' >> Installed.md

atom=$(apm list | grep 'Community Packages' -A 100 | sed '1,1d')

echo "\`\`\`bash" >> Installed.md	
while read -r line; do
	a=$(echo "$line" | awk -F  "@" '{print $1}')
	atom_pkg=${a:4}
	echo "$atom_pkg" >> "$chemin/Installed.md"		
done <<< "$atom"
echo "\`\`\`" >> Installed.md
echo '' >> Installed.md


# Node.js packages (npm)

echo '## Node.js packages' >> Installed.md
echo '' >> Installed.md

echo -e "🌿  Get npm \033[3m\033[93m node global packages\033[0m installed scripts"
echo '### Global:' >> Installed.md

pkg_global_npm=$(npm list -g --depth=0 --silent | sed '1,2d' | awk '{print $2}' | awk -F  "@" '{print $1}')
echo "\`\`\`bash" >> Installed.md	
echo "$pkg_global_npm" >> Installed.md	
echo "\`\`\`" >> Installed.md

#echo "$local_path"
if [ -d "$local_path" ]; then
	cd $local_path

	echo -e "🌿  Get npm \033[3m\033[93m node local packages\033[0m installed scripts"
	echo '### Local:' >> "$chemin/Installed.md"

	pkg_local=$(npm ls | sed '1,1d' | grep -v 'deduped')

	echo "\`\`\`bash" >> "$chemin/Installed.md"	
	while read -r line; do
		a=$(echo "$line" | awk -F  "@" '{print $1}')
		pkg_local_npm=${a:4}
		echo "$pkg_local_npm" >> "$chemin/Installed.md"		
	done <<< "$pkg_local"
	echo "\`\`\`" >> "$chemin/Installed.md"
	
	cd $chemin
fi

echo "" >> Installed.md

echo ''


# Create a Brewfile
echo -e "🍺  Create a \033[3m\033[93mBrewfile\033[0m:"
echo "list all  of the installed brew packages, cask applications, and Mac App Store applications currently on the machine..."
brew bundle dump
echo ''
echo -e "To restore everything listed in that file, run \033[3m\033[93m'$ brew bundle'\033[0m in folder that contains the Brewfile."
echo ''

mv Installed.md "$filename".md

open "$filename".md
