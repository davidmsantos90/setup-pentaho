# Prerequisites

The script requires three external tools to be installed before use.

---

## 1. `date` (GNU coreutils)

macOS ships with the BSD version of `date`, which is not compatible.  
The GNU version from **coreutils** must be available on your `$PATH`.

```zsh
brew install coreutils
```

Add the GNU bin directory to your shell profile (e.g. `~/.zprofile`):

```zsh
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
```

---

## 2. `jq`

Used to parse the build repository's JSON manifest.

```zsh
brew install jq
```

---

## 3. `wget`

Used to download artifact ZIP files from the build repository.

```zsh
brew install wget
```

---

## Verify

Run the script once without any flags; it will check for all dependencies and print a clear error if anything is missing:

```zsh
setup-pentaho
```

