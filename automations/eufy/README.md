# Eufy Security Automations

This directory contains automations for Eufy security cameras with Home Assistant.

## Features

### 1. Human Detection Automation
- **File**: `human-detection-automation.yaml`
- **Purpose**: Updates the "Event Image" on the home page dashboard when a human is detected
- **Triggers**: Human detection sensors from Eufy cameras
- **Actions**: 
  - Takes snapshot and saves as `/config/www/event_image.jpg`
  - Updates timestamp and location text entities
  - Sends persistent notification

### 2. Pet Detection Automation
- **File**: `pet-detection-automation.yaml`
- **Purpose**: Sends push notification with image preview when a pet is detected
- **Triggers**: Pet detection sensors from Eufy cameras
- **Actions**:
  - Takes snapshot with timestamp
  - Sends push notification to mobile app
  - Logs detection event
  - Cleans up old images automatically

### 3. Privacy Mode Automation
- **File**: `privacy-mode-automation.yaml`
- **Purpose**: Disables cameras when phone is detected at home
- **Triggers**: Phone location changes
- **Actions**:
  - Enables privacy mode when phone is home
  - Disables privacy mode when phone leaves
  - Allows manual override

## Setup Instructions

### 1. Add Helper Entities
Add the contents of `helper-entities.yaml` to your `configuration.yaml`:

```yaml
# Add to configuration.yaml
input_text:
  event_image_timestamp:
    name: "Event Image Timestamp"
    initial: "Never"
  event_image_location:
    name: "Event Image Location"
    initial: "None"
  last_pet_detection:
    name: "Last Pet Detection"
    initial: "Never"

input_boolean:
  privacy_mode:
    name: "Privacy Mode"
    initial: false
    icon: mdi:eye-off

shell_command:
  cleanup_pet_images:
    command: "find /config/www -name 'pet_detection_*.jpg' -mtime +7 -delete"
    timeout: 30
```

### 2. Add Automations
Copy the automation files to your Home Assistant automations directory:

```bash
# Copy automations
cp human-detection-automation.yaml /config/automations/
cp pet-detection-automation.yaml /config/automations/
cp privacy-mode-automation.yaml /config/automations/
```

### 3. Configure Dashboard
Add the dashboard cards from `dashboard-cards.yaml` to your Home Assistant dashboard.

### 4. Update Entity Names
**IMPORTANT**: Update the entity names in the automations to match your actual Eufy camera entities:

- Replace `camera.living_room` with your actual camera entity names
- Replace `binary_sensor.living_room_human` with your actual human detection sensors
- Replace `binary_sensor.living_room_pet` with your actual pet detection sensors
- Replace `device_tracker.your_phone` with your actual phone tracker
- Replace `notify.mobile_app_your_phone` with your actual mobile app notification service

### 5. Test Automations
1. Go to **Settings** → **Automations & Scenes**
2. Enable the automations
3. Test by manually triggering the sensors
4. Check the logs for any errors

## Entity Names to Update

Before using these automations, you need to update the entity names to match your actual Eufy camera setup. Check your Home Assistant entities:

1. Go to **Settings** → **Devices & Services** → **Entities**
2. Search for "camera" to find your camera entities
3. Search for "binary_sensor" to find your motion/human/pet detection sensors
4. Update the automation files with the correct entity names

## Troubleshooting

### Common Issues:
1. **Entity names don't match**: Update the entity names in the automation files
2. **Mobile app notifications not working**: Check your mobile app configuration
3. **Images not saving**: Ensure `/config/www/` directory exists and is writable
4. **Privacy mode not working**: Check if your Eufy cameras support privacy mode

### Logs:
Check the Home Assistant logs for any automation errors:
- Go to **Settings** → **System** → **Logs**
- Look for automation-related errors

## Files Created:
- `human-detection-automation.yaml
- `pet-detection-automation.yaml`
- `privacy-mode-automation.yaml`
- `helper-entities.yaml`
- `dashboard-cards.yaml`
- `README.md`
