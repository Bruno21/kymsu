#!/usr/bin/env bash

# Install script for KYMSU
# https://github.com/welcoMattic/kymsu
# fork https://github.com/Bruno21/kymsu
# Verified by Claude

#########################################
#
# Settings:
#  - use kymsu.cfg for configuring options

# Pour tester l'installation
#HOME=/tmp/kymsu-test ./install.sh

# --- Chemins (définis une seule fois, sans "/" final) ---
KYMSU_DIR=/usr/local/bin
KYMSU_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # le dépôt
KYMSU_HOME="$HOME/.kymsu"
SCRIPTS_DIR="$KYMSU_HOME/plugins.d"                          # destination
PREF_FILE="$SCRIPTS_DIR/kymsu.cfg"
TEMP_FILE="$SCRIPTS_DIR/kymsu.cfg.tmp"

# --- Premier install ? (avant toute suppression) ---
new_install=false
[[ -d "$SCRIPTS_DIR" ]] || new_install=true

bold='\033[1m'
italic='\033[3m'
underline='\033[4m'
yellow='\033[33m'
reset='\033[0m'
#
#########################################


# --- Commande kymsu2 dans le PATH ---
echo -e "\nInstalling ${bold}kymsu2${reset} in ${bold}$KYMSU_DIR${reset} ..."
sudo mkdir -p "$KYMSU_DIR" && sudo ln -fs "$KYMSU_PATH/kymsu2.sh" "$KYMSU_DIR/kymsu2"

# --- Mémoriser l'emplacement du dépôt ---
mkdir -p "$KYMSU_HOME" && echo "$KYMSU_PATH" > "$KYMSU_HOME/path"

# --- Sauvegarder la liste des plugins désactivés (noms sans "_") ---
disabled=()
for f in "$SCRIPTS_DIR"/_*; do
	[[ -e "$f" ]] || continue
	n="${f##*/}"
	disabled+=("${n#_}")
done

# --- Sauvegarder la config personnelle (si elle existe) ---
saved_cfg=""
if [[ -f "$PREF_FILE" ]]; then
	saved_cfg="$(mktemp)" || exit 1
	cp -p "$PREF_FILE" "$saved_cfg" || { echo "Cannot back up $PREF_FILE" >&2; exit 1; }
fi

# --- Remplacer les plugins ---
rm -rf "${SCRIPTS_DIR:?}"

echo -e "Copying plugins in ${bold}$SCRIPTS_DIR${reset} ..."
mkdir -p "$SCRIPTS_DIR"
for f in "$KYMSU_PATH/plugins.d"/*; do
	[[ -f "$f" ]] || continue
	case "$f" in
		*.sh|*.png|*.shlib|*.cfg) cp -p "$f" "$SCRIPTS_DIR/" ;;
	esac
done

# --- Restaurer la config personnelle + ajouter les nouvelles clés ---
if [[ -n "$saved_cfg" ]]; then
	added=()
	while IFS= read -r line; do
		[[ "$line" =~ ^[[:space:]]*([A-Za-z0-9_.-]+)= ]] || continue
		key="${BASH_REMATCH[1]}"
		if ! grep -qE "^[[:space:]]*${key//./[.]}=" "$saved_cfg"; then
			echo "$line" >> "$saved_cfg"
			added+=("$key")
		fi
	done < "$SCRIPTS_DIR/kymsu.cfg"

	mv "$saved_cfg" "$PREF_FILE"
	echo -e "Preserved ${bold}kymsu.cfg${reset}"
	(( ${#added[@]} > 0 )) && echo -e "New settings added: ${bold}${added[*]}${reset}"
fi

# --- Quarantaine (macOS uniquement) ---
if [[ "$OSTYPE" == darwin* ]]; then
	for f in "$SCRIPTS_DIR"/*.sh; do
		if xattr -l "$f" 2>/dev/null | grep -q "com.apple.quarantine"; then
			echo -e "${yellow}Clear quarantine flag: ${f##*/}${reset}"
			xattr -d com.apple.quarantine "$f"
		fi
	done
fi

# --- Timestamp de mise à jour ---
if awk -F'=' -v OFS='=' -v newval="$(date +%s)" \
	'/^last.update/{$2=newval;print;next}1' "$PREF_FILE" > "$TEMP_FILE"; then
	mv "$TEMP_FILE" "$PREF_FILE"
else
	rm -f "$TEMP_FILE"
fi

# --- Re-désactiver les plugins qui l'étaient (nom exact) ---
if (( ${#disabled[@]} > 0 )); then
	echo -e "Disabling previous disabled plugins ..."
	for name in "${disabled[@]}"; do
		[[ -e "$SCRIPTS_DIR/$name" ]] && mv "$SCRIPTS_DIR/$name" "$SCRIPTS_DIR/_$name"
	done
fi

echo -e "\n${bold}altKYMSU${reset} has been installed. Run ${bold}kymsu2${reset} command!"
echo -e "It's a fork from ${italic}https://github.com/welcoMattic/kymsu${reset}"
echo -e "All credits to ${underline}welcoMattic${reset}\n"

# --- Premier install : choisir les plugins à désactiver ---
if [[ "$new_install" == true ]]; then
	read -r -p "Do you want to activate / deactivate some plugins ? [y/n] " answer
	echo ""

	if [[ "${answer,,}" == "y" ]]; then
		for f in "$SCRIPTS_DIR"/*.sh; do
			i="${f##*/}"
			[[ "$i" == 00* || "$i" == _* ]] && continue

			read -r -p "$(echo -e "Do you want to deactivate ${bold}$i${reset} plugin ? [y/n] ")" rep
			if [[ "${rep,,}" == "y" ]]; then
				mv "$f" "$SCRIPTS_DIR/_$i" && echo -e "${bold}$i${reset} deactivated !"
			fi
		done
	fi
fi