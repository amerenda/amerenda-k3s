#!/bin/bash

# Script to generate ConfigMap from automation files
# Usage: ./generate-automations-configmap.sh

set -e

AUTOMATIONS_DIR="automations"
OUTPUT_FILE="automations-configmap.yaml"
NAMESPACE="home-assistant"

echo "Generating ConfigMap from automation files..."

# Start the ConfigMap YAML
cat > "$OUTPUT_FILE" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: homeassistant-automations
  namespace: $NAMESPACE
data:
EOF

# Process each YAML file in the automations directory
for file in "$AUTOMATIONS_DIR"/*.yaml; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "Processing $filename..."
        
        # Add the file to the ConfigMap
        echo "  $filename: |" >> "$OUTPUT_FILE"
        
        # Add the content with proper indentation
        sed 's/^/    /' "$file" >> "$OUTPUT_FILE"
        
        # Add a blank line between files
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Blueprints are handled in a separate ConfigMap (blueprints-configmap.yaml)

echo "ConfigMap generated: $OUTPUT_FILE"
echo "To apply: kubectl apply -f $OUTPUT_FILE"
