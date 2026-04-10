# CLI Reference

All flags are optional. Defaults are shown in brackets.

```
setup-pentaho [-h] [-c] [-x] [-m mode] [-b build] [-f feature] [-v version]
              [-d date] [-p plugins] [-s secure] [-l launch]
```

---

## Flags

### `-h` — Help

Print the inline help message and exit.

```zsh
setup-pentaho -h
```

---

### `-c [FILTER]` — Catalog (list local builds)

List builds on disk. Each date entry shows a tree of all known artifacts (server, plugins, PDI) with individual `✓ downloaded` / `✓ unzipped` status.

The optional `FILTER` value controls which build types are shown:

| Value | Description |
|---|---|
| *(omitted)* | Filter by the current `-b` value (default) |
| `all` | Show every build type |
| `snapshot` | Show snapshot builds only |
| `qat` | Show QAT builds only |
| `release` | Show release builds only |

```zsh
# List builds matching the current -b flag (default: snapshot)
setup-pentaho -c

# List all build types
setup-pentaho -c all

# List only QAT builds
setup-pentaho -c qat

# List snapshots explicitly
setup-pentaho -c snapshot
```

Example output:
```
[snapshot] master / 11.1.0.0
├─ 2026-04-10
│   ├─ pentaho-server-ee   ✓ downloaded   ✓ unzipped
│   └─ pdi-ee-client       ✗ downloaded   ✗ unzipped
└─ 2026-04-09
    └─ pentaho-server-ee   ✓ downloaded   ✗ unzipped
```

---

### `-x` — Stop server

Gracefully stop a running Pentaho Server.

Locates `tomcat/bin/catalina.pid` inside the resolved build directory and calls `stop-pentaho.sh`. If the PID file is not found, falls back to `pkill -f tomcat` with a warning.

Use `-b`, `-f`, `-v`, and `-d` to identify which build's server to stop (defaults apply if not specified).

```zsh
# Stop the default build's server
setup-pentaho -x

# Stop a specific build's server
setup-pentaho -x -b snapshot -f master -v 10.3.0.0 -d 2026-04-10
```

---

### `-m` — Mode `[server]`

Which Pentaho product to set up.

| Value | Description |
|---|---|
| `server` | Pentaho Server (default) |
| `pdi` | Pentaho Data Integration (Spoon) |

```zsh
setup-pentaho -m server
setup-pentaho -m pdi
```

---

### `-b` — Build type `[snapshot]`

Selects the maturity level of the artifact to download.

| Value | Description |
|---|---|
| `snapshot` | Latest continuous build (default) |
| `qat` | QA-tested build |
| `release` | Official release |

```zsh
setup-pentaho -b snapshot
setup-pentaho -b qat
setup-pentaho -b release
```

---

### `-f` — Feature branch `[master]`

Download a build from a specific feature branch (applies to `snapshot` builds only).

| Value | Description |
|---|---|
| `master` | Main branch (default) |
| `WCAG-branch` | WCAG accessibility branch |
| `schedule-plugin` | Scheduler plugin branch |

```zsh
setup-pentaho -f master
setup-pentaho -f WCAG-branch
setup-pentaho -f schedule-plugin
```

---

### `-v` — Version `[10.3.0.0]`

The Pentaho version string to target.

```zsh
setup-pentaho -v 10.3.0.0
setup-pentaho -v 10.2.0.0
```

---

### `-d` — Date `[today's latest]`

Set up a specific historical build by date.  
The build artifacts must already be present in the download directory — the script will **not** re-download them.

Format: `YYYY-MM-DD` (other formats accepted by GNU `date` may also work).

```zsh
setup-pentaho -d 2025-06-15
```

---

### `-p` — Plugins `[none]`

Comma-separated list of server-side plugins to download and install.  
Only applies when `-m server` is used.

| Value | Plugin |
|---|---|
| `paz-plugin-ee` | Pentaho Analyzer |
| `pdd-plugin-ee` | Pentaho Dashboard Designer |
| `pir-plugin-ee` | Pentaho Interactive Reporting |

```zsh
# Single plugin
setup-pentaho -m server -p paz-plugin-ee

# Multiple plugins
setup-pentaho -m server -p paz-plugin-ee,pdd-plugin-ee,pir-plugin-ee
```

---

### `-s` — Secure mode `[true]`

Controls SSL certificate validation when downloading artifacts via `wget`.  
Set to `false` if you encounter certificate errors.

```zsh
setup-pentaho -s false
```

---

### `-l` — Launch after setup `[false]`

Automatically launch the product once download and extraction are complete.

- **Server** — runs `start-pentaho-debug.sh` and tails `catalina.out` with colorised log output. Press `Ctrl+C` to stop Tomcat.
- **PDI** — launches `spoon.sh` with colorised log output.

```zsh
setup-pentaho -m server -l true
setup-pentaho -m pdi -l true
```

---

## Common examples

```zsh
# Latest snapshot server build with all three plugins, then launch
setup-pentaho -m server -p paz-plugin-ee,pdd-plugin-ee,pir-plugin-ee -l true

# QAT server build for a specific version
setup-pentaho -m server -b qat -v 10.2.0.0

# Snapshot PDI from a feature branch
setup-pentaho -m pdi -f schedule-plugin

# Set up an already-downloaded build from a past date
setup-pentaho -m server -d 2025-06-15

# Download without certificate validation (VPN / self-signed cert)
setup-pentaho -m server -s false
```

