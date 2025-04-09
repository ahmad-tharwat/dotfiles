#!/usr/bin/env zsh

### Script for functions I usually use with yt-dlp
#
# I prefer to download videos from youtube to study later than to stream it every time
# due to limited internet data plans. I need a lot of quota for databases
#
# my default yt-dlp arguments are provided below. If you read the yt-dlp command, you will 
# understand why I did not want to write it every time I need to download a video/audio

### TODO
# >>> 08 April 2025
# [x] Apply default values in case of empty variables
# [x] Only accept correct arguments (interactive)
# [x] Only accept correct arguments (flags)
# [x] Prototype for DEBUG mode
# >>> 09 April 2025
# [x] Add checks for used packages
# [x] Add checks for bash and other packages versions
# [x] Portability between bash and zsh
# [x] Make checks function shell agnostic
# [x] Enable multiple URLs
#
# [ ] Make a comprehensive DEBUG mode

if [ -n "$ZSH_VERSION" ]; then
	low() { echo "${1:l}"; }
	# TODO: check for required zsh version
elif [ -n "$BASH_VERSION" ]; then
	low() { echo "${1,,}"; }
	if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3) )); then
		printf "Error: This script requires at least Bash 4.3 (you are running %s)." "$BASH_VERSION" >&2
		exit 1
	fi
else
	printf "Unsupported shell!"
	exit 1
fi

### yt-dlp command check
cmd="yt-dlp"
if ! command -v "$cmd" >/dev/null 2>&1; then
	echo "Error: Required command '$cmd' is not installed or not in the PATH.\n" >&2
	exit 1
fi

### Arguments check
if [ $# -eq 0 ]; then
	printf "error: You must provide at least one URL.\n"
	printf "usage: %s [options] url [url...]\n" "$0"
	printf "Type %s -h to see available options.\n" "$0"
	exit 1
fi

### Help menu
flags()
{
	printf "usage: %s [options] url [url...]\n\n" "$0"
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

### Arrays and function to check user input for supported formats
media_types=( "a" "audio" "v" "video" )
audio_formats=( "aac" "m4a" "mp3" "ogg" "wav" )
video_formats=( "3gp" "flv" "mp4" "webm" )
video_resolutions=( "240" "360" "480" "720" "1080" )
yes_no=( "y" "yes" "n" "no" )

_pattern_check()
{
	# proceed later to dafault value
	if [ -z "$1" ]; then
		return 0
	fi

	local input=$(low "$1")
	local -a checks
	eval "checks=(\"\${${2}[@]}\")"

	# SUCCESS
	for pattern in "${checks[@]}"; do
		if [ "${pattern}" = "$input" ]; then
			return 0
		fi
	done
	
	# FAILURE
	printf "%s not supported. try again\n" "$input"
	return 1
}

interactive_mode()
{
	# Processes here are equivilant to do...while loop. User can only proceed with empty or valid input.
	# In C style, that would be similar to:
	# 		(get_input >  CHECK <input> vs <array> ? break : repeat_loop)
	while read -p "Media(a/V)? " media && ! _pattern_check "$media" "media_types"; do : ; done
	while read -p "Audio extension [m4a]? " audio_ext && ! _pattern_check "$audio_ext" "audio_formats"; do : ; done
	while read -p "Embed chapters(y/N)? " embed && ! _pattern_check "$embed" "yes_no"; do : ; done

	if [ "$(low "$embed")" = "y" ] || [ "$(low "$embed")" = "yes" ]; then
		chapters=${chapters/"$embed"/"--embed-chapters"}
	fi

	if [ -z "$media" ] || [ "$(low "$media")" = "v" ] || [ "$(low "$media")" = "video" ]; then
		while read -p "Video format [mp4]? " video_ext && ! _pattern_check "$video_ext" "video_formats"; do : ; done
		while read -p "Video resolution [1080]? " res && ! _pattern_check "$res" "video_resolutions"; do : ; done
	fi
}

script_start()
{
	if [ "$1" = "DEBUG" ]; then
		if [ "$(low "$media")" = "v" ] || [ "$(low "$media")" = "video" ]; then
			printf "\nyt-dlp -f \"bestvideo[height<=%s][ext=%s]+bestaudio[ext=%s]/best[height<=%s][ext=%s]\" %s "\
				"${res}" "${video_ext}" "${audio_ext}" "${res}" "${video_ext}" "${chapters}"
			for u in "${urls[@]}"; do  printf "\"%s\" " "$u"; done
		elif [ "$(low "$media")" = "a" ] || [ "$(low "$media")" = "audio" ]; then
			printf "\nyt-dlp -f \"bestaudio[ext=%s]\" %s " "${audio_ext}" "${chapters}"
			for u in "${urls[@]}"; do  printf "\"%s\" " "$u"; done
		else
			printf "Error: media not specified!"
		fi
	elif [ -z "$1" ]; then
		if [ "$(low "$media")" = "v" ] || [ "$(low "$media")" = "video" ]; then
			yt-dlp -f "bestvideo[height<=${res}][ext=${video_ext}]+bestaudio[ext=${audio_ext}]/\
				best[height<=${res}][ext=${video_ext}]" ${chapters} "${urls[@]}"
		elif [ "$(low "$media")" = "a" ] || [ "$(low "$media")" = "audio" ]; then
			yt-dlp -f "bestaudio[ext=${audio_ext}]" ${chapters} "${urls[@]}"
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
			urls="${OPTARG[@]}";;
		v)
			video_ext="${OPTARG}"
			_pattern_check "$video_ext" "video_formats" || exit 1
			;;
		:)
			printf "Error: option -%s needs an argument." "${OPTARG}"
			exit 1;;
		\?)
			printf "Error: Invalid option -%s\n" "${OPTARG}"
			printf "Type %s -h to see available options.\n" "$0"
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
urls=("${@:$OPTIND}")

script_start "$debug_state"

