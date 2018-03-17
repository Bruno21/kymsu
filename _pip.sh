#!/usr/bin/env bash

# pip plugin for KYMSU
# https://github.com/welcoMattic/kymsu


echo "🐍  pip"
echo ""

echo "🐍  update pip3 (Python 3)(Homebrew)"
echo ""
pip3 install --upgrade pip
#pip3 install --upgrade mkdocs
#pip3 install --upgrade mkdocs-material
echo ""

pip3_outdated=$(pip3 list --outdated --format columns)
upd3=$(echo "$pip3_outdated" | sed '1,2d' | awk '{print $1}')
#echo $upd3
# terminaltables tornado

#pip3_outdated_freeze=$(pip3 list --outdated --format=freeze)
#echo $pip3_outdated_freeze
#upd3=$(echo $pip3_outdated_freeze | tr [:space:] '\n' | awk -F== '{print $1}')

if [ -n "$upd3" ]; then

	echo -e "\033[4mAvailables updates:\033[0m"
	#echo $pip3_outdated_freeze | tr [:space:] '\n'
	echo "$pip3_outdated"
	echo ""
	
	echo -e "\033[4mCheck dependancies:\033[0m"
	echo "Be carefull!! This updates can be a dependancie for some modules. Check for any incompatible version."
	echo ""
	for i in $upd3
		do
			#echo "$i" | xargs pipdeptree -r -p | grep "$upd3" | sed '1d'
			dependencies=$(echo "$i" | xargs pipdeptree -r -p | grep "$upd3")
			#a=$(echo "$dependencies" | sed '1d')
			b=$(echo "$dependencies" | wc -l)
		
			#if [ "$b" -ge 2 ]; then
				z=0
				while read -r line; do
					if [[ $line = *"<"* ]]; then
						echo -e "\033[31m$line\033[0m"
					else
						if [ "$z" -eq 0 ]; then
							echo -e "\033[3m$line\033[0m"
						else
							echo "$line"
						fi
						z=$((z+1))
					fi
				done <<< "$dependencies"
			#fi
			
			b=$(echo -e "Do you wanna run \033[1mpip3 install --upgrade "$i"\033[0m ? (y/n)")
  			read -p "$b" choice
  			case "$choice" in
    			#y|Y|o ) echo $i | xargs -p pip3 install --upgrade ;;
    			y|Y|o ) echo $i | xargs -p echo ;;
    			n|N ) echo "Ok, let's continue";;
    			* ) echo "invalid";;
  			esac
  			echo ""
			
		done

<<COMMENT

	#echo "$pip3_outdated" | sed '1,2d' | awk '{print $1}'
	#echo ""
	a=$(echo -e "Do you wanna run \033[1mpip3 install --upgrade "$upd3"\033[0m ? (y/n) (You may have choice for each module)")

  	read -p "$a" choice
  	case "$choice" in
    	y|Y|o ) echo $upd3 | xargs -p -n 1 pip3 install --upgrade ;;
    	n|N ) echo "Ok, let's continue";;
    	* ) echo "invalid";;
  	esac
COMMENT
  	
else
	echo -e "\033[4mNo availables updates.\033[0m"
fi

echo ""
