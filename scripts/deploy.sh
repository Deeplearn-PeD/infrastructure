#!/bin/bash
# Deploy Kwar-AI Infrastructure
# This script deploys the complete infrastructure stack

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "=================================="
echo "Kwar-AI Infrastructure Deployment"
echo "=================================="
echo ""

# Check if OpenTofu is installed
if ! command -v tofu &> /dev/null; then
    echo "ERROR: OpenTofu is not installed"
    echo "Please install OpenTofu: https://opentofu.org/docs/intro/install/"
    exit 1
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "ERROR: terraform.tfvars not found"
    echo "Please run: ./scripts/setup-hetzner-api.sh"
    exit 1
fi

# Initialize OpenTofu
echo "Initializing OpenTofu..."
tofu init

# Plan deployment
echo ""
echo "Planning deployment..."
tofu plan -out=tfplan

# Ask for confirmation
echo ""
read -p "Do you want to apply this plan? (y/n): " confirm

if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Apply infrastructure
echo ""
echo "Applying infrastructure..."
tofu apply tfplan

# Get server IP
SERVER_IP=$(tofu output -raw server_ip)

echo ""
echo "=================================="
echo "Infrastructure deployed successfully!"
echo "=================================="
echo ""
echo "Server IP: $SERVER_IP"
echo ""

# Generate Ansible inventory
echo "Generating Ansible inventory..."
SSH_KEY_PATH=$(tofu output -raw ssh_private_key_path 2>/dev/null || echo "./ssh_keys/kwar-ai-ssh-key")

cat > ansible/inventory.ini << EOF
[webservers]
${SERVER_IP} ansible_user=root ansible_ssh_private_key_file=${SSH_KEY_PATH}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

# Generate Ansible variables
echo "Generating Ansible variables..."
tofu output -json > /tmp/tofu_outputs.json

# Create group_vars from terraform outputs
cat > ansible/group_vars/all.yml << EOF
---
$(tofu output -json | jq -r 'to_entries | .[] | "\(.key): \"\(.value.value)\""' | head -n -1)
EOF

echo ""
echo "Next steps:"
echo "1. Configure DNS records:"
echo "   - A record: epidbot.kwar-ai.com.br -> $SERVER_IP"
echo "   - A record: libby.kwar-ai.com.br -> $SERVER_IP"
echo "   - A record: grafana.kwar-ai.com.br -> $SERVER_IP"
echo ""
echo "2. Wait for DNS propagation (5-30 minutes)"
echo ""
echo "3. Deploy services with Ansible:"
echo "   cd ansible && ansible-playbook -i inventory.ini playbook.yml"
echo ""
echo "4. Or use the quick deploy script:"
echo "   ./scripts/deploy-services.sh"
echo ""
echo "To SSH into the server:"
echo "ssh -i ${SSH_KEY_PATH} root@${SERVER_IP}"
