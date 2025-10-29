# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automated Home Assistant configuration validation and ConfigMap generation.

## Workflows

### 1. Home Assistant Configuration Check (`ha-config-check.yaml`)

**Triggers:**
- Push to `main` branch for HA-related files
- Pull requests to `main` branch for HA-related files
- Changes to the workflow file itself

**Features:**
- YAML linting using `.yamllint.yaml` configuration
- Home Assistant configuration validation using `hass --script check_config`
- Uses `frenck/action-home-assistant@v1` with pinned version from `.HA_VERSION`
- Runs on self-hosted `arc-runner-set` runners
- Optional hassfest validation for custom components

**Paths monitored:**
- `gitops/apps/home-assistant/**`
- `.github/workflows/ha-config-check.yaml`

### 2. ConfigMap Generation (`ha-generate-configmaps.yaml`)

**Triggers:**
- Push to `main` branch for HA source files
- Changes to the workflow file itself

**Features:**
- Auto-generates all Home Assistant ConfigMaps
- Commits generated ConfigMaps back to repository
- Uses self-hosted `arc-runner-set` runners
- Runs all generation scripts in parallel

**Paths monitored:**
- `gitops/apps/home-assistant/automations/**`
- `gitops/apps/home-assistant/blueprints/**`
- `gitops/apps/home-assistant/packages/**`
- `gitops/apps/home-assistant/scripts/**`
- `gitops/apps/home-assistant/dashboards/**`
- `.github/workflows/ha-generate-configmaps.yaml`

## Configuration Files

### `.yamllint.yaml`
YAML linting configuration optimized for Home Assistant YAML files:
- 120 character line length limit
- 2-space indentation
- Allows Home Assistant truthy values (`yes`/`no`, `on`/`off`)
- Permits flow-style YAML for complex configurations

### `.HA_VERSION`
Pins the Home Assistant version used for configuration validation in CI. Currently set to `2024.10.0`.

## Self-Hosted Runners

All workflows use self-hosted runners deployed via GitHub Actions Runner Controller (ARC) on your k3s cluster:

- **Runner Label**: `arc-runner-set`
- **Namespace**: `arc-systems`
- **Scaling**: 0-10 runners based on demand
- **Resources**: 200m-1000m CPU, 256Mi-1Gi memory

## Generated ConfigMaps

The workflows generate the following ConfigMaps:

1. **`homeassistant-automations`** - From `automations/*.yaml`
2. **`homeassistant-blueprints`** - From `blueprints/automation/*.yaml`
3. **`homeassistant-scripts`** - From `scripts/*.yaml`
4. **`homeassistant-dashboards`** - From `dashboards/*.yaml`
5. **`homeassistant-helpers-input-boolean`** - Generated from Jinja2 templates
6. **`homeassistant-helpers-input-datetime`** - Generated from Jinja2 templates
7. **`homeassistant-helpers-input-select`** - Generated from Jinja2 templates
8. **`homeassistant-helpers-input-number`** - Generated from Jinja2 templates
9. **`homeassistant-helpers-input-text`** - From `packages/helpers/input_text/*.yaml`

## Scripts

All generation scripts have been updated to work without `kubectl` dependency:
- Generate pure YAML ConfigMap manifests
- Use standard shell tools (`cat`, `sed`, `for` loops)
- Maintain proper YAML indentation
- Exclude generation scripts from output

## Benefits

1. **Automated Validation**: Catch configuration errors before deployment
2. **Consistent ConfigMaps**: Auto-generate from source files
3. **GitOps Integration**: Changes are committed back to repository
4. **Self-Hosted Runners**: Run in your k3s cluster with access to cluster resources
5. **Scalable**: Runners scale automatically based on demand
6. **Secure**: Uses GitHub App authentication instead of PATs

## Troubleshooting

### Workflow Failures

1. **YAML Lint Errors**: Check `.yamllint.yaml` configuration and fix formatting
2. **HA Config Errors**: Use `hass --script check_config` locally to debug
3. **Runner Issues**: Check ARC controller and runner scale set status in `arc-systems` namespace
4. **Permission Errors**: Verify GitHub App has correct permissions

### Local Testing

```bash
# Test YAML linting
yamllint gitops/apps/home-assistant/

# Test HA config validation
hass --script check_config --config /path/to/ha/config

# Test ConfigMap generation
cd gitops/apps/home-assistant/automations
./generate-automations-configmap.sh
```

### Monitoring

```bash
# Check workflow runs
gh run list --workflow=ha-config-check.yaml
gh run list --workflow=ha-generate-configmaps.yaml

# Check runner status
kubectl get pods -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set
```
