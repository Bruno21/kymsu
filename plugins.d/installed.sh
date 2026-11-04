#!/usr/bin/env bash

# List of brew, cask, mas, python, npm, pecl installed...
# https://github.com/welcoMattic/kymsu
# fork https://github.com/Bruno21/kymsu
# Verified by Claude

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
#
#########################################

###############################################################################################
#
# Require software:
#	-brew
#   -mas (Mac App Store command-line interface) (https://github.com/mas-cli/mas)
#   -pecl (part of PHP)
#   -pip (part of Python)
#   -pipx (Execute binaries from Python packages in isolated environments) (https://pipx.pypa.io)
#   -cargo (part of Rust)
#   -apm
#   -npm (part of node)
#   -gem (part of Ruby)
#
###############################################################################################

#if [ ! -d chemin ]; then mkdir $chemin; fi
mkdir -p "$chemin"
cd "$chemin" || exit 1

now=$(date +"%d-%m-%Y_%T" | sed 's/://g')
mac=$(hostname -s)
file=$mac"@"$now
filename="Installed_$file"

echo -e "\033[1m🛠  Installed \033[0m"

echo ''

# Delete 'Installed*.md' files
Installed=$(find "$chemin" -maxdepth 1 -name 'Installed*.md')
if [ -n "$Installed" ]; then
   	echo -e "A file \033[93mInstalled*.md\033[0m already exist! We remove it."
   	find "$chemin" -maxdepth 1 -name 'Installed*.md' -delete
fi

# If a Brewfile file exists, it is renamed to today's date
if [ -f "$chemin"/Brewfile ]; then
	echo -e "The \033[93mBrewfile\033[0m already exist! We rename it."
	d=$(date -r "$chemin"/Brewfile  "+%d-%m-%Y_%H%M%S")

	mv "$chemin/Brewfile" "$chemin/Brewfile_$mac@$d"
fi

#####################################
# We create the 'Installed.md' file #
#####################################

{
echo '# Apps, package, scripts installed:'
echo "*$mac@$now*"
echo ''

echo '[TOC]'
echo ''
} >> "$chemin"/Installed.md

# Homebrew

if command -v brew >/dev/null 2>&1; then
	{
	echo '## 🍺  Homebrew'
	echo ''
	}  >> "$chemin"/Installed.md

	echo -e "🍺  Get Homebrew \033[3m\033[93mtap\033[0m list"

	tap=$(brew tap)
	{
	echo '### Tap:'
	echo "\`\`\`bash"
	echo "$tap"
	echo "\`\`\`"
	echo ""
	echo ''
	} >> "$chemin"/Installed.md

	echo -e "🍺  Get Homebrew \033[3m\033[93mpackages\033[0m installed list"

	brew=$(brew list --formula)
	{
	echo '### Packages:'
	echo "\`\`\`bash"
	echo "$brew"
	echo "\`\`\`"
	echo ""
	echo ''
	} >> "$chemin"/Installed.md

	echo -e "🍺  Get Homebrew \033[3m\033[93mCask\033[0m installed list"

	cask=$(brew list --cask)
	{
	echo '### Casks:'
	echo "\`\`\`bash"
	echo "$cask"
	echo "\`\`\`"
	echo ""
	echo ''
	} >> "$chemin"/Installed.md
fi

# liste des apps de l'Appstore installées (nom & numéro)

if command -v mas >/dev/null 2>&1; then
	echo -e "🍏  Get mas \033[3m\033[93mApp Store applications\033[0m list"

	appfrommas=$(mas list | sed -E 's/^ *([0-9]+) +(.*[^ ]) +\([^()]*\)$/\2 (\1)/' | sort -f)
	{
	echo '## 🍏  mas (Mac App Store)'
	echo ''
	echo "\`\`\`bash"
	echo "$appfrommas"
	echo "\`\`\`"
	echo ""
	echo ''
	} >> "$chemin"/Installed.md
fi

# Extensions PHP PECL

if command -v pecl >/dev/null 2>&1; then
	echo -e "🐘  Get PECL \033[3m\033[93mPHP extensions\033[0m list"

	ext_pecl=$(pecl list | sed '1,3d' | awk '{print $1}')
	{
	echo '## 🐘  PECL extensions'
	echo ''
	echo "\`\`\`bash"
	echo "$ext_pecl"
	echo "\`\`\`"
	echo ""
	echo ''
	} >> "$chemin"/Installed.md
fi

# Python packages (pip)

if command -v "$pip_version" >/dev/null 2>&1; then
	echo -e "🐍  Get pip \033[3m\033[93mPython 3 packages\033[0m installed list"

	pip_packages=$($pip_version list | sed '1,2d' | awk '{print $1}')
	{
	echo '## 🐍  Python packages'
	echo ''
	echo "\`\`\`bash"
	echo "$pip_packages"
	echo "\`\`\`"
	echo ""
	echo ''
	} >> "$chemin"/Installed.md
