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
  annotations:
    reloader.stakater.com/auto: "true"
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

# Generate blueprints ConfigMap
BLUEPRINTS_DIR="blueprints"
BLUEPRINTS_OUTPUT="blueprints-configmap.yaml"

if [ -d "$BLUEPRINTS_DIR" ]; then
    echo "Generating blueprints ConfigMap..."
    
    # Start the blueprints ConfigMap YAML
    cat > "$BLUEPRINTS_OUTPUT" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ha-blueprints-defaults
  namespace: $NAMESPACE
  annotations:
    reloader.stakater.com/auto: "true"
data:
EOF

    # Process each YAML file in the blueprints directory
    find "$BLUEPRINTS_DIR" -name "*.yaml" -type f | while read -r file; do
        filename=$(basename "$file")
        echo "Processing blueprint: $filename..."
        
        # Add the file to the ConfigMap
        echo "  $filename: |" >> "$BLUEPRINTS_OUTPUT"
        
        # Add the content with proper indentation
        sed 's/^/    /' "$file" >> "$BLUEPRINTS_OUTPUT"
        
        # Add a blank line between files
        echo "" >> "$BLUEPRINTS_OUTPUT"
    done
    
    echo "Blueprints ConfigMap generated: $BLUEPRINTS_OUTPUT"
else
    echo "No blueprints directory found, skipping blueprints ConfigMap"
fi

# Generate schedule configuration ConfigMap
CONFIG_DIR="config"
SCHEDULE_OUTPUT="schedule-configmap.yaml"

if [ -d "$CONFIG_DIR" ]; then
    echo "Generating schedule configuration ConfigMap..."
    
    # Start the schedule ConfigMap YAML
    cat > "$SCHEDULE_OUTPUT" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ha-schedule-config
  namespace: $NAMESPACE
  annotations:
    reloader.stakater.com/auto: "true"
data:
EOF

    # Process each YAML file in the config directory, excluding redundant files
    find "$CONFIG_DIR" -name "*.yaml" -type f | grep -v "schedule_inputs.yaml" | while read -r file; do
        filename=$(basename "$file")
        echo "Processing config: $filename..."
        
        # Add the file to the ConfigMap
        echo "  $filename: |" >> "$SCHEDULE_OUTPUT"
        
        # Add the content with proper indentation
        sed 's/^/    /' "$file" >> "$SCHEDULE_OUTPUT"
        
        # Add a blank line between files
        echo "" >> "$SCHEDULE_OUTPUT"
    done
    
    echo "Schedule ConfigMap generated: $SCHEDULE_OUTPUT"
else
    echo "No config directory found, skipping schedule ConfigMap"
fi

echo "ConfigMap generated: $OUTPUT_FILE"
echo "To apply: commit the changes and push to the repository"
