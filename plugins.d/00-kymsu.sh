#!/usr/bin/env bash

# Update plugin for KYMSU
# https://github.com/welcoMattic/kymsu
# fork https://github.com/Bruno21/kymsu
# Verified by Claude

#########################################
#
# Settings:
#  - use kymsu.cfg for configuring options

# --- Chemins (définis une seule fois, sans "/" final) ---
KYMSU_HOME="$HOME/.kymsu"
SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/.kymsu/plugins.d}"
PREF_FILE="$SCRIPTS_DIR/kymsu.cfg"
TEMP_FILE="$SCRIPTS_DIR/kymsu.cfg.tmp"

# shellcheck source=/dev/null
if [ ! -r "$SCRIPTS_DIR/config.shlib" ]; then
	echo "config.shlib not found in $SCRIPTS_DIR (set SCRIPTS_DIR or check the KYMSU installation)." >&2
	exit 1
fi
# shellcheck source=/dev/null
source "$SCRIPTS_DIR/config.shlib"

red="$(config_get red)"
reset="$(config_get reset)"
#
#########################################

if date --version 2>/dev/null | grep -qi 'GNU'; then
	date_gnu=true
else
	date_gnu=false
fi

format_timestamp() {
	if [[ "$date_gnu" == true ]]; then
		date -d "@$1" +'%d-%m-%Y %H:%M:%S'			# GNU
	else
		date -jf "%s" "$1" +'%d-%m-%Y %H:%M:%S'		# BSD
	fi
}

secondes_en_duree() {
	local total=$1
	local jours=$(( total / 86400 ))
	local heures=$(( (total % 86400) / 3600 ))
	local minutes=$(( (total % 3600) / 60 ))
	local secs=$(( total % 60 ))
	printf "%dj %dh %dm %ds\n" "$jours" "$heures" "$minutes" "$secs"
}

# Intervalle de mise à jour (depuis kymsu.cfg, défaut : 1w)
update_interval="$(config_get update_interval)"
update_interval="${update_interval:-1w}"

x="${update_interval: -1}"
case $x in
	m) unite=60 ;;
	h) unite=3600 ;;
	d) unite=$(( 3600*24 )) ;;
	w) unite=$(( 3600*24*7 )) ;;
	M) unite=$(( 3600*24*30 )) ;;
	Y) unite=$(( 3600*24*365 )) ;;
	*) echo -e "${red}Bad update_interval: $update_interval${reset}\n" >&2; exit 1 ;;
esac

nb="${update_interval:0:$(( ${#update_interval}-1 ))}"
w=$(( unite * nb ))

current_timestamp=$(date +"%s")

lu="$(config_get last.update)"
if [ -n "$lu" ]; then
	last_update="$lu"
else
	last_update=$current_timestamp
	awk -F'=' -v OFS='=' -v newval="$current_timestamp" \
		'/^last.update/{$2=newval;print;next}1' "$PREF_FILE" > "$TEMP_FILE" \
		&& mv "$TEMP_FILE" "$PREF_FILE"
fi

temps=$(( current_timestamp - last_update ))
next_update=$(( last_update + w ))
duree=$(( next_update - current_timestamp ))

echo "Last update: $(format_timestamp "$last_update")"

if (( duree > 0 )); then
	echo -e "Next update: $(format_timestamp "$next_update") (in $(secondes_en_duree "$duree"))\n"
else
	echo -e "Next update: ${red}overdue${reset}\n"
fi


if (( temps > w )); then
	echo "🦄  KYMSU self update"
	pushd "$(cat "$KYMSU_HOME/path")" > /dev/null || exit 1
	git pull
	popd > /dev/null || true
	echo ""

	awk -F'=' -v OFS='=' -v newval="$current_timestamp" \
		'/^last.update/{$2=newval;print;next}1' "$PREF_FILE" > "$TEMP_FILE" \
		&& mv "$TEMP_FILE" "$PREF_FILE"
fi
