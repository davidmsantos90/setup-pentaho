# Setup Pentaho Script

## Script alias

To run the script anywhere, you can create an alias (e.g. in your `.zprofile`) with:
```
# replace <path-to-git-repo> with correct path
alias setup-pentaho="<path-to-git-repo>/setup-pentaho/main.sh"
```

## Using the script

### Help
```
setup-pentaho -h
```

### Setup pentaho-server
```
setup-pentaho -m server
```

### Setup pdi
```
setup-pentaho -m pdi
```

