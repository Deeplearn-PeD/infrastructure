#!/bin/bash
# EpidBot DuckDB Restore Script
# Restores the EpidBot DuckDB database from a backup file
#
# WARNING: This will replace the current database!
# Make sure to stop EpidBot before restoring.

set -e

# Configuration
DATA_DIR="${DATA_DIR:-/opt/kwar-ai/epidbot/data}"
BACKUP_DIR="${BACKUP_DIR:-/opt/kwar-ai/epidbot/backups}"
DB_FILE="${DB_FILE:-${DATA_DIR}/chat_history.duckdb}"
CONTAINER_NAME="${CONTAINER_NAME:-epidbot}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

list_backups() {
    echo "Available backups in $BACKUP_DIR:"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "  No backup directory found"
        return 1
    fi
    
    local backups=$(find "$BACKUP_DIR" -name "epidbot_duckdb_*.duckdb.gz" -type f -printf '%f\n' 2>/dev/null | sort -r)
    
    if [ -z "$backups" ]; then
        echo "  No backups found"
        return 1
    fi
    
    printf "%-5s %-35s %-12s %s\n" "#" "Filename" "Size" "Date"
    printf "%-5s %-35s %-12s %s\n" "---" "-----------------------------------" "------------" "----"
    
    local i=1
    while IFS= read -r backup; do
        local filepath="$BACKUP_DIR/$backup"
        local size=$(du -h "$filepath" | cut -f1)
        local date=$(stat -c %y "$filepath" 2>/dev/null | cut -d. -f1)
        printf "%-5s %-35s %-12s %s\n" "$i" "$backup" "$size" "$date"
        i=$((i + 1))
    done <<< "$backups"
    
    echo ""
    echo "Usage: $0 restore <backup_file|number>"
}

stop_container() {
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log "Stopping EpidBot container..."
        cd /opt/kwar-ai/epidbot && docker-compose down
        return 0
    fi
    return 1
}

start_container() {
    log "Starting EpidBot container..."
    cd /opt/kwar-ai/epidbot && docker-compose up -d
}

restore_backup() {
    local backup_input="$1"
    local backup_file=""
    
    # Check if input is a number (selection from list)
    if [[ "$backup_input" =~ ^[0-9]+$ ]]; then
        local files=($(find "$BACKUP_DIR" -name "epidbot_duckdb_*.duckdb.gz" -type f -printf '%f\n' 2>/dev/null | sort -r))
        if [ "$backup_input" -lt 1 ] || [ "$backup_input" -gt ${#files[@]} ]; then
            log_error "Invalid selection number"
            return 1
        fi
        backup_file="$BACKUP_DIR/${files[$((backup_input - 1))]}"
    else
        # Check if it's a full path or just filename
        if [[ "$backup_input" = /* ]]; then
            backup_file="$backup_input"
        else
            backup_file="$BACKUP_DIR/$backup_input"
        fi
    fi
    
    # Verify backup file exists
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    log "Restoring from: $backup_file"
    
    # Check if container is running and offer to stop it
    local container_was_running=0
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        container_was_running=1
        log_warn "EpidBot container is running. It must be stopped to restore."
        read -p "Stop container and continue? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Restore cancelled"
            return 1
        fi
        stop_container
    fi
    
    # Create backup of current database if it exists
    if [ -f "$DB_FILE" ]; then
        local pre_restore_backup="${DB_FILE}.pre_restore_$(date +%Y%m%d_%H%M%S)"
        log "Creating pre-restore backup: $pre_restore_backup"
        cp "$DB_FILE" "$pre_restore_backup"
    fi
    
    # Decompress and restore
    log "Decompressing and restoring database..."
    local temp_restore="/tmp/epidbot_restore_$$.duckdb"
    
    if gunzip -c "$backup_file" > "$temp_restore"; then
        # Verify the restored database is valid
        if file "$temp_restore" | grep -q "DuckDB"; then
            mv "$temp_restore" "$DB_FILE"
            chmod 666 "$DB_FILE"
            log_success "Database restored successfully"
        else
            log_error "Restored file is not a valid DuckDB database"
            rm -f "$temp_restore"
            return 1
        fi
    else
        log_error "Failed to decompress backup"
        rm -f "$temp_restore"
        return 1
    fi
    
    # Restart container if it was running
    if [ $container_was_running -eq 1 ]; then
        read -p "Start EpidBot container now? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            start_container
        fi
    fi
    
    log_success "Restore completed"
    return 0
}

case "${1:-help}" in
    restore)
        if [ -z "$2" ]; then
            list_backups
            exit 1
        fi
        restore_backup "$2"
        ;;
    list)
        list_backups
        ;;
    help|--help|-h)
        echo "EpidBot DuckDB Restore Script"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  list                  List available backups"
        echo "  restore <file|num>    Restore from backup (filename or list number)"
        echo "  help                  Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 restore 1                    # Restore from first backup in list"
        echo "  $0 restore epidbot_duckdb_20240101_120000.duckdb.gz"
        echo ""
        echo "WARNING: Restore will stop the EpidBot container and replace the current database!"
        echo ""
        echo "Environment variables:"
        echo "  DATA_DIR       Data directory (default: /opt/kwar-ai/epidbot/data)"
        echo "  BACKUP_DIR     Backup directory (default: /opt/kwar-ai/epidbot/backups)"
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
