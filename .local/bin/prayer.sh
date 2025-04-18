#!/bin/sh

# TODO
# [x] make defaults
# [ ] store result locally
# [ ] format output
# [ ] play azhan
# [ ] background process
# [ ] ensure POSIX

flags()
{
	printf "Default: %s\n\n" "$(basename "$0")"
	printf "Options:\n"
	printf "  -c	city\n"
	printf "  -d	date in DD-MM-YYYY format (defaults to current system date)\n"
	printf "  -h	show the options\n"
	printf "  -l	latitude Adjustment Method\n"
	printf "  -m	method\n"
	printf "  -r	country code\n"
}


while getopts ":hc:d:l:m:r:" option; do
	case ${option} in
		c)
			city=${OPTARG};;
		d)
			date=${OPTARG};;
		l)
			lat=${OPTARG};;
		m)
			method=${OPTARG};;
		r)
			country=${OPTARG};;
		h)
			flags
			exit;;
		:)
			printf "Option -%s requires an argument.\n" "${OPTARG}" >&2
			exit;;
		\?)
			printf "Invalid option: -%s\n" "${OPTARG}" >&2
			exit 1;;
		*)
			exit 1;;
	esac
done
	

# default values to use for the script. You will probably want to change them
if [ "${OPTIND}" -eq 1 ]; then
	city=${city:-"Alexandria"}
	country=${country:-"EG"}
	lat=${lat:-3}
	method=${method:-5}
	date=${date:-$(date +%d-%m-%Y)}	# do not change this date format; this is for the url to work
fi


if [ -z "${city}" ] || [ -z "${country}" ] || [ -z "${method}" ] || [ -z "${lat}" ] || [ -z "${date}" ]; then
	printf "Error: did not specify arguments!\n" >&2
	printf "Usage: %s [options] [arguments]\n" "$(basename "$0")"
	exit 1
else
	res=$(curl -X GET "https://api.aladhan.com/v1/timingsByCity/${date}?city=${city}&country=${country}&method=${method}&latitudeAdjustmentMethod=${lat}" -H 'accept: application/json')
	printf "%s" "${res}" | jq .data.timings
fi

