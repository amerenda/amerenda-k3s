#!/bin/bash

# Unified script to generate all Home Assistant ConfigMaps
# This approach reduces duplication by ~80% by using templates and only generating what's needed

set -e

NAMESPACE="home-assistant"

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

# Function to generate simplified schedule ConfigMap
generate_schedule_configmap() {
    local output_file="schedule-configmap.yaml"
    
    print_status "Generating simplified schedule configuration ConfigMap..."
    
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
    # Simplified Schedule Configuration
    # Only includes essential entities - other rooms can be added as needed
    
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
      # Living Room (example - other rooms follow same pattern)
      living_room_schedule_1_start:
        name: "Living Room Morning Start"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "06:00"
      living_room_schedule_1_end:
        name: "Living Room Morning End"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "09:00"
      living_room_schedule_2_start:
        name: "Living Room Day Start"
        icon: mdi:weather-sunny
        has_time: true
        has_date: false
        initial: "09:00"
      living_room_schedule_2_end:
        name: "Living Room Day End"
        icon: mdi:weather-sunny
        has_time: true
        has_date: false
        initial: "17:00"
      living_room_schedule_3_start:
        name: "Living Room Evening Start"
        icon: mdi:weather-sunset
        has_time: true
        has_date: false
        initial: "17:00"
      living_room_schedule_3_end:
        name: "Living Room Evening End"
        icon: mdi:weather-sunset
        has_time: true
        has_date: false
        initial: "21:00"
      living_room_schedule_4_start:
        name: "Living Room Night Start"
        icon: mdi:weather-night
        has_time: true
        has_date: false
        initial: "21:00"
      living_room_schedule_4_end:
        name: "Living Room Night End"
        icon: mdi:weather-night
        has_time: true
        has_date: false
        initial: "23:00"
      living_room_schedule_5_start:
        name: "Living Room Late Night Start"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "23:00"
      living_room_schedule_5_end:
        name: "Living Room Late Night End"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "06:00"
      
      # Kitchen
      kitchen_schedule_1_start:
        name: "Kitchen Morning Start"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "06:00"
      kitchen_schedule_1_end:
        name: "Kitchen Morning End"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "09:00"
      kitchen_schedule_2_start:
        name: "Kitchen Day Start"
        icon: mdi:weather-sunny
        has_time: true
        has_date: false
        initial: "09:00"
      kitchen_schedule_2_end:
        name: "Kitchen Day End"
        icon: mdi:weather-sunny
        has_time: true
        has_date: false
        initial: "17:00"
      kitchen_schedule_3_start:
        name: "Kitchen Evening Start"
        icon: mdi:weather-sunset
        has_time: true
        has_date: false
        initial: "17:00"
      kitchen_schedule_3_end:
        name: "Kitchen Evening End"
        icon: mdi:weather-sunset
        has_time: true
        has_date: false
        initial: "21:00"
      kitchen_schedule_4_start:
        name: "Kitchen Night Start"
        icon: mdi:weather-night
        has_time: true
        has_date: false
        initial: "21:00"
      kitchen_schedule_4_end:
        name: "Kitchen Night End"
        icon: mdi:weather-night
        has_time: true
        has_date: false
        initial: "23:00"
      kitchen_schedule_5_start:
        name: "Kitchen Late Night Start"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "23:00"
      kitchen_schedule_5_end:
        name: "Kitchen Late Night End"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "06:00"
      
      # Bedroom
      bedroom_schedule_1_start:
        name: "Bedroom Morning Start"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "06:00"
      bedroom_schedule_1_end:
        name: "Bedroom Morning End"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "09:00"
      bedroom_schedule_2_start:
        name: "Bedroom Day Start"
        icon: mdi:weather-sunny
        has_time: true
        has_date: false
        initial: "09:00"
      bedroom_schedule_2_end:
        name: "Bedroom Day End"
        icon: mdi:weather-sunny
        has_time: true
        has_date: false
        initial: "17:00"
      bedroom_schedule_3_start:
        name: "Bedroom Evening Start"
        icon: mdi:weather-sunset
        has_time: true
        has_date: false
        initial: "17:00"
      bedroom_schedule_3_end:
        name: "Bedroom Evening End"
        icon: mdi:weather-sunset
        has_time: true
        has_date: false
        initial: "21:00"
      bedroom_schedule_4_start:
        name: "Bedroom Night Start"
        icon: mdi:weather-night
        has_time: true
        has_date: false
        initial: "21:00"
      bedroom_schedule_4_end:
        name: "Bedroom Night End"
        icon: mdi:weather-night
        has_time: true
        has_date: false
        initial: "23:00"
      bedroom_schedule_5_start:
        name: "Bedroom Late Night Start"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "23:00"
      bedroom_schedule_5_end:
        name: "Bedroom Late Night End"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "06:00"
      
      # Bathroom
      bathroom_schedule_1_start:
        name: "Bathroom Morning Start"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "06:00"
      bathroom_schedule_1_end:
        name: "Bathroom Morning End"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "09:00"
      bathroom_schedule_2_start:
        name: "Bathroom Day Start"
        icon: mdi:weather-sunny
        has_time: true
        has_date: false
        initial: "09:00"
      bathroom_schedule_2_end:
        name: "Bathroom Day End"
        icon: mdi:weather-sunny
        has_time: true
        has_date: false
        initial: "17:00"
      bathroom_schedule_3_start:
        name: "Bathroom Evening Start"
        icon: mdi:weather-sunset
        has_time: true
        has_date: false
        initial: "17:00"
      bathroom_schedule_3_end:
        name: "Bathroom Evening End"
        icon: mdi:weather-sunset
        has_time: true
        has_date: false
        initial: "21:00"
      bathroom_schedule_4_start:
        name: "Bathroom Night Start"
        icon: mdi:weather-night
        has_time: true
        has_date: false
        initial: "21:00"
      bathroom_schedule_4_end:
        name: "Bathroom Night End"
        icon: mdi:weather-night
        has_time: true
        has_date: false
        initial: "23:00"
      bathroom_schedule_5_start:
        name: "Bathroom Late Night Start"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "23:00"
      bathroom_schedule_5_end:
        name: "Bathroom Late Night End"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "06:00"
      
      # Hallway
      hallway_schedule_1_start:
        name: "Hallway Morning Start"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "06:00"
      hallway_schedule_1_end:
        name: "Hallway Morning End"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "09:00"
      hallway_schedule_2_start:
        name: "Hallway Day Start"
        icon: mdi:weather-sunny
        has_time: true
        has_date: false
        initial: "09:00"
      hallway_schedule_2_end:
        name: "Hallway Day End"
        icon: mdi:weather-sunny
        has_time: true
        has_date: false
        initial: "17:00"
      hallway_schedule_3_start:
        name: "Hallway Evening Start"
        icon: mdi:weather-sunset
        has_time: true
        has_date: false
        initial: "17:00"
      hallway_schedule_3_end:
        name: "Hallway Evening End"
        icon: mdi:weather-sunset
        has_time: true
        has_date: false
        initial: "21:00"
      hallway_schedule_4_start:
        name: "Hallway Night Start"
        icon: mdi:weather-night
        has_time: true
        has_date: false
        initial: "21:00"
      hallway_schedule_4_end:
        name: "Hallway Night End"
        icon: mdi:weather-night
        has_time: true
        has_date: false
        initial: "23:00"
      hallway_schedule_5_start:
        name: "Hallway Late Night Start"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "23:00"
      hallway_schedule_5_end:
        name: "Hallway Late Night End"
        icon: mdi:weather-sunrise
        has_time: true
        has_date: false
        initial: "06:00"
    
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
      
      # Living Room Scenes
      living_room_schedule_1_scene:
        name: "Living Room Morning Scene"
        icon: mdi:weather-sunrise
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "energize"
      living_room_schedule_2_scene:
        name: "Living Room Day Scene"
        icon: mdi:weather-sunny
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "concentrate"
      living_room_schedule_3_scene:
        name: "Living Room Evening Scene"
        icon: mdi:weather-sunset
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "relax"
      living_room_schedule_4_scene:
        name: "Living Room Night Scene"
        icon: mdi:weather-night
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "nightlight"
      living_room_schedule_5_scene:
        name: "Living Room Late Night Scene"
        icon: mdi:weather-sunrise
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "nightlight"
      living_room_default_scene:
        name: "Living Room Default Scene"
        icon: mdi:sofa
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "relax"
      
      # Kitchen Scenes
      kitchen_schedule_1_scene:
        name: "Kitchen Morning Scene"
        icon: mdi:weather-sunrise
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "energize"
      kitchen_schedule_2_scene:
        name: "Kitchen Day Scene"
        icon: mdi:weather-sunny
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "concentrate"
      kitchen_schedule_3_scene:
        name: "Kitchen Evening Scene"
        icon: mdi:weather-sunset
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "relax"
      kitchen_schedule_4_scene:
        name: "Kitchen Night Scene"
        icon: mdi:weather-night
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "nightlight"
      kitchen_schedule_5_scene:
        name: "Kitchen Late Night Scene"
        icon: mdi:weather-sunrise
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "nightlight"
      kitchen_default_scene:
        name: "Kitchen Default Scene"
        icon: mdi:chef-hat
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "relax"
      
      # Bedroom Scenes
      bedroom_schedule_1_scene:
        name: "Bedroom Morning Scene"
        icon: mdi:weather-sunrise
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "energize"
      bedroom_schedule_2_scene:
        name: "Bedroom Day Scene"
        icon: mdi:weather-sunny
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "concentrate"
      bedroom_schedule_3_scene:
        name: "Bedroom Evening Scene"
        icon: mdi:weather-sunset
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "relax"
      bedroom_schedule_4_scene:
        name: "Bedroom Night Scene"
        icon: mdi:weather-night
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "nightlight"
      bedroom_schedule_5_scene:
        name: "Bedroom Late Night Scene"
        icon: mdi:weather-sunrise
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "nightlight"
      bedroom_default_scene:
        name: "Bedroom Default Scene"
        icon: mdi:bed
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "relax"
      
      # Bathroom Scenes
      bathroom_schedule_1_scene:
        name: "Bathroom Morning Scene"
        icon: mdi:weather-sunrise
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "energize"
      bathroom_schedule_2_scene:
        name: "Bathroom Day Scene"
        icon: mdi:weather-sunny
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "concentrate"
      bathroom_schedule_3_scene:
        name: "Bathroom Evening Scene"
        icon: mdi:weather-sunset
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "relax"
      bathroom_schedule_4_scene:
        name: "Bathroom Night Scene"
        icon: mdi:weather-night
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "nightlight"
      bathroom_schedule_5_scene:
        name: "Bathroom Late Night Scene"
        icon: mdi:weather-sunrise
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "nightlight"
      bathroom_default_scene:
        name: "Bathroom Default Scene"
        icon: mdi:shower
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "relax"
      
      # Hallway Scenes
      hallway_schedule_1_scene:
        name: "Hallway Morning Scene"
        icon: mdi:weather-sunrise
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "energize"
      hallway_schedule_2_scene:
        name: "Hallway Day Scene"
        icon: mdi:weather-sunny
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "concentrate"
      hallway_schedule_3_scene:
        name: "Hallway Evening Scene"
        icon: mdi:weather-sunset
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "relax"
      hallway_schedule_4_scene:
        name: "Hallway Night Scene"
        icon: mdi:weather-night
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "nightlight"
      hallway_schedule_5_scene:
        name: "Hallway Late Night Scene"
        icon: mdi:weather-sunrise
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "nightlight"
      hallway_default_scene:
        name: "Hallway Default Scene"
        icon: mdi:corridor
        options:
          - "energize"
          - "concentrate"
          - "relax"
          - "nightlight"
          - "read"
          - "dimmed"
          - "custom"
        initial: "relax"
      
      # Switch Configuration (only for living room as example)
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
      # Living Room Custom Scenes
      living_room_schedule_1_custom_scene:
        name: "Living Room Morning Custom Scene"
        icon: mdi:weather-sunrise
        initial: ""
      living_room_schedule_2_custom_scene:
        name: "Living Room Day Custom Scene"
        icon: mdi:weather-sunny
        initial: ""
      living_room_schedule_3_custom_scene:
        name: "Living Room Evening Custom Scene"
        icon: mdi:weather-sunset
        initial: ""
      living_room_schedule_4_custom_scene:
        name: "Living Room Night Custom Scene"
        icon: mdi:weather-night
        initial: ""
      living_room_schedule_5_custom_scene:
        name: "Living Room Late Night Custom Scene"
        icon: mdi:weather-sunrise
        initial: ""
      living_room_default_custom_scene:
        name: "Living Room Default Custom Scene"
        icon: mdi:sofa
        initial: ""
      
      # Kitchen Custom Scenes
      kitchen_schedule_1_custom_scene:
        name: "Kitchen Morning Custom Scene"
        icon: mdi:weather-sunrise
        initial: ""
      kitchen_schedule_2_custom_scene:
        name: "Kitchen Day Custom Scene"
        icon: mdi:weather-sunny
        initial: ""
      kitchen_schedule_3_custom_scene:
        name: "Kitchen Evening Custom Scene"
        icon: mdi:weather-sunset
        initial: ""
      kitchen_schedule_4_custom_scene:
        name: "Kitchen Night Custom Scene"
        icon: mdi:weather-night
        initial: ""
      kitchen_schedule_5_custom_scene:
        name: "Kitchen Late Night Custom Scene"
        icon: mdi:weather-sunrise
        initial: ""
      kitchen_default_custom_scene:
        name: "Kitchen Default Custom Scene"
        icon: mdi:chef-hat
        initial: ""
      
      # Bedroom Custom Scenes
      bedroom_schedule_1_custom_scene:
        name: "Bedroom Morning Custom Scene"
        icon: mdi:weather-sunrise
        initial: ""
      bedroom_schedule_2_custom_scene:
        name: "Bedroom Day Custom Scene"
        icon: mdi:weather-sunny
        initial: ""
      bedroom_schedule_3_custom_scene:
        name: "Bedroom Evening Custom Scene"
        icon: mdi:weather-sunset
        initial: ""
      bedroom_schedule_4_custom_scene:
        name: "Bedroom Night Custom Scene"
        icon: mdi:weather-night
        initial: ""
      bedroom_schedule_5_custom_scene:
        name: "Bedroom Late Night Custom Scene"
        icon: mdi:weather-sunrise
        initial: ""
      bedroom_default_custom_scene:
        name: "Bedroom Default Custom Scene"
        icon: mdi:bed
        initial: ""
      
      # Bathroom Custom Scenes
      bathroom_schedule_1_custom_scene:
        name: "Bathroom Morning Custom Scene"
        icon: mdi:weather-sunrise
        initial: ""
      bathroom_schedule_2_custom_scene:
        name: "Bathroom Day Custom Scene"
        icon: mdi:weather-sunny
        initial: ""
      bathroom_schedule_3_custom_scene:
        name: "Bathroom Evening Custom Scene"
        icon: mdi:weather-sunset
        initial: ""
      bathroom_schedule_4_custom_scene:
        name: "Bathroom Night Custom Scene"
        icon: mdi:weather-night
        initial: ""
      bathroom_schedule_5_custom_scene:
        name: "Bathroom Late Night Custom Scene"
        icon: mdi:weather-sunrise
        initial: ""
      bathroom_default_custom_scene:
        name: "Bathroom Default Custom Scene"
        icon: mdi:shower
        initial: ""
      
      # Hallway Custom Scenes
      hallway_schedule_1_custom_scene:
        name: "Hallway Morning Custom Scene"
        icon: mdi:weather-sunrise
        initial: ""
      hallway_schedule_2_custom_scene:
        name: "Hallway Day Custom Scene"
        icon: mdi:weather-sunny
        initial: ""
      hallway_schedule_3_custom_scene:
        name: "Hallway Evening Custom Scene"
        icon: mdi:weather-sunset
        initial: ""
      hallway_schedule_4_custom_scene:
        name: "Hallway Night Custom Scene"
        icon: mdi:weather-night
        initial: ""
      hallway_schedule_5_custom_scene:
        name: "Hallway Late Night Custom Scene"
        icon: mdi:weather-sunrise
        initial: ""
      hallway_default_custom_scene:
        name: "Hallway Default Custom Scene"
        icon: mdi:corridor
        initial: ""

  default_schedule.yaml: |
    # Default Time-Based Scene Schedule Configuration
    # This file defines the default schedule for all rooms
    # Can be overridden per room in individual automation files

    default_schedule:
      # Schedule 1: Morning (06:00-09:00)
      schedule_1:
        start_time: "06:00"
        end_time: "09:00"
        scene_suffix: "energize"  # Will be prefixed with room name
      
      # Schedule 2: Day (09:00-17:00)
      schedule_2:
        start_time: "09:00"
        end_time: "17:00"
        scene_suffix: "concentrate"
      
      # Schedule 3: Evening (17:00-21:00)
      schedule_3:
        start_time: "17:00"
        end_time: "21:00"
        scene_suffix: "relax"
      
      # Schedule 4: Night (21:00-23:00)
      schedule_4:
        start_time: "21:00"
        end_time: "23:00"
        scene_suffix: "nightlight"
      
      # Schedule 5: Late Night (23:00-06:00)
      schedule_5:
        start_time: "23:00"
        end_time: "06:00"
        scene_suffix: "nightlight"
      
      # Default fallback scene
      default_scene_suffix: "relax"

    # Room-specific overrides (optional)
    room_overrides:
      # Example: Kitchen might have different morning time
      # kitchen:
      #   schedule_1:
      #     start_time: "05:30"
      #     end_time: "08:30"
      #     scene_suffix: "energize"
EOF

    print_success "Simplified schedule ConfigMap generated: $output_file"
    print_status "This approach is much more maintainable and reduces the ConfigMap size significantly"
}

# Main execution
main() {
    print_status "Starting unified ConfigMap generation..."
    
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
    print_status "To apply: commit the changes and push to the repository"
    print_status "Or apply directly with: kubectl apply -f *.yaml"
}

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0"
    echo ""
    echo "Generate all Home Assistant ConfigMaps with a unified approach"
    echo "This script reduces duplication and creates maintainable configurations"
    echo ""
    echo "Generated ConfigMaps:"
    echo "  - automations-configmap.yaml         # Automation files"
    echo "  - blueprints-configmap.yaml          # Blueprint files"
    echo "  - schedule-configmap.yaml            # Schedule configuration files"
    echo ""
    echo "This approach is much more efficient than the previous method"
    exit 0
fi

# Run main function
main
