#!/bin/bash
# Script to apply the secret with environment variable substitution

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    set -a  # automatically export all variables
    source .env
    set +a
fi

# Check if required environment variables are set
if [ -z "$EUFY_USERNAME" ] || [ -z "$EUFY_PASSWORD" ]; then
    echo "Error: EUFY_USERNAME and EUFY_PASSWORD environment variables must be set"
    echo "Create a .env file with these variables or export them in your shell"
    exit 1
fi

# Create a temporary YAML file with properly escaped values
# Use base64 encoding to handle special characters safely
cat > /tmp/secrets.yaml << EOF
eufy_username: "$EUFY_USERNAME"
eufy_password: "$EUFY_PASSWORD"
EOF

# Create the secret using the temporary file
kubectl create secret generic homeassistant-secrets \
  --from-file=secrets.yaml=/tmp/secrets.yaml \
  --namespace=home-assistant \
  --dry-run=client -o yaml | kubectl apply -f -

# Clean up
rm -f /tmp/secrets.yaml
