	while read line
	do
		compareStart=
		compareEnd=
	    thisDateString=$( echo "$line" | cut -d$'\t' -f3 )
	    thisDate=$(date -d "$thisDateStartString" +"%d")

	    if [[ ("$startDateCompare" = "$thisDateEnd" || "$startDateCompare" < "$thisDateEnd") && ("$endDateCompare" = "$thisDateStart" || "$endDateCompare" > "$thisDateStart") ]]; then conflict=true; fi

done < ~/.schedule/schedule.dat