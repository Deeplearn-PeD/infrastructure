#!/bin/bash
# Setup Hetzner API Token
# This script helps you create and configure your Hetzner Cloud API token

set -e

echo "=================================="
echo "Hetzner Cloud API Token Setup"
echo "=================================="
echo ""
echo "To use this infrastructure, you need a Hetzner Cloud API token."
echo ""
echo "Steps to create your API token:"
echo "1. Go to: https://console.hetzner.cloud"
echo "2. Log in to your account"
echo "3. Select your project (or create a new one)"
echo "4. Go to: Security > API Tokens"
echo "5. Click 'Generate API token'"
echo "6. Give it a name (e.g., 'kwar-ai-deployment')"
echo "7. Set permissions to: Read & Write"
echo "8. Copy the generated token"
echo ""
echo "IMPORTANT: Copy the token now! You won't be able to see it again."
echo ""

read -p "Have you created your API token? (y/n): " created

if [[ $created != "y" && $created != "Y" ]]; then
    echo "Please create your API token first and run this script again."
    exit 1
fi

echo ""
read -sp "Enter your Hetzner API token: " API_TOKEN
echo ""

# Verify token
echo "Verifying token..."
if ! curl -s -H "Authorization: Bearer $API_TOKEN" https://api.hetzner.cloud/v1/server | grep -q "servers"; then
    echo "ERROR: Invalid API token or API is unreachable"
    exit 1
fi

echo "✓ Token is valid!"
echo ""

# Create terraform.tfvars file
if [ -f "terraform.tfvars" ]; then
    read -p "terraform.tfvars already exists. Overwrite? (y/n): " overwrite
    if [[ $overwrite != "y" && $overwrite != "Y" ]]; then
        echo "Keeping existing terraform.tfvars"
        exit 0
    fi
fi

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Update token in file
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/YOUR_HETZNER_API_TOKEN_HERE/$API_TOKEN/" terraform.tfvars
else
    sed -i "s/YOUR_HETZNER_API_TOKEN_HERE/$API_TOKEN/" terraform.tfvars
fi

echo ""
echo "✓ terraform.tfvars created with your API token"
echo ""
echo "Next steps:"
echo "1. Edit terraform.tfvars and configure other variables:"
echo "   - postgres_password"
echo "   - secret_key"
echo "   - grafana_admin_password"
echo "   - API keys (openai_api_key, gemini_api_key, etc.)"
echo ""
echo "2. Generate secure passwords with: openssl rand -base64 32"
echo ""
echo "3. Run: tofu init"
echo "4. Run: tofu plan"
echo "5. Run: tofu apply"
