#!/bin/bash

list_builds() {
  local filter="${1:-}"
  local builds_root="$root_directory/builds"

  if [ ! -d "$builds_root" ]; then
    echo -e "$WARN- No builds directory found at '$builds_root'$CLEAR"
    return 0
  fi

  local found=false

  for build_dir in "$builds_root"/*/; do
    [ -d "$build_dir" ] || continue
    local build_name
    build_name=$(basename "$build_dir")
    [ "$build_name" = ".temp" ] && continue

    # apply build type filter (empty filter means use default which is set by caller)
    if [ -n "$filter" ] && [ "$filter" != "all" ] && [ "$build_name" != "$filter" ]; then
      continue
    fi

    for feature_dir in "$build_dir"*/; do
      [ -d "$feature_dir" ] || continue
      local feature_name
      feature_name=$(basename "$feature_dir")

      for version_dir in "$feature_dir"*/; do
        [ -d "$version_dir" ] || continue
        local version_name
        version_name=$(basename "$version_dir")

        # ── first pass: collect date dirs that have at least one known artifact ──
        local valid_dates=()
        for date_dir_candidate in "$version_dir"*/; do
          [ -d "$date_dir_candidate" ] || continue
          local dn
          dn=$(basename "$date_dir_candidate")
          [[ "$dn" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || continue

          local ud="$root_directory/$build_name/$feature_name/$version_name/$dn"
          if [ -f "${date_dir_candidate}${SERVER}.zip" ] || [ -d "$ud/$SERVER" ] || \
             [ -f "${date_dir_candidate}${PDI}.zip" ]    || [ -d "$ud/$PDI" ]; then
            valid_dates+=("$dn")
          fi
        done

        [ "${#valid_dates[@]}" -eq 0 ] && continue

        found=true
        echo -e "\n$INFO[$build_name] $feature_name / $version_name$CLEAR"

        # ── compute max artifact name length across ALL dates in this group ──
        # so the status columns stay aligned even when different dates have
        # different artifact subsets (e.g. one date has only server, another only pdi)
        local max_artifact_len=0
        for dn in "${valid_dates[@]}"; do
          local _dd="$version_dir$dn/"
          local _ud="$root_directory/$build_name/$feature_name/$version_name/$dn"
          if [ -f "${_dd}${SERVER}.zip" ] || [ -d "$_ud/$SERVER" ]; then
            [ "${#SERVER}" -gt "$max_artifact_len" ] && max_artifact_len="${#SERVER}"
          fi
          if [ -f "${_dd}${PDI}.zip" ] || [ -d "$_ud/$PDI" ]; then
            [ "${#PDI}" -gt "$max_artifact_len" ] && max_artifact_len="${#PDI}"
          fi
        done

        local total_dates="${#valid_dates[@]}"
        local date_idx=0

        for date_name in "${valid_dates[@]}"; do
          date_idx=$((date_idx + 1))
          local date_dir="$version_dir$date_name/"
          local unzip_dir="$root_directory/$build_name/$feature_name/$version_name/$date_name"

          # choose connector and the prefix to use for child artifact lines
          local date_connector="├─"
          local child_prefix="│   "
          if [ "$date_idx" -eq "$total_dates" ]; then
            date_connector="└─"
            child_prefix="    "
          fi

          echo -e "$date_connector $date_name"

          # ── artifacts: server then pdi (no plugins) ──
          local artifacts=()
          if [ -f "${date_dir}${SERVER}.zip" ] || [ -d "$unzip_dir/$SERVER" ]; then
            artifacts+=("$SERVER")
          fi
          if [ -f "${date_dir}${PDI}.zip" ] || [ -d "$unzip_dir/$PDI" ]; then
            artifacts+=("$PDI")
          fi

          local total_artifacts="${#artifacts[@]}"
          local art_idx=0

          for artifact in "${artifacts[@]}"; do
            art_idx=$((art_idx + 1))
            local art_connector="├─"
            [ "$art_idx" -eq "$total_artifacts" ] && art_connector="└─"

            local padded_artifact
            printf -v padded_artifact "%-${max_artifact_len}s" "$artifact"

            # downloaded: zip file present in the download directory
            local dl_status
            if [ -f "${date_dir}${artifact}.zip" ]; then
              dl_status="${SUCCESS}✓ downloaded${CLEAR}"
            else
              dl_status="${ERROR}✗ downloaded${CLEAR}"
            fi

            # unzipped: extracted directory exists in the correct location
            local unzip_status
            if [ "$artifact" = "$SERVER" ]; then
              if [ -d "$unzip_dir/$SERVER" ]; then
                unzip_status="${SUCCESS}✓ unzipped${CLEAR}"
              else
                unzip_status="${ERROR}✗ unzipped${CLEAR}"
              fi
            else
              if [ -d "$unzip_dir/$PDI" ]; then
                unzip_status="${SUCCESS}✓ unzipped${CLEAR}"
              else
                unzip_status="${ERROR}✗ unzipped${CLEAR}"
              fi
            fi

            echo -e "${child_prefix}${art_connector} $padded_artifact   $dl_status   $unzip_status"
          done
        done

        echo ""
      done
    done
  done

  if [ "$found" = false ]; then
    if [ -n "$filter" ] && [ "$filter" != "all" ]; then
      echo -e "$WARN- No '$filter' builds found under '$builds_root'$CLEAR"
    else
      echo -e "$WARN- No builds found under '$builds_root'$CLEAR"
    fi
  fi
}
