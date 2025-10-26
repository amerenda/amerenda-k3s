#!/bin/bash

# Unified script to generate all ConfigMaps for Home Assistant
# Usage: ./generate-configmaps.sh [room_name] [overrides_file]

set -e

ROOM_NAME="$1"
OVERRIDES_FILE="$2"
NAMESPACE="home-assistant"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to generate room schedule configuration
generate_room_schedule() {
    local room_name="$1"
    local overrides_file="$2"
    
    if [ -z "$room_name" ]; then
        print_error "Room name is required for room schedule generation"
        return 1
    fi
    
    print_status "Generating schedule for room: $room_name" >&2
    
    # Default schedule configuration
    local default_schedule='{
      "schedule_1": {"start_time": "06:00", "end_time": "09:00", "scene_suffix": "energize"},
      "schedule_2": {"start_time": "09:00", "end_time": "17:00", "scene_suffix": "concentrate"},
      "schedule_3": {"start_time": "17:00", "end_time": "21:00", "scene_suffix": "relax"},
      "schedule_4": {"start_time": "21:00", "end_time": "23:00", "scene_suffix": "nightlight"},
      "schedule_5": {"start_time": "23:00", "end_time": "06:00", "scene_suffix": "nightlight"},
      "default_scene_suffix": "relax"
    }'
    
    # Room-specific icons
    declare -A room_icons=(
        ["living_room"]="mdi:sofa"
        ["kitchen"]="mdi:chef-hat"
        ["bedroom"]="mdi:bed"
        ["bathroom"]="mdi:shower"
        ["hallway"]="mdi:corridor"
        ["office"]="mdi:desk"
        ["dining_room"]="mdi:table-chair"
    )
    
    local room_icon="${room_icons[$room_name]:-mdi:home}"
    
    # Function to get schedule value with override support
    get_schedule_value() {
        local schedule_key="$1"
        local value_key="$2"
        local default_value="$3"
        
        if [ -n "$overrides_file" ] && [ -f "$overrides_file" ]; then
            local override_value=$(awk "
                /^room_overrides:/ { in_room_overrides=1; next }
                in_room_overrides && /^  $room_name:/ { in_room=1; next }
                in_room && /^  [a-zA-Z]/ && !/^  $room_name:/ { in_room=0; next }
                in_room && /^    $schedule_key:/ { in_schedule=1; next }
                in_schedule && /^    [a-zA-Z]/ && !/^    $schedule_key:/ { in_schedule=0; next }
                in_schedule && /^      $value_key:/ { 
                    gsub(/^[[:space:]]*$value_key:[[:space:]]*/, \"\")
                    gsub(/[[:space:]]*#.*$/, \"\")  # Remove comments
                    gsub(/[[:space:]]*$/, \"\")
                    gsub(/^\"|\"$/, \"\")
                    print
                    exit
                }
            " "$overrides_file")
            
            if [ -n "$override_value" ]; then
                echo "$override_value"
                return
            fi
        fi
        
        echo "$default_value"
    }
    
    # Generate the room schedule configuration
    cat << EOF
# ${room_name^} Schedule Configuration
# Generated from default schedule with room-specific overrides
input_boolean:
  ${room_name}_schedule_enabled:
    name: "${room_name^} Schedule Enabled"
    icon: ${room_icon}
    initial: true

input_datetime:
EOF

    # Generate datetime inputs for each schedule
    for i in {1..5}; do
        local start_time=$(get_schedule_value "schedule_${i}" "start_time" "$(echo "$default_schedule" | jq -r ".schedule_${i}.start_time")")
        local end_time=$(get_schedule_value "schedule_${i}" "end_time" "$(echo "$default_schedule" | jq -r ".schedule_${i}.end_time")")
        
        # Map schedule numbers to names
        case $i in
            1) period_name="Morning" ;;
            2) period_name="Day" ;;
            3) period_name="Evening" ;;
            4) period_name="Night" ;;
            5) period_name="Late Night" ;;
        esac
        
        # Map schedule numbers to icons
        case $i in
            1) period_icon="mdi:weather-sunrise" ;;
            2) period_icon="mdi:weather-sunny" ;;
            3) period_icon="mdi:weather-sunset" ;;
            4) period_icon="mdi:weather-night" ;;
            5) period_icon="mdi:weather-sunrise" ;;
        esac
        
        cat << EOF
  ${room_name}_schedule_${i}_start:
    name: "${room_name^} ${period_name} Start"
    icon: ${period_icon}
    has_time: true
    has_date: false
    initial: "${start_time}"  # Default: ${start_time}
  ${room_name}_schedule_${i}_end:
    name: "${room_name^} ${period_name} End"
    icon: ${period_icon}
    has_time: true
    has_date: false
    initial: "${end_time}"  # Default: ${end_time}
