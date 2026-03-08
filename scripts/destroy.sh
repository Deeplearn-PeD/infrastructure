#!/bin/bash
# Destroy Infrastructure
# This script destroys all infrastructure resources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "=================================="
echo "Destroy Kwar-AI Infrastructure"
echo "=================================="
echo ""
echo "WARNING: This will destroy all infrastructure resources!"
echo "This action cannot be undone."
echo ""

read -p "Are you sure you want to continue? (yes/no): " confirm

if [[ $confirm != "yes" ]]; then
    echo "Destruction cancelled"
    exit 0
fi

echo ""
echo "Creating final backup before destruction..."
./scripts/backup.sh || echo "Backup failed, continuing anyway..."
echo ""

echo "Destroying infrastructure..."
tofu destroy

echo ""
echo "=================================="
echo "Infrastructure destroyed"
echo "=================================="
echo ""
echo "Note: Backups are preserved in: $PROJECT_ROOT/backups/"
