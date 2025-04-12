#!/bin/sh

# TODO
# [x] argument check
# [x] zsh autocompletion for /usr/share/doc/
# [x] file/directory check
# [x] read ASCII text files
# [x] read UTF-8 text files
# [x] read html files
# [x] assign multiple values to check

BASE_DIR="/usr/share/doc"
FILE="${BASE_DIR}/$1"

# argument checkk
if [ "$#" -lt 1 ]; then
	printf "Error: no command provided!\n" >&2
	printf "Usage: %s document\n" "$(basename "$0")"
	exit 1
fi

# document check
if [ ! -e "${BASE_DIR}/$1" ]; then
	printf "Error: no documentation found!\n" >&2
	exit 1
fi

_file_type_check()
{
	file_out=$(file "$1")
	shift
	for pattern in "$@"; do
		printf "%s" "${file_out}" | grep -q "${pattern}" && return 0
	done
	return 1
}

if _file_type_check "${FILE}" "HTML"; then
	cmd="lynx"
elif _file_type_check "${FILE}" "compressed data"; then
	cmd="zcat"
elif _file_type_check "${FILE}" "ASCII" "UTF-8" "text/plain" "XML" "Rich Text Format"; then
	cmd="cat"
elif _file_type_check "${FILE}" "PDF"; then
	cmd="pdftotext"
else
	cmd="cat"
fi

printf "Displaying document using %s...\n" "${cmd}"
if [ "${cmd}" = "lynx" ]; then
	"${cmd}" "${FILE}"
else
	"${cmd}" "${FILE}" | less
fi
