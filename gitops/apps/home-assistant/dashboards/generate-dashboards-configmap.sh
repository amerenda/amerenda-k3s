#!/bin/bash
# generate-dashboards-configmap.sh
# Generates ConfigMap manifest from dashboard YAML files in the dashboards/ directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/../dashboards-configmap.yaml"

echo "Generating dashboards ConfigMap..."

# Create ConfigMap YAML manually (no kubectl dependency)
cat > "$OUTPUT_FILE" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: homeassistant-dashboards
data:
EOF

# Add each YAML file to the ConfigMap
for file in "$SCRIPT_DIR"/*.yaml; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    echo "  $filename: |" >> "$OUTPUT_FILE"
    # Indent each line with 4 spaces and add to ConfigMap
    sed 's/^/    /' "$file" >> "$OUTPUT_FILE"
  fi
done

echo "Dashboards ConfigMap generated: $OUTPUT_FILE"
echo "ConfigMap includes:"
ls -1 "$SCRIPT_DIR"/*.yaml | sed 's/^/  /'
