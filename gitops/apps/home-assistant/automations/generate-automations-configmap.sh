#!/bin/bash
# generate-automations-configmap.sh
# Generates ConfigMap manifest from automation YAML files in the automations/ directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/../automations-configmap.yaml"

echo "Generating automations ConfigMap..."

# Create ConfigMap from automations directory
kubectl create configmap homeassistant-automations \
  --from-file="$SCRIPT_DIR/" \
  --dry-run=client \
  -o yaml > "$OUTPUT_FILE"

echo "Automations ConfigMap generated: $OUTPUT_FILE"
echo "ConfigMap includes:"
ls -1 "$SCRIPT_DIR"/*.yaml | sed 's/^/  /'
