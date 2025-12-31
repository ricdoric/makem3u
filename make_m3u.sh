#!/usr/bin/env bash

set -e

# Check argument
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <folder>"
  exit 1
fi

FOLDER="$1"

if [ ! -d "$FOLDER" ]; then
  echo "Error: '$FOLDER' is not a directory"
  exit 1
fi

# Normalize paths
FOLDER="$(realpath "$FOLDER")"
PARENT_DIR="$(dirname "$FOLDER")"
FOLDER_NAME="$(basename "$FOLDER")"

M3U_PATH="$PARENT_DIR/$FOLDER_NAME.m3u"
NOLOAD_PATH="$FOLDER/noload.txt"

# Create empty noload.txt inside the folder
: > "$NOLOAD_PATH"

# Create m3u with relative paths
> "$M3U_PATH"

find "$FOLDER" -type f -iname "*.cue" | sort | sed "s|^$PARENT_DIR/||" >> "$M3U_PATH"

echo "Created:"
echo "  $NOLOAD_PATH"
echo "  $M3U_PATH"
