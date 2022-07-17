#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
#PREF_FILE="$SCRIPT_DIR/kymsu.pref"
#TEMP_FILE="$SCRIPT_DIR/kymsu.pref.tmp"
PREF_FILE="$HOME/.kymsu/plugins.d/kymsu.pref"
TEMP_FILE="$HOME/.kymsu/plugins.d/kymsu.pref.tmp"

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

if [ -f $PREF_FILE ]; then
	last_update=$(cat $PREF_FILE | grep "last.update" | awk -F"=" '{print $2}' )
else
	last_update=0
fi

current_timestamp=$(date +"%s")
temps=$(( current_timestamp-last_update))

if [ $(( temps-w)) -gt 0 ]; then
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

