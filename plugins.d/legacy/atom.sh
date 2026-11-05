#!/usr/bin/env bash

echo -e "\033[1m⚛️  Atom editor will be shiny when you'll be back from your coffee/tea break! \033[0m"

command -v apm >/dev/null 2>&1 || { echo -e "\n${bold}Atom editor${reset} is not installed.\n\nRun ${italic}'brew install atom'${reset} for install." && exit 1; }

if hash apm-beta 2>/dev/null; then
    apm-beta upgrade -c false
fi
if hash apm 2>/dev/null; then
    apm upgrade -c false
fi
echo ""
