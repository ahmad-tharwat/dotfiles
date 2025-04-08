#!/bin/bash

flags()
{
	printf "Default:\n"
	printf "  prayer.sh\n\n"
	printf "Options:\n"
	printf "  -h\t show the options\n\n"
	printf "  -d\t date in DD-MM-YYYY format (defaults to current system date)\n"
	printf "  -c\t city\n"
	printf "  -r\t country code\n"
	printf "  -l\t latitudeAdjustmentMethod\n"
	printf "  -m\t method\n"
}

printf -v date '%(%d-%m-%Y)T' -1	# do not change this date format; this is for the url to work

if [ $# -eq 0 ]; then
	# my default values to use for the script. 
	# you will probably want to change them
	city="Alexandria"
	country="EG"
	method=5
	latitudeAdjustmentMethod=3
else
	while getopts ":hc:d:l:m:r:" option; do
		case $option in
			c)
				city=${OPTARG};;
			d)
				date=${OPTARG};;
			l)
				latitudeAdjustmentMethod=${OPTARG};;
			m)
				method=${OPTARG};;
			r)
				country=${OPTARG};;
			h)
				flags
				exit;;
			:)
				printf "Option -${OPTARG} requires an argument.\n"
				exit;;
			\?)
				printf "Invalid option: -${OPTARG}\n"
				exit 1;;
		esac
	done
	
fi

if [ -z "$city" ] || [ -z "$country" ] || [ -z "$method" ] || [ -z "$latitudeAdjustmentMethod" ]; then
	printf "Error: did not specify arguments!\n\n"
	printf "Usage: $0 [options] [arguments]\n"
	flags
	exit 1
else
	res=`curl -X GET "https://api.aladhan.com/v1/timingsByCity/${date}?city=${city}&country=${country}&method=${method}&latitudeAdjustmentMethod=${latitudeAdjustmentMethod}" -H 'accept: application/json'`
	printf "$res" | jq .data.timings
fi

