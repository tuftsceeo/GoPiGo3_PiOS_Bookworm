#!/bin/bash

# Course materials auto-update script
# Pulls latest materials while preserving student work

LOG_FILE="/var/log/course-update.log"
REPO_DIR="/home/jupyter/EDL"
BACKUP_DIR="/tmp/student_work_backup"
CUTOFF_DATE="2025-08-01"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

should_update_content() {
    local current_date=$(date +%Y-%m-%d)
    if [[ "$current_date" > "$CUTOFF_DATE" ]]; then
        return 1  # Don't update
    else
        return 0  # Do update
    fi
}

wait_for_network() {
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            return 0
        fi
        sleep 5
        attempt=$((attempt + 1))
    done
    return 1
}

main() {
    log_message "Starting course update"
    
    # Check date cutoff
    if ! should_update_content; then
        log_message "Content frozen after $CUTOFF_DATE - only fixing permissions"
        if [ -d "$REPO_DIR" ]; then
            cd "$REPO_DIR"
            chown -R jupyter "$REPO_DIR"
            chmod -R +x "$REPO_DIR"
        fi
        exit 0
    fi
    
    # Check network
    if ! wait_for_network; then
        log_message "No network - skipping update"
        exit 0
    fi
    
    # Check repo exists
    if [ ! -d "$REPO_DIR" ]; then
        log_message "ERROR: $REPO_DIR does not exist"
        exit 1
    fi
    
    cd "$REPO_DIR"
    
    # Check for student modifications
    local modified_files=$(git diff-index --name-only HEAD --)
    
    # Backup student work if needed
    if [ -n "$modified_files" ]; then
        log_message "Backing up student work"
        rm -rf "$BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        
        echo "$modified_files" | while read file; do
            if [ -f "$file" ]; then
                mkdir -p "$BACKUP_DIR/$(dirname "$file")"
                cp "$file" "$BACKUP_DIR/$file"
            fi
        done
    fi
    
    # Pull updates
    if git pull >> "$LOG_FILE" 2>&1; then
        log_message "Git pull successful"
    else
        log_message "Git pull failed - check log"
    fi
    
    # Restore student work
    if [ -n "$modified_files" ]; then
        echo "$modified_files" | while read file; do
            if [ -f "$BACKUP_DIR/$file" ]; then
                cp "$BACKUP_DIR/$file" "$file"
            fi
        done
        rm -rf "$BACKUP_DIR"
        log_message "Restored student work"
    fi
    
    # Fix permissions
    chown -R jupyter "$REPO_DIR"
    chmod -R +x "$REPO_DIR"
    
    log_message "Update completed"
}

main "$@"