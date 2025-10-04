# Eufy Automations with ConfigMaps

This directory contains Eufy security camera automations managed as Kubernetes ConfigMaps, allowing you to edit them as files instead of inline YAML.

## 🎯 Features

- **Human Detection**: Updates event image on dashboard
- **Pet Detection**: Push notifications with image preview
- **Privacy Mode**: Disables cameras when phone is home
- **ConfigMap Management**: Edit files directly instead of inline YAML

## 📁 Files Structure

```
automations/eufy/
├── human-detection-automation.yaml          # Human detection automation
├── pet-detection-automation.yaml            # Pet detection automation  
├── privacy-mode-automation.yaml             # Privacy mode automation
├── helper-entities.yaml                     # Helper entities configuration
├── dashboard-cards.yaml                     # Dashboard card configurations
├── human-detection-configmap.yaml           # ConfigMap for human detection
├── pet-detection-configmap.yaml             # ConfigMap for pet detection
├── privacy-mode-configmap.yaml              # ConfigMap for privacy mode
├── helper-entities-configmap.yaml           # ConfigMap for helper entities
├── dashboard-cards-configmap.yaml           # ConfigMap for dashboard cards
├── setup-automations.sh                     # Setup script
├── generate-configmaps.sh                   # ConfigMap generator
└── CONFIGMAP-README.md                      # This file
```

## 🚀 Quick Setup

### 1. Run the Setup Script
```bash
cd /home/alex/projects/amerenda-k3s/automations/eufy
./setup-automations.sh
```

This will:
- Apply all ConfigMaps
- Update Home Assistant deployment
- Mount automation files in `/config/automations/`

### 2. Add Helper Entities
The helper entities need to be added to your Home Assistant configuration:

```bash
# View the helper entities
kubectl exec -it deployment/homeassistant -n home-assistant -- cat /config/automations/helper-entities.yaml

# Add them to your configuration.yaml
kubectl exec -it deployment/homeassistant -n home-assistant -- sh -c 'cat /config/automations/helper-entities.yaml >> /config/configuration.yaml'
```

### 3. Update Entity Names
**IMPORTANT**: Update the entity names in the automation files to match your actual Eufy camera entities.

## 🔧 Managing ConfigMaps

### View ConfigMaps
```bash
kubectl get configmaps -n home-assistant | grep eufy
```

### Edit Automation Files
```bash
# Edit human detection automation
kubectl edit configmap eufy-human-detection-automation -n home-assistant

# Edit pet detection automation  
kubectl edit configmap eufy-pet-detection-automation -n home-assistant

# Edit privacy mode automation
kubectl edit configmap eufy-privacy-mode-automation -n home-assistant
```

### Update ConfigMaps from Files
```bash
# Update from local files
./generate-configmaps.sh

# Or manually update a specific ConfigMap
kubectl create configmap eufy-human-detection-automation \
  --from-file=human-detection-automation.yaml=human-detection-automation.yaml \
  --namespace=home-assistant \
  --dry-run=client -o yaml | kubectl apply -f -
```

## 📝 Editing Automation Files

### Method 1: Edit ConfigMaps Directly
```bash
kubectl edit configmap eufy-human-detection-automation -n home-assistant
```

### Method 2: Edit Local Files and Update
1. Edit the local automation files
2. Run `./generate-configmaps.sh` to update ConfigMaps
3. Restart Home Assistant: `kubectl rollout restart deployment/homeassistant -n home-assistant`

## 🔍 Troubleshooting

### Check ConfigMap Contents
```bash
kubectl get configmap eufy-human-detection-automation -n home-assistant -o yaml
```

### View Mounted Files in Home Assistant
```bash
kubectl exec -it deployment/homeassistant -n home-assistant -- ls -la /config/automations/
kubectl exec -it deployment/homeassistant -n home-assistant -- cat /config/automations/human-detection-automation.yaml
```

### Check Home Assistant Logs
```bash
kubectl logs -l app=homeassistant -n home-assistant --tail=50 | grep -E "(automation|eufy)"
```

### Restart Home Assistant
```bash
kubectl rollout restart deployment/homeassistant -n home-assistant
```

## 📋 Entity Names to Update

Before using these automations, update the entity names in the ConfigMaps:

1. **Camera Entities**: `camera.living_room`, `camera.bedroom`, etc.
2. **Human Detection**: `binary_sensor.living_room_human`, etc.
3. **Pet Detection**: `binary_sensor.living_room_pet`, etc.
4. **Motion Sensors**: `binary_sensor.living_room_motion`, etc.
5. **Phone Tracker**: `device_tracker.your_phone`
6. **Mobile App**: `notify.mobile_app_your_phone`

## 🎛️ Dashboard Configuration

The dashboard cards are available in the ConfigMap. To use them:

1. Go to **Home Assistant** → **Overview** → **Edit Dashboard**
2. Add the cards from `/config/automations/dashboard-cards.yaml`
3. Customize the cards as needed

## 🔄 Workflow for Updates

1. **Edit local files** (e.g., `human-detection-automation.yaml`)
2. **Update ConfigMap**: `./generate-configmaps.sh`
3. **Restart Home Assistant**: `kubectl rollout restart deployment/homeassistant -n home-assistant`
4. **Test automations** in Home Assistant UI

## 📊 Benefits of ConfigMap Approach

- ✅ **Edit as files** instead of inline YAML
- ✅ **Version control** with Git
- ✅ **Easy updates** without rebuilding containers
- ✅ **Separation of concerns** - automations separate from deployment
- ✅ **Reusable** across different Home Assistant instances

## 🆘 Support

If you encounter issues:

1. Check the logs: `kubectl logs -l app=homeassistant -n home-assistant`
2. Verify ConfigMaps: `kubectl get configmaps -n home-assistant | grep eufy`
3. Check mounted files: `kubectl exec -it deployment/homeassistant -n home-assistant -- ls -la /config/automations/`
4. Restart Home Assistant: `kubectl rollout restart deployment/homeassistant -n home-assistant`
