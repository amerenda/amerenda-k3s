# Home Assistant Includes in Kubernetes ConfigMaps

This guide explains how to properly handle Home Assistant `!include` statements when using Kubernetes ConfigMaps.

## The Problem

Home Assistant supports `!include` statements to organize configuration across multiple files, but this creates challenges in Kubernetes environments:

1. **ConfigMap Structure**: Files are mounted as individual files, not as a traditional file system
2. **YAML Syntax**: Standalone `!include` statements are invalid YAML
3. **Path Resolution**: Includes need to reference files that exist in the mounted ConfigMap

## Solutions

### ✅ Solution 1: Direct Inclusion (Recommended)

Instead of using `!include`, directly include the content in the main configuration:

**❌ Don't do this:**
```yaml
# This is invalid YAML syntax
!include schedule/living_room_schedule.yaml
```

**✅ Do this:**
```yaml
# Include the content directly in the appropriate section
input_boolean:
  living_room_schedule_enabled:
    name: "Living Room Schedule Enabled"
    icon: mdi:sofa
    initial: true

input_datetime:
  living_room_schedule_1_start:
    name: "Living Room Morning Start"
    # ... rest of the configuration
```

### ✅ Solution 2: Proper Include Structure

If you must use includes, structure them properly:

**❌ Don't do this:**
```yaml
# Standalone include - invalid YAML
!include schedule/living_room_schedule.yaml
```

**✅ Do this:**
```yaml
# Include as part of a list or mapping
input_boolean: !include schedule/living_room_schedule.yaml
# OR
includes:
  - !include schedule/living_room_schedule.yaml
```

### ✅ Solution 3: ConfigMap File Organization

Organize your ConfigMap to make includes work:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ha-schedule-config
data:
  # Main configuration file
  configuration.yaml: |
    input_boolean: !include schedule/input_boolean.yaml
    input_datetime: !include schedule/input_datetime.yaml
    input_select: !include schedule/input_select.yaml
  
  # Separate files for each section
  schedule/input_boolean.yaml: |
    living_room_schedule_enabled:
      name: "Living Room Schedule Enabled"
      icon: mdi:sofa
      initial: true
  
  schedule/input_datetime.yaml: |
    living_room_schedule_1_start:
      name: "Living Room Morning Start"
      # ... rest of datetime config
  
  schedule/input_select.yaml: |
    living_room_schedule_1_scene:
      name: "Living Room Morning Scene"
      # ... rest of select config
```

## Common Patterns

### Pattern 1: Single File Approach (Current)
- All configuration in one large file
- No includes needed
- Easier to manage in Kubernetes
- **Use when**: Configuration is relatively small

### Pattern 2: Section-Based Includes
- Separate files for each configuration section
- Use includes to reference them
- **Use when**: Configuration is large and needs organization

### Pattern 3: Room-Based Includes
- Separate file for each room
- Include all room files
- **Use when**: You have many rooms with similar structure

## Best Practices

### 1. Validate YAML Syntax
Always check that your YAML is valid before applying:

```bash
# Check YAML syntax
kubectl apply --dry-run=client -f your-configmap.yaml

# Test in Home Assistant
kubectl exec -n home-assistant <pod-name> -- python -m homeassistant --script check_config
```

### 2. Use Comments for Organization
Instead of includes, use comments to organize large configurations:

```yaml
# =============================================================================
# LIVING ROOM SCHEDULE CONFIGURATION
# =============================================================================
input_boolean:
  living_room_schedule_enabled:
    name: "Living Room Schedule Enabled"
    # ... configuration

# =============================================================================
# KITCHEN SCHEDULE CONFIGURATION  
# =============================================================================
# (kitchen config would go here)
```

### 3. Keep Related Config Together
Group related configuration sections together:

```yaml
# All input_boolean entities
input_boolean:
  # Global schedule
  time_schedule_enabled: ...
  # Living room schedule
  living_room_schedule_enabled: ...
  # Kitchen schedule
  kitchen_schedule_enabled: ...

# All input_datetime entities
input_datetime:
  # Global schedule times
  schedule_1_start: ...
  # Living room schedule times
  living_room_schedule_1_start: ...
  # Kitchen schedule times
  kitchen_schedule_1_start: ...
```

## Troubleshooting

### Error: "could not find expected ':'"
**Cause**: Standalone `!include` statement
**Fix**: Either remove the include or structure it properly

**Example of the error:**
```yaml
# This causes the error
automation: !include_dir_list automations/
script: !include scripts.yaml

# This line causes "could not find expected ':'"
!include schedule/living_room_schedule.yaml

input_boolean:
  time_schedule_enabled: ...
```

**Solution:**
```yaml
automation: !include_dir_list automations/
script: !include scripts.yaml

# Remove the standalone include and add content directly
input_boolean:
  time_schedule_enabled: ...
  living_room_schedule_enabled:
    name: "Living Room Schedule Enabled"
    # ... rest of config
```

### Error: "file not found"
**Cause**: Include path doesn't exist in ConfigMap
**Fix**: Ensure the file exists in the ConfigMap data section

### Error: "invalid YAML"
**Cause**: Malformed YAML structure
**Fix**: Validate YAML syntax and indentation

## Migration Guide

### From Includes to Direct Inclusion

1. **Identify all include statements**:
   ```bash
   grep -r "!include" your-config/
   ```

2. **Copy content from included files**:
   ```bash
   # Get content from included file
   cat config/schedule/living_room_schedule.yaml
   ```

3. **Paste content into main configuration**:
   - Place in appropriate section (input_boolean, input_datetime, etc.)
   - Maintain proper indentation
   - Remove the include statement

4. **Remove included files**:
   ```bash
   rm config/schedule/living_room_schedule.yaml
   ```

5. **Update ConfigMap**:
   - Remove file from ConfigMap data section
   - Update main configuration

## Examples

### Example 1: Simple Room Schedule
```yaml
# In deployment.yaml
input_boolean:
  living_room_schedule_enabled:
    name: "Living Room Schedule Enabled"
    icon: mdi:sofa
    initial: true

input_datetime:
  living_room_schedule_1_start:
    name: "Living Room Morning Start"
    icon: mdi:weather-sunrise
    has_time: true
    has_date: false
    initial: "06:00"
  # ... more datetime entities

input_select:
  living_room_schedule_1_scene:
    name: "Living Room Morning Scene"
    options: ["energize", "concentrate", "relax", "nightlight", "read", "dimmed"]
    initial: "energize"
  # ... more select entities
```

### Example 2: Multiple Rooms
```yaml
# In deployment.yaml
input_boolean:
  # Living room
  living_room_schedule_enabled: ...
  # Kitchen
  kitchen_schedule_enabled: ...
  # Bedroom
  bedroom_schedule_enabled: ...

input_datetime:
  # Living room times
  living_room_schedule_1_start: ...
  living_room_schedule_1_end: ...
  # Kitchen times
  kitchen_schedule_1_start: ...
  kitchen_schedule_1_end: ...
  # Bedroom times
  bedroom_schedule_1_start: ...
  bedroom_schedule_1_end: ...
```

## Summary

- **Avoid standalone includes** - they're invalid YAML
- **Use direct inclusion** for most cases
- **Organize with comments** instead of file separation
- **Validate YAML syntax** before applying
- **Keep related config together** for better maintainability

This approach is more reliable in Kubernetes environments and easier to debug when issues arise.
