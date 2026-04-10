# Configuration

## `.env` file

Create a `.env` file in the root of the repository (next to `main.sh`).  
The file is sourced automatically on every run.

### Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `build_repository` | **Yes** | — | Base URL of the internal artifact repository (e.g. `https://my-nexus-server`) |
| `root_directory` | No | `~/Pentaho` | Root directory where builds are downloaded and extracted |

### Example

```dotenv
build_repository=https://my-nexus-server
root_directory=/opt/pentaho
```

> **Note:** Without `build_repository` the script cannot resolve build URLs and will exit with a warning.

---

## Directory structure

The script organises all artifacts under `root_directory` using a predictable layout.

### Downloads

Raw ZIP files are stored at:
```
<root_directory>/builds/<build>/<feature>/<version>/<date>/
```

A temporary directory used during mapping resolution:
```
<root_directory>/builds/.temp/
```

### Extracted artifacts

Unzipped artifacts live at:
```
<root_directory>/<build>/<feature>/<version>/<date>/
```

| Artifact | Extracted path |
|---|---|
| Pentaho Server | `…/<date>/pentaho-server-ee/` |
| PDI (Spoon) | `…/<date>/pdi-ee-client/` |
| Server plugins | `…/<date>/pentaho-server-ee/pentaho-server/pentaho-solutions/system/<plugin-name>/` |

### Concrete example

```
~/Pentaho/
├── builds/
│   └── snapshot/
│       └── master/
│           └── 10.3.0.0/
│               └── 2025-07-09/
│                   ├── pentaho-server-ee.zip
│                   └── paz-plugin-ee.zip
└── snapshot/
    └── master/
        └── 10.3.0.0/
            └── 2025-07-09/
                └── pentaho-server-ee/
                    └── pentaho-server/
                        └── …
```

