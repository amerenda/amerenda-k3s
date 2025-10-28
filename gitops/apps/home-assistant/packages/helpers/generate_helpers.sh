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

echo "Generating input-boolean ConfigMap..."
kubectl create configmap homeassistant-helpers-input-boolean \
  --from-file="$OUTPUT_DIR/input_boolean" \
  --dry-run=client \
  -o yaml > "$CONFIGMAP_DIR/helpers-input-boolean-configmap.yaml"

echo "Generating input-datetime ConfigMap..."
kubectl create configmap homeassistant-helpers-input-datetime \
  --from-file="$OUTPUT_DIR/input_datetime" \
  --dry-run=client \
  -o yaml > "$CONFIGMAP_DIR/helpers-input-datetime-configmap.yaml"

echo "Generating input-select ConfigMap..."
kubectl create configmap homeassistant-helpers-input-select \
  --from-file="$OUTPUT_DIR/input_select" \
  --dry-run=client \
  -o yaml > "$CONFIGMAP_DIR/helpers-input-select-configmap.yaml"

echo "Generating input-number ConfigMap..."
kubectl create configmap homeassistant-helpers-input-number \
  --from-file="$OUTPUT_DIR/input_number" \
  --dry-run=client \
  -o yaml > "$CONFIGMAP_DIR/helpers-input-number-configmap.yaml"

echo "Generating input-text ConfigMap..."
kubectl create configmap homeassistant-helpers-input-text \
  --from-file="$OUTPUT_DIR/input_text" \
  --dry-run=client \
  -o yaml > "$CONFIGMAP_DIR/helpers-input-text-configmap.yaml"

echo ""
echo "All ConfigMaps generated:"
echo "  helpers-input-boolean-configmap.yaml"
echo "  helpers-input-datetime-configmap.yaml"
echo "  helpers-input-select-configmap.yaml"
echo "  helpers-input-number-configmap.yaml"
echo "  helpers-input-text-configmap.yaml"
