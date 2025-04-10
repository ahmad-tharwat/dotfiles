#!/bin/sh

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
# [x] Add checks for bash and zsh versions
# [x] Portability between bash and zsh
# [x] Make checks function shell agnostic
# [x] Enable multiple URLs
# >>> 10 April 2025
# [x] Make the script POSIX compliant
# [x] Fix urls
#
# [ ] Make a comprehensive DEBUG mode

### yt-dlp command check
commands="yt-dlp"
for cmd in ${commands}; do
	if ! command -v "${cmd}" >/dev/null 2>&1; then
		printf "Error: Required command '%s' is not installed or not in the PATH.\n" "${cmd}" >&2
		command_error=0
	fi
done
[ -z "${command_error}" ] || exit 1

### Arguments check
if [ $# -eq 0 ]; then
	printf "Error: You must provide at least one URL.\n" >&2
	printf "usage: yt-dlp.sh [options] url [url...]\n"
	printf "Type yt-dlp.sh -h to see available options.\n"
	exit 1
fi

### Help menu
flags() {
	printf "usage: %s [options] url [url...]\n\n" "$(basename "$0")"
	printf "Options:\n"
	printf "  -h               show this help\n"
	printf "  -a FORMAT        audio format (aac|m4a|mp3|ogg|wav)\n"
	printf "  -c               enable --embed-chapters\n"
	printf "  -D               debug mode (print command instead of executing)\n"
	printf "  -m MEDIA         media to download ([a]udio|[v]ideo)\n"
	printf "  -r RESOLUTION    choose video resolution\n"
	printf "  -u URLS          specify url(s) to download (overrides remaining arguments)\n"
	printf "  -v FORMAT        video format (3gp|flv|mp4|webm)\n"
}

### Strings and function to check user input for supported patterns/formats
audio_media="a audio"
video_media="v video"
audio_formats="aac m4a mp3 ogg wav"
video_formats="3gp flv mp4 webm"
video_resolutions="240 360 480 720 1080"
no="n no"
yes="y yes"

_pattern_check() {
	input=$(printf "%s" "$1" | tr "[:upper:]" "[:lower:]")

	# proceed to dafault value if empty input
	[ -z "${input}" ] && return 0 || shift

	# SUCCESS
	for pattern in "$@"; do
		if [ "${pattern}" = "${input}" ]; then
			return 0
		fi
	done

	# FAILURE
	printf "Error: '%s' not supported. Choices: (%s)\n" "${input}" "$*" >&2
	return 1
}

interactive_mode() {
	# Processes here are equivilant to do...while loop. User can only proceed with empty(default) or valid input.
	while true; do
		printf "Media(a/V)? "
		read -r media
		if _pattern_check "${media}" ${video_media} >/dev/null 2>&1; then
			while
				printf "Video format [mp4]? "
				read -r video_ext && ! _pattern_check "${video_ext}" ${video_formats}
			do :; done
			while
				printf "Video resolution [1080]? "
				read -r res && ! _pattern_check "${res}" ${video_resolutions}
			do :; done
			break
		elif _pattern_check "${media}" ${audio_media} ${video_media}; then
			break
		fi
	done
	while
		printf "Audio extension [m4a]? "
		read -r audio_ext && ! _pattern_check "${audio_ext}" ${audio_formats}
	do :; done

	while true; do
		printf "Embed chapters(y/N)? "
		read -r embed
		if _pattern_check "${embed}" ${no} >/dev/null 2>&1; then
			break
		elif _pattern_check "${embed}" ${yes} ${no}; then
			chapters="--embed-chapters"
			break
		fi
	done

	while true; do
		printf "Debug(y/N)? "
		read -r debug
		if _pattern_check "${debug}" ${no} >/dev/null 2>&1; then
			break
		elif _pattern_check "${debug}" ${yes} ${no}; then
			debug_state="DEBUG"
			break
		fi
	done
}

while getopts ":cDha:m:r:v:" option; do
	case ${option} in
	a)
		audio_ext="${OPTARG}"
		_pattern_check "${audio_ext}" ${audio_formats} || exit 1
		;;
	c)
		chapters="--embed-chapters"
		;;
	D)
		debug_state="DEBUG"
		;;
	h)
		flags
		exit 0
		;;
	m)
		media="${OPTARG}"
		_pattern_check "${media}" ${video_media} ${audio_media} || exit 1
		;;
	r)
		res="${OPTARG}"
		_pattern_check "${res}" ${video_resolutions} || exit 1
		;;
	v)
		video_ext="${OPTARG}"
		_pattern_check "${video_ext}" ${video_formats} || exit 1
		;;
	:)
		printf "Error: option -%s needs an argument.\n" "${OPTARG}" >&2
		exit 1
		;;
	\?)
		printf "Error: Invalid option -%s\n" "${OPTARG}" >&2
		printf "Type yt-dlp.sh -h to see available options.\n"
		exit 1
		;;
	*) ;;
	esac
done

[ "${OPTIND}" -eq 1 ] && interactive_mode

### Default values
media=${media:-"video"}
audio_ext=${audio_ext:-"m4a"}
video_ext=${video_ext:-"mp4"}
res=${res:-"1080"}

shift $((OPTIND - 1))
urls=${urls:-"$*"}

if [ -z "${urls}" ]; then
	printf "Error: No URLs specified.\n" >&2
	exit 1
fi

### Action
if [ "${debug_state}" = "DEBUG" ]; then
	printf "=========================\n"
	printf "	DEBUG MODE\n"
	printf "=========================\n"
	printf "Media Type: %s\n" "${media}"
	printf "Audio Format: %s\n" "${audio_ext}"
	printf "Embed Chapters: %s\n" "${chapters}"
	if _pattern_check "${media}" ${video_media} >/dev/null 2>&1; then
		printf "Video Format: %s\n" "${video_ext}"
		printf "Video Resolution: %s\n" "${res}"
		printf "yt-dlp -f \"bestvideo[height<=%s][ext=%s]+bestaudio[ext=%s]/best[height<=%s][ext=%s]\" %s " \
			"${res}" "${video_ext}" "${audio_ext}" "${res}" "${video_ext}" "${chapters}"
	elif _pattern_check "${media}" ${audio_media} ${video_media}; then
		printf "yt-dlp -f \"bestaudio[ext=%s]\" %s " "${audio_ext}" "${chapters}"
	fi
	printf "\"%s\" " "${@}"
else
	if _pattern_check "${media}" ${video_media} >/dev/null 2>&1; then
		yt-dlp -f "bestvideo[height<=${res}][ext=${video_ext}]+bestaudio[ext=${audio_ext}]/\
				best[height<=${res}][ext=${video_ext}]" ${chapters} "$@"
	elif _pattern_check "${media}" ${audio_media} ${video_media}; then
		yt-dlp -f "bestaudio[ext=${audio_ext}]" ${chapters} "$@"
	fi
fi
