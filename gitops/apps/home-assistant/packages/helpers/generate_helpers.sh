#!/bin/bash
# generate_helpers.sh
# Generates helper YAML files for each room using Jinja2 templates, split by domain type.
# Requires 'jinja2-cli' package (pip install jinja2-cli).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/generated"

# Create domain-specific directories
mkdir -p "$OUTPUT_DIR/input_boolean"
mkdir -p "$OUTPUT_DIR/input_datetime"
mkdir -p "$OUTPUT_DIR/input_select"
mkdir -p "$OUTPUT_DIR/input_number"
mkdir -p "$OUTPUT_DIR/input_text"

rooms=(bedroom bathroom living_room kitchen hallway)

for room in "${rooms[@]}"; do
  echo "Generating helpers for $room..."
  
  # Generate input_boolean helpers
  jinja2 "$SCRIPT_DIR/input_boolean_template.yaml.j2" -D room="$room" > "$OUTPUT_DIR/input_boolean/${room}.yaml"
  
  # Generate input_datetime helpers
  jinja2 "$SCRIPT_DIR/input_datetime_template.yaml.j2" -D room="$room" > "$OUTPUT_DIR/input_datetime/${room}.yaml"
  
  # Generate input_select helpers
  jinja2 "$SCRIPT_DIR/input_select_template.yaml.j2" -D room="$room" > "$OUTPUT_DIR/input_select/${room}.yaml"
  
  # Generate input_number helpers
  jinja2 "$SCRIPT_DIR/input_number_template.yaml.j2" -D room="$room" > "$OUTPUT_DIR/input_number/${room}.yaml"
done

# Copy all global input_text helpers
cp "$SCRIPT_DIR/input_text"/*.yaml "$OUTPUT_DIR/input_text/"

echo "All helper files generated in: $OUTPUT_DIR"
echo "Directory structure:"
echo "  input_boolean/ - Boolean switches and toggles"
echo "  input_datetime/ - Time pickers for schedule windows"
echo "  input_select/ - Scene selection dropdowns"
echo "  input_number/ - Brightness and numeric controls"

echo ""
echo "Generating ConfigMaps..."

# Generate ConfigMaps for each domain
CONFIGMAP_DIR="$SCRIPT_DIR/../.."

# Function to generate ConfigMap YAML manually
generate_configmap() {
  local name="$1"
  local source_dir="$2"
  local output_file="$3"
  
  echo "Generating $name ConfigMap..."
  
  cat > "$output_file" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: $name
data:
EOF

  # Add each YAML file to the ConfigMap
  for file in "$source_dir"/*.yaml; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      echo "  $filename: |" >> "$output_file"
      # Indent each line with 4 spaces and add to ConfigMap
      sed 's/^/    /' "$file" >> "$output_file"
    fi
  done
}

# Generate all ConfigMaps
generate_configmap "homeassistant-helpers-input-boolean" "$OUTPUT_DIR/input_boolean" "$CONFIGMAP_DIR/helpers-input-boolean-configmap.yaml"
generate_configmap "homeassistant-helpers-input-datetime" "$OUTPUT_DIR/input_datetime" "$CONFIGMAP_DIR/helpers-input-datetime-configmap.yaml"
generate_configmap "homeassistant-helpers-input-select" "$OUTPUT_DIR/input_select" "$CONFIGMAP_DIR/helpers-input-select-configmap.yaml"
generate_configmap "homeassistant-helpers-input-number" "$OUTPUT_DIR/input_number" "$CONFIGMAP_DIR/helpers-input-number-configmap.yaml"
generate_configmap "homeassistant-helpers-input-text" "$OUTPUT_DIR/input_text" "$CONFIGMAP_DIR/helpers-input-text-configmap.yaml"

echo ""
echo "All ConfigMaps generated:"
echo "  helpers-input-boolean-configmap.yaml"
echo "  helpers-input-datetime-configmap.yaml"
echo "  helpers-input-select-configmap.yaml"
echo "  helpers-input-number-configmap.yaml"
echo "  helpers-input-text-configmap.yaml"