EOF
    done

    cat << EOF

input_select:
EOF

    # Generate select inputs for each schedule
    for i in {1..5}; do
        local scene_suffix=$(get_schedule_value "schedule_${i}" "scene_suffix" "$(echo "$default_schedule" | jq -r ".schedule_${i}.scene_suffix")")
        
        # Map schedule numbers to names
        case $i in
            1) period_name="Morning" ;;
            2) period_name="Day" ;;
            3) period_name="Evening" ;;
            4) period_name="Night" ;;
            5) period_name="Late Night" ;;
        esac
        
        # Map schedule numbers to icons
        case $i in
            1) period_icon="mdi:weather-sunrise" ;;
            2) period_icon="mdi:weather-sunny" ;;
            3) period_icon="mdi:weather-sunset" ;;
            4) period_icon="mdi:weather-night" ;;
            5) period_icon="mdi:weather-sunrise" ;;
        esac
        
        cat << EOF
  ${room_name}_schedule_${i}_scene:
    name: "${room_name^} ${period_name} Scene"
    icon: ${period_icon}
    options:
      - "energize"
      - "concentrate"
      - "relax"
      - "nightlight"
      - "read"
      - "dimmed"
    initial: "${scene_suffix}"  # Default: ${scene_suffix}
EOF
    done

    # Generate default scene
    local default_scene=$(get_schedule_value "default_scene_suffix" "scene_suffix" "$(echo "$default_schedule" | jq -r ".default_scene_suffix")")

    cat << EOF
  ${room_name}_default_scene:
    name: "${room_name^} Default Scene"
    icon: ${room_icon}
    options:
      - "energize"
      - "concentrate"
      - "relax"
      - "nightlight"
      - "read"
      - "dimmed"
    initial: "${default_scene}"  # Default: ${default_scene}
EOF
}

