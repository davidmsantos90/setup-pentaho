#!/bin/bash

# TODO
#  - list builds
#  - better error handling
#  - better detection of installed build and plugins
#  - canceling script before download finished, should delete files

BIFS="$IFS"

### Setup modes (-m / mode) ###
  MODE_SERVER="server"
  MODE_PDI="pdi"

### Server Plugins (-p / plugins) ###
  PLUGIN_PAZ="paz-plugin-ee"
  PLUGIN_PDD="pdd-plugin-ee"
  PLUGIN_PIR="pir-plugin-ee"

### Buils (-b / build) ###
  SNAPSHOT="snapshot"
  QAT="qat"
  RELEASE="release"

### Features (-f / feature) ###
  FEAT_MASTER="master"
  FEAT_WCAG="WCAG-branch"
  FEAT_SCHEDULER="schedule-plugin"


### log colors ###
  INFO="\033[1;34m"
  SUCCESS="\033[1;32m"
  WARN="\033[1;33m"
  ERROR="\033[1;31m"
  CLEAR="\033[0;39m"

### Artifacts ###
  PDI=pdi-ee-client
  SERVER=pentaho-server-ee

CURRENT_SCRIPT_DIR=$(dirname "$(realpath "$0")")

set -a
  . "$CURRENT_SCRIPT_DIR/utils/download.sh"
  . "$CURRENT_SCRIPT_DIR/utils/json.sh"
  . "$CURRENT_SCRIPT_DIR/utils/unzip.sh"
set +a


get_temp_directory() {
  echo "$root_directory/builds/.temp"
}

get_download_directory() {
  echo "$root_directory/builds/$build/$feature/$version/$date_setup"
}

get_unzip_directory() {
  echo "$root_directory/$build/$feature/$version/$date_setup"
}

get_pdi_unzip_directory() {
  echo "$(get_unzip_directory)/$PDI"
}

get_server_unzip_directory() {
  echo "$(get_unzip_directory)/$SERVER"
}

get_plugin_unzip_directory() {
  echo "$(get_server_unzip_directory)/pentaho-server/pentaho-solutions/system"
}

check_dependencies() {
  local date_path
  local jq_path
  local wget_path
  local has_dependencies_installed=true

  date_path=$(which date)
  if [ -z "$date_path" ]; then
    has_dependencies_installed=false
    [[ $OSTYPE != 'darwin'* ]] && echo -e "$ERROR! this script needs 'date' to be installed !$CLEAR"
  fi

  if [ $has_dependencies_installed = false ] || { [[ $OSTYPE == 'darwin'* ]] && [[ $date_path != *'coreutils'* ]]; }; then
    has_dependencies_installed=false

    echo -e "$ERROR! this script needs 'date' from 'coreutils' to be installed !$CLEAR"
    echo -e "  - $ 'brew install coreutils'"
    echo -e "  - and add it to your $INFO\$PATH$CLEAR"
    echo -e "     - PATH=\"/opt/homebrew/opt/coreutils/libexec/gnubin:\$PATH\""
  fi


  jq_path=$(which jq)
  if [ -z "$jq_path" ]; then
    has_dependencies_installed=false
    echo -e "$ERROR! this script needs 'jq' to be installed !$CLEAR"
  fi

  wget_path=$(which wget)
  if [ -z "$wget_path" ]; then
    has_dependencies_installed=false
    echo -e "$ERROR! this script needs 'wget' to be installed !$CLEAR"
  fi

  if [ $has_dependencies_installed = false ]; then
    return 1
  fi
}

get_date() {
  local date_str=$1
  local output_format="%Y-%m-%d"

  date -d "$date_str" "+$output_format"
}

is_build_downloaded() {
  local flag=true

  if [ "$mode" = "$MODE_SERVER" ]; then
    if [ ! -d "$(get_server_unzip_directory)" ] && [ ! -d "$(get_download_directory)" ]; then
      flag=false
    fi
  else
    if [ ! -d "$(get_pdi_unzip_directory)" ] && [ ! -d "$(get_download_directory)" ]; then
      flag=false
    fi
  fi

  echo "$flag"
}

is_build_unzipped() {
  local flag=false

  if [ "$mode" = "$MODE_SERVER" ]; then
    if [ -d "$(get_server_unzip_directory)" ]; then
      flag=true
    fi
  else
    if [ -d "$(get_pdi_unzip_directory)" ]; then
      flag=true
    fi
  fi

  echo "$flag"
}


print_help() {
  echo -e "$INFO\c"
  echo -e "$INFO### Help ###\n"
  echo -e "$INFO (-s) [true]        Download build in secure / unsecure mode"
  echo -e "$INFO (-l) [false]       Launch after build is ready"
  echo -e "$INFO (-m) [server]      Setup mode"
  echo -e "$CLEAR                      - 'server'"
  echo -e "$CLEAR                      - 'pdi'"
  echo -e "$INFO (-p) [null]        Pentaho Server plugins"
  echo -e "$CLEAR                      - 'paz-plugin-ee'"
  echo -e "$CLEAR                      - 'paz-plugin-ee,pdd-plugin-ee,pir-plugin-ee'"
  echo -e "$CLEAR                      - '...'"
  echo -e "$INFO (-b) [snapshot]    Pentaho build type"
  echo -e "$CLEAR                      - 'snapshot'"
  echo -e "$CLEAR                      - 'qat'"
  echo -e "$CLEAR                      - 'release'"
  echo -e "$INFO (-f) [master]      Download build from a feature branch"
  echo -e "$CLEAR                      - 'master'"
  echo -e "$CLEAR                      - 'WCAG-branch'"
  echo -e "$CLEAR                      - 'schedule-plugin'"
  echo -e "$CLEAR                      - '...'"
  echo -e "$INFO (-v) [$version]    Pentaho build version"
  echo -e "$INFO (-d) [$date_today]  Specify the build date you want to setup"
  echo -e "$CLEAR                      - need to have build already downloaded"
  echo -e "$CLEAR                      - format: YYYY-MM-DD (other formats may be valid)"

  echo -e "$CLEAR"
}

print_setup_info() {
  local date_extra="${1:-latest}"

  echo -e "$INFO\n### Setup Pentaho Build ###"
  echo -e "- mode: '$mode'"
  if [ "$mode" = "$MODE_SERVER" ]; then
    echo -e "- plugins: '$plugins'"
  fi
  echo -e "- build: '$build'"
  echo -e "- feature: '$feature'"
  echo -e "- version: '$version'"
  echo -e "- date: '$date_setup' ($date_extra) \n$CLEAR"
}
