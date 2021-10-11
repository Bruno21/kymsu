#!/usr/bin/env bash

# pip plugin for KYMSU
# https://github.com/welcoMattic/kymsu

list=$(pipx list --include-injected --json)

#echo "$list"

pipx-outdated() {
	echo "OUTDATED PACKAGES:"
	while read -sr pyPkgName pyPkyVersion; do
		local pypi_latest="$(curl -sS https://pypi.org/simple/${pyPkgName}/ | grep -o '>.*</' | tail -n 1 | grep -o -E '[0-9]([0-9]|[-._])*[0-9]')"
		[ "$pyPkyVersion" != "$pypi_latest" ] && printf "%s\n\tCurrent: %s\tLatest: %s\n" "$pyPkgName" "$pyPkyVersion" "$pypi_latest"
	done < <( pipx list | grep -o 'package.*,' | tr -d ',' | cut -d ' ' -f 2- )
}

pipx-outdated

#echo "----------"

packages=$(echo "$list" | jq '{venvs} | .[]')

#echo "$packages"

for row in $(jq -c '.[] | .[]' <<< "$packages");
do
	inj=$(echo "$row" | jq -j '.injected_packages')
	echo "$inj"
	#echo "$row"
done