#!/bin/bash
#
# schedule.sh
# Allows a user to manage a schedule for events, meetings, classes, etc. at the command line.
# Rachael Birky
# 2014.10.06

printHelp() {
    printf "===========\nschedule.sh Usage\n===========\n"
    printf "\n./schedule.sh help\n  This command prints a synopsis of available commands and a brief description of each.\n"
    printf '\n./schedule.sh add "event in quotes" "<start>" "<end>"\n  This command takes three quoted strings representing an event name, and start and end dates and times.\n'
    printf "\n./schedule.sh del <event number>\n  This command deletes the specified event given its unique event number.\n"
    printf "\n./schedule.sh list (day|week|month) [optional date string]\n  This command displays the events that occur within the given timeframe. If no time is given, the events for today are listed.\n"
}

addEvent() {
	if [[ $# -ne 3 ]]; then
		printf "Illegal number of parameters.\n" >&2
		exit 1
	fi

       	eventName="$1"
	( date --date="$2" "+%m/%d/%y  %l:%M%p" 2>&1 ) > /dev/null	
       	startValid=$?
	if [[ $startValid -ne 0 ]]; then printf "Invalid start date.\n" >&2; exit 1;
	else startDate=$( date --date="$2" "+%m/%d/%y  %l:%M%p" ); fi

	( date --date="$3" "+%m/%d/%y  %l:%M%p" 2>&1 ) > /dev/null
	endValid=$?
	if [[ $endValid -ne 0 ]]; then printf "Invalid end date.\n" >&2; exit 1;
	else endDate=$( date --date="$3" "+%m/%d/%y  %l:%M%p" ); fi
	
	startDateCompare=$(date -d "$2" +"%s")
	endDateCompare=$(date -d "$3" +"%s")
       	if [[ $startDateCompare -gt $endDateCompare ]]; then printf "Invalid dates.\n" >&2; exit 1; fi

	# Check for overlapping times
	while read line
	do
	    echo "a line:"
	    thisDateStartString=$( echo "$line" | cut -d$'\t' -f3 )
	    thisDateEndString=$( echo "$line" | cut -d$'\t' -f4 )
	    #printf "this date string: $thisDateString \n"
	    thisDateStart=$(date -d "$thisDateStartString" +"%s")
	    thisDateEnd=$(date -d "$thisDateEndString" +"%s")
	    printf "this date: $thisDate \n"
	    printf "start date: $startDateCompare \n"
	    conflict=false

	    if [[ ("$startDateCompare" = "$thisDateEnd" || "$startDateCompare" < "$thisDateEnd") && ("$endDateCompare" = "$thisDateStart" || "$endDateCompare" > "$thisDateStart") ]]; then conflict=true; fi
#	    if [[ "$thisDate" = "$startDateCompare" ]]; then echo "One or more"; fi
        done < ~/.schedule/schedule.dat

	if [[ $conflict ]]
	    read -r -p "One or more conflicts exist.  Still add? (Y/N): " stillAdd
	then
	    while [[ $stillAdd != "Y" && $stillAdd != "N" && $stillAdd != "y" && $stillAdd != "n" ]]
	    do
		read -r -p "Invalid option. Type Y or N): " stillAdd
	    done
	fi

	if [[ $stillAdd ]]; then
	    EVENT_NUM=$( cat ~/.schedule/EVENT_NUM.dat );
	    printf $(( $EVENT_NUM + 1 )) > ~/.schedule/EVENT_NUM.dat;
	    printf "$EVENT_NUM:\t$1\t$startDate\t$endDate\n" >> ~/.schedule/schedule.dat;
	    printf "ADDED #$EVENT_NUM - $1";
	fi

}

deleteEvent() {
	if [[ $# -ne 1 ]]; then
		printf "Illegal number of parameters.\n" >&2
		exit 1
	elif [[ $1 -lt 0 ]]; then
		printf "Illegal parameters.\n  Event number should be greater than zero.\n" >&2
		exit 1
	else
	    grep "/^$1:/d;" ~/.schedule/schedule.dat
	    if [[ $? -eq 0 ]]; then
		sed -i "/^$1:/d;" ~/.schedule/schedule.dat
		echo "DELETED $1"
	    else
		printf "Event not found!\n" >&2
		exit 1
	    fi
	fi
}

listEvents() {

    # Optional date string given
    if [[ $# -eq 2 ]]; then
	#validate range
	if [[ "$1" != "month" && "$1" != "week" && "$1" != "day" ]]; then
	    printf "Illegal option. Must be day, week, or month." >&2
	    exit 2
	fi

	#validate given date
	( date --date="$2" 2>&1 ) > /dev/null
	dateValid=$?
	if [[ $dateValid -ne 0 ]]; then
	    printf "Invalid date.\n" >&2; exit 1;
	else givenDate=$( date --date="$2" +"%y%m%U%d" ); filter "$1" $givenDate; fi

    # No date string
    elif [[ $# -eq 1 ]]; then
	#validate range
	if [[ "$1" != "month" && "$1" != "week" && "$1" != "day" ]]; then
	   printf "Illegal option. Must be day, week, or month.\n" >&2; exit 2;
	else filter "$@"; fi

    # No options given at all
     else
	printf "Illegal option. Must provide day, week, or month as range.\n" >&2;
	exit 2;
     fi

}

filter(){

    range="$1"

    if [[ $# -eq 1 ]]; then
	compareDate=$( date --date="today" +"%y%m%U%d" )
    else
	compareDate="$2"
    fi

    echo $range
    echo $compareDate
   
   case $range in
       "day")
	   echo "day"
	   
	   ;;
       "week")
	   echo "week"
	   ;;
       "month")
	   echo "month"
	   ;;
       *)
	   printf "Illegal option. Must provide day, week, or month as range.\n" >&2;
	   exit 2;
   esac

    if [[ ! -f ~/.schedule/temp.dat ]]; then
	printf "Evt#\tEvent Name\tStart Time\tEnd Time\n" > ~/.schedule/temp.dat	
    else
	rm ~/.schedule/temp.dat;
	printf "Evt#\tEvent Name\tStart Time\tEnd Time\n" > ~/.schedule/temp.dat	
    fi

    (cat ~/.schedule/schedule.dat | sort -g -r -k5) >> ~/.schedule/temp.dat
    column -t -s$'\t' ~/.schedule/temp.dat

}

# MAIN
if [[ ! -d ~/.schedule ]]; then
    mkdir ~/.schedule
fi

if [[ ! -f ~/.schedule/EVENT_NUM.dat ]]; then
    EVENT_NUM=1    
    echo "$EVENT_NUM" > ~/.schedule/EVENT_NUM.dat
fi

if [[ ! -f ~/.schedule/schedule.dat ]]; then
    printf "" > ~/.schedule/schedule.dat
fi

if [[ $1 = 'print' ]]; then printL; fi


if [[ $# -eq 1 && $1 = 'help' ]]; then
    printHelp
elif [[ $1 = 'add' ]]; then
	shift
	addEvent "$@"
elif [[ $1 = 'del' ]]; then
	shift
	deleteEvent $@
elif [[ $1 = 'list' ]]; then
	shift
	listEvents "$@"
else
	printf "Invalid option.\n  Type ./schedule.sh help for proper usage.\n"
fi
exit 0

