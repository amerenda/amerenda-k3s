# Home Assistant (GitOps-managed)

- Single replica (Home Assistant is not cluster-aware; avoids config corruption)
- Config PVC: homeassistant-config (Longhorn, RWX)

## Configuration Management

### ConfigMaps

Home Assistant configuration is managed through Kubernetes ConfigMaps for different components:

- **Automations**: `homeassistant-automations` - File-based automations from `automations/` directory
- **Blueprints**: `homeassistant-blueprints` - Automation blueprints from `blueprints/automation/` directory  
- **Scripts**: `homeassistant-scripts` - File-based scripts from `scripts/` directory
- **Helpers**: Domain-organized input helpers:
  - `homeassistant-helpers-input-boolean` - Boolean switches and toggles
  - `homeassistant-helpers-input-datetime` - Time pickers for schedule windows
  - `homeassistant-helpers-input-select` - Scene selection dropdowns
  - `homeassistant-helpers-input-number` - Brightness and numeric controls
- **Dashboards**: `homeassistant-dashboards` - Lovelace dashboard views

### Generation Scripts

ConfigMaps are generated from source files using generation scripts:

```bash
# Generate automations ConfigMap
cd automations/
./generate-automations-configmap.sh

# Generate blueprints ConfigMap  
cd blueprints/
./generate-blueprints-configmap.sh

# Generate scripts ConfigMap
cd scripts/
./generate-scripts-configmap.sh

# Generate helpers ConfigMaps (requires jinja2-cli)
cd packages/helpers/
./generate_helpers.sh
```

### Directory Structure

```
gitops/apps/home-assistant/
├── automations/
│   ├── generate-automations-configmap.sh
│   └── *.yaml (automation files)
├── blueprints/
│   ├── generate-blueprints-configmap.sh
│   └── automation/*.yaml (blueprint files)
├── scripts/
│   ├── generate-scripts-configmap.sh
│   └── *.yaml (script files)
├── packages/helpers/
│   ├── generate_helpers.sh
│   ├── *_template.yaml.j2 (Jinja2 templates)
│   └── generated/ (domain-organized helper files)
├── *-configmap.yaml (generated ConfigMaps)
└── deployment.yaml
```

### Configuration Features

- **Hybrid Dashboard Mode**: Supports both YAML-managed dashboards and UI-created ones
- **Domain-Organized Helpers**: Input helpers split by type for cleaner configuration management
- **Preserved UI Editing**: UI-created automations, scripts, and scenes are preserved during deployments
- **GitOps Integration**: All configuration managed through Git and automatically deployed