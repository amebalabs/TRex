#!/usr/bin/env bash
set -euo pipefail

# This script fixes framework structure for App Store submission.
# The issue: TesseractSwift frameworks have an Info.plist symlink at root level
# which causes "unsealed contents" errors during App Store validation.
# Solution: Remove the improper Info.plist symlink while keeping the versioned structure.

if [ $# -ne 1 ]; then
  echo "Usage: $0 path/to/App.app" >&2
  exit 1
fi

APP_PATH="$1"
FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"
if [ ! -d "$FRAMEWORKS_DIR" ]; then
  echo "No frameworks directory at $FRAMEWORKS_DIR; nothing to fix."
  exit 0
fi

fix_framework() {
  local framework_path="$1"
  local framework_name
  framework_name="$(basename "$framework_path")"

  # Remove the improper Info.plist symlink at root level if it exists
  # This symlink causes "unsealed contents" errors during App Store validation
  local info_plist_link="$framework_path/Info.plist"
  if [ -L "$info_plist_link" ]; then
    echo "Removing improper Info.plist symlink from $framework_name"
    rm -f "$info_plist_link"
  fi
}

for framework in "TesseractCore.framework" "Leptonica.framework"; do
  framework_path="$FRAMEWORKS_DIR/$framework"
  if [ -d "$framework_path" ]; then
    fix_framework "$framework_path"
  fi
done

echo "Framework structure fixed for App Store submission."
