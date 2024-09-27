#!/bin/bash

# TODO
#  - list builds
#  - better error handling
#  - better detection of installed plugins
#  - canceling script before download finished, should delete files

CURRENT_SCRIPT_DIR=$(dirname "$(realpath "$0")")

set -a
  . "$CURRENT_SCRIPT_DIR/utils/main.sh"

  env_path="$CURRENT_SCRIPT_DIR/.env"
  if test -f "$env_path"; then
    # shellcheck source=src/.env
    . "$env_path"
  fi
set +a

### Check script dependencies
check_dependencies || exit 0

### load script arguments ###
  while getopts hs:l:m:p:b:f:v:d: flag
  do
    case "${flag}" in
      h) help=true;;
      s) secure=${OPTARG};;
      l) launch_server=${OPTARG};;
      m) mode=${OPTARG};;
      p) plugins=${OPTARG};;
      b) build=${OPTARG};;
      f) feature=${OPTARG};;
      v) version=${OPTARG};;
      d) date_setup="$(get_date "${OPTARG}")";;
      *) echo -e "$WARN- flag '${flag}' is not supported";;
      esac
  done


### set default values after load ###
  date_today="$(get_date)"
  root_directory="${root_directory:-$(realpath ~/Pentaho)}"

  secure="${secure:-true}"
  help="${help:-false}"
  launch_server="${launch_server:-false}"

  version="${version:-10.3.0.0}"
  mode="${mode:-$MODE_SERVER}"
  build="${build:-$SNAPSHOT}"
  feature="${feature:-$FEAT_MASTER}"
  date_setup="${date_setup:-$date_today}"


if [ "$help" = true ]; then
  print_help && exit 0
fi


###
## 1. Control phase.
#

do_download_phase=true
do_unzip_phase=true

if [ "$date_setup" != "$date_today" ]; then
  print_setup_info "selected build from the past"

  if [ "$(is_build_downloaded)" = true ]; then
    do_download_phase=false
    echo -e "$SUCCESS- build already downloaded $CLEAR"
  else
    echo -e "\n$WARN- artifacts from past build don't exist. setup won't continue$CLEAR"
    exit 0
  fi

  if [ "$(is_build_unzipped)" = true ]; then
    do_unzip_phase=false
    echo -e "$SUCCESS- build already unzipped $CLEAR"
  fi
else
  # get data from build site (if not exit with warning)
  if [ -z "$build_repository" ]; then
    echo -e "\n$WARN### 'build_repository' must be defined in the '.env' file ###"
    exit 0
  fi

  json_build_folder=$(get_json_build_folder)
  if [ -z "$json_build_folder" ]; then
    echo -e "\n$WARN### Repo site didn't return any data. this is most likely a vpn or a certificate issue! ###"
    echo -e "- first check if you are connected to the VPN."
    echo -e "- if yes, try running with '-s false' to run script in unsecure mode$CLEAR"
    exit 0
  fi

  latest_date=$(get_date_from_json "$json_build_folder")
  if [ -z "$latest_date" ] || [ "$latest_date" = null ]; then
    echo -e "\n$ERROR### Failed to parse the build latest date! ###$CLEAR"
    exit 0
  fi

  # update setup_date with latest_date
  if [ "$latest_date" != "$date_today" ]; then
    date_setup=$latest_date
  fi

  print_setup_info
fi


###
## 2. Download phase
#
if [ $do_download_phase = true ]; then
  echo -e "$INFO\n### Download phase started ###\n$CLEAR"

  if [ ! -d "$(get_download_directory)" ]; then
    echo -e "$INFO- Creating download directory: $(get_download_directory)$CLEAR"
    mkdir -p "$(get_download_directory)"
  fi

  if [ "$mode" = "$MODE_SERVER" ]; then
    download_server "$json_build_folder"

    IFS=","
    for plugin in $plugins; do
      download_plugin "$json_build_folder" "$plugin"
    done
  else
    download_pdi "$json_build_folder"
  fi

  echo -e "$SUCCESS\n### Download phase finished ###\n$CLEAR"
fi


###
## 3. Unzip phase
#
if [ $do_unzip_phase = true ]; then
  echo -e "$INFO\n### Unzip phase started ###\n$CLEAR"

  if [ ! -d "$(get_unzip_directory)" ]; then
    echo -e "$INFO- Creating unzip directory: $(get_unzip_directory)$CLEAR"
    mkdir -p "$(get_unzip_directory)"
  fi

  if [ "$mode" = "$MODE_SERVER" ]; then
    unzip_server

    IFS=","
    for plugin in $plugins; do
      unzip_plugin "$plugin"
    done
  else
    unzip_pdi
  fi

  echo -e "$SUCCESS\n### Unzip phase finished ###\n$CLEAR"
fi

###
## 4. launch server
#
if [ "$launch_server" = true ]; then
  if [ "$mode" = "$MODE_SERVER" ]; then
    trap ctrl_c INT

    ctrl_c() {
      pkill -9 -f tomcat
    }

    sleep 1
    "$(get_server_unzip_directory)/pentaho-server/start-pentaho-debug.sh" && tail -f "$(get_server_unzip_directory)/pentaho-server/tomcat/logs/catalina.out" | sed \
      -e 's/\(.*INFO.*\)/\x1B[1;34m\1\x1B[39m/' \
      -e 's/\(.*DEBUG.*\)/\x1B[1;35m\1\x1B[39m/' \
      -e 's/\(.*ERROR.*\)/\x1B[31m\1\x1B[39m/' \
      -e 's/\(.*Exception in.*\)/\x1B[31m\1\x1B[39m/' \
      -e 's/\(.*Caused by:.*\)/\x1B[31m\1\x1B[39m/' \
      -e 's/\(.*WARNING.*\)/\x1B[33m\1\x1B[39m/'
  else
    "$(get_pdi_unzip_directory)/data-integration/spoon.sh" | sed \
      -e 's/\(.*INFO.*\)/\x1B[1;34m\1\x1B[39m/' \
      -e 's/\(.*DEBUG.*\)/\x1B[1;35m\1\x1B[39m/' \
      -e 's/\(.*ERROR.*\)/\x1B[31m\1\x1B[39m/' \
      -e 's/\(.*Exception in.*\)/\x1B[31m\1\x1B[39m/' \
      -e 's/\(.*Caused by:.*\)/\x1B[31m\1\x1B[39m/' \
      -e 's/\(.*WARNING.*\)/\x1B[33m\1\x1B[39m/'
  fi
else
  if [ "$mode" = "$MODE_SERVER" ]; then
    echo -e "$INFO"
    echo -e "To launch and log the server, run:"
    echo -e "  $ cd $(get_server_unzip_directory)/pentaho-server"
    echo -e "  $ ./start-pentaho-debug.sh && tail -f ./tomcat/logs/catalina.out | sed \\"
    echo -e "       -e 's/\(.*INFO.*\)/\\\x1B[1;34m\1\\\x1B[39m/' \\"
    echo -e "       -e 's/\(.*DEBUG.*\)/\\\x1B[1;35m\1\\\x1B[39m/' \\"
    echo -e "       -e 's/\(.*ERROR.*\)/\\\x1B[31m\1\\\x1B[39m/' \\"
    echo -e "       -e 's/\(.*Exception in.*\)/\\\x1B[31m\1\\\x1B[39m/' \\"
    echo -e "       -e 's/\(.*Caused by:.*\)/\\\x1B[31m\1\\\x1B[39m/' \\"
    echo -e "       -e 's/\(.*WARNING.*\)/\\\x1B[33m\1\\\x1B[39m/'\n"
    echo -e "$CLEAR"
  fi
fi
