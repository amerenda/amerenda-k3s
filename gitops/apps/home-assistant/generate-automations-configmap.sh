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

# Process blueprints directory
BLUEPRINTS_DIR="blueprints"
if [ -d "$BLUEPRINTS_DIR" ]; then
    echo "Processing blueprints..."
    find "$BLUEPRINTS_DIR" -name "*.yaml" -type f | while read -r file; do
        # Get relative path from blueprints directory
        rel_path="${file#$BLUEPRINTS_DIR/}"
        echo "Processing blueprint: $rel_path..."
        
        # Add the file to the ConfigMap with blueprints/ prefix
        echo "  blueprints/$rel_path: |" >> "$OUTPUT_FILE"
        
        # Add the content with proper indentation
        sed 's/^/    /' "$file" >> "$OUTPUT_FILE"
        
        # Add a blank line between files
        echo "" >> "$OUTPUT_FILE"
    done
fi

echo "ConfigMap generated: $OUTPUT_FILE"
echo "To apply: kubectl apply -f $OUTPUT_FILE"
