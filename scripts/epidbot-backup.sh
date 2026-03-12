#!/bin/bash
# EpidBot DuckDB Backup Script
# Creates backups of the EpidBot DuckDB database with retention policy
# 
# This script handles:
# - Database locking (waits or fails gracefully)
# - Retention policy (deletes old backups)
# - Compression (gzip)
# - Logging

set -e

# Configuration
DATA_DIR="${DATA_DIR:-/var/lib/docker/volumes/epidbot_epidbot_data/_data}"
BACKUP_DIR="${BACKUP_DIR:-/opt/kwar-ai/epidbot/backups}"
DB_FILE="${DB_FILE:-${DATA_DIR}/chat_history.duckdb}"
METADATA_FILE="${BACKUP_DIR}/.metadata"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
CONTAINER_NAME="${CONTAINER_NAME:-epidbot}"
MAX_RETRIES="${MAX_RETRIES:-3}"
RETRY_DELAY="${RETRY_DELAY:-10}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

create_backup() {
    local backup_date=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/epidbot_duckdb_${backup_date}.duckdb.gz"
    local temp_backup="${BACKUP_DIR}/.temp_backup_${backup_date}.duckdb"
    
    # Ensure backup directory exists
    mkdir -p "$BACKUP_DIR"
    
    # Check if database file exists
    if [ ! -f "$DB_FILE" ]; then
        log_error "Database file not found: $DB_FILE"
        return 1
    fi
    
    # Check if container is running
    local container_running=0
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        container_running=1
    fi
    
    # Try to create backup with retries
    local retry_count=0
    local backup_success=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        # Copy database file
        if cp "$DB_FILE" "$temp_backup" 2>/dev/null; then
            backup_success=1
            break
        fi
        
        retry_count=$((retry_count + 1))
        
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log_warn "Database locked, retrying in ${RETRY_DELAY}s (attempt $retry_count/$MAX_RETRIES)..."
            sleep $RETRY_DELAY
        fi
    done
    
    if [ $backup_success -eq 0 ]; then
        log_error "Failed to backup database after $MAX_RETRIES attempts (database may be locked)"
        rm -f "$temp_backup" 2>/dev/null || true
        return 1
    fi
    
    # Compress the backup
    if gzip -c "$temp_backup" > "$backup_file"; then
        rm -f "$temp_backup"
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "Backup created: $backup_file ($size)"
        return 0
    else
        log_error "Failed to compress backup"
        rm -f "$temp_backup" "$backup_file" 2>/dev/null || true
        return 1
    fi
}

extract_metadata() {
    log "Extracting database metadata..."
    mkdir -p "$BACKUP_DIR"
    
    local table_count=0
    local total_rows=0
    local db_copy="/var/lib/docker/volumes/epidbot_epidbot_data/_data/.metadata_copy.duckdb"
    
    if [ -f "$DB_FILE" ] && docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        cp "$DB_FILE" "$db_copy" 2>/dev/null || true
        
        if [ -f "$db_copy" ]; then
            table_count=$(docker exec ${CONTAINER_NAME} /app/.venv/bin/python -c "
import duckdb
try:
    conn = duckdb.connect('/data/.metadata_copy.duckdb', read_only=True)
    result = conn.execute(\"SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog')\").fetchone()
    print(result[0] if result else 0)
except Exception as e:
    print(0)
" 2>/dev/null) || table_count=0
            
            total_rows=$(docker exec ${CONTAINER_NAME} /app/.venv/bin/python -c "
import duckdb
try:
    conn = duckdb.connect('/data/.metadata_copy.duckdb', read_only=True)
    tables = conn.execute(\"SELECT table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog')\").fetchall()
    total = 0
    for t in tables:
        try:
            count = conn.execute(f'SELECT count(*) FROM {t[0]}').fetchone()
            total += count[0] if count else 0
        except:
            pass
    print(total)
except Exception as e:
    print(0)
" 2>/dev/null) || total_rows=0
            
            rm -f "$db_copy" 2>/dev/null || true
        fi
    fi
    
    cat > "$METADATA_FILE" << EOF
# EpidBot DuckDB Metadata
# Generated: $(date -Iseconds)
table_count=$table_count
total_rows=$total_rows
db_size=$(stat -c %s "$DB_FILE" 2>/dev/null || echo 0)
EOF
    
    log "Metadata saved: $table_count tables, $total_rows total rows"
}

cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    
    local deleted_count=0
    local total_freed=0
    
    # Find and delete old backups
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            local size=$(du -b "$file" | cut -f1)
            rm -f "$file"
            deleted_count=$((deleted_count + 1))
            total_freed=$((total_freed + size))
        fi
    done < <(find "$BACKUP_DIR" -name "epidbot_duckdb_*.duckdb.gz" -type f -mtime +$RETENTION_DAYS -print0 2>/dev/null)
    
    if [ $deleted_count -gt 0 ]; then
        local freed_human=$(numfmt --to=iec --suffix=B $total_freed 2>/dev/null || echo "${total_freed} bytes")
        log_success "Deleted $deleted_count old backup(s), freed $freed_human"
    else
        log "No old backups to delete"
    fi
}

show_status() {
    log "=== EpidBot DuckDB Backup Status ==="
    echo ""
    
    if [ -f "$DB_FILE" ]; then
        local db_size=$(du -h "$DB_FILE" | cut -f1)
        local db_modified=$(stat -c %y "$DB_FILE" 2>/dev/null | cut -d. -f1)
        echo "Database: $DB_FILE"
        echo "  Size: $db_size"
        echo "  Last modified: $db_modified"
    else
        echo "Database: NOT FOUND ($DB_FILE)"
    fi
    
    echo ""
    echo "Backups in $BACKUP_DIR:"
    
    if [ -d "$BACKUP_DIR" ]; then
        local backup_count=$(find "$BACKUP_DIR" -name "epidbot_duckdb_*.duckdb.gz" -type f 2>/dev/null | wc -l)
        local total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        
        if [ $backup_count -gt 0 ]; then
            echo "  Count: $backup_count"
            echo "  Total size: $total_size"
            echo ""
            echo "  Recent backups:"
            find "$BACKUP_DIR" -name "epidbot_duckdb_*.duckdb.gz" -type f -printf '    %f (%.10kKB, %t)\n' 2>/dev/null | \
                sort -r | head -5 | while read line; do
                echo "$line"
            done
        else
            echo "  No backups found"
        fi
    else
        echo "  Backup directory does not exist"
    fi
    
    echo ""
    echo "Configuration:"
    echo "  Retention: $RETENTION_DAYS days"
    echo "  Max retries: $MAX_RETRIES"
}

case "${1:-backup}" in
    backup)
        log "Starting EpidBot DuckDB backup..."
        extract_metadata
        create_backup
        cleanup_old_backups
        log "Backup process completed"
        ;;
    metadata)
        extract_metadata
        ;;
    status)
        show_status
        ;;
    cleanup)
        cleanup_old_backups
        ;;
    help|--help|-h)
        echo "EpidBot DuckDB Backup Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  backup    Create a backup and cleanup old ones (default)"
        echo "  metadata  Extract and save database metadata only"
        echo "  status    Show backup status and statistics"
        echo "  cleanup   Only cleanup old backups"
        echo "  help      Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  DATA_DIR         Data directory (default: /opt/kwar-ai/epidbot/data)"
        echo "  BACKUP_DIR       Backup directory (default: /opt/kwar-ai/epidbot/backups)"
        echo "  RETENTION_DAYS   Days to keep backups (default: 7)"
        echo "  MAX_RETRIES      Max attempts if DB locked (default: 3)"
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