# Function to generate automations ConfigMap
generate_automations_configmap() {
    local output_file="automations-configmap.yaml"
    local automations_dir="automations"
    
    print_status "Generating automations ConfigMap..."
    
    # Start the ConfigMap YAML
    cat > "$output_file" << EOF
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
    for file in "$automations_dir"/*.yaml; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            print_status "Processing automation: $filename"
            
            # Add the file to the ConfigMap
            echo "  $filename: |" >> "$output_file"
            
            # Add the content with proper indentation
            sed 's/^/    /' "$file" >> "$output_file"
            
            # Add a blank line between files
            echo "" >> "$output_file"
        fi
    done
    
    print_success "Automations ConfigMap generated: $output_file"
}

# Function to generate blueprints ConfigMap
generate_blueprints_configmap() {
    local output_file="blueprints-configmap.yaml"
    local blueprints_dir="blueprints"
    
    if [ -d "$blueprints_dir" ]; then
        print_status "Generating blueprints ConfigMap..."
        
        # Start the blueprints ConfigMap YAML
        cat > "$output_file" << EOF
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
        find "$blueprints_dir" -name "*.yaml" -type f | while read -r file; do
            local filename=$(basename "$file")
            print_status "Processing blueprint: $filename"
            
            # Add the file to the ConfigMap
            echo "  $filename: |" >> "$output_file"
            
            # Add the content with proper indentation
            sed 's/^/    /' "$file" >> "$output_file"
            
            # Add a blank line between files
            echo "" >> "$output_file"
        done
        
        print_success "Blueprints ConfigMap generated: $output_file"
    else
        print_warning "No blueprints directory found, skipping blueprints ConfigMap"
    fi
}

# Function to generate schedule ConfigMap
generate_schedule_configmap() {
    local output_file="schedule-configmap.yaml"
    local config_dir="config"
    
    if [ -d "$config_dir" ]; then
        print_status "Generating schedule configuration ConfigMap..."
        
        # Start the schedule ConfigMap YAML
        cat > "$output_file" << EOF
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
        find "$config_dir" -name "*.yaml" -type f | grep -v -E "(schedule_inputs\.yaml|schedule_input_.*\.yaml|schedule_config\.yaml|room_schedule_.*\.yaml|temp_.*\.yaml|living_room_schedule\.yaml)" | while read -r file; do
            local filename=$(basename "$file")
            print_status "Processing config: $filename"
            
            # Add the file to the ConfigMap
            echo "  $filename: |" >> "$output_file"
            
            # Add the content with proper indentation
            sed 's/^/    /' "$file" >> "$output_file"
            
            # Add a blank line between files
            echo "" >> "$output_file"
        done
        
        print_success "Schedule ConfigMap generated: $output_file"
    else
        print_warning "No config directory found, skipping schedule ConfigMap"
    fi
}

# Function to generate room-specific ConfigMap
generate_room_configmap() {
    local room_name="$1"
    local overrides_file="$2"
    local output_file="${room_name}-configmap.yaml"
    
    if [ -z "$room_name" ]; then
        print_error "Room name is required for room ConfigMap generation"
        return 1
    fi
    
    print_status "Generating ${room_name} ConfigMap..."
    
    # Generate room schedule configuration
    local room_config=$(generate_room_schedule "$room_name" "$overrides_file")
    
    # Create the ConfigMap
    cat > "$output_file" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ha-${room_name}-config
  namespace: $NAMESPACE
  annotations:
    reloader.stakater.com/auto: "true"
data:
  ${room_name}_schedule.yaml: |
$(echo "$room_config" | sed 's/^/    /')
EOF
    
    print_success "Room ConfigMap generated: $output_file"
}

# Main execution
main() {
    print_status "Starting ConfigMap generation..."
    
    # Generate all standard ConfigMaps
    generate_automations_configmap
    generate_blueprints_configmap
    generate_schedule_configmap
    
    # Generate room-specific ConfigMap if room name provided
    if [ -n "$ROOM_NAME" ]; then
        generate_room_configmap "$ROOM_NAME" "$OVERRIDES_FILE"
    fi
    
    print_success "All ConfigMaps generated successfully!"
    print_status "To apply: commit the changes and push to the repository"
    print_status "Or apply directly with: kubectl apply -f *.yaml"
}

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [room_name] [overrides_file]"
    echo ""
    echo "Generate all Home Assistant ConfigMaps"
    echo ""
    echo "Arguments:"
    echo "  room_name      Generate room-specific ConfigMap (optional)"
    echo "  overrides_file Path to room overrides file (optional, requires room_name)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Generate all standard ConfigMaps"
    echo "  $0 kitchen                           # Generate kitchen ConfigMap with defaults"
    echo "  $0 bedroom config/room_overrides.yaml # Generate bedroom ConfigMap with overrides"
    echo ""
    echo "Generated ConfigMaps:"
    echo "  - automations-configmap.yaml         # Automation files"
    echo "  - blueprints-configmap.yaml          # Blueprint files"
    echo "  - schedule-configmap.yaml            # Schedule configuration files"
    echo "  - {room}-configmap.yaml              # Room-specific schedule (if room_name provided)"
    exit 0
fi

# Run main function
main
