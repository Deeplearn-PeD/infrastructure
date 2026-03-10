#!/bin/bash
# Sync PySUS data to Hetzner server
# Uploads parquet files from local ~/pysus to epidbot data directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
LOCAL_PYSUS="${HOME}/pysus"
SERVER_USER="root"
SERVER_IP="204.168.149.153"
REMOTE_PYSUS="/opt/kwar-ai/epidbot/data/pysus"
SSH_KEY="${PROJECT_ROOT}/ssh_keys/kwar-ai-ssh-key"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=================================="
echo "PySUS Data Sync to Hetzner"
echo "=================================="
echo ""

# Check if local pysus directory exists
if [ ! -d "$LOCAL_PYSUS" ]; then
    echo -e "${RED}ERROR: Local PySUS directory not found: $LOCAL_PYSUS${NC}"
    exit 1
fi

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo -e "${RED}ERROR: SSH key not found: $SSH_KEY${NC}"
    exit 1
fi

# Count local parquet files
PARQUET_COUNT=$(find "$LOCAL_PYSUS" -name "*.parquet" -type f | wc -l)

if [ "$PARQUET_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}WARNING: No parquet files found in $LOCAL_PYSUS${NC}"
    exit 0
fi

echo "Local PySUS directory: $LOCAL_PYSUS"
echo "Remote destination: ${SERVER_USER}@${SERVER_IP}:${REMOTE_PYSUS}"
echo "Parquet files found: $PARQUET_COUNT"
echo ""

# Calculate total size
TOTAL_SIZE=$(du -sh "$LOCAL_PYSUS" | cut -f1)
echo "Total size: $TOTAL_SIZE"
echo ""

# Ask for confirmation
read -p "Proceed with sync? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Sync cancelled."
    exit 0
fi

echo ""
echo "Starting sync..."
echo ""

# Create remote directory if it doesn't exist
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_IP}" "mkdir -p $REMOTE_PYSUS"

# Sync using rsync (preserves directory structure)
rsync -avz \
    --progress \
    --include="*/" \
    --include="*.parquet" \
    --include="*.duckdb" \
    --include="*.duckdb.wal" \
    --exclude="*" \
    -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" \
    "$LOCAL_PYSUS/" \
    "${SERVER_USER}@${SERVER_IP}:${REMOTE_PYSUS}/"

echo ""
echo -e "${GREEN}Sync completed successfully!${NC}"
echo ""

# Show remote directory contents
echo "Remote directory contents:"
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_IP}" "du -sh $REMOTE_PYSUS && find $REMOTE_PYSUS -name '*.parquet' | wc -l | xargs -I {} echo 'Parquet files: {}'"

# Ask if user wants to restart epidbot
echo ""
read -p "Restart epidbot container to pick up new data? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Restarting epidbot..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_IP}" "cd /opt/kwar-ai/epidbot && docker-compose restart epidbot"
    echo -e "${GREEN}Epidbot restarted.${NC}"
fi

echo ""
echo "Done."
