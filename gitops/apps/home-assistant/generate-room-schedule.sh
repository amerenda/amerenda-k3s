#!/bin/bash

# Generate room-specific schedule configuration
# Usage: ./generate-room-schedule.sh <room_name> [overrides_file]

set -e

ROOM_NAME="$1"
OVERRIDES_FILE="$2"

if [ -z "$ROOM_NAME" ]; then
    echo "Usage: $0 <room_name> [overrides_file]"
    echo "Example: $0 kitchen"
    echo "Example: $0 bedroom overrides/bedroom.yaml"
    exit 1
fi

# Default schedule configuration
DEFAULT_SCHEDULE='{
  "schedule_1": {"start_time": "06:00", "end_time": "09:00", "scene_suffix": "energize"},
  "schedule_2": {"start_time": "09:00", "end_time": "17:00", "scene_suffix": "concentrate"},
  "schedule_3": {"start_time": "17:00", "end_time": "21:00", "scene_suffix": "relax"},
  "schedule_4": {"start_time": "21:00", "end_time": "23:00", "scene_suffix": "nightlight"},
  "schedule_5": {"start_time": "23:00", "end_time": "06:00", "scene_suffix": "nightlight"},
  "default_scene_suffix": "relax"
}'

# Room-specific icons
declare -A ROOM_ICONS=(
    ["living_room"]="mdi:sofa"
    ["kitchen"]="mdi:chef-hat"
    ["bedroom"]="mdi:bed"
    ["bathroom"]="mdi:shower"
    ["hallway"]="mdi:corridor"
    ["office"]="mdi:desk"
    ["dining_room"]="mdi:table-chair"
)

ROOM_ICON="${ROOM_ICONS[$ROOM_NAME]:-mdi:home}"

# Function to get schedule value with override support
get_schedule_value() {
    local schedule_key="$1"
    local value_key="$2"
    local default_value="$3"
    
    if [ -n "$OVERRIDES_FILE" ] && [ -f "$OVERRIDES_FILE" ]; then
        # Try to get override value from YAML file using a more robust approach
        local override_value=$(awk "
            /^room_overrides:/ { in_room_overrides=1; next }
            in_room_overrides && /^  $ROOM_NAME:/ { in_room=1; next }
            in_room && /^  [a-zA-Z]/ && !/^  $ROOM_NAME:/ { in_room=0; next }
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
        " "$OVERRIDES_FILE")
        
        if [ -n "$override_value" ]; then
            echo "$override_value"
            return
        fi
    fi
    
    echo "$default_value"
}

# Generate the room schedule configuration
cat << EOF
# ${ROOM_NAME^} Schedule Configuration
# Generated from default schedule with room-specific overrides
input_boolean:
  ${ROOM_NAME}_schedule_enabled:
    name: "${ROOM_NAME^} Schedule Enabled"
    icon: ${ROOM_ICON}
    initial: true

input_datetime:
EOF

# Generate datetime inputs for each schedule
for i in {1..5}; do
    start_time=$(get_schedule_value "schedule_${i}" "start_time" "$(echo "$DEFAULT_SCHEDULE" | jq -r ".schedule_${i}.start_time")")
    end_time=$(get_schedule_value "schedule_${i}" "end_time" "$(echo "$DEFAULT_SCHEDULE" | jq -r ".schedule_${i}.end_time")")
    
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
  ${ROOM_NAME}_schedule_${i}_start:
    name: "${ROOM_NAME^} ${period_name} Start"
    icon: ${period_icon}
    has_time: true
    has_date: false
    initial: "${start_time}"  # Default: ${start_time}
  ${ROOM_NAME}_schedule_${i}_end:
    name: "${ROOM_NAME^} ${period_name} End"
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
    scene_suffix=$(get_schedule_value "schedule_${i}" "scene_suffix" "$(echo "$DEFAULT_SCHEDULE" | jq -r ".schedule_${i}.scene_suffix")")
    
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
  ${ROOM_NAME}_schedule_${i}_scene:
    name: "${ROOM_NAME^} ${period_name} Scene"
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
default_scene=$(get_schedule_value "default_scene_suffix" "scene_suffix" "$(echo "$DEFAULT_SCHEDULE" | jq -r ".default_scene_suffix")")

cat << EOF
  ${ROOM_NAME}_default_scene:
    name: "${ROOM_NAME^} Default Scene"
    icon: ${ROOM_ICON}
    options:
      - "energize"
      - "concentrate"
      - "relax"
      - "nightlight"
      - "read"
      - "dimmed"
    initial: "${default_scene}"  # Default: ${default_scene}
EOF
