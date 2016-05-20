#!/bin/bash

#function library	May 19, 2016
#Bryndon Lezchuk (bryndonlezchuk@gmail.com)

INTERACTIVE="ON"
VERBOSE="OFF"
LOGFILE="OFF"
RECURSIVE="OFF"

setup () {
	#setup temp files/directories
	#the arg for both d and f are the amount of files or directories to create
	local OPTIND
	while getopts ":d:f:" OPT; do
		case "$OPT" in
			#directory
			d)	if [[ "$OPTARG" =~ [[:digit:]] && ! "$OPTARG" -eq 0 ]]
				then
					for ((i=0; i<"$OPTARG"; i++))
					do
						TMPDIR[$i]=$(mktemp -d)
						verbout "TMPDIR[$i]=${TMPDIR[$1]}" "green"
					done
				fi;;
			#file
			f)	if [[ "$OPTARG" =~ [[:digit:]] && ! "$OPTARG" -eq 0 ]]
                                then
                                        for ((i=0; i<"$OPTARG"; i++))
                                        do
                                                TMPFILE[$i]=$(mktemp)
						verbout "TMPFILE[$i]=${TMPFILE[$1]}" "green"
                                        done
                                fi;;
			#other
			\?)	echo "Unkown option for function setup"
				cleanup 1;;
		esac
	done
	shift $(($OPTIND-1))


	IFSTEMP="$IFS"
	IFS=$' \n\t'
	getargs "$@"
	RUNDIR="$(pwd)"
}

cleanup () {
	IFS="$IFSTEMP"
	cd "$RUNDIR"

	for ITEM in "${TMPDIR[@]}"
	do
		rm -Rf "$ITEM"
		verbout "Removing directory '$ITEM' and all contents" "purple"
	done

	for ITEM in "${TMPFILE[@]}"
	do
		rm -f "$ITEM"
		verbout "Removing file '$ITEM'" "purple"
	done

	verbout "Exiting program" "red"

	if [[ -z $1 ]]
	then
		exit 0
	elif [[ $1 =~ [0-9]* ]]
	then
		exit "$1"
	else	
		exit 1
	fi
}

getargs () {
	local I=0
	for ITEM in "$@"
	do
		debugout "ARGS[$I]=$ITEM" "yellow"
		ARGS[$I]="$ITEM"
		((I++))
	done
}

message () {
	if [[ -z "$2" ]]
	then
		echo -e "$1"
	else
		cmessage "$2" "$1\n"
	fi
}

errormessage () {
	cmessage "red" "ERROR: $1\n" >&2

	#write to a log file
	if [[ ! -z $2 ]]
	then
		echo -e "$(date): $1" >> "$2"
	fi
}

cmessage () {
	local COLOR
	local MSG=$2

	case $1 in
		black)	COLOR='\e[0;30m';;
		red)	COLOR='\e[0;31m';;
		green)	COLOR='\e[0;32m';;
		yellow)	COLOR='\e[0;33m';;
		blue)	COLOR='\e[0;34m';;
		purple) COLOR='\e[0;35m';;
		cyan)	COLOR='\e[0;36m';;
		white)	COLOR='\e[0;37m';;
	esac

	echo -ne "${COLOR}${MSG}\e[0m"
}

yesnoquit () {
	while true
	do
		message "$1 (yes/no/quit)"
		read INPUT

		case $INPUT in
			y | Y | yes | Yes)
				return 0;;
			n | N | no | No)
				return 1;;
			q | Q | quit | Quit)
				cleanup;;
			*)	message "Unkown input, please try again";;
		esac
	done
}

log () {
	logger "${0##*/}: $1"
}

verbout () {
	if [[ "$VERBOSE" = "ON" ]]
	then
		if [[ -z "$2" ]]
		then
			message "$1" "cyan"
		else
			cmessage "$2" "$1\n"
		fi
	fi
}

debugout () {
	if [[ "$DEBUG" = "ON" ]]
	then
		if [[ -z "$2" ]]
       		then
       	        	message "$1" "yellow"
        	else
                	cmessage "$2" "$1\n"
        	fi
	fi
}

getipaddr () {
	DEVICE="$1"
	#one liner to pull the IP off of the given device interface
	ifconfig "$DEVICE" | egrep -o "(([01]?[[:digit:]]?[[:digit:]]|2[0-4][[:digit:]]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])" | head -n 1
}

sedreplace () {
	OLD="$1"
	NEW="$2"
	FILE="$3"
	sed -i "s/$OLD/$NEW/g" "$FILE"
}

verifyipv4 () {
	local IP="$1"
	if echo "$IP" | egrep -o "(([01]?[[:digit:]]?[[:digit:]]|2[0-4][[:digit:]]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])"
	then
		return true
	else
		return false
	fi
}

makedir () {
	local DIR="$1"
	if [[ ! -d "$DIR" ]]
	then
		mkdir "$DIR"
	else
		verbout "$DIR already exists"
		debugout "$DIR already exists"
	fi
}
