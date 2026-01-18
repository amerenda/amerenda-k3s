#!/bin/bash
# generate-configmaps.sh
# Unified script to generate all Home Assistant ConfigMaps from configuration files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR"
OUTPUT_DIR="$SCRIPT_DIR/.."

# Function to generate ConfigMap YAML manually
generate_configmap() {
  local name="$1"
  local source_dir="$2"
  local output_file="$3"
  local file_pattern="${4:-*.yaml}"
  
  echo "Generating $name ConfigMap..."
  
  cat > "$output_file" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: $name
data:
EOF

  # Add each YAML file to the ConfigMap
  local file_count=0
  for file in "$source_dir"/$file_pattern; do
    if [ -f "$file" ] && [ ! -d "$file" ]; then
      filename=$(basename "$file")
      echo "  $filename: |" >> "$output_file"
      # Indent each line with 4 spaces and add to ConfigMap
      sed 's/^/    /' "$file" >> "$output_file"
      file_count=$((file_count + 1))
    fi
  done
  
  if [ $file_count -eq 0 ]; then
    echo "  Warning: No files found in $source_dir matching $file_pattern" >&2
  fi
}

echo "=========================================="
echo "Home Assistant ConfigMap Generator"
echo "=========================================="
echo ""

# Generate automations ConfigMap
if [ -d "$CONFIG_DIR/automations" ]; then
  generate_configmap "homeassistant-automations" "$CONFIG_DIR/automations" "$OUTPUT_DIR/automations-configmap.yaml" "*.yaml"
  echo "  ✓ Automations ConfigMap generated"
else
  echo "  ⚠ Skipping automations (directory not found)"
fi
echo ""

# Generate blueprints ConfigMap
if [ -d "$CONFIG_DIR/blueprints/automation" ]; then
  generate_configmap "homeassistant-blueprints" "$CONFIG_DIR/blueprints/automation" "$OUTPUT_DIR/blueprints-configmap.yaml" "*.yaml"
  echo "  ✓ Blueprints ConfigMap generated"
else
  echo "  ⚠ Skipping blueprints (directory not found)"
fi
echo ""

# Generate dashboards ConfigMap
if [ -d "$CONFIG_DIR/dashboards" ]; then
  # Check for yaml files in dashboards directory and subdirectories
  if find "$CONFIG_DIR/dashboards" -name "*.yaml" -type f | grep -q .; then
    # For dashboards, we need to handle nested structure (e.g., views/)
    cat > "$OUTPUT_DIR/dashboards-configmap.yaml" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: homeassistant-dashboards
data:
EOF
    
    # Find and add all YAML files, preserving directory structure in key names
    while IFS= read -r file; do
      if [ -f "$file" ]; then
        # Get relative path from dashboards directory
        rel_path="${file#$CONFIG_DIR/dashboards/}"
        # Replace / with _ for ConfigMap key
        key=$(echo "$rel_path" | tr '/' '_')
        echo "  $key: |" >> "$OUTPUT_DIR/dashboards-configmap.yaml"
        sed 's/^/    /' "$file" >> "$OUTPUT_DIR/dashboards-configmap.yaml"
      fi
    done < <(find "$CONFIG_DIR/dashboards" -name "*.yaml" -type f)
    
    echo "  ✓ Dashboards ConfigMap generated"
  else
    echo "  ⚠ Skipping dashboards (no YAML files found)"
  fi
else
  echo "  ⚠ Skipping dashboards (directory not found)"
fi
echo ""

# Generate scripts ConfigMap
if [ -d "$CONFIG_DIR/scripts" ]; then
  generate_configmap "homeassistant-scripts" "$CONFIG_DIR/scripts" "$OUTPUT_DIR/scripts-configmap.yaml" "*.yaml"
  echo "  ✓ Scripts ConfigMap generated"
else
  echo "  ⚠ Skipping scripts (directory not found)"
fi
echo ""

