#!/bin/bash

# TODO
#  - better error handling

BIFS="$IFS"

### Setup modes (-m / mode) ###
  MODE_SERVER="server"
  MODE_PDI="pdi"

### Server Plugins (-p / plugins) ###
  PLUGIN_PAZ="paz-plugin-ee"
  PLUGIN_PDD="pdd-plugin-ee"
  PLUGIN_PIR="pir-plugin-ee"

# Maps a plugin zip name to the folder name it extracts into under system/
get_plugin_folder_name() {
  local plugin_name="$1"
  case "$plugin_name" in
    "$PLUGIN_PAZ") echo "analyzer";;
    "$PLUGIN_PDD") echo "dashboards";;
    "$PLUGIN_PIR") echo "pentaho-interactive-reporting";;
    *)             echo "$plugin_name";;  # unknown plugin: assume zip name = folder name
  esac
}

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
  . "$CURRENT_SCRIPT_DIR/utils/list.sh"
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

  if [ "$has_dependencies_installed" = false ] || { [[ $OSTYPE == 'darwin'* ]] && [[ $date_path != *'coreutils'* ]]; }; then
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

  if [ "$has_dependencies_installed" = false ]; then
    return 1
  fi
}

get_date() {
  local date_str=$1
  local output_format="%Y-%m-%d"

  if [ -z "$date_str" ]; then
    date "+$output_format"
  else
    date -d "$date_str" "+$output_format"
  fi
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
  echo -e "$INFO"
  echo -e "  ### setup-pentaho ###"
  echo -e "$CLEAR"
  echo -e "  setup-pentaho [flags]"
  echo ""

  # Column layout: flag + default occupy cols 0-19, description starts at col 20.
  # Padding per flag (visible chars counted without ANSI codes):
  #   -h / -x / -p          →  4 chars  → 16 spaces
  #   -m / -f / -c [FILTER] → 13 chars  →  7 spaces
  #   -b / -v                → 15 chars  →  5 spaces
  #   -s [true]              → 11 chars  →  9 spaces
  #   -l [false]             → 12 chars  →  8 spaces
  #   -d [YYYY-MM-DD]        → 18 chars  →  2 spaces
  # Continuation / option lines always indent 20 spaces.

  echo -e "$INFO  UTILITY$CLEAR"
  echo ""
  echo -e "  $INFO-h$CLEAR                Print this help message and exit"
  echo ""
  echo -e "  $INFO-c$CLEAR $WARN[FILTER]$CLEAR       List local builds with download / unzip status"
  echo -e "                    Filter: all | snapshot | qat | release"
  echo -e "                    Defaults to the current -b value"
  echo ""
  echo -e "  $INFO-x$CLEAR                Gracefully stop a running Pentaho Server"
  echo -e "                    Resolves the build path from -b / -f / -v / -d"
  echo ""

  echo -e "$INFO  SETUP$CLEAR"
  echo ""
  echo -e "  $INFO-m$CLEAR $WARN[server]$CLEAR       Mode — product to set up"
  echo -e "                    server  Pentaho Server (default)"
  echo -e "                    pdi     Pentaho Data Integration / Spoon"
  echo ""
  echo -e "  $INFO-b$CLEAR $WARN[snapshot]$CLEAR     Build type"
  echo -e "                    snapshot  Latest continuous build (default)"
  echo -e "                    qat       QA-tested build"
  echo -e "                    release   Official release"
  echo ""
  echo -e "  $INFO-f$CLEAR $WARN[master]$CLEAR       Feature branch  (snapshot builds only)"
  echo -e "                    master           Main branch (default)"
  echo -e "                    WCAG-branch      WCAG accessibility branch"
  echo -e "                    schedule-plugin  Scheduler plugin branch"
  echo ""
  echo -e "  $INFO-v$CLEAR $WARN[$version]$CLEAR     Version string"
  echo ""
  echo -e "  $INFO-p$CLEAR                Comma-separated server plugins  ($INFO-m server$CLEAR only)"
  echo -e "                    paz-plugin-ee  /  pdd-plugin-ee  /  pir-plugin-ee"
  echo ""

  echo -e "$INFO  DOWNLOAD$CLEAR"
  echo ""
  echo -e "  $INFO-s$CLEAR $WARN[true]$CLEAR         SSL certificate validation"
  echo -e "                    true   Validate certificates (default)"
  echo -e "                    false  Skip  (use for VPN / self-signed cert issues)"
  echo ""
  echo -e "  $INFO-d$CLEAR $WARN[$date_today]$CLEAR  Date of an already-downloaded build"
  echo -e "                    Format: YYYY-MM-DD  (other GNU date formats may work)"
  echo -e "                    Artifacts must already exist locally"
  echo ""

  echo -e "$INFO  LAUNCH$CLEAR"
  echo ""
  echo -e "  $INFO-l$CLEAR $WARN[false]$CLEAR        Launch the product after setup completes"
  echo -e "                    Server  start-pentaho-debug.sh + tail catalina.out"
  echo -e "                    PDI     spoon.sh"
  echo -e "                    Output is colour-coded  (Ctrl+C to stop)"
  echo ""

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

stop_pentaho_server() {
  local server_dir
  server_dir="$(get_server_unzip_directory)/pentaho-server"

  if [ ! -d "$server_dir" ]; then
    echo -e "$ERROR- Server directory not found: '$server_dir'$CLEAR"
    echo -e "  - Make sure -b, -f, -v, and -d flags point to an installed build."
    return 1
  fi

  local pid_file="$server_dir/tomcat/bin/catalina.pid"

  if [ -f "$pid_file" ]; then
    echo -e "$INFO- Stopping Pentaho Server (PID: $(cat "$pid_file"))...$CLEAR"
    "$server_dir/stop-pentaho.sh"
    echo -e "$SUCCESS- Server stopped.$CLEAR"
  else
    echo -e "$WARN- PID file not found at '$pid_file'. Falling back to pkill...$CLEAR"
    if pkill -f tomcat; then
      echo -e "$SUCCESS- Tomcat processes killed.$CLEAR"
    else
      echo -e "$ERROR- No running Tomcat process found.$CLEAR"
      return 1
    fi
  fi
}

