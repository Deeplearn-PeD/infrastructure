#!/bin/bash
# Sync PySUS data to Hetzner server
# Uploads parquet files from local pysus to epidbot data directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
DEFAULT_LOCAL_PYSUS="${HOME}/pysus"
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

# Ask for source path
echo "Select PySUS data source:"
echo "1) Default path: ${DEFAULT_LOCAL_PYSUS}"
echo "2) Custom path"
echo ""
read -p "Enter choice (1 or 2) [default: 1]: " -n 1 -r
echo ""

if [[ -z "$REPLY" || "$REPLY" == "1" ]]; then
    LOCAL_PYSUS="$DEFAULT_LOCAL_PYSUS"
    echo "Using default path: $LOCAL_PYSUS"
elif [[ "$REPLY" == "2" ]]; then
    read -p "Enter custom PySUS path: " LOCAL_PYSUS
    # Expand ~ if present
    LOCAL_PYSUS="${LOCAL_PYSUS/#\~/$HOME}"
    echo "Using custom path: $LOCAL_PYSUS"
else
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
fi

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

# Count local files recursively
PARQUET_COUNT=$(find "$LOCAL_PYSUS" -name "*.parquet" -type f | wc -l)
DUCKDB_COUNT=$(find "$LOCAL_PYSUS" -name "*.duckdb" -type f | wc -l)
DUCKDB_WAL_COUNT=$(find "$LOCAL_PYSUS" -name "*.duckdb.wal" -type f | wc -l)

TOTAL_FILES=$((PARQUET_COUNT + DUCKDB_COUNT + DUCKDB_WAL_COUNT))

if [ "$TOTAL_FILES" -eq 0 ]; then
    echo -e "${YELLOW}WARNING: No parquet or duckdb files found in $LOCAL_PYSUS${NC}"
    echo "Searched recursively in: $LOCAL_PYSUS"
    exit 0
fi

echo "Local PySUS directory: $LOCAL_PYSUS"
echo "Remote destination: ${SERVER_USER}@${SERVER_IP}:${REMOTE_PYSUS}"
echo ""
echo "Files found (recursive scan):"
echo "  - Parquet files:  $PARQUET_COUNT"
echo "  - DuckDB files:   $DUCKDB_COUNT"
echo "  - DuckDB WAL:     $DUCKDB_WAL_COUNT"
echo "  - Total:          $TOTAL_FILES"
echo ""

# Show directory structure
echo "Directory structure:"
find "$LOCAL_PYSUS" -type d | head -20 | sed 's/^/  /'
DIR_COUNT=$(find "$LOCAL_PYSUS" -type d | wc -l)
if [ "$DIR_COUNT" -gt 20 ]; then
    echo "  ... and $((DIR_COUNT - 20)) more directories"
fi
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
