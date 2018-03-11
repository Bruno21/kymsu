#!/usr/bin/env bash

# npm plugin for KYMSU (install local package)
# https://github.com/welcoMattic/kymsu

echo " 🌿  npm"
cd /Users/bruno/Sites/node_modules/
npm ls
npm outdated
npm outdated | awk '{print $1}' | xargs npm update
echo ""
