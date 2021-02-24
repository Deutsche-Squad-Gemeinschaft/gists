#!/bin/bash
# Write the passed MapRotation content to a named variable
MapRotation="$1"

# Remove blank lines
MapRotation=$(echo "$MapRotation" | sed -r '/^\s*$/d')

# Remove comments with # & // style
MapRotation=$(echo "$MapRotation" | sed -r '/^#/d')
MapRotation=$(echo "$MapRotation" | sed -r '/^\/\//d')

# Output the cleaned MapRotation
echo "$MapRotation"