# Generate groups ConfigMap
if [ -f "$CONFIG_DIR/groups.yaml" ]; then
  cat > "$OUTPUT_DIR/groups-configmap.yaml" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: homeassistant-groups
data:
  groups.yaml: |
EOF
  # Indent and append the file content
  sed 's/^/    /' "$CONFIG_DIR/groups.yaml" >> "$OUTPUT_DIR/groups-configmap.yaml"
  echo "  ✓ Groups ConfigMap generated"
else
  echo "  ⚠ Skipping groups (groups.yaml not found)"
fi
echo ""

# Generate helpers ConfigMaps (requires Jinja2 generation first)
if [ -d "$CONFIG_DIR/helpers" ]; then
  echo "Generating helpers (requires jinja2-cli)..."
  
  # First, generate the helper YAML files from templates
  if [ -f "$CONFIG_DIR/helpers/generate_helpers.sh" ]; then
    cd "$CONFIG_DIR/helpers"
    bash generate_helpers.sh
    cd "$SCRIPT_DIR"
  else
    echo "  ⚠ Warning: generate_helpers.sh not found, skipping helpers generation"
  fi
  
  # Now generate ConfigMaps from the generated helper files
  HELPERS_GENERATED="$CONFIG_DIR/helpers/generated"
  
  if [ -d "$HELPERS_GENERATED/input_boolean" ]; then
    generate_configmap "homeassistant-helpers-input-boolean" "$HELPERS_GENERATED/input_boolean" "$OUTPUT_DIR/helpers-input-boolean-configmap.yaml"
    echo "  ✓ Helpers input_boolean ConfigMap generated"
  fi
  
  if [ -d "$HELPERS_GENERATED/input_datetime" ]; then
    generate_configmap "homeassistant-helpers-input-datetime" "$HELPERS_GENERATED/input_datetime" "$OUTPUT_DIR/helpers-input-datetime-configmap.yaml"
    echo "  ✓ Helpers input_datetime ConfigMap generated"
  fi
  
  if [ -d "$HELPERS_GENERATED/input_select" ]; then
    generate_configmap "homeassistant-helpers-input-select" "$HELPERS_GENERATED/input_select" "$OUTPUT_DIR/helpers-input-select-configmap.yaml"
    echo "  ✓ Helpers input_select ConfigMap generated"
  fi
  
  if [ -d "$HELPERS_GENERATED/input_number" ]; then
    generate_configmap "homeassistant-helpers-input-number" "$HELPERS_GENERATED/input_number" "$OUTPUT_DIR/helpers-input-number-configmap.yaml"
    echo "  ✓ Helpers input_number ConfigMap generated"
  fi
  
  if [ -d "$HELPERS_GENERATED/input_text" ]; then
    generate_configmap "homeassistant-helpers-input-text" "$HELPERS_GENERATED/input_text" "$OUTPUT_DIR/helpers-input-text-configmap.yaml"
    echo "  ✓ Helpers input_text ConfigMap generated"
  fi
else
  echo "  ⚠ Skipping helpers (directory not found)"
fi
echo ""

echo "=========================================="
echo "ConfigMap generation complete!"
echo "=========================================="
echo "All ConfigMaps written to: $OUTPUT_DIR"
echo ""

