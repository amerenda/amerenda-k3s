#!/bin/bash
# generate-scripts-configmap.sh
# Generates ConfigMap manifest from script YAML files in the scripts/ directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/../scripts-configmap.yaml"

echo "Generating scripts ConfigMap..."

# Create ConfigMap from scripts directory (only .yaml files)
# Use a temporary directory to avoid including the generation script
TEMP_DIR=$(mktemp -d)
cp "$SCRIPT_DIR"/*.yaml "$TEMP_DIR/"

kubectl create configmap homeassistant-scripts \
  --from-file="$TEMP_DIR" \
  --dry-run=client \
  -o yaml > "$OUTPUT_FILE"

# Cleanup
rm -rf "$TEMP_DIR"

echo "Scripts ConfigMap generated: $OUTPUT_FILE"
echo "ConfigMap includes:"
ls -1 "$SCRIPT_DIR"/*.yaml | sed 's/^/  /'
