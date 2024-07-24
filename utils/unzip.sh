#!/bin/bash

unzip_artifact() {
  local filename="$1.zip"
  local destination="$2"

  cd "$(get_download_directory)" || exit

  if [ -d "$destination" ]; then
    echo -e "$SUCCESS- '$filename' already unzipped!$CLEAR"
    return 0
  fi

  echo -e "$INFO- unzipping $filename to $destination'"
  unzip -q "$filename" -d "$destination"
  echo -e "$CLEAR\c"
}

unzip_pdi() {
  local destination
  destination="$(get_pdi_unzip_directory)"

  unzip_artifact "$PDI" "$destination"

  # enable debug on pdi
  sed -i "" "s/#OPT/OPT/" "$destination/data-integration/spoon.sh"
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

  unzip_artifact "$name" "$(get_plugin_unzip_directory)"
}
