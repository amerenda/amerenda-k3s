#!/bin/bash
# generate-scripts-configmap.sh
# Generates ConfigMap manifest from script YAML files in the scripts/ directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/../scripts-configmap.yaml"

echo "Generating scripts ConfigMap..."

# Create ConfigMap YAML manually (no kubectl dependency)
cat > "$OUTPUT_FILE" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: homeassistant-scripts
data:
EOF

# Add each YAML file to the ConfigMap (exclude generation script)
for file in "$SCRIPT_DIR"/*.yaml; do
  if [ -f "$file" ] && [ "$(basename "$file")" != "generate-scripts-configmap.sh" ]; then
    filename=$(basename "$file")
    echo "  $filename: |" >> "$OUTPUT_FILE"
    # Indent each line with 4 spaces and add to ConfigMap
    sed 's/^/    /' "$file" >> "$OUTPUT_FILE"
  fi
done

echo "Scripts ConfigMap generated: $OUTPUT_FILE"
echo "ConfigMap includes:"
ls -1 "$SCRIPT_DIR"/*.yaml | grep -v "generate-scripts-configmap.sh" | sed 's/^/  /'
