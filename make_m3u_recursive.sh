#!/usr/bin/env bash

set -euo pipefail

print_usage() {
  cat <<EOF
Usage: $0 [-r|--recursive] [-n|--dry-run] <folder>

Options:
  -r, --recursive   Iterate over all first-level subfolders of <folder>
  -n, --dry-run     Show what would be done without creating files
  -h, --help        Show this help and exit
EOF
} 

# Parse options
RECURSIVE=0
DRY_RUN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -r|--recursive)
      RECURSIVE=1
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -* )
      echo "Unknown option: $1"
      print_usage
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

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

# Summary counters
PROCESSED=0
SKIPPED=0

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

  # Gather .cue or .chd files directly in this folder (not nested)
  FILES=$(find "$FOLDER" -maxdepth 1 -type f \( -iname "*.cue" -o -iname "*.chd" \) | sort)
  if [ -z "$FILES" ]; then
    echo "Skipping: '$FOLDER' (no .cue or .chd files)"
    SKIPPED=$((SKIPPED+1))
    return
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "Found folder: '$FOLDER'"
    # echo "  Would create:"
    echo "    $NOLOAD_PATH"
    echo "    $M3U_PATH"
    # echo "  Would write the following entries to $M3U_PATH:"
    # echo "$FILES" | sed "s|^$PARENT_DIR/||"
    PROCESSED=$((PROCESSED+1))
    return
  fi

  # Create empty noload.txt inside the folder
  : > "$NOLOAD_PATH"

  # Create m3u with relative paths (strip the parent dir prefix).
  > "$M3U_PATH"
  printf "%s
" "$FILES" | sed "s|^$PARENT_DIR/||" >> "$M3U_PATH"

  echo "Created:"
  echo "  $NOLOAD_PATH"
  echo "  $M3U_PATH"
  PROCESSED=$((PROCESSED+1))
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

# Summary
echo "Summary:"
echo "  Folders processed: $PROCESSED"
echo "  Folders skipped:   $SKIPPED"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Note: dry-run enabled - no files written"
fi
