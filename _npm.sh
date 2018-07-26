#!/usr/bin/env bash

# npm plugin for KYMSU (install local package)
# https://github.com/welcoMattic/kymsu

# Fixing npm On Mac OS X for Homebrew Users
# https://gist.github.com/rcugut/c7abd2a425bb65da3c61d8341cd4b02d
# https://gist.github.com/DanHerbert/9520689

# brew install node
# node -v => 9.11.1
# npm -v => 5.6.0

# npm install -g npm
# npm -v => 5.8.0

# https://github.com/npm/npm/issues/17744

echo -e "\033[1m🌿  npm \033[0m"
echo ""

cd /Users/bruno/Sites/node_modules/
echo -e "\033[4mInstalled scripts:\033[0m"
npm ls
outdated=$(npm outdated)
echo "$outdated" | awk '{print $1}' | xargs npm update
echo ""

if [[ $1 == "--npm_cleanup" ]]; then
	echo "🌬  Cleaning npm cache"
	npm cache clean
	echo ""
fi

echo ""
