#!/bin/bash

unzip_artifact() {
  local filename="$1.zip"
  local destination="$2"
  local skip_check="$3"

  cd "$(get_download_directory)" || exit

  if [ "$skip_check" != true ]; then
    if [ -d "$destination" ]; then
      echo -e "$SUCCESS- '$filename' already unzipped!$CLEAR"
      return 0
    fi
  fi

  echo -e "$INFO- unzipping '$filename' to '$destination'"
  unzip -q "$filename" -d "$destination"
  echo -e "$CLEAR\c"
}

unzip_pdi() {
  local destination
  destination="$(get_pdi_unzip_directory)"

  unzip_artifact "$PDI" "$destination"

  configure_pdi_launcher
}

configure_pdi_launcher() {
  local launcher="$(get_pdi_unzip_directory)/data-integration/spoon.sh"

  # Enable debugging (builds use both '#OPT' and '# OPT').
  sed -i "" 's/^#[[:space:]]*\(OPT=.*-Xdebug.*\)/\1/' "$launcher" || return

  # Cocoa requires separate key/value arguments, not key=value or a JVM option.
  if ! grep -q 'NSRequiresAquaSystemAppearance' "$launcher"; then
    sed -i "" '/^OPT=.*-Xdebug/a\
set -- -NSRequiresAquaSystemAppearance True "$@"
' "$launcher"
  fi
}

unzip_server() {
  local destination
  destination="$(get_server_unzip_directory)"

  unzip_artifact "$SERVER" "$destination"

  # will not prompt user to press enter on server first run
  rm -f "$destination/pentaho-server/promptuser.sh"
}

unzip_plugin() {
  local name="$1"
  local plugin_dir
  plugin_dir="$(get_plugin_unzip_directory)/$(get_plugin_folder_name "$name")"

  # check for the plugin's own subdirectory, not the shared system/ parent
  if [ -d "$plugin_dir" ]; then
    echo -e "$SUCCESS- '$name' already unzipped!$CLEAR"
    return 0
  fi

  # skip_check=true because destination is the shared system/ dir (always exists)
  unzip_artifact "$name" "$(get_plugin_unzip_directory)" "true"
}
