#!/bin/bash

# Course materials auto-update script - SAFE VERSION
# Pulls latest materials while preserving student work
# Includes comprehensive error checking and rollback capability

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

# Check if we have enough disk space (at least 100MB)
check_disk_space() {
    local available=$(df /tmp | tail -1 | awk '{print $4}')
    if [ "$available" -lt 102400 ]; then  # 100MB in KB
        log_message "ERROR: Insufficient disk space in /tmp"
        return 1
    fi
    return 0
}

# Safely backup student work with verification
backup_student_work() {
    local modified_files="$1"
    local untracked_files="$2"
    
    # Back up student-modified files
    if [ -n "$modified_files" ]; then
        log_message "Backing up student-modified files"
        echo "$modified_files" | while read file; do
            if [ -f "$file" ]; then
                mkdir -p "$BACKUP_DIR/modified/$(dirname "$file")"
                if ! cp "$file" "$BACKUP_DIR/modified/$file"; then
                    log_message "ERROR: Failed to backup $file"
                    return 1
                fi
            fi
        done
        # Verify backup worked
        if [ $? -ne 0 ]; then
            log_message "ERROR: Modified files backup failed"
            return 1
        fi
    fi
    
    # Back up student-created files
    if [ -n "$untracked_files" ]; then
        log_message "Backing up student-created files"
        echo "$untracked_files" | while read file; do
            if [ -f "$file" ]; then
                mkdir -p "$BACKUP_DIR/untracked/$(dirname "$file")"
                if ! cp "$file" "$BACKUP_DIR/untracked/$file"; then
                    log_message "ERROR: Failed to backup $file"
                    return 1
                fi
            fi
        done
        # Verify backup worked
        if [ $? -ne 0 ]; then
            log_message "ERROR: Untracked files backup failed"
            return 1
        fi
    fi
    
    return 0
}

# Restore student work with verification
restore_student_work() {
    local modified_files="$1"
    local untracked_files="$2"
    
    # Restore student-modified files (overwrite whatever git pulled)
    if [ -n "$modified_files" ]; then
        log_message "Restoring student-modified files"
        echo "$modified_files" | while read file; do
            if [ -f "$BACKUP_DIR/modified/$file" ]; then
                if ! cp "$BACKUP_DIR/modified/$file" "$file"; then
                    log_message "ERROR: Failed to restore $file"
                    return 1
                fi
            fi
        done
    fi
    
    # Restore student-created files
    if [ -n "$untracked_files" ]; then
        log_message "Restoring student-created files"
        echo "$untracked_files" | while read file; do
            if [ -f "$BACKUP_DIR/untracked/$file" ]; then
                if ! cp "$BACKUP_DIR/untracked/$file" "$file"; then
                    log_message "ERROR: Failed to restore $file"
                    return 1
                fi
            fi
        done
    fi
    
    return 0
}

main() {
    log_message "Starting course update"
    
    # Check date cutoff
    if ! should_update_content; then
        log_message "Content frozen after $CUTOFF_DATE - only fixing permissions"
        if [ -d "$REPO_DIR" ]; then
            cd "$REPO_DIR"
            chown -R jupyter:jupyter "$REPO_DIR"
            chmod -R +x "$REPO_DIR"
        fi
        exit 0
    fi
    
    # Check network
    if ! wait_for_network; then
        log_message "No network - skipping update"
        exit 0
    fi
    
    # Check disk space
    if ! check_disk_space; then
        log_message "Insufficient disk space - skipping update"
        exit 0
    fi
    
    # Check repo exists
    if [ ! -d "$REPO_DIR" ]; then
        log_message "ERROR: $REPO_DIR does not exist"
        exit 1
    fi
    
    cd "$REPO_DIR"
    
    # Configure git to trust this directory when running as root
    git config --global --add safe.directory "$REPO_DIR" 2>/dev/null
    
    # Create backup directory for timestamps and student files
    rm -rf "$BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Store original file timestamps for ALL files before any operations
    find . -type f -name "*.ipynb" -o -name "*.py" -o -name "*.md" | while read file; do
        if [ -f "$file" ]; then
            stat -c "%Y %n" "$file" >> "$BACKUP_DIR/timestamps"
        fi
    done 2>/dev/null
    
    # Identify student work
    local modified_files=$(git diff-index --name-only HEAD --)
    local untracked_files=$(git ls-files --others --exclude-standard)
    
    # Only proceed if we successfully backup student work
    if [ -n "$modified_files" ] || [ -n "$untracked_files" ]; then
        if ! backup_student_work "$modified_files" "$untracked_files"; then
            log_message "ABORTING: Could not safely backup student work"
            exit 1
        fi
    fi
    
    # Now safe to clean git state (student work is safely backed up)
    if ! git reset --hard HEAD >> "$LOG_FILE" 2>&1; then
        log_message "ERROR: git reset failed"
        exit 1
    fi
    
    if ! git clean -fd >> "$LOG_FILE" 2>&1; then
        log_message "ERROR: git clean failed"
        exit 1
    fi
    
    # Pull updates
    if git pull >> "$LOG_FILE" 2>&1; then
        log_message "Git pull successful"
    else
        log_message "ERROR: Git pull failed even with clean working directory"
        git status >> "$LOG_FILE" 2>&1
        # Continue to restore student work even if pull failed
    fi
    
    # Restore student work
    if [ -n "$modified_files" ] || [ -n "$untracked_files" ]; then
        if ! restore_student_work "$modified_files" "$untracked_files"; then
            log_message "ERROR: Failed to restore student work"
            log_message "Student work is backed up in $BACKUP_DIR"
            # Don't delete backup directory if restore failed
        else
            # Only clean up if everything succeeded
            rm -rf "$BACKUP_DIR"
        fi
    fi
    
    # Restore ALL original timestamps so script is invisible to students
    if [ -f "$BACKUP_DIR/timestamps" ]; then
        while read timestamp filepath; do
            if [ -f "$filepath" ]; then
                touch -d "@$timestamp" "$filepath" 2>/dev/null
            fi
        done < "$BACKUP_DIR/timestamps"
    fi
    
    # Fix permissions - make sure jupyter user owns everything including .git
    chown -R jupyter:jupyter "$REPO_DIR"
    chmod -R +x "$REPO_DIR"
    
    log_message "Update completed"
}

main "$@"