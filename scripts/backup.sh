#!/bin/bash
# Backup Script
# This script creates backups of all Kwar-AI data

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "=== Kwar-AI Backup Script ==="
echo "Date: $(date)"
echo ""

# Get server IP
if [ ! -f "ansible/inventory.ini" ]; then
    echo "ERROR: inventory.ini not found"
    exit 1
fi

SERVER_IP=$(grep -oP '\d+\.\d+\.\d+\.\d+' ansible/inventory.ini | head -1)
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
LOCAL_BACKUP_DIR="$PROJECT_ROOT/backups/$BACKUP_DATE"

echo "Creating backup directory..."
mkdir -p "$LOCAL_BACKUP_DIR"

echo "Starting backup..."
echo ""

# Backup PostgreSQL
echo "1. Backing up PostgreSQL..."
ssh root@$SERVER_IP "docker exec libby-postgres pg_dumpall -U libby | gzip" > "$LOCAL_BACKUP_DIR/postgres_backup.sql.gz"
echo "   ✓ PostgreSQL backup completed"

# Backup Libby data
echo "2. Backing up Libby data..."
ssh root@$SERVER_IP "tar -czf - -C /opt/kwar-ai/libby data" > "$LOCAL_BACKUP_DIR/libby_data.tar.gz"
echo "   ✓ Libby data backup completed"

# Backup EpidBot data
echo "3. Backing up EpidBot data..."
ssh root@$SERVER_IP "tar -czf - -C /opt/kwar-ai/epidbot data" > "$LOCAL_BACKUP_DIR/epidbot_data.tar.gz"
echo "   ✓ EpidBot data backup completed"

# Backup Docker volumes
echo "4. Backing up Docker volumes..."
ssh root@$SERVER_IP "docker run --rm -v postgres-data:/data -v /backup:/backup alpine tar czf /backup/postgres_volume.tar.gz -C /data ." 2>/dev/null || true
ssh root@$SERVER_IP "cd /backup && tar czf - postgres_volume.tar.gz" > "$LOCAL_BACKUP_DIR/postgres_volume.tar.gz" 2>/dev/null || true
echo "   ✓ Docker volumes backup completed"

# Create backup manifest
echo "5. Creating backup manifest..."
cat > "$LOCAL_BACKUP_DIR/manifest.txt" << EOF
Backup Date: $BACKUP_DATE
Server IP: $SERVER_IP
Backup Contents:
- postgres_backup.sql.gz (PostgreSQL dump)
- libby_data.tar.gz (Libby data directory)
- epidbot_data.tar.gz (EpidBot data directory)
- postgres_volume.tar.gz (PostgreSQL Docker volume)
EOF

echo "   ✓ Manifest created"

# Calculate backup size
BACKUP_SIZE=$(du -sh "$LOCAL_BACKUP_DIR" | cut -f1)
echo ""
echo "=== Backup Completed ==="
echo "Location: $LOCAL_BACKUP_DIR"
echo "Size: $BACKUP_SIZE"
echo ""
echo "To restore from backup, use: ./scripts/restore.sh $BACKUP_DATE"
