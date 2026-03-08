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

# Extract HCLOUD_TOKEN from terraform.tfvars and export it
# This ensures the token is available to the provider
if grep -q "^hcloud_token" terraform.tfvars; then
    HCLOUD_TOKEN=$(grep "^hcloud_token" terraform.tfvars | cut -d'"' -f2)
    if [ -n "$HCLOUD_TOKEN" ] && [ "$HCLOUD_TOKEN" != "YOUR_HETZNER_API_TOKEN_HERE" ]; then
        export HCLOUD_TOKEN
        echo "✓ HCLOUD_TOKEN loaded from terraform.tfvars"
    else
        echo "ERROR: Invalid or placeholder token in terraform.tfvars"
        echo "Please run: ./scripts/setup-hetzner-api.sh"
        exit 1
    fi
else
    echo "ERROR: hcloud_token not found in terraform.tfvars"
    echo "Please run: ./scripts/setup-hetzner-api.sh"
    exit 1
fi

echo ""

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
    rm -f tfplan
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
SSH_KEY_PATH=$(tofu output -raw ssh_private_key_path 2>/dev/null || echo "")

# Convert to absolute path if relative
if [[ "$SSH_KEY_PATH" != /* ]]; then
    SSH_KEY_PATH="${PROJECT_ROOT}/${SSH_KEY_PATH}"
fi

# If SSH key path is empty or doesn't exist, use default
if [ -z "$SSH_KEY_PATH" ] || [ ! -f "$SSH_KEY_PATH" ]; then
    SSH_KEY_PATH="${PROJECT_ROOT}/ssh_keys/kwar-ai-ssh-key"
fi

echo "SSH Key Path: $SSH_KEY_PATH"

cat > ansible/inventory.ini << EOF
[webservers]
${SERVER_IP} ansible_user=root ansible_ssh_private_key_file=${SSH_KEY_PATH}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

# Generate Ansible variables
echo "Generating Ansible variables..."
tofu output -json > /tmp/tofu_outputs.json

# Extract variables from terraform.tfvars and add to group_vars
echo "Extracting configuration from terraform.tfvars..."

# Create group_vars with both outputs and tfvars
cat > ansible/group_vars/all.yml << EOF
---
# Server outputs
server_ip: "$(tofu output -raw server_ip)"
server_name: "$(tofu output -raw server_name)"
server_status: "$(tofu output -raw server_status)"
domain_name: "$(tofu output -raw domain_name)"
epidbot_url: "$(tofu output -raw epidbot_url)"
libby_url: "$(tofu output -raw libby_url)"
grafana_url: "$(tofu output -raw grafana_url)"

# Variables from terraform.tfvars
$(grep -E "^(admin_email|postgres_db|postgres_user|postgres_password|secret_key|backup_retention_days|enable_monitoring|grafana_admin_password|openai_api_key|gemini_api_key|zhipu_api_key|deepseek_api_key|github_client_id|github_client_secret|embedding_model|ollama_model|epidbot_subdomain|libby_subdomain|grafana_subdomain)" terraform.tfvars | sed 's/\s*=\s*/: /' | sed 's/"\([^"]*\)"/"\1"/g')
EOF

echo "✓ Ansible variables generated"

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
