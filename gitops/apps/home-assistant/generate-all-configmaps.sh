#!/bin/bash

# Unified script to generate all Home Assistant ConfigMaps
# This approach reads from config files and applies room overrides

set -e

NAMESPACE="home-assistant"
CONFIG_DIR="config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to get schedule value with override support
get_schedule_value() {
    local room_name="$1"
    local schedule_key="$2"
    local value_key="$3"
    local default_value="$4"
    
    # Check for room override first
    if [ -f "$CONFIG_DIR/room_overrides.yaml" ]; then
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
        " "$CONFIG_DIR/room_overrides.yaml")
        
        if [ -n "$override_value" ]; then
            echo "$override_value"
            return
        fi
    fi
    
    # Fall back to default schedule
    if [ -f "$CONFIG_DIR/default_schedule.yaml" ]; then
        local default_value_from_file=$(awk "
            /^default_schedule:/ { in_default_schedule=1; next }
            in_default_schedule && /^  $schedule_key:/ { in_schedule=1; next }
            in_schedule && /^  [a-zA-Z]/ && !/^  $schedule_key:/ { in_schedule=0; next }
            in_schedule && /^    $value_key:/ { 
                gsub(/^[[:space:]]*$value_key:[[:space:]]*/, \"\")
                gsub(/[[:space:]]*#.*$/, \"\")  # Remove comments
                gsub(/[[:space:]]*$/, \"\")
                gsub(/^\"|\"$/, \"\")
                print
                exit
            }
        " "$CONFIG_DIR/default_schedule.yaml")
        
        if [ -n "$default_value_from_file" ]; then
            echo "$default_value_from_file"
            return
        fi
    fi
    
    # Final fallback to hardcoded default
    echo "$default_value"
}

# Function to generate automations ConfigMap
generate_automations_configmap() {
    local output_file="automations-configmap.yaml"
    local automations_dir="automations"
    
    print_status "Generating automations ConfigMap..."
    
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
            
            echo "  $filename: |" >> "$output_file"
            sed 's/^/    /' "$file" >> "$output_file"
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
            
            echo "  $filename: |" >> "$output_file"
            sed 's/^/    /' "$file" >> "$output_file"
            echo "" >> "$output_file"
        done
        
        print_success "Blueprints ConfigMap generated: $output_file"
    else
        print_warning "No blueprints directory found, skipping blueprints ConfigMap"
    fi
}

# Function to generate schedule ConfigMap with config file support
generate_schedule_configmap() {
    local output_file="schedule-configmap.yaml"
    
    print_status "Generating schedule configuration ConfigMap with config file support..."
    
    # Check if config files exist
    if [ ! -f "$CONFIG_DIR/default_schedule.yaml" ]; then
        print_error "Default schedule config file not found: $CONFIG_DIR/default_schedule.yaml"
        return 1
    fi
    
    print_status "Reading schedule configuration from config files..."
    
    cat > "$output_file" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: ha-schedule-config
  namespace: home-assistant
  annotations:
    reloader.stakater.com/auto: "true"
data:
  schedule_entities.yaml: |
    # Schedule Configuration with Config File Support
    # Generated from default_schedule.yaml with room-specific overrides from room_overrides.yaml
    
    input_boolean:
      global_schedule_enabled:
        name: "Global Schedule Enabled"
        icon: mdi:home-clock-outline
        initial: true
      living_room_schedule_enabled:
        name: "Living Room Schedule Enabled"
        icon: mdi:sofa
        initial: true
      kitchen_schedule_enabled:
        name: "Kitchen Schedule Enabled"
        icon: mdi:chef-hat
        initial: true
      bedroom_schedule_enabled:
        name: "Bedroom Schedule Enabled"
        icon: mdi:bed
        initial: true
      bathroom_schedule_enabled:
        name: "Bathroom Schedule Enabled"
        icon: mdi:shower
        initial: true
      hallway_schedule_enabled:
        name: "Hallway Schedule Enabled"
        icon: mdi:corridor
        initial: true
    
    input_datetime:
EOF

    # Generate datetime inputs for all rooms using config files
    local rooms=("living_room" "kitchen" "bedroom" "bathroom" "hallway")
    local room_icons=("mdi:sofa" "mdi:chef-hat" "mdi:bed" "mdi:shower" "mdi:corridor")
    local period_names=("Morning" "Day" "Evening" "Night" "Late Night")
    local period_icons=("mdi:weather-sunrise" "mdi:weather-sunny" "mdi:weather-sunset" "mdi:weather-night" "mdi:weather-sunrise")
    
    for i in "${!rooms[@]}"; do
        local room="${rooms[$i]}"
        print_status "Generating schedule for room: $room"
        
        for j in {1..5}; do
            local period_name="${period_names[$((j-1))]}"
            local period_icon="${period_icons[$((j-1))]}"
            
            # Get start and end times from config files
            local start_time=$(get_schedule_value "$room" "schedule_${j}" "start_time" "06:00")
            local end_time=$(get_schedule_value "$room" "schedule_${j}" "end_time" "09:00")
            
            cat >> "$output_file" << EOF
      ${room}_schedule_${j}_start:
        name: "${room^} ${period_name} Start"
        icon: ${period_icon}
        has_time: true
        has_date: false
        initial: "${start_time}"
        restore_value: true
      ${room}_schedule_${j}_end:
        name: "${room^} ${period_name} End"
        icon: ${period_icon}
        has_time: true
        has_date: false
        initial: "${end_time}"
        restore_value: true
EOF
        done
    done

    cat >> "$output_file" << EOF

    input_select:
      room_schedule_selector:
        name: "Select Room to Configure"
        icon: mdi:home-edit
        options:
          - "living_room"
          - "kitchen"
          - "bedroom"
          - "bathroom"
          - "hallway"
        initial: "living_room"
      
EOF

    # Generate select inputs for all rooms using config files
    for i in "${!rooms[@]}"; do
        local room="${rooms[$i]}"
        local icon="${room_icons[$i]}"
        
        # Generate scene selects for each schedule period
        for j in {1..5}; do
            local period_name="${period_names[$((j-1))]}"
            local period_icon="${period_icons[$((j-1))]}"
            
            # Get scene from config files
            local scene=$(get_schedule_value "$room" "schedule_${j}" "scene_suffix" "energize")
            
            cat >> "$output_file" << EOF
      ${room}_schedule_${j}_scene:
        name: "${room^} ${period_name} Scene"
        icon: ${period_icon}
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "${scene}"
        restore_value: true
EOF
        done
        
        # Generate default scene select
        local default_scene=$(get_schedule_value "$room" "default_scene_suffix" "scene_suffix" "relax")
        
        cat >> "$output_file" << EOF
      ${room}_default_scene:
        name: "${room^} Default Scene"
        icon: ${icon}
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "${default_scene}"
        restore_value: true
EOF
    done

    # Add switch configuration (simplified - only for living room and hallway)
    cat >> "$output_file" << EOF
      
      # Switch Configuration
      living_room_switch_brightness_step:
        name: "Living Room Brightness Step"
        icon: mdi:brightness-6
        options:
          - "10"
          - "15"
          - "20"
          - "25"
          - "30"
          - "35"
          - "40"
          - "50"
        initial: "25"
      living_room_switch_min_brightness:
        name: "Living Room Min Brightness"
        icon: mdi:brightness-1
        options:
          - "1"
          - "5"
          - "10"
          - "15"
          - "20"
          - "25"
          - "30"
        initial: "1"
      living_room_switch_max_brightness:
        name: "Living Room Max Brightness"
        icon: mdi:brightness-7
        options:
          - "200"
          - "220"
          - "240"
          - "255"
        initial: "255"
      living_room_button_1_short:
        name: "Living Room Button 1 Short Press"
        icon: mdi:lightbulb-on
        options:
          - "toggle_lights"
          - "turn_on_lights"
          - "turn_off_lights"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
          - "color_cycle"
        initial: "toggle_lights"
      living_room_button_1_long:
        name: "Living Room Button 1 Long Press"
        icon: mdi:lightbulb-off
        options:
          - "all_lights_off"
          - "room_lights_off"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
          - "color_cycle"
        initial: "all_lights_off"
      living_room_button_2_short:
        name: "Living Room Button 2 Short Press"
        icon: mdi:brightness-7
        options:
          - "brightness_up"
          - "brightness_down"
          - "toggle_lights"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
        initial: "brightness_up"
      living_room_button_3_short:
        name: "Living Room Button 3 Short Press"
        icon: mdi:brightness-1
        options:
          - "brightness_up"
          - "brightness_down"
          - "toggle_lights"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
        initial: "brightness_down"
      living_room_button_4_short:
        name: "Living Room Button 4 Short Press"
        icon: mdi:palette
        options:
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
          - "color_cycle"
          - "toggle_lights"
          - "brightness_up"
          - "brightness_down"
        initial: "scene_cycle"
      living_room_button_4_long:
        name: "Living Room Button 4 Long Press"
        icon: mdi:palette-outline
        options:
          - "room_relax_scene"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
          - "color_cycle"
          - "all_lights_off"
          - "room_lights_off"
        initial: "room_relax_scene"
      
      # Hallway Secondary Switch
      hallway_2_switch_brightness_step:
        name: "Hallway Secondary Brightness Step"
        icon: mdi:brightness-6
        options:
          - "10"
          - "15"
          - "20"
          - "25"
          - "30"
          - "35"
          - "40"
          - "50"
        initial: "25"
      hallway_2_switch_min_brightness:
        name: "Hallway Secondary Min Brightness"
        icon: mdi:brightness-1
        options:
          - "1"
          - "5"
          - "10"
          - "15"
          - "20"
          - "25"
          - "30"
        initial: "1"
      hallway_2_switch_max_brightness:
        name: "Hallway Secondary Max Brightness"
        icon: mdi:brightness-7
        options:
          - "200"
          - "220"
          - "240"
          - "255"
        initial: "255"
      hallway_2_button_1_short:
        name: "Hallway Secondary Button 1 Short Press"
        icon: mdi:lightbulb-on
        options:
          - "toggle_lights"
          - "turn_on_lights"
          - "turn_off_lights"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
          - "color_cycle"
        initial: "toggle_lights"
      hallway_2_button_1_long:
        name: "Hallway Secondary Button 1 Long Press"
        icon: mdi:lightbulb-off
        options:
          - "all_lights_off"
          - "room_lights_off"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
          - "color_cycle"
        initial: "all_lights_off"
      hallway_2_button_2_short:
        name: "Hallway Secondary Button 2 Short Press"
        icon: mdi:brightness-7
        options:
          - "brightness_up"
          - "brightness_down"
          - "toggle_lights"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
        initial: "brightness_up"
      hallway_2_button_3_short:
        name: "Hallway Secondary Button 3 Short Press"
        icon: mdi:brightness-1
        options:
          - "brightness_up"
          - "brightness_down"
          - "toggle_lights"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
        initial: "brightness_down"
      hallway_2_button_4_short:
        name: "Hallway Secondary Button 4 Short Press"
        icon: mdi:palette
        options:
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
          - "color_cycle"
          - "toggle_lights"
          - "brightness_up"
          - "brightness_down"
        initial: "scene_cycle"
      hallway_2_button_4_long:
        name: "Hallway Secondary Button 4 Long Press"
        icon: mdi:palette-outline
        options:
          - "room_relax_scene"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
          - "color_cycle"
          - "all_lights_off"
          - "room_lights_off"
        initial: "room_relax_scene"
    
    input_text:
EOF

    # Generate custom scene text inputs for all rooms
    for i in "${!rooms[@]}"; do
        local room="${rooms[$i]}"
        local icon="${room_icons[$i]}"
        
        # Generate custom scene text inputs for each schedule period
        for j in {1..5}; do
            local period_name="${period_names[$((j-1))]}"
            local period_icon="${period_icons[$((j-1))]}"
            
            cat >> "$output_file" << EOF
      ${room}_schedule_${j}_custom_scene:
        name: "${room^} ${period_name} Custom Scene"
        icon: ${period_icon}
        initial: ""
        restore_value: true
EOF
        done
        
        # Generate default custom scene text input
        cat >> "$output_file" << EOF
      ${room}_default_custom_scene:
        name: "${room^} Default Custom Scene"
        icon: ${icon}
        initial: ""
        restore_value: true
EOF
    done

    # Include the config files in the ConfigMap
    if [ -d "$CONFIG_DIR" ]; then
        find "$CONFIG_DIR" -name "*.yaml" -type f | while read -r file; do
            local filename=$(basename "$file")
            print_status "Including config file: $filename"
            
            echo "  $filename: |" >> "$output_file"
            sed 's/^/    /' "$file" >> "$output_file"
            echo "" >> "$output_file"
        done
    fi
    
    print_success "Schedule ConfigMap generated with config file support: $output_file"
}

# Main execution
main() {
    print_status "Starting unified ConfigMap generation with config file support..."
    
    # Generate all ConfigMaps
    generate_automations_configmap
    generate_blueprints_configmap
    generate_schedule_configmap
    
    print_success "All ConfigMaps generated successfully!"
    print_status "Generated files:"
    print_status "  - automations-configmap.yaml"
    print_status "  - blueprints-configmap.yaml"
    print_status "  - schedule-configmap.yaml"
    print_status ""
    print_status "Schedule configuration now reads from:"
    print_status "  - config/default_schedule.yaml (default values)"
    print_status "  - config/room_overrides.yaml (room-specific overrides)"
    print_status ""
    print_status "To apply: commit the changes and push to the repository"
    print_status "Or apply directly with: kubectl apply -f *.yaml"
}

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0"
    echo ""
    echo "Generate all Home Assistant ConfigMaps with config file support"
    echo "This script reads from default_schedule.yaml and applies room_overrides.yaml"
    echo ""
    echo "Config Files:"
    echo "  - config/default_schedule.yaml    # Default schedule for all rooms"
    echo "  - config/room_overrides.yaml      # Room-specific overrides"
    echo ""
    echo "Generated ConfigMaps:"
    echo "  - automations-configmap.yaml      # Automation files"
    echo "  - blueprints-configmap.yaml       # Blueprint files"
    echo "  - schedule-configmap.yaml         # Schedule configuration files"
    echo ""
    echo "This approach is flexible and maintainable"
    exit 0
fi

# Run main function
main