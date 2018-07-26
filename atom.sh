#!/usr/bin/env bash
echo -e "\033[1m⚛️  Atom editor will be shiny when you'll be back from your coffee/tea break! \033[0m"

if hash apm-beta 2>/dev/null; then
    apm-beta upgrade -c false
fi
if hash apm 2>/dev/null; then
    apm upgrade -c false
fi
echo ""
