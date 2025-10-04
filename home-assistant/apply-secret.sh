#!/bin/bash
# Script to apply the secret with environment variable substitution

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check if required environment variables are set
if [ -z "$EUFY_USERNAME" ] || [ -z "$EUFY_PASSWORD" ]; then
    echo "Error: EUFY_USERNAME and EUFY_PASSWORD environment variables must be set"
    echo "Create a .env file with these variables or export them in your shell"
    exit 1
fi

# Apply the secret with environment variable substitution
envsubst < secret.yaml | kubectl apply -f -
