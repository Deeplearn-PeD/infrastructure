#!/bin/bash
# Deploy Services with Ansible
# This script runs the Ansible playbook to deploy all services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT/ansible"

echo "=================================="
echo "Deploying Kwar-AI Services"
echo "=================================="
echo ""

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "ERROR: Ansible is not installed"
    echo "Please install Ansible: pip install ansible"
    exit 1
fi

# Check if inventory exists
if [ ! -f "inventory.ini" ]; then
    echo "ERROR: inventory.ini not found"
    echo "Please run: ./scripts/deploy.sh first"
    exit 1
fi

# Install required Ansible collections
echo "Installing required Ansible collections..."
ansible-galaxy collection install community.docker community.general --force

# Run Ansible playbook
echo ""
echo "Running Ansible playbook..."
ansible-playbook -i inventory.ini playbook.yml --verbose

echo ""
echo "=================================="
echo "Services deployed successfully!"
echo "=================================="
echo ""
echo "Access your services:"
echo "- EpidBot: https://epidbot.kwar-ai.com.br"
echo "- Libby API: https://libby.kwar-ai.com.br"
echo "- Grafana: https://grafana.kwar-ai.com.br"
echo ""
echo "Monitor services:"
echo "./scripts/healthcheck.sh"
