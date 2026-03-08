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
echo ""

# Verify token
echo "Verifying token..."

# Debug: Show token length (not the token itself)
echo "Token length: ${#API_TOKEN} characters"

# Make API call and capture both status and response
HTTP_STATUS=$(curl -s -o /tmp/hetzner_response.txt -w "%{http_code}" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    https://api.hetzner.cloud/v1/servers)

RESPONSE=$(cat /tmp/hetzner_response.txt)
rm -f /tmp/hetzner_response.txt

echo "HTTP Status: $HTTP_STATUS"

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✓ Token is valid!"
elif [ "$HTTP_STATUS" = "401" ]; then
    echo "ERROR: Invalid API token (unauthorized)"
    echo ""
    echo "Please check that you copied the entire token correctly."
    exit 1
elif [ "$HTTP_STATUS" = "000" ]; then
    echo "ERROR: Cannot reach Hetzner API"
    echo ""
    echo "Please check your internet connection."
    exit 1
else
    echo "ERROR: API request failed (HTTP $HTTP_STATUS)"
    echo ""
    echo "Response: $RESPONSE"
    exit 1
fi

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
# Use | as delimiter to avoid issues with special characters in token
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|YOUR_HETZNER_API_TOKEN_HERE|${API_TOKEN}|g" terraform.tfvars
else
    sed -i "s|YOUR_HETZNER_API_TOKEN_HERE|${API_TOKEN}|g" terraform.tfvars
fi

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
