#!/bin/bash

### Script for functions I usually use with yt-dlp
#
# I prefer to download videos from youtube to study later than to stream it every time
# due to limited internet data plans. I need a lot of quota for databases
#
# my default yt-dlp arguments are provided below. If you read the yt-dlp command, you will 
# understand why I did not want to write it every time I need to download a video/audio

### TODO
# [x] Apply default values in case of empty variables
# [ ] Enable multiple URLs
# [x] Only accept correct arguments (interactive)
# [x] Only accept correct arguments (flags)
# [ ] Add checks for used packages
# [ ] Add checks for bash and other packages versions
# [x] Prototype for DEBUG mode

if [ $# -eq 0 ]; then
	printf "error: You must provide at least one URL.\n"
	printf "usage: $0 [options] url [url...]\n"
	printf "Type $0 -h to see available options.\n"
	exit 1
fi

flags()
{
	printf "usage: $0 [options] url [url...]\n\n"
	printf "Options:\n"
	printf "  -h\t\t show this help\n"
	printf "  -a FORMAT\t audio format (aac|m4a|mp3|ogg|wav)\n"
	printf "  -c\t\t enable --embed-chapters\n"
	printf "  -D\t\t debug instead of install\n"
	printf "  -m MEDIA\t media to download ([a]udio | [v]ideo)\n"
	printf "  -r RESOLUTION\t choose video resolution\n"
	printf "  -u URLS\t specify urls(s) to download\n"
	printf "  -v FORMAT\t video format (3gp|flv|mp4|webm)\n"
}

### Reusable arrays
media_types=("a" "audio" "v" "video")
audio_formats=("aac" "m4a" "mp3" "ogg" "wav")
video_formats=("3gp" "flv" "mp4" "webm")
video_resolutions=("240" "360" "480" "720" "1080")
yes_no=("y" "yes" "n" "no")

_pattern_check()
{
	# condition to proceed later to dafault value
	if [ -z "$1" ]; then
		return 0
	fi

	local input="${1,,}"
	local arr="${2}"
	declare -n checks="$arr"

	# success condition
	for pattern in "${checks[@]}"; do
		if [ "${pattern}" = "$input" ]; then
			return 0
		fi
	done
	
	# failure
	printf "$input not supported. try again\n"
	return 1
}

interactive_mode()
{
	while read -p "Media(a/V)? " media && ! _pattern_check "$media" "media_types"; do : ; done
	while read -p "Audio extension [m4a]? " audio_ext && ! _pattern_check "$audio_ext" "audio_formats"; do : ; done
	while read -p "Embed chapters(y/N)? " embed && ! _pattern_check "$embed" "yes_no"; do : ; done

	if [ "${embed,,}" = "y" ] || [ "${embed,,}" = "yes" ]; then
		chapters=${chapters/${embed}/"--embed-chapters"}
	fi

	if [ -z "$media" ] || [ "${media,,}" = "v" ] || [ "${media,,}" = "video" ]; then
		while read -p "Video format [mp4]? " video_ext && ! _pattern_check "$video_ext" "video_formats"; do : ; done
		while read -p "Video resolution [1080]? " res && ! _pattern_check "$res" "video_resolutions"; do : ; done
	fi
}

script_start()
{
	if [ "$1" = "DEBUG" ]; then
		if [ "${media,,}" = "v" ] || [ "${media,,}" = "video" ]; then
			# separated the command on 2 lines for readability
			printf "yt-dlp -f \"bestvideo[height<=${res}][ext=${video_ext}]+bestaudio[ext=${audio_ext}]/"
			printf "best[height<=${res}][ext=${video_ext}]\" ${chapters} \"${urls}\""
		elif [ "${media,,}" = "a" ] || [ "${media,,}" = "audio" ]; then
			printf "yt-dlp -f \"bestaudio[ext=${audio_ext}]\" ${chapters} \"${urls}\""
		else
			printf "Error: media not specified!"
		fi
	elif [ -z "$1" ]; then
		if [ "${media,,}" = "v" ] || [ "${media,,}" = "video" ]; then
			yt-dlp -f "bestvideo[height<=${res}][ext=${video_ext}]+bestaudio[ext=${audio_ext}]/\
				best[height<=${res}][ext=${video_ext}]" ${chapters} "${urls}"
		elif [ "${media,,}" = "a" ] || [ "${media,,}" = "audio" ]; then
			yt-dlp -f "bestaudio[ext=${audio_ext}]" ${chapters} "${urls}"
		else
			printf "Error: media not specified!"
		fi
	else
		printf "Error: invalid mode of operation!\n"
	fi
}

while getopts ":cDha:m:r:u:v:" option; do
	case $option in
		a)
			audio_ext="${OPTARG}"
			_pattern_check "$audio_ext" "audio_formats" || exit 1
			;;
		c)
			chapters="--embed-chapters";;
		D)
			debug_state="DEBUG";;
		h)
			flags
			exit;;
		m)
			media="${OPTARG}"
			_pattern_check "$media" "media_types" || exit 1
			;;
		r)
			res="${OPTARG}"
			_pattern_check "$res" "video_resolutions" || exit 1
			;;
		u)
			urls="${OPTARG}";;
		v)
			video_ext="${OPTARG}"
			_pattern_check "$video_ext" "video_formats" || exit 1
			;;
		:)
			printf "Error: option -${OPTARG} needs an argument."
			exit 1;;
		\?)
			printf "Error: Invalid option -${OPTARG}\n"
			printf "Type $0 -h to see available options.\n"
			exit 1;;
	esac
done

if [ "$OPTIND" -eq 1 ]; then
	interactive_mode
fi

### Default values
media=${media:-"v"}
audio_ext=${audio_ext:-"m4a"}
video_ext=${video_ext:-"mp4"}
res=${res:-"1080"}
urls=${@: -1} # TODO: multiple urls

script_start "$debug_state"
