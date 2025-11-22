# Webp2PngX
developed by X Project

Webp2PngX is an advanced, safe, and fast Bash tool for converting `.webp` images into `.png` (or any format supported by `dwebp`).  
It scans a directory, converts every WebP it finds, preserves folder structure, and can safely remove, delete, or archive originals.

This repository contains a single script:
- `webp2pngx.sh`

---

## Features

- Batch conversion of `.webp` images to `.png`
- Recursive scanning through subfolders (optional)
- Preserves folder structure into output directory
- Output naming with optional suffix
- Safe handling of originals:
  - Move to Trash (default, safer)
  - Permanently delete
  - Move to backup directory (keeps structure)
  - Keep originals unchanged
- Overwrite protection (skip existing outputs unless forced)
- Dry-run mode (preview changes without touching files)
- Parallel processing for high speed on large libraries
- Optional logging to a file
- Robust error handling (continues even if some files fail)

---

## Requirements

Mandatory:
- `dwebp` from `libwebp-tools`
- `find`
- `realpath` (from `coreutils`)

Optional but recommended:
- `trash-put` from `trash-cli` for moving originals to Trash.  
  If it is not available, the script automatically falls back to permanent delete unless `--keep` is used.

---

## Installation

### Ubuntu / Debian
```bash
sudo apt update
sudo apt install libwebp-tools trash-cli coreutils findutils
```

### Arch / Manjaro
```bash
sudo pacman -S libwebp trash-cli coreutils findutils
```

### macOS (Homebrew)
```bash
brew install webp trash-cli coreutils findutils
```

Note: On macOS, `realpath` may come from `coreutils` as `grealpath`.  
If needed, create an alias:
```bash
alias realpath=grealpath
```

---

## Usage

Make the script executable:
```bash
chmod +x webp2pngx.sh
```

Run:
```bash
./webp2pngx.sh [options]
```

---

## Options

| Option | Description | Default |
|-------|-------------|---------|
| `-d, --dir DIR` | Input directory to scan | `~/Pictures` |
| `-o, --outdir DIR` | Output directory | same as input |
| `-s, --suffix TXT` | Suffix appended before extension | empty |
| `-f, --format FMT` | Output extension (`png`, `tiff`, etc.) | `png` |
| `-n, --non-recursive` | Scan only top-level dir | recursive ON |
| `-k, --keep` | Keep original `.webp` files | OFF |
| `--trash` | Move originals to Trash | ON |
| `--delete` | Permanently delete originals | OFF |
| `--backup DIR` | Move originals to backup dir, preserving structure | OFF |
| `--force` | Overwrite existing outputs | OFF |
| `--dry-run` | Preview actions, no changes | OFF |
| `-j, --jobs N` | Parallel jobs for faster conversion | `1` |
| `-l, --log FILE` | Append logs to FILE | none |
| `-h, --help` | Show help | — |

---

## Examples

### 1. Convert all `.webp` in `~/Pictures`
```bash
./webp2pngx.sh
```

### 2. Convert a specific folder
```bash
./webp2pngx.sh -d /data/images
```

### 3. Convert into a separate output directory
```bash
./webp2pngx.sh -d ./pics -o ./pngs
```

### 4. Add a suffix to output names
```bash
./webp2pngx.sh -d ./pics -s _converted
```
`image.webp` becomes `image_converted.png`

### 5. Keep originals
```bash
./webp2pngx.sh -d ./pics --keep
```

### 6. Backup originals instead of deleting
```bash
./webp2pngx.sh -d ./pics --backup ./webp_backup
```
Originals are moved into `./webp_backup` with identical subfolder structure.

### 7. Permanently delete originals
```bash
./webp2pngx.sh -d ./pics --delete
```

### 8. Convert faster using 4 parallel jobs
```bash
./webp2pngx.sh -d ./pics --jobs 4
```

### 9. Preview actions without changing anything
```bash
./webp2pngx.sh -d ./pics --dry-run
```

### 10. Overwrite existing outputs
```bash
./webp2pngx.sh -d ./pics --force
```

### 11. Save logs to a file
```bash
./webp2pngx.sh -d ./pics --log /tmp/webp2pngx.log
```

---

## How it works

### Scanning
The script uses `find` to locate `.webp` files:
- Recursive by default
- Non-recursive if `--non-recursive` is set

### Output paths
For input:
```
/input/path/subdir/image.webp
```

Output will be:
```
/output/path/subdir/image{SUFFIX}.png
```

If `--outdir` is not provided, output is written next to the original file in the same folder.

### Overwrite protection
If output already exists and `--force` is not used, the file is skipped:
```
SKIP (exists): image.webp -> image.png
```

### Original handling
After successful conversion:

- `--trash` (default)  
  Moves original to Trash (requires `trash-put`)
- `--delete`  
  Permanently deletes original
- `--backup DIR`  
  Moves original into backup directory, preserving folder structure
- `--keep`  
  Leaves original untouched

If conversion fails, the original is never touched.

---

## Exit behavior

Per-file conversion:
- Success returns `0`
- Failure returns `2`

The main script logs failures and continues processing other files.

---

## Troubleshooting

### Dependency missing: dwebp
Install:
```bash
sudo apt install libwebp-tools
```

### trash-put not found
Install:
```bash
sudo apt install trash-cli
```

Or choose a different removal mode:
```bash
./webp2pngx.sh --keep
./webp2pngx.sh --delete
./webp2pngx.sh --backup ./backup_dir
```

### Some files fail to convert
Possible causes:
- Corrupted WebP file
- No write permission
- Disk is full

Debug with dry-run and logs:
```bash
./webp2pngx.sh -d ./pics --dry-run --log ./debug.log
```

---

## Safety notes

- Script does not change your terminal working directory after it ends.
- Defaults are conservative:
  - No overwrite unless forced
  - Uses Trash instead of deleting
  - Single-threaded unless you enable jobs
- Always test important libraries with `--dry-run` first.

---

## License and credits

Webp2PngX is developed by X Project.  
You may use, modify, and distribute it freely in your own environments.

If you extend the tool, keeping the credit line is appreciated:
"developed by X Project"
