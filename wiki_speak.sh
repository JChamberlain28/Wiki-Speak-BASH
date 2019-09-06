#!/bin/bash

clear
mkdir -p temp

menu () {
	
	clear
	
	echo "=============================================================="
	echo "Welcome to the Wiki-Speak Authoring Tool"
	echo "=============================================================="
	echo "Please select from one of the following options:"
	echo ""
	echo "	(l)ist existing creations"
	echo "	(p)lay an existing creation"
	echo "	(d)elete an existing creation"
	echo "	(c)reate a new creation"
	echo "	(q)uit authoring tool"
	echo ""
	read -p "Enter a selection [l/p/d/c/q]: " menuSelection


	case $menuSelection in

	[lL])
		listCreations
		returnToMenuPrompt
    	;;

	[pP])
    		listCreations
		noOfCreations=$?
		checkZeroCreations "playCreation" # only runs function contained in string if creations exist
    	;;

	[dD])
		listCreations
		noOfCreations=$?
		checkZeroCreations "deleteCreation" # only runs function contained in string if creations exist
	;;

	[cC])
    		create
    	;;

	[qQ])
		rm -r temp
		clear
    		exit 0
    	;;

  	*)
    		menu
    	;;
	esac
}






create(){

	clear

	read -p "Please enter a term for your creation to be about: " term

	result=$(wikit $term) 

	if [[ $result = "$term not found :^(" ]] || [[ $term = "" ]] # also prevents empty string being accepted
	then
		echo "Term not found" >&2
		read -p "(s)earch new term or go to (m)enu: " termNotFoundSelection


		case $termNotFoundSelection in

  	   	[mM])
	     		clear
  	     		menu
  	     	;;

 	   	*)
  	     		create
   	     	;;

		esac

	else
		
		echo $result | sed 's/\([.!?]\) \([[:upper:]]\)/\1\n\2/g' > temp/description.txt # Formats the wikit output so each sentance
												 # is on a new line
		lineNo=$(wc -l < temp/description.txt)
		cat -n temp/description.txt


		lineNoSelection="EwanTempero" # required to enter the while loop
		condition="+([[:digit:]])"


		# Only allows numbers within the range 1 to number of lines in wikit output
		while [[ $lineNoSelection != $condition ]] || [[ $lineNoSelection -lt 1 ]] || [[ $lineNoSelection -gt $lineNo ]]
		do
			read -p "Enter how many lines to include in your creation (1 to $lineNo): " lineNoSelection	
		done


		sed -n "1,${lineNoSelection}p" temp/description.txt > temp/descriptionSnip.txt
		cat temp/descriptionSnip.txt | text2wave -o temp/audio.mp3 &> /dev/null
        	vidLength=$(echo $(soxi -D temp/audio.mp3)  + 1 | bc)  #add one second so there is a pause after audio stops before video stops

		nameCreation


		# creates a video with blue background and resolution 320x240
		# video contains name of creation
		ffmpeg -loglevel panic -f lavfi -i color=c=blue:s=320x240:d=$vidLength -vf "drawtext=fontfile=myfont.ttf:fontsize=30: fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:text='$term'" temp/video.mp4
		ffmpeg -loglevel panic -i temp/video.mp4 -i temp/audio.mp3 -strict experimental "creations/$Name.mp4"
		rm -f temp/video.mp4 temp/audio.mp3
		echo ""
		echo "Creation generated"

		returnToMenuPrompt
		


	
	fi 


}






nameCreation() {
	
	read -p "Enter a name for this creation: " Name
	
	if [[ $Name = *"/"* ]] || [[ $Name = "" ]] # prevents names that will lead to hidden file creation
	then
		echo "Invalid Name" >&2
		nameCreation

	elif  ls creations | grep -qwi "$Name.mp4"
	then
		echo "Creation with that name already exists" >&2
		nameCreation

	fi
	
}






listCreations() {

	clear
	
	numOfCreations=$(ls -1 creations | wc -l)
	
	if [[ $numOfCreations = 0 ]]
	then
		echo "(No creations currently exist)"
	else
	
		echo "Number of creations: $numOfCreations"
		echo "-------------------------"
		echo ""
		ls creations | sed -e 's/\.[^.]*$//' | cat -n - # sed processing removes file name extensions
	fi

	echo ""
	
	return $numofCreations

}






checkZeroCreations() {

	if [[ $(listCreations) = *"(No creations currently exist)"* ]]
	then 
		action=$(echo ${1%"Creation"}) # extracts command type e.g. play, delete to display to user below
		echo "Cannot perform $action action with no creations" >&2
		returnToMenuPrompt
	else
		${1} # runs command that is passed in as an argument.
	fi

}






returnToMenuPrompt() {
		read -n 1 -s -r -p "Press any key to return to menu"
		
		menu
}






playCreation() {

	read -p "Please select the creation you want to play: " creationSelect
	
	creation=$(findCreation "$creationSelect")
	
	if [ -f "creations/$creation.mp4" ] && [[ $creationSelect != "" ]]
	then
		ffplay -loglevel fatal -autoexit "creations/$creation.mp4"



	else
		echo "Creation not found" >&2
		read -p "(t)ry again or go to (m)enu: " creationNotFoundResponse
		
		case $creationNotFoundResponse in

  	   	[mM])
	     		clear
  	     		menu
  	     	;;


	   	*)
			listCreations
	     		playCreation
	     	;;

		esac
	fi

	menu
}






deleteCreation() {

	read -p "Please select the creation you want to delete: " creationSelect

	creation=$(findCreation "$creationSelect")
	
	if [ -f "creations/$creation.mp4" ] && [[ $creationSelect != "" ]]
	then
		deletionPrompt "$creation"
		



	else
		echo "Creation not found" >&2
		read -p "(t)ry again or go to (m)enu: " creationNotFoundResponse
		
		case $creationNotFoundResponse in

  	   	[mM])
	     		clear
  	     		menu
  	     	;;


	   	*)
			listCreations
	     		deleteCreation
	     	;;

		esac
	fi

	menu
}






findCreation() { # searches creation list for matching number, then extracts the creation name from the line
	listCreations > temp/creationList.txt
	searchResult=$(cat temp/creationList.txt | sed 1,2d | grep "\b${1}\b" - )
	pos=$( echo ${#1} + 6 | bc)
	creation=${searchResult:$pos} # removes number from creation matched
	echo $creation
}






deletionPrompt() {

read -p "Are you sure you want to delete $1 [y/n] " creationDeleteConfirmation

		case $creationDeleteConfirmation in

  	   	[yY])
	     		rm "creations/$1.mp4"
			menu
  	     	;;


	   	[nN])
			menu
	     	;;

	   	*)
			deletionPrompt "$1"
	     	;;

		esac		

}





mkdir -p creations
menu



