#!/bin/bash
# generate-blueprints-configmap.sh
# Generates ConfigMap manifest from blueprint automation YAML files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/../blueprints-configmap.yaml"

echo "Generating blueprints ConfigMap..."

# Create ConfigMap from blueprints/automation directory
kubectl create configmap homeassistant-blueprints \
  --from-file="$SCRIPT_DIR/automation/" \
  --dry-run=client \
  -o yaml > "$OUTPUT_FILE"

echo "Blueprints ConfigMap generated: $OUTPUT_FILE"
echo "ConfigMap includes:"
ls -1 "$SCRIPT_DIR/automation"/*.yaml | sed 's/^/  /'
