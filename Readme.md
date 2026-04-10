# Setup Pentaho Script

A Bash script that automates downloading, extracting, and optionally launching **Pentaho Server** or **PDI (Spoon)** from an internal build repository.

The script resolves the correct artifact URLs from a JSON file mapping hosted by the repository, downloads the ZIPs with `wget`, unzips them into a versioned directory tree, and can launch the product with colourised log output when done.

---

## Documentation

| Document | Description |
|---|---|
| [Prerequisites](docs/prerequisites.md) | Required tools and how to install them |
| [Configuration](docs/configuration.md) | `.env` file variables and directory layout |
| [CLI Reference](docs/cli-reference.md) | All flags, accepted values, and examples |
| [Roadmap](docs/roadmap.md) | Planned and proposed features |

---

## Quick start

### 1. Install dependencies

See [docs/prerequisites.md](docs/prerequisites.md) — you need GNU `date` (coreutils), `jq`, and `wget`.

### 2. Create a `.env` file

```dotenv
# .env  (place next to main.sh)
build_repository=https://your-internal-nexus-server
```

See [docs/configuration.md](docs/configuration.md) for all options.

### 3. Create a shell alias

Add the following to your `~/.zprofile` (replace `<path-to-git-repo>` with the actual path):

```zsh
alias setup-pentaho="<path-to-git-repo>/setup-pentaho/main.sh"
```

Then reload your profile:

```zsh
source ~/.zprofile
```

---

## Basic usage

```zsh
# Show help
setup-pentaho -h

# Set up the latest snapshot Pentaho Server
setup-pentaho -m server

# Set up the latest snapshot PDI (Spoon)
setup-pentaho -m pdi

# Server + plugins, then launch immediately
setup-pentaho -m server -p paz-plugin-ee,pdd-plugin-ee,pir-plugin-ee -l true

# QAT build of a specific version
setup-pentaho -m server -b qat -v 10.2.0.0
```

For the full list of flags and options see [docs/cli-reference.md](docs/cli-reference.md).

---

## How it works

The script runs in four sequential phases:

1. **Control** — Resolves the build date from the repository manifest (or skips download/unzip if artifacts already exist for the requested date).
2. **Download** — Creates a versioned directory and downloads the artifact ZIP(s) via `wget`. Already-downloaded files are skipped.
3. **Unzip** — Extracts the ZIP(s) into a separate versioned directory. Already-extracted directories are skipped.
4. **Launch** *(optional, `-l true`)* — Starts the server or Spoon with colourised log output.
