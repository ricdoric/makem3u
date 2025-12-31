#!/usr/bin/env bash

set -euo pipefail

print_usage() {
  cat <<EOF
Usage: $0 [-r|--recursive] <folder>

Options:
  -r, --recursive   Iterate over all first-level subfolders of <folder>
  -h, --help        Show this help and exit
EOF
}

# Parse options
RECURSIVE=0
if [ "$#" -ge 1 ]; then
  case "$1" in
    -r|--recursive)
      RECURSIVE=1
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
  esac
fi

if [ "$#" -ne 1 ]; then
  print_usage
  exit 1
fi

TARGET="$1"
if [ ! -d "$TARGET" ]; then
  echo "Error: '$TARGET' is not a directory"
  exit 1
fi

# Normalize
TARGET="$(realpath "$TARGET")"

process_folder() {
  local FOLDER="$1"
  local PARENT_DIR
  local FOLDER_NAME
  local M3U_PATH
  local NOLOAD_PATH

  PARENT_DIR="$(dirname "$FOLDER")"
  FOLDER_NAME="$(basename "$FOLDER")"

  M3U_PATH="$PARENT_DIR/$FOLDER_NAME.m3u"
  NOLOAD_PATH="$FOLDER/noload.txt"

  # Ensure there are .cue or .chd files (case-insensitive)
  if ! find "$FOLDER" -type f \( -iname "*.cue" -o -iname "*.chd" \) | grep -q .; then
    echo "Skipping: '$FOLDER' (no .cue or .chd files)"
    return
  fi

  # Create empty noload.txt inside the folder
  : > "$NOLOAD_PATH"

  # Create m3u with relative paths (strip the parent dir prefix)
  > "$M3U_PATH"
  find "$FOLDER" -type f \( -iname "*.cue" -o -iname "*.chd" \) | sort | sed "s|^$PARENT_DIR/||" >> "$M3U_PATH"

  echo "Created:"
  echo "  $NOLOAD_PATH"
  echo "  $M3U_PATH"
}

if [ "$RECURSIVE" -eq 1 ]; then
  # Iterate immediate subdirectories
  shopt -s nullglob
  for d in "$TARGET"/*/; do
    [ -d "$d" ] || continue
    process_folder "${d%/}"
  done
else
  process_folder "$TARGET"
fi
