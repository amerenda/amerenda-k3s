#!/bin/bash
# generate-blueprints-configmap.sh
# Generates ConfigMap manifest from blueprint automation YAML files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/../blueprints-configmap.yaml"

echo "Generating blueprints ConfigMap..."

# Create ConfigMap YAML manually (no kubectl dependency)
cat > "$OUTPUT_FILE" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: homeassistant-blueprints
data:
EOF

# Add each YAML file to the ConfigMap
for file in "$SCRIPT_DIR/automation"/*.yaml; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    echo "  $filename: |" >> "$OUTPUT_FILE"
    # Indent each line with 4 spaces and add to ConfigMap
    sed 's/^/    /' "$file" >> "$OUTPUT_FILE"
  fi
done

echo "Blueprints ConfigMap generated: $OUTPUT_FILE"
echo "ConfigMap includes:"
ls -1 "$SCRIPT_DIR/automation"/*.yaml | sed 's/^/  /'
