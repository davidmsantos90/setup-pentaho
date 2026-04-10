#!/bin/bash

download_artifact() {
  local artifact="$1"
  local filename="$artifact.zip"
  local url=$2


  cd "$(get_download_directory)" || exit

  if test -f "./$filename"; then
    echo -e "$SUCCESS- '$filename' already downloaded!$CLEAR"
    return 0
  fi

  insecure_flag=""; [ "$secure" = false ] && insecure_flag="--no-check-certificate"

  # expose the full path so the interrupt trap in main.sh can clean up a partial file
  _current_download="$(get_download_directory)/$filename"

  echo -e "$INFO\c"
  wget -nv -q --show-progress -nc $insecure_flag -O "$filename" "$url"
  local wget_exit=$?

  _current_download=""
  echo -e "$CLEAR\c"
  return "$wget_exit"
}

download_pdi() {
  local data=$1

  local url
  url=$(get_artifact_url_from_json "$data")

  download_artifact "$PDI" "$url"
}

download_server() {
  local data=$1

  local url
  url=$(get_artifact_url_from_json "$data")

  download_artifact "$SERVER" "$url"
}

download_plugin() {
  local data=$1
  local name=$2

  local url
  url=$(get_artifact_url_from_json "$data" "$name")

  download_artifact "$name" "$url"
}
