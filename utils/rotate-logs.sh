#!/bin/bash

# =========================
# Log Rotation Script
# =========================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# --- CONFIG ---
readonly LOG_DIR="${LOG_DIR:-/var/log/iiot}"
readonly RETENTION_DAYS="${RETENTION_DAYS:-7}"
readonly LOG_EXTENSION="${LOG_EXTENSION:-log}"

# --- FUNCTIONS ---
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1"
}

validate_config() {
    if [[ ! -d "$LOG_DIR" ]]; then
        log_message "ERROR: Log directory does not exist: $LOG_DIR"
        exit 1
    fi
    
    if [[ ! $RETENTION_DAYS =~ ^[0-9]+$ ]] || [[ $RETENTION_DAYS -lt 1 ]]; then
        log_message "ERROR: RETENTION_DAYS must be a positive integer"
        exit 1
    fi
}

compress_logs() {
    log_message "Compressing .$LOG_EXTENSION files older than 1 day..."
    local count=$(find "$LOG_DIR" -type f -name "*.$LOG_EXTENSION" -mtime +1 | wc -l)
    
    if [[ $count -gt 0 ]]; then
        find "$LOG_DIR" -type f -name "*.$LOG_EXTENSION" -mtime +1 -exec gzip -f {} \;
        log_message "Compressed $count log files"
    else
        log_message "No log files to compress"
    fi
}

cleanup_old_logs() {
    log_message "Removing .$LOG_EXTENSION.gz files older than $RETENTION_DAYS days..."
    local count=$(find "$LOG_DIR" -type f -name "*.$LOG_EXTENSION.gz" -mtime +$RETENTION_DAYS | wc -l)
    
    if [[ $count -gt 0 ]]; then
        find "$LOG_DIR" -type f -name "*.$LOG_EXTENSION.gz" -mtime +$RETENTION_DAYS -exec rm -f {} \;
        log_message "Removed $count old compressed log files"
    else
        log_message "No old compressed log files to remove"
    fi
}

# --- MAIN ---
main() {
    log_message "Starting log rotation in $LOG_DIR (retention: $RETENTION_DAYS days)..."
    
    validate_config
    compress_logs
    cleanup_old_logs
    
    log_message "Log rotation completed successfully"
}

# Execute main function
main "$@"