fi

# pipx apps

if command -v pipx >/dev/null 2>&1; then
	echo -e "🛠   Get \033[3m\033[93mpipx apps\033[0m installed list"

	pipx_apps=$(pipx list --short | awk '{print $1}')
	{
	echo '## 🛠  pipx apps'
	echo ''
	echo "\`\`\`bash"
	echo "$pipx_apps"
	echo "\`\`\`"
	echo ""
	echo ''
	} >> "$chemin"/Installed.md
fi

# rust apps

if command -v cargo >/dev/null 2>&1; then
	echo -e "🦀  Get \033[3m\033[93mCrates (Rust)\033[0m installed list"

	crates=$(cargo install --list | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+:' | cut -f1 -d' ')
	{
	echo '## 🦀  Crates (Rust)'
	echo ''
	echo "\`\`\`bash"
	echo "$crates"
	echo "\`\`\`"
	echo ""
	echo ''
	} >> "$chemin"/Installed.md
fi

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
		echo "$a"
	done <<< "$atom"

	echo "\`\`\`"
	echo ""
	echo ''
	} >> "$chemin"/Installed.md
fi

# Node.js packages (npm)

if command -v npm >/dev/null 2>&1; then
	echo -e "🌿  Get npm \033[3m\033[93m node global packages\033[0m installed scripts"
	#pkg_global_npm=$(npm list -g --depth=0 --silent | sed '1d' | awk '{print $2}' | awk -F  "@" '{print $1}')
	pkg_global_npm=$(npm list -g --depth=0 --silent | sed '1d' | awk '{print $2}' | sed -E 's/@[^@]*$//')

	{
	echo '## 🌿 Node.js packages'
	echo ''

	echo '### Global:'

	echo "\`\`\`bash"
	echo "$pkg_global_npm"
	echo "\`\`\`"
	} >> "$chemin"/Installed.md

	if [ -d "$local_path" ]; then
		cd "$local_path" || exit 1

		echo -e "🌿  Get npm \033[3m\033[93m node local packages\033[0m installed scripts"
		echo '### Local:' >> "$chemin/Installed.md"

		pkg_local=$(npm ls | sed '1d' | grep -v 'deduped')

		{
		echo "\`\`\`bash"
		while read -r line; do
			pkg_local_npm=$(echo "$line" | sed -E 's/^[^@A-Za-z0-9]+//; s/@[^@]*$//')
			echo "$pkg_local_npm"
		done <<< "$pkg_local"
		echo "\`\`\`"
		} >> "$chemin/Installed.md"

		cd "$chemin" || exit 1
	fi
fi

echo "" >> "$chemin"/Installed.md

# gem

if command -v gem >/dev/null 2>&1; then
	echo -e "💍  Get \033[3m\033[93mgem\033[0m installed list"

	gems=$(gem list --no-versions)
	{
	echo '## 💍 Gem packages'
	echo ''
	echo "\`\`\`bash"

	echo "$gems"

	echo "\`\`\`"
	echo ""
	echo ''
	} >> "$chemin"/Installed.md
fi

##################################
# End of the 'Installed.md' file #
##################################

echo ''

#####################
# Create a Brewfile #
#####################

if command -v brew >/dev/null 2>&1; then
	echo -e "🍺  Create a \033[3m\033[93mBrewfile\033[0m:"
	echo "list all  of the installed brew packages, cask applications, and Mac App Store applications currently on the machine..."
	brew bundle dump --force --file="$chemin/Brewfile" 2>/dev/null
	echo -e "To restore everything listed in that file, run \033[3m\033[93m'brew bundle'\033[0m in folder that contains the Brewfile."
	echo ''

	# Rename 'Brewfile' to today's date ($file -> line 26)
	mv "$chemin"/Brewfile "$chemin/Brewfile_$file".txt
fi

#####################
# Remove oldest Brewfile #
#####################

# garder les 10 plus récents

# shellcheck disable=SC2012
y=$(ls -1t "$chemin"/Brewfile_* 2>/dev/null | tail -n +11)

if [ -n "$y" ]; then
	echo -e "🍺  Remove oldest \033[3m\033[93mBrewfile\033[0m:"
	nb=0
	while IFS= read -r f; do
		rm -- "$f" && nb=$((nb+1))
	done <<< "$y"
	echo -e "\033[93m$nb Brewfile_*\033[0m files removed !\n\n"
fi

#iconv -f macroman -t utf-8  Installed.md > Installed-utf8.md
#mv Installed-utf8.md "$filename".md
#rm Installed.md

#########################
# Rename 'Installed.md' #
#########################

mv "$chemin"/Installed.md "$chemin/$filename".md

open "$chemin/$filename".md
