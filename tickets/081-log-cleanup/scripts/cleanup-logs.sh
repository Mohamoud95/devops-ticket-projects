#!/usr/bin/env bash

set -u

readonly RETENTION_DAYS=30
MODE="preview"

usage() {
    printf 'Usage: %s [--delete] <log-directory>\n' "$0" >&2
}

log_message() {
    printf '%s %s\n' "$(date --iso-8601=seconds)" "$1"
}

if [[ $# -eq 1 ]]; then
    LOG_DIR="$1"
elif [[ $# -eq 2 && "$1" == "--delete" ]]; then
    MODE="delete"
    LOG_DIR="$2"
else
    usage
    exit 2
fi

if [[ ! -d "$LOG_DIR" ]]; then
    printf 'Error: directory does not exist: %s\n' "$LOG_DIR" >&2
    exit 1
fi

if [[ -L "$LOG_DIR" ]]; then
    printf 'Error: target directory cannot be a symbolic link\n' >&2
    exit 1
fi

LOG_DIR="$(realpath -- "$LOG_DIR")"

if [[ "$LOG_DIR" == "/" ]]; then
    printf 'Error: refusing to process the root directory\n' >&2
    exit 1
fi

if [[ ! -r "$LOG_DIR" || ! -x "$LOG_DIR" ]]; then
    printf 'Error: directory cannot be safely searched: %s\n' "$LOG_DIR" >&2
    exit 1
fi

if [[ "$MODE" == "delete" && ! -w "$LOG_DIR" ]]; then
    printf 'Error: directory is not writable: %s\n' "$LOG_DIR" >&2
    exit 1
fi

mapfile -d '' -t CANDIDATES < <(
    find "$LOG_DIR" \
        -maxdepth 1 \
        -type f \
        -mtime +"$RETENTION_DAYS" \
        -print0
)

log_message "Mode: $MODE"
log_message "Directory: $LOG_DIR"
log_message "Retention: $RETENTION_DAYS days"
log_message "Candidates found: ${#CANDIDATES[@]}"

if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
    log_message "No files matched the cleanup policy."
    exit 0
fi

FAILURES=0

for FILE in "${CANDIDATES[@]}"; do
    if [[ "$MODE" == "preview" ]]; then
        log_message "[PREVIEW] Would delete: $FILE"
    else
        if rm -- "$FILE"; then
            log_message "[DELETED] $FILE"
        else
            printf 'Error: failed to delete: %s\n' "$FILE" >&2
            FAILURES=$((FAILURES + 1))
        fi
    fi
done

if [[ $FAILURES -gt 0 ]]; then
    printf 'Error: %d file deletion(s) failed\n' "$FAILURES" >&2
    exit 3
fi

log_message "Cleanup completed successfully."
exit 0
