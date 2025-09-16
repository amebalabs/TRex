#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 path/to/App.app" >&2
  exit 1
fi

APP_PATH="$1"
FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"
if [ ! -d "$FRAMEWORKS_DIR" ]; then
  echo "No frameworks directory at $FRAMEWORKS_DIR; nothing to flatten."
  exit 0
fi

flatten_framework() {
  local framework_path="$1"
  local framework_name
  framework_name="$(basename "$framework_path")"
  local binary_name="${framework_name%.framework}"
  local versions_dir="$framework_path/Versions"

  if [ ! -d "$versions_dir" ]; then
    return
  fi

  local current_name
  if [ -L "$versions_dir/Current" ]; then
    current_name="$(readlink "$versions_dir/Current")"
  fi
  local current_dir
  if [ -n "${current_name:-}" ] && [ -d "$versions_dir/$current_name" ]; then
    current_dir="$versions_dir/$current_name"
  elif [ -d "$versions_dir/A" ]; then
    current_dir="$versions_dir/A"
  else
    echo "Skipping $framework_name: unable to determine current version" >&2
    return
  fi

  echo "Flattening $framework_name"

  copy_item() {
    local source_path="$1"
    local destination_path="$2"

    if [ -d "$source_path" ]; then
      rm -rf "$destination_path"
      cp -R "$source_path" "$destination_path"
    elif [ -f "$source_path" ]; then
      rm -f "$destination_path"
      cp "$source_path" "$destination_path"
    fi
  }

  copy_item "$current_dir/$binary_name" "$framework_path/$binary_name"
  copy_item "$current_dir/Resources" "$framework_path/Resources"
  copy_item "$current_dir/Headers" "$framework_path/Headers"
  copy_item "$current_dir/Modules" "$framework_path/Modules"

  local info_source="$current_dir/Resources/Info.plist"
  if [ -f "$info_source" ]; then
    rm -f "$framework_path/Info.plist"
    cp "$info_source" "$framework_path/Info.plist"
  fi

  rm -rf "$versions_dir"
}

for framework in "TesseractCore.framework" "Leptonica.framework"; do
  framework_path="$FRAMEWORKS_DIR/$framework"
  if [ -d "$framework_path" ]; then
    flatten_framework "$framework_path"
  fi
done
