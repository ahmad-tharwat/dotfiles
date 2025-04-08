#!/bin/zsh

### Script to make reading docs easier

### TODO
# [ ] set autocompletion for /usr/share/doc/
# [ ] ensure command exist in directory
# [ ] ensure document exist in command directory
# [ ] put logic for different doc files

DOC_DIR="/usr/share/doc"

if [ ! -f DOC_DIR/$1 ]; then
	printf "Document does not exist\n"
fi
