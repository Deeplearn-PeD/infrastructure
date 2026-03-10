#!/bin/bash
# Deploy Services with Ansible
# This script runs the Ansible playbook to deploy all services
# Usage: ./scripts/deploy-services.sh [service]
#   service: docker, nginx, libby, epidbot, monitoring (optional)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT/ansible"

# Parse arguments
SERVICE="${1:-}"

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

# Build ansible-playbook command
ANSIBLE_CMD="ansible-playbook -i inventory.ini playbook.yml --verbose"

# If a specific service is provided, use tags
if [ -n "$SERVICE" ]; then
    case "$SERVICE" in
        docker)
            TAGS="docker,setup"
            ;;
        nginx)
            TAGS="nginx,web"
            ;;
        libby)
            TAGS="libby,services"
            ;;
        epidbot)
            TAGS="epidbot,services"
            ;;
        monitoring)
            TAGS="monitoring"
            ;;
        *)
            echo "ERROR: Unknown service '$SERVICE'"
            echo "Available services: docker, nginx, libby, epidbot, monitoring"
            exit 1
            ;;
    esac
    ANSIBLE_CMD="$ANSIBLE_CMD --tags $TAGS"
    echo "Deploying only: $SERVICE (tags: $TAGS)"
else
    echo "Deploying all services"
fi

echo ""

# Run Ansible playbook
echo "Running Ansible playbook..."
$ANSIBLE_CMD

echo ""
echo "=================================="
if [ -n "$SERVICE" ]; then
    echo "$SERVICE deployed successfully!"
else
    echo "Services deployed successfully!"
fi
echo "=================================="
echo ""
echo "Access your services:"
echo "- EpidBot: https://epidbot.kwar-ai.com.br"
echo "- Libby API: https://libby.kwar-ai.com.br"
echo "- Grafana: https://grafana.kwar-ai.com.br"
echo ""
echo "Monitor services:"
echo "./scripts/healthcheck.sh"
