# Roadmap

Features are grouped by theme and ordered by priority within each group.  
Items marked **[TODO]** were already identified in the source code comments.

---

## P1 — Should do (high impact, low-hanging fruit)

### ~~1. Partial download cleanup on interrupt~~ ✅

**Implemented.** `_cleanup_on_interrupt` trap set in `main.sh` fires on `INT`/`TERM`. `download_artifact` sets `_current_download` to the full ZIP path before calling `wget` and clears it on clean exit. The trap deletes the partial file if present.

---

### ~~2. Reliable plugin detection~~ ✅

**Implemented.** `unzip_plugin` now checks for `system/<plugin-name>/` instead of the shared `system/` parent directory, removing the `skip_check=true` workaround.

---

### ~~3. List local builds~~ ✅

**Implemented.** `-c` flag calls `list_builds` (`utils/list.sh`). Walks `$root_directory/builds/` and prints per-build, per-date download/unzip status with colour-coded ✓/✗ indicators.

---

### ~~4. Graceful server stop~~ ✅

**Implemented.** `-x` flag calls `stop_pentaho_server` (`utils/main.sh`). Uses `tomcat/bin/catalina.pid` + `stop-pentaho.sh` for a clean shutdown; falls back to `pkill -f tomcat` with a warning if the PID file is missing.

---

## P2 — Could do (meaningful quality-of-life improvements)

### 5. Named profiles

**Problem:** Frequently used flag combinations (e.g. "snapshot server with all three plugins") must be retyped every time. There is no shorthand.

**Plan:**
- Allow defining profiles in the `.env` file, e.g.:
  ```dotenv
  PROFILE_FULL="server -b snapshot -p paz-plugin-ee,pdd-plugin-ee,pir-plugin-ee -l true"
  PROFILE_PDI="pdi -b snapshot -f master"
  ```
- Add a `-r PROFILE_NAME` flag that expands the saved flags before the rest of the argument parsing runs.
- Document available profiles when `-h` is called.

---

### 6. Server ready notification

**Problem:** When `-l true` is used, there is no indication of when the server has finished starting up. The user has to watch the log output and infer it from Tomcat messages.

**Plan:**
- After launching the server, poll `http://localhost:8080/pentaho/Login` (or a configurable URL) in a background loop.
- Once the server responds with HTTP 200, print a prominent success message (and optionally trigger a macOS notification via `osascript` / `terminal-notifier`).
- Add a configurable timeout (e.g. 5 minutes) after which a warning is printed.

---

### 7. Build freshness check / update prompt

**Problem:** When using a past build (`-d DATE`), there is no way to know if a newer build has been published without running the script without `-d` first.

**Plan:**
- After resolving `latest_date` from the JSON manifest, compare it against `date_setup`.
- If the local build is older, print an info message: `"A newer build is available (YYYY-MM-DD). Use without -d to download it."`
- This should also work in the catalog (`-c`) view to flag stale entries.

---

### 8. Dry-run mode

**Problem:** There is no safe way to preview what the script will do before committing to a potentially long download.

**Plan:**
- Add a `-n` flag for dry run.
- When set, skip all `wget`, `unzip`, `mkdir`, `rm`, and launch calls.
- Print each action that *would* be taken, prefixed with `[dry-run]`.
- Still resolve the JSON manifest so the resolved URLs and dates are shown.

---

### 9. Disk cleanup command

**Problem:** Over time, the `root_directory` accumulates many versioned build directories. There is no way to prune them from the script.

**Plan:**
- Add a `-C` (`--clean`) flag, with an optional argument for how many builds to keep per `build/feature/version` combination (default: keep last 3).
- Dry-run should also apply here: print which directories would be deleted before deleting them.
- Add a `--clean-all` variant that removes everything under `root_directory` for a full reset.

---

## P3 — Nice to have (larger scope or lower urgency)

### 10. Interactive mode (picker)

**Problem:** New users or users who don't remember all available values for `-b`, `-f`, `-v` etc. have to consult the help text.

**Plan:**
- If `fzf` is installed and the script is run with no flags (or with `-i`), present interactive menus for each option using `fzf`.
- Menus for build type, feature branch, version, and plugins.
- Available feature branches and versions can be derived from the JSON manifest.
- Degrade gracefully if `fzf` is not available (fall back to current behaviour).

---

### 11. Configurable server port

**Problem:** The server always starts on its default port. Running two builds in parallel or using a non-default port requires manual file edits.

**Plan:**
- Add a `--port PORT` option.
- Before launching, patch `$server_dir/pentaho-server/tomcat/conf/server.xml` to replace the HTTP connector port with the specified value (using `sed`).
- Also update `start-pentaho.sh`'s `CATALINA_OPTS` if needed.

---

### 12. Log management

**Problem:** Tomcat log files grow unboundedly across sessions. Starting a new debug session means scrolling past logs from previous runs.

**Plan:**
- Before launching the server, optionally truncate or archive `catalina.out` and the other logs under `tomcat/logs/`.
- Add a `--clear-logs` flag (default: off) and a `--archive-logs` variant that renames the existing log with a timestamp before starting.

---

### 13. Multi-instance support

**Problem:** Only one server can be managed at a time; there is no concept of named instances.

**Plan:**
- Allow running the script multiple times pointing to different build directories without them conflicting.
- This is mostly blocked by the port configuration feature (item 11) — each instance needs its own port.
- Consider tracking active instances in a lock file under `.temp/` so the `--stop` flag can target a specific one.

