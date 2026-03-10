#!/bin/bash
# Docker Fix Script
# This script attempts to fix common Docker issues on Ubuntu

set -e

echo "=================================="
echo "Docker Fix Script"
echo "=================================="
echo ""

# Check if we're root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

echo "This script will attempt to fix Docker by:"
echo "1. Stopping Docker service"
echo "2. Removing Docker daemon config (if broken)"
echo "3. Reinstalling Docker packages"
echo "4. Restarting Docker service"
echo ""
read -p "Continue? (y/n): " confirm

if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo "Step 1: Stopping Docker services..."
systemctl stop docker || true
systemctl stop docker.socket || true
systemctl stop containerd || true

echo ""
echo "Step 2: Backing up and removing Docker config..."
if [ -f /etc/docker/daemon.json ]; then
    cp /etc/docker/daemon.json /etc/docker/daemon.json.backup
    rm -f /etc/docker/daemon.json
    echo "✓ Removed daemon.json (backup created)"
fi

echo ""
echo "Step 3: Cleaning up Docker state..."
rm -rf /var/run/docker.sock
rm -rf /var/run/docker.pid

echo ""
echo "Step 4: Reinstalling Docker packages..."
apt-get update
apt-get install --reinstall docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

echo ""
echo "Step 5: Starting Docker service..."
systemctl daemon-reload
systemctl start docker
systemctl enable docker

echo ""
echo "Step 6: Verifying Docker..."
sleep 3
if systemctl is-active --quiet docker; then
    echo "✓ Docker is running!"
    systemctl status docker --no-pager
    echo ""
    docker ps
else
    echo "✗ Docker still not running"
    echo ""
    echo "Checking logs..."
    journalctl -u docker.service -n 20 --no-pager
fi

echo ""
echo "=================================="
echo "Fix Script Complete"
echo "=================================="
