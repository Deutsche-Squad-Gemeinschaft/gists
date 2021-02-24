#!/bin/bash
###############
# Small helper script to determine if the provided LayerRotation.cfg is valid or not.
#
# Usage:
#  bash <(curl -s https://raw.githubusercontent.com/Deutsche-Squad-Gemeinschaft/gists/master/validateMapRotation.sh) ./LayerRotation.cfg
###############

# Define basic colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Define the OWI provided maps from automatically updated MapRotation.cfg
readarray -t OfficalMaps < <(curl -s https://raw.githubusercontent.com/Deutsche-Squad-Gemeinschaft/gists/master/data/LayerRotation.cfg | sed -r '/^\s*$/d' | sed 's/[ \t]*$//' | sed 's/\r//g')

# Allow custom maps to be defined externally
CustomMaps=${CustomMaps:=''}

hasOfficalMap() {
    for (( i=0; i<${#OfficalMaps[@]}; i++ )); do
        if [[ ${OfficalMaps[$i]} == $1 ]]; then
            return 0
        fi
    done

    return 1
}

hasCustomMap() {
    for element in "${CustomMaps[@]}"; do       
        if [[ $element == "$1" ]]; then
            return 0
        fi
    done

    return 1
}

while IFS= read -r line; do
    if ! hasOfficalMap "$line" && ! hasCustomMap "$line"; then
        echo -e "${RED}MapRotation is invalid! Map \"$line\" is not recognized.${NC}"
        exit 1
    fi
done < "$1"

echo -e "${GREEN}MapRotation is valid!${NC}"
