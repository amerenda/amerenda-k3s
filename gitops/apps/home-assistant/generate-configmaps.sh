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

# Function to generate schedule ConfigMap with all room entities
generate_schedule_configmap() {
    local output_file="schedule-configmap.yaml"
    local config_dir="config"
    
    print_status "Generating unified schedule configuration ConfigMap..."
    
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
  schedule_entities.yaml: |
    # Unified Schedule Entities for All Rooms
    # This file contains all schedule input entities for all rooms
    
    input_boolean:
      # Global schedule control
      global_schedule_enabled:
        name: "Global Schedule Enabled"
        icon: mdi:home-clock-outline
        initial: true
      
      # Room-specific schedule controls
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

    # Generate datetime inputs for all rooms using a more efficient approach
    local rooms=("living_room" "kitchen" "bedroom" "bathroom" "hallway")
    local room_icons=("mdi:sofa" "mdi:chef-hat" "mdi:bed" "mdi:shower" "mdi:corridor")
    
    # Default schedule values from default_schedule.yaml
    local default_times=("06:00" "09:00" "17:00" "21:00" "23:00")
    local default_end_times=("09:00" "17:00" "21:00" "23:00" "06:00")
    local period_names=("Morning" "Day" "Evening" "Night" "Late Night")
    local period_icons=("mdi:weather-sunrise" "mdi:weather-sunny" "mdi:weather-sunset" "mdi:weather-night" "mdi:weather-sunrise")
    
    # Generate all datetime inputs in one loop
    for i in "${!rooms[@]}"; do
        local room="${rooms[$i]}"
        for j in {1..5}; do
            local period_name="${period_names[$((j-1))]}"
            local period_icon="${period_icons[$((j-1))]}"
            local start_time="${default_times[$((j-1))]}"
            local end_time="${default_end_times[$((j-1))]}"
            
            cat >> "$output_file" << EOF
      ${room}_schedule_${j}_start:
        name: "${room^} ${period_name} Start"
        icon: ${period_icon}
        has_time: true
        has_date: false
        initial: "${start_time}"
      ${room}_schedule_${j}_end:
        name: "${room^} ${period_name} End"
        icon: ${period_icon}
        has_time: true
        has_date: false
        initial: "${end_time}"
EOF
        done
    done

    cat >> "$output_file" << EOF

    input_select:
      # Room selector for dashboard
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

    # Generate select inputs for all rooms
    local default_scenes=("energize" "concentrate" "relax" "nightlight" "nightlight")
    local default_scene="relax"
    local scene_options=("energize" "concentrate" "relax" "nightlight" "read" "dimmed")
    
    # Add input_text section header
    cat >> "$output_file" << EOF

input_text:
EOF
    
    # Define switches per room (room_name: switch1,switch2,...)
    declare -A room_switches
    room_switches["living_room"]="main_switch"
    room_switches["kitchen"]="main_switch"
    room_switches["bedroom"]="main_switch"
    room_switches["bathroom"]="main_switch"
    room_switches["hallway"]="main_switch,secondary_switch"
    
    for i in "${!rooms[@]}"; do
        local room="${rooms[$i]}"
        local icon="${room_icons[$i]}"
        local switches="${room_switches[$room]}"
        
        # Generate scene selects for each schedule period
        for j in {1..5}; do
            local period_name="${period_names[$((j-1))]}"
            local period_icon="${period_icons[$((j-1))]}"
            local scene="${default_scenes[$((j-1))]}"
            
            cat >> "$output_file" << EOF
      ${room}_schedule_${j}_scene:
        name: "${room^} ${period_name} Scene"
        icon: ${period_icon}
        options:
EOF
            for option in "${scene_options[@]}"; do
                echo "          - \"${option}\"" >> "$output_file"
            done
            echo "          - \"custom\"" >> "$output_file"
            cat >> "$output_file" << EOF
        initial: "${scene}"
EOF
        done
        
        # Generate custom scene text inputs
        for j in {1..5}; do
            local period_name="${period_names[$((j-1))]}"
            local period_icon="${period_icons[$((j-1))]}"
            
            cat >> "$output_file" << EOF
  ${room}_schedule_${j}_custom_scene:
    name: "${room^} ${period_name} Custom Scene"
    icon: ${period_icon}
    initial: ""
EOF
        done
        
        # Generate default scene select
        cat >> "$output_file" << EOF
      ${room}_default_scene:
        name: "${room^} Default Scene"
        icon: ${icon}
        options:
EOF
        for option in "${scene_options[@]}"; do
            echo "          - \"${option}\"" >> "$output_file"
        done
        echo "          - \"custom\"" >> "$output_file"
        cat >> "$output_file" << EOF
        initial: "${default_scene}"
EOF
        
        # Generate default custom scene text input
        cat >> "$output_file" << EOF
  ${room}_default_custom_scene:
    name: "${room^} Default Custom Scene"
    icon: ${icon}
    initial: ""
EOF
        
        # Generate switch configuration entities (no individual room switch selectors - using global one)
        # Create switch array from switches string
        IFS=',' read -ra switch_array <<< "$switches"
        
        cat >> "$output_file" << EOF
      ${room}_switch_brightness_step:
        name: "${room^} Brightness Step"
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
      ${room}_switch_min_brightness:
        name: "${room^} Min Brightness"
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
      ${room}_switch_max_brightness:
        name: "${room^} Max Brightness"
        icon: mdi:brightness-7
        options:
          - "200"
          - "220"
          - "240"
          - "255"
        initial: "255"
      ${room}_button_1_short:
        name: "${room^} Button 1 Short Press"
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
      ${room}_button_1_long:
        name: "${room^} Button 1 Long Press"
        icon: mdi:lightbulb-off
        options:
          - "all_lights_off"
          - "room_lights_off"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
          - "color_cycle"
        initial: "all_lights_off"
      ${room}_button_2_short:
        name: "${room^} Button 2 Short Press"
        icon: mdi:brightness-7
        options:
          - "brightness_up"
          - "brightness_down"
          - "toggle_lights"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
        initial: "brightness_up"
      ${room}_button_3_short:
        name: "${room^} Button 3 Short Press"
        icon: mdi:brightness-1
        options:
          - "brightness_up"
          - "brightness_down"
          - "toggle_lights"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
        initial: "brightness_down"
      ${room}_button_4_short:
        name: "${room^} Button 4 Short Press"
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
      ${room}_button_4_long:
        name: "${room^} Button 4 Long Press"
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
EOF
        
        # Generate entities for additional switches (if any)
        if [ ${#switch_array[@]} -gt 1 ]; then
            for switch_idx in $(seq 1 $((${#switch_array[@]}-1))); do
                local switch="${switch_array[$switch_idx]}"
                local switch_num=$((switch_idx + 1))
                
                cat >> "$output_file" << EOF
      ${room}_${switch_num}_switch_brightness_step:
        name: "${room^} ${switch^} Brightness Step"
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
      ${room}_${switch_num}_switch_min_brightness:
        name: "${room^} ${switch^} Min Brightness"
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
      ${room}_${switch_num}_switch_max_brightness:
        name: "${room^} ${switch^} Max Brightness"
        icon: mdi:brightness-7
        options:
          - "200"
          - "220"
          - "240"
          - "255"
        initial: "255"
      ${room}_${switch_num}_button_1_short:
        name: "${room^} ${switch^} Button 1 Short Press"
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
      ${room}_${switch_num}_button_1_long:
        name: "${room^} ${switch^} Button 1 Long Press"
        icon: mdi:lightbulb-off
        options:
          - "all_lights_off"
          - "room_lights_off"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
          - "color_cycle"
        initial: "all_lights_off"
      ${room}_${switch_num}_button_2_short:
        name: "${room^} ${switch^} Button 2 Short Press"
        icon: mdi:brightness-7
        options:
          - "brightness_up"
          - "brightness_down"
          - "toggle_lights"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
        initial: "brightness_up"
      ${room}_${switch_num}_button_3_short:
        name: "${room^} ${switch^} Button 3 Short Press"
        icon: mdi:brightness-1
        options:
          - "brightness_up"
          - "brightness_down"
          - "toggle_lights"
          - "scene_cycle"
          - "scene_next"
          - "scene_previous"
        initial: "brightness_down"
      ${room}_${switch_num}_button_4_short:
        name: "${room^} ${switch^} Button 4 Short Press"
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
      ${room}_${switch_num}_button_4_long:
        name: "${room^} ${switch^} Button 4 Long Press"
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
EOF
            done
        fi
    done

    # Add other config files
    if [ -d "$config_dir" ]; then
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
    fi
    
    print_success "Unified schedule ConfigMap generated: $output_file"
}

# Function to generate room-specific ConfigMap (overrides only)
generate_room_configmap() {
    local room_name="$1"
    local overrides_file="$2"
    local output_file="${room_name}-configmap.yaml"
    
    if [ -z "$room_name" ]; then
        print_error "Room name is required for room ConfigMap generation"
        return 1
    fi
    
    print_status "Generating ${room_name} overrides ConfigMap..."
    
    # Create a simple overrides ConfigMap
    cat > "$output_file" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ha-${room_name}-overrides
  namespace: $NAMESPACE
  annotations:
    reloader.stakater.com/auto: "true"
data:
  ${room_name}_overrides.yaml: |
    # ${room_name^} Schedule Overrides
    # This file contains room-specific overrides for the default schedule
    # Only include values that differ from the default schedule
    
    room_overrides:
      ${room_name}:
        # Add room-specific overrides here
        # Example:
        # schedule_1:
        #   start_time: "05:30"
        #   end_time: "08:30"
        #   scene_suffix: "energize"
EOF
    
    print_success "Room overrides ConfigMap generated: $output_file"
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
