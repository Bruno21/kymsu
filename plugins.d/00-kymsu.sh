#!/usr/bin/env bash

source config.shlib; # load the config library functions

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PREF_FILE="$HOME/.kymsu/plugins.d/kymsu.cfg"
TEMP_FILE="$HOME/.kymsu/plugins.d/kymsu.cfg.tmp"

secondes_en_duree() {
    local total=$1
    local jours=$((total / 86400))
    local heures=$(( (total % 86400) / 3600 ))
    local minutes=$(( (total % 3600) / 60 ))
    local secs=$((total % 60))
    printf "%dj %dh %dm %ds\n" "$jours" "$heures" "$minutes" "$secs"
}

# 5m	5 minutes
# 2h 	2 hours
# 4d	4 days
# 3w	3 weeks
# 1M	1 month
# 1Y	1 year

update_interval="1w"
x=${update_interval: -1}
case $x in
	m) unite=60;;
	h) unite=3600;;
	d) unite=$(( 3600*24 ));;
	w) unite=$(( 3600*24*7 ));;
	M) unite=$(( 3600*24*30 ));;
	Y) unite=$(( 3600*24*30*12 ));;
	*) echo "Bad update_interval pref" >&2
		#exit -1;;
esac

y=$(( ${#update_interval}-1 ))
nb=${update_interval:0:$y}
w=$(( unite*nb ))

current_timestamp=$(date +"%s")

lu="$(config_get last.update)"
#echo ${#lu} # 0 ou 10

if [ -n "$lu" ]; then
	last_update="$lu"
else
	last_update=$current_timestamp
	awk -F'=' -v OFS='=' -v newval="$current_timestamp" '/^last.update/{$2=newval;print;next}1' $PREF_FILE > $TEMP_FILE
	mv $TEMP_FILE $PREF_FILE
fi 

temps=$(( current_timestamp-last_update ))

last_upd=$(date +'%d-%m-%Y %H:%M:%S' -d @$last_update)
echo "Last update: $last_upd"

current=$(date +'%d-%m-%Y %H:%M:%S' -d @$current_timestamp)
#echo "Current: $current"

next_update=$(( last_update+w ))
next_upd=$(date +'%d-%m-%Y %H:%M:%S' -d @$next_update)

duree=$(( next_update-current_timestamp ))
q=$(secondes_en_duree $duree)
echo -e "Next update: $next_upd (in $q)\n"


if [ $(( temps-w )) -gt 0 ]; then	# more than $update_interval
	echo "🦄  KYMSU self update"
	pushd "$(cat ~/.kymsu/path)" > /dev/null
	#git pull
	git pull https://Bruno21@github.com/Bruno21/kymsu.git
	popd > /dev/null
	echo ""
	
	if [ $last_update -eq 0 ]; then
		echo "last.update=$current_timestamp" > $PREF_FILE
	else
		awk -F'=' -v OFS='=' -v newval="$current_timestamp" '/^last.update/{$2=newval;print;next}1' $PREF_FILE > $TEMP_FILE
		mv $TEMP_FILE $PREF_FILE
	fi
fi

