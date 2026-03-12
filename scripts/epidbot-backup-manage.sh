#!/bin/bash
# Local script to manage EpidBot backups on remote server
# Run from your local machine

set -e

REMOTE_HOST="204.168.149.153"
SSH_USER="${SSH_USER:-root}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SSH_KEY="${SSH_KEY:-${SCRIPT_DIR}/../ssh_keys/kwar-ai-ssh-key}"
BACKUP_SCRIPT="/opt/kwar-ai/epidbot/scripts/epidbot-backup.sh"
RESTORE_SCRIPT="/opt/kwar-ai/epidbot/scripts/epidbot-restore.sh"

ssh_cmd() {
    ssh -i "${SSH_KEY}" "${SSH_USER}@${REMOTE_HOST}" "$@"
}

usage() {
    echo "EpidBot Backup Management"
    echo ""
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  backup                  Create a backup on the remote server"
    echo "  status                  Show backup status and statistics"
    echo "  list                    List available backups"
    echo "  restore <file|num>      Restore from backup (stops EpidBot)"
    echo "  download [dest]         Download latest backup to local machine"
    echo "  download-all [dest]     Download all backups to local machine"
    echo "  logs                    Show backup logs"
    echo "  help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 backup"
    echo "  $0 status"
    echo "  $0 list"
    echo "  $0 restore 1"
    echo "  $0 download ~/backups"
    echo ""
    echo "Environment variables:"
    echo "  SSH_USER  - SSH user (default: root)"
    echo "  SSH_KEY   - SSH private key path"
    exit 1
}

cmd_backup() {
    echo "Creating backup on remote server..."
    ssh_cmd "$BACKUP_SCRIPT backup"
}

cmd_status() {
    ssh_cmd "$BACKUP_SCRIPT status"
}

cmd_list() {
    ssh_cmd "$RESTORE_SCRIPT list"
}

cmd_restore() {
    local backup="$1"
    
    if [ -z "$backup" ]; then
        echo "Error: Missing backup file or number"
        echo "Usage: $0 restore <backup_file|number>"
        echo ""
        cmd_list
        exit 1
    fi
    
    echo "Warning: This will stop EpidBot and replace the database!"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    ssh_cmd "$RESTORE_SCRIPT restore \"$backup\""
}

cmd_download() {
    local dest="${1:-./epidbot-backups}"
    local remote_backup_dir="/opt/kwar-ai/epidbot/backups"
    
    mkdir -p "$dest"
    
    echo "Finding latest backup..."
    local latest=$(ssh_cmd "ls -t $remote_backup_dir/epidbot_duckdb_*.duckdb.gz 2>/dev/null | head -1")
    
    if [ -z "$latest" ]; then
        echo "Error: No backups found on remote server"
        exit 1
    fi
    
    local filename=$(basename "$latest")
    local local_file="$dest/$filename"
    
    echo "Downloading: $filename"
    scp -i "${SSH_KEY}" "${SSH_USER}@${REMOTE_HOST}:$latest" "$local_file"
    
    local size=$(du -h "$local_file" | cut -f1)
    echo "Downloaded to: $local_file ($size)"
}

cmd_download_all() {
    local dest="${1:-./epidbot-backups}"
    local remote_backup_dir="/opt/kwar-ai/epidbot/backups"
    
    mkdir -p "$dest"
    
    echo "Downloading all backups..."
    scp -i "${SSH_KEY}" "${SSH_USER}@${REMOTE_HOST}:$remote_backup_dir/epidbot_duckdb_*.duckdb.gz" "$dest/" 2>/dev/null || {
        echo "No backups found or download failed"
        exit 1
    }
    
    local count=$(ls -1 "$dest"/epidbot_duckdb_*.duckdb.gz 2>/dev/null | wc -l)
    local total_size=$(du -sh "$dest" | cut -f1)
    echo "Downloaded $count backup(s) to $dest (total: $total_size)"
}

cmd_logs() {
    echo "=== Recent backup logs ==="
    ssh_cmd "tail -50 /var/log/epidbot-backup.log 2>/dev/null || echo 'No logs found'"
}

case "${1:-help}" in
    backup)
        cmd_backup
        ;;
    status)
        cmd_status
        ;;
    list)
        cmd_list
        ;;
    restore)
        cmd_restore "$2"
        ;;
    download)
        cmd_download "$2"
        ;;
    download-all)
        cmd_download_all "$2"
        ;;
    logs)
        cmd_logs
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "Error: Unknown command '$1'"
        usage
        ;;
esac
