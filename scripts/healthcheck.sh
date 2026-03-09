#!/bin/bash
# Health Check Script
# This script checks the health of all Kwar-AI services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "=== Kwar-AI Health Check ==="
echo "Date: $(date)"
echo ""

# Check if we can reach the server
if [ ! -f "ansible/inventory.ini" ]; then
    echo "ERROR: inventory.ini not found"
    echo "Please deploy infrastructure first"
    exit 1
fi

SERVER_IP=$(grep -oP '\d+\.\d+\.\d+\.\d+' ansible/inventory.ini | head -1)
SSH_KEY="ssh_keys/kwar-ai-ssh-key"

if [ -z "$SERVER_IP" ]; then
    echo "ERROR: Could not find server IP in inventory"
    exit 1
fi

echo "Server IP: $SERVER_IP"
echo ""

# Check SSH connectivity
echo "1. Checking SSH connectivity..."
if ssh -i "$SSH_KEY" -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no root@$SERVER_IP "echo 'OK'" &>/dev/null; then
    echo "   ✓ SSH connection: OK"
else
    echo "   ✗ SSH connection: FAILED"
    echo "   Make sure you have the correct SSH key"
fi
echo ""

# Check Docker containers
echo "2. Checking Docker containers..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no root@$SERVER_IP "docker ps --format 'table {{.Names}}\t{{.Status}}'" 2>/dev/null || echo "   ✗ Could not retrieve container status"
echo ""

# Check EpidBot
echo "3. Checking EpidBot..."
EPIDBOT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://epidbot.kwar-ai.com.br/ 2>/dev/null || echo "000")
if [ "$EPIDBOT_STATUS" = "200" ]; then
    echo "   ✓ EpidBot: OK (HTTP $EPIDBOT_STATUS)"
else
    echo "   ✗ EpidBot: FAILED (HTTP $EPIDBOT_STATUS)"
fi
echo ""

# Check Libby API
echo "4. Checking Libby API..."
LIBBY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://libby.kwar-ai.com.br/api/health 2>/dev/null || echo "000")
if [ "$LIBBY_STATUS" = "200" ]; then
    echo "   ✓ Libby API: OK (HTTP $LIBBY_STATUS)"
else
    echo "   ✗ Libby API: FAILED (HTTP $LIBBY_STATUS)"
fi
echo ""

# Check PostgreSQL
echo "5. Checking PostgreSQL..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no root@$SERVER_IP "docker exec libby-postgres pg_isready -U libby" 2>/dev/null && echo "   ✓ PostgreSQL: OK" || echo "   ✗ PostgreSQL: FAILED"
echo ""

# Check SSL certificates
echo "6. Checking SSL certificates..."
CERT_EXPIRY=$(echo | openssl s_client -servername epidbot.kwar-ai.com.br -connect epidbot.kwar-ai.com.br:443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null || echo "Unknown")
echo "   Certificate expiry: $CERT_EXPIRY"
echo ""

# Check disk usage
echo "7. Checking disk usage..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no root@$SERVER_IP "df -h /opt/kwar-ai" 2>/dev/null || echo "   ✗ Could not retrieve disk usage"
echo ""

# Check memory usage
echo "8. Checking memory usage..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no root@$SERVER_IP "free -h" 2>/dev/null || echo "   ✗ Could not retrieve memory usage"
echo ""

echo "=== Health check completed ==="