# Function to validate configuration using Home Assistant Docker image
validate_config() {
  echo "=========================================="
  echo "Validating Home Assistant Configuration"
  echo "=========================================="
  
  if ! command -v docker &> /dev/null; then
    echo "  ⚠ Docker not found, skipping validation."
    return 0
  fi

  echo "  Setting up temporary validation environment..."
  VDIR=$(mktemp -d)
  
  # 1. Create HA directory structure
  mkdir -p "$VDIR/automations"
  mkdir -p "$VDIR/scripts"
  mkdir -p "$VDIR/blueprints/automation/_defaults"
  mkdir -p "$VDIR/dashboards/views"
  mkdir -p "$VDIR/helpers/input_boolean"
  mkdir -p "$VDIR/helpers/input_datetime"
  mkdir -p "$VDIR/helpers/input_select"
  mkdir -p "$VDIR/helpers/input_number"
  mkdir -p "$VDIR/helpers/input_text"
  mkdir -p "$VDIR/packages"
  mkdir -p "$VDIR/themes"

  # 2. Copy source files into HA structure
  [ -d "$CONFIG_DIR/automations" ] && cp -r "$CONFIG_DIR/automations"/* "$VDIR/automations/" 2>/dev/null || true
  [ -d "$CONFIG_DIR/scripts" ] && cp -r "$CONFIG_DIR/scripts"/* "$VDIR/scripts/" 2>/dev/null || true
  [ -d "$CONFIG_DIR/blueprints/automation" ] && cp -r "$CONFIG_DIR/blueprints/automation"/* "$VDIR/blueprints/automation/_defaults/" 2>/dev/null || true
  [ -d "$CONFIG_DIR/dashboards" ] && cp -r "$CONFIG_DIR/dashboards"/* "$VDIR/dashboards/views/" 2>/dev/null || true
  
  HELPERS_GENERATED="$CONFIG_DIR/helpers/generated"
  if [ -d "$HELPERS_GENERATED" ]; then
    [ -d "$HELPERS_GENERATED/input_boolean" ] && cp -r "$HELPERS_GENERATED/input_boolean"/* "$VDIR/helpers/input_boolean/" 2>/dev/null || true
    [ -d "$HELPERS_GENERATED/input_datetime" ] && cp -r "$HELPERS_GENERATED/input_datetime"/* "$VDIR/helpers/input_datetime/" 2>/dev/null || true
    [ -d "$HELPERS_GENERATED/input_select" ] && cp -r "$HELPERS_GENERATED/input_select"/* "$VDIR/helpers/input_select/" 2>/dev/null || true
    [ -d "$HELPERS_GENERATED/input_number" ] && cp -r "$HELPERS_GENERATED/input_number"/* "$VDIR/helpers/input_number/" 2>/dev/null || true
    [ -d "$HELPERS_GENERATED/input_text" ] && cp -r "$HELPERS_GENERATED/input_text"/* "$VDIR/helpers/input_text/" 2>/dev/null || true
  fi

  # 3. Seed required UI files
  echo "[]" > "$VDIR/automations.yaml"
  echo "[]" > "$VDIR/scenes.yaml"
  echo "{}" > "$VDIR/scripts.yaml"
  [ -f "$CONFIG_DIR/groups.yaml" ] && cp "$CONFIG_DIR/groups.yaml" "$VDIR/groups.yaml" || echo "{}" > "$VDIR/groups.yaml"

  # 4. Generate configuration.yaml (matches deployment.yaml logic)
  cat > "$VDIR/configuration.yaml" << 'EOF'
default_config: {}
frontend:
  themes: !include_dir_merge_named themes
automation: !include automations.yaml
automation manual: !include_dir_list automations
scene: !include scenes.yaml
group: !include groups.yaml
script: !include_dir_merge_named scripts
input_boolean:  !include_dir_merge_named helpers/input_boolean/
input_datetime: !include_dir_merge_named helpers/input_datetime/
input_select:   !include_dir_merge_named helpers/input_select/
input_number:   !include_dir_merge_named helpers/input_number/
input_text:     !include_dir_merge_named helpers/input_text/
homeassistant:
  packages: !include_dir_named packages
scheduler: {}
EOF

  # 5. Run HA config check via Docker
  echo "  Running Home Assistant config check..."
  if docker run --rm -v "$VDIR:/config" ghcr.io/home-assistant/home-assistant:stable python3 -m homeassistant --script check_config --config /config; then
    echo ""
    echo "  ✓ Configuration validation passed!"
    echo ""
    rm -rf "$VDIR"
    return 0
  else
    echo ""
    echo "  ✖ Configuration validation failed!"
    echo ""
    rm -rf "$VDIR"
    exit 1
  fi
}

# Run validation
validate_config
