# Home Assistant Automations GitOps

This directory contains automation files that are automatically deployed to Home Assistant via GitOps.

## 📁 Directory Structure

```
gitops/apps/home-assistant/
├── automations/                    # Source automation files
│   ├── climate_control.yaml
│   ├── human_detection.yaml
│   ├── night_lights.yaml
│   └── pet_detection.yaml
├── automations-configmap.yaml      # Generated ConfigMap
├── generate-automations-configmap.sh  # Generation script
└── deployment.yaml                 # Updated with automations mount
```

## 🔄 GitOps Workflow

### 1. **Edit Automation Files**
- Edit files in the `automations/` directory
- Each `.yaml` file should contain a list of automations

### 2. **Generate ConfigMap**
```bash
cd gitops/apps/home-assistant/
./generate-automations-configmap.sh
```

### 3. **Commit and Push**
```bash
git add .
git commit -m "Update automations"
git push
```

### 4. **ArgoCD Sync**
- ArgoCD will automatically detect changes
- ConfigMap will be updated in the cluster
- Home Assistant will reload automations

## 🏗️ How It Works

1. **ConfigMap**: Contains all automation files as data
2. **Volume Mount**: Mounted to `/config/automations/` in Home Assistant
3. **Configuration**: Home Assistant loads automations from both:
   - `/config/automations.yaml` (manual UI automations)
   - `/config/automations/` (file-based automations)

## 📝 Configuration

In `configuration.yaml`:
```yaml
automation:
  - !include automations.yaml
  - !include_dir_merge_list automations/
```

## 🚀 Benefits

- ✅ **Version Control**: All automations tracked in Git
- ✅ **GitOps**: Automatic deployment via ArgoCD
- ✅ **Separation**: UI automations vs file-based automations
- ✅ **Organization**: Multiple files for different automation categories
- ✅ **Rollback**: Easy to revert changes via Git

## 🔧 Manual Commands

```bash
# Generate ConfigMap manually
./generate-automations-configmap.sh

# Apply ConfigMap manually
kubectl apply -f automations-configmap.yaml

# Check mounted files
kubectl exec -n home-assistant deployment/homeassistant -- ls -la /config/automations/
```
