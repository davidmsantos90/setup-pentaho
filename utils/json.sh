#!/bin/bash

get_json_folder_id() {
  local build_uppercase=$(echo "$build" | tr '[:lower:]' '[:upper:]')

  local id=""
  case "$build" in
    "$RELEASE") id="$version";;
    "$QAT")
      major=$(echo $version | cut -d'.' -f 1)
      minor=$(echo $version | cut -d'.' -f 2)

      id="$major.$minor-$build_uppercase"
      ;;
    *) # SNAPSHOT and others
      id="$version-$build_uppercase"; [ "$feature" != "master" ] && id="$feature"
      ;;
  esac

  echo $id
}

get_json_build_file_id() {
  local id=$1
  local sufix=""

  if [ -z $id ]; then
    case "$mode" in
      "$MODE_SERVER") id=$SERVER;;
      "$MODE_PDI")
        id=$PDI
        sufix="-osgi"
        ;;

      # ?handle feature branch ids?
      # *) ;;
    esac
  fi

  if [ $build = $SNAPSHOT ]; then
    local build_uppercase=$(echo "$build" | tr '[:lower:]' '[:upper:]')
    id="$id-$version-$build_uppercase"
  fi

  echo "$id$sufix.zip"
}

get_json_file_mapping() {
  mkdir -p $(get_temp_directory)

  local filename="fileMapping.json"

  cd "$(get_temp_directory)" || exit

  local mapping_url="$build_repository/hosted/$filename"
  wget -nv -q -nc "$mapping_url"

  echo $(jq -c '.' $filename)
}

get_json_build_folder() {
  local jq_filter="folders.\"$(get_json_folder_id)\""
  case "$build" in
    # release and qat
    # has multiple builds in ".groups" but we only want the latest
    "$RELEASE" | "$QAT") jq_filter="$jq_filter.latest[0]";;

    # snapshot and others
    # always have just one build in groups (the latest)
    *) jq_filter="$jq_filter.groups[0]";;
  esac

  json_mapping="$(get_json_file_mapping)"
  if [ -n "$json_mapping" ]; then
    echo $(get_json_file_mapping) | jq -c -r ".$jq_filter"
  fi
}

get_date_from_json() {
  local folder=$1

  if [ "$build" != "$SNAPSHOT" ]; then
    local label=$(echo "$folder" | jq -r ".label")

    echo $label | cut -d'|' -f 2 | cut -d'_' -f 1 | tr -d ' '
  else
    local request_url=$(echo "$folder" | jq -r ".files.\"$(get_json_build_file_id)\".url")
    local request_info=$(wget -S --spider "$request_url" 2>&1)
    local content_disposition=$(echo "$request_info" | grep "Content-Disposition")

    local regex="filename=\".+-$version-([0-9]+)\..+\";"
    if [[ $content_disposition =~ $regex ]]; then
      echo $(get_date "${BASH_REMATCH[1]}")
    fi
  fi
}

get_artifact_url_from_json() {
  local folder=$1
  local id_override=$2

  local url=$(echo "$folder" | jq -r ".files.\"$(get_json_build_file_id $id_override)\".url")

  echo $url
}
