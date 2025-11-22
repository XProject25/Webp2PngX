#!/usr/bin/env bash
# ============================================================
#  WEBP -> PNG (advanced)
#  developed by X Project
# ============================================================

set -Eeuo pipefail
IFS=$'\n\t'

# -------------------------------
# Defaults
# -------------------------------
DIR="${HOME}/Pictures"
OUTDIR=""            # if empty -> same as DIR
SUFFIX=""            # e.g. "_converted"
FORMAT="png"         # png default (dwebp picks by extension)
RECURSIVE=1
KEEP_ORIGINAL=0
FORCE=0
DRY_RUN=0
JOBS=1
LOG_FILE=""

# Removal mode: trash | delete | backup
REMOVE_MODE="trash"
BACKUP_DIR=""

# -------------------------------
# Helpers
# -------------------------------
log() {
  local msg="$*"
  if [[ -n "$LOG_FILE" ]]; then
    printf "%s %s\n" "$(date '+%F %T')" "$msg" >> "$LOG_FILE"
  fi
  echo "$msg"
}

die() {
  log "ERROR: $*"
  exit 1
}

need_cmd() {
  command -v "$1" &>/dev/null || die "Missing dependency: $1"
}

usage() {
  cat <<'EOF'
Usage:
  webp2pngx.sh [options]

Options:
  -d, --dir DIR           Input directory (default: ~/Pictures)
  -o, --outdir DIR        Output directory (default: same as input)
  -s, --suffix TXT        Suffix appended before extension (default: "")
  -f, --format FMT        Output format by extension (default: png)
                          (png/tiff supported by dwebp)
  -n, --non-recursive     Do not scan subfolders
  -k, --keep              Keep original .webp files
      --trash             Move originals to Trash (default)
      --delete            Permanently delete originals
      --backup DIR        Move originals to backup DIR (preserves structure)
      --force             Overwrite existing outputs
      --dry-run           Show what would happen, don't change files
  -j, --jobs N            Parallel jobs (default: 1)
  -l, --log FILE          Append logs to FILE
  -h, --help              Show this help

Examples:
  ./webp2pngx.sh
  ./webp2pngx.sh -d /data/images -s _x
  ./webp2pngx.sh -d ./pics -o ./pngs --keep
  ./webp2pngx.sh -d ./pics --backup ./webp_backup --jobs 4
EOF
}

# -------------------------------
# Arg parsing
# -------------------------------
while (( "$#" )); do
  case "$1" in
    -d|--dir)        DIR="$2"; shift 2;;
    -o|--outdir)     OUTDIR="$2"; shift 2;;
    -s|--suffix)     SUFFIX="$2"; shift 2;;
    -f|--format)     FORMAT="$2"; shift 2;;
    -n|--non-recursive) RECURSIVE=0; shift;;
    -k|--keep)       KEEP_ORIGINAL=1; shift;;
    --trash)         REMOVE_MODE="trash"; shift;;
    --delete)        REMOVE_MODE="delete"; shift;;
    --backup)        REMOVE_MODE="backup"; BACKUP_DIR="$2"; shift 2;;
    --force)         FORCE=1; shift;;
    --dry-run)       DRY_RUN=1; shift;;
    -j|--jobs)       JOBS="$2"; shift 2;;
    -l|--log)        LOG_FILE="$2"; shift 2;;
    -h|--help)       usage; exit 0;;
    *) die "Unknown option: $1 (use --help)";;
  esac
done

# -------------------------------
# Validation / deps
# -------------------------------
[[ -d "$DIR" ]] || die "Input dir not found: $DIR"
need_cmd dwebp
need_cmd find
need_cmd realpath

if [[ "$REMOVE_MODE" == "trash" ]]; then
  command -v trash-put &>/dev/null || {
    log "WARN: trash-put not found. Falling back to --delete unless --keep."
    REMOVE_MODE="delete"
  }
fi

if [[ "$REMOVE_MODE" == "backup" ]]; then
  [[ -n "$BACKUP_DIR" ]] || die "--backup requires a directory"
  mkdir -p "$BACKUP_DIR"
fi

if [[ -z "$OUTDIR" ]]; then
  OUTDIR="$DIR"
else
  mkdir -p "$OUTDIR"
fi

# Normalize paths
DIR="$(realpath "$DIR")"
OUTDIR="$(realpath "$OUTDIR")"
[[ "$REMOVE_MODE" != "backup" ]] || BACKUP_DIR="$(realpath "$BACKUP_DIR")"

# -------------------------------
# Core processing
# -------------------------------
process_file() {
  local in="$1"
  local rel="${in#"$DIR"/}"             # relative path inside DIR
  local base="${rel%.webp}"            # remove extension
  local out="$OUTDIR/${base}${SUFFIX}.${FORMAT}"

  local out_dir
  out_dir="$(dirname "$out")"

  if [[ -f "$out" && "$FORCE" -eq 0 ]]; then
    log "SKIP (exists): $in -> $out"
    return 0
  fi

  log "CONVERT: $in -> $out"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi

  mkdir -p "$out_dir"

  if dwebp "$in" -o "$out" &>/dev/null && [[ -f "$out" ]]; then
    if [[ "$KEEP_ORIGINAL" -eq 1 ]]; then
      log "KEEP: $in"
      return 0
    fi

    case "$REMOVE_MODE" in
      trash)
        trash-put "$in"
        log "TRASHED: $in"
        ;;
      delete)
        rm -f -- "$in"
        log "DELETED: $in"
        ;;
      backup)
        local bpath="$BACKUP_DIR/$rel"
        mkdir -p "$(dirname "$bpath")"
        mv -- "$in" "$bpath"
        log "BACKUP: $in -> $bpath"
        ;;
    esac
    return 0
  else
    log "FAIL: $in"
    return 2
  fi
}

export -f process_file log
export DIR OUTDIR SUFFIX FORMAT FORCE DRY_RUN KEEP_ORIGINAL REMOVE_MODE BACKUP_DIR LOG_FILE

# -------------------------------
# Find + Run (optionally parallel)
# -------------------------------
log "Scanning: $DIR (recursive=$RECURSIVE) format=$FORMAT suffix='$SUFFIX' jobs=$JOBS"

if [[ "$RECURSIVE" -eq 1 ]]; then
  FIND_CMD=(find "$DIR" -type f \( -iname "*.webp" \) -print0)
else
  FIND_CMD=(find "$DIR" -maxdepth 1 -type f \( -iname "*.webp" \) -print0)
fi

if [[ "$JOBS" -gt 1 ]]; then
  "${FIND_CMD[@]}" | xargs -0 -n1 -P "$JOBS" bash -c 'process_file "$0"' 
else
  while IFS= read -r -d $'\0' f; do
    process_file "$f" || true
  done < <("${FIND_CMD[@]}")
fi

log "Done."
