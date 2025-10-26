# Room Schedule System

This system allows you to create room-specific schedules that inherit from a default schedule but can be overridden per room.

> **📚 Related Documentation**: See [README-includes.md](README-includes.md) for guidance on handling Home Assistant includes in Kubernetes ConfigMaps.

## How It Works

1. **Default Schedule**: All rooms start with the same default schedule defined in `default_schedule.yaml`
2. **Room Overrides**: You can override specific times and scenes for individual rooms using `room_overrides.yaml`
3. **Generated Configs**: The `generate-room-schedule.sh` script creates room-specific configurations

## Default Schedule

The default schedule includes 5 time periods:

- **Morning**: 06:00-09:00 (energize scene)
- **Day**: 09:00-17:00 (concentrate scene)
- **Evening**: 17:00-21:00 (relax scene)
- **Night**: 21:00-23:00 (nightlight scene)
- **Late Night**: 23:00-06:00 (nightlight scene)

Default fallback scene: `relax`

## Creating Room Schedules

### Method 1: Use the Generator Script

```bash
# Generate a room schedule with default values
./generate-room-schedule.sh living_room

# Generate a room schedule with overrides
./generate-room-schedule.sh kitchen config/room_overrides.yaml
```

### Method 2: Manual Configuration

1. Create a new file: `config/{room_name}_schedule.yaml`
2. Copy the structure from `living_room_schedule.yaml`
3. Update the room name and icon
4. Adjust times and scenes as needed
5. Add the include to `deployment.yaml`

## Room Overrides

To override the default schedule for a specific room, edit `config/room_overrides.yaml`:

```yaml
room_overrides:
  kitchen:
    schedule_1:
      start_time: "05:30"  # Earlier start for kitchen
      end_time: "08:30"    # Earlier end for kitchen
      scene_suffix: "energize"
    schedule_2:
      start_time: "08:30"  # Adjusted start time
      end_time: "17:00"    # Same end time
      scene_suffix: "concentrate"
```

## Available Scene Types

- `energize` - Bright, energizing light for morning
- `concentrate` - Focused light for daytime work
- `relax` - Warm, cozy light for evening
- `nightlight` - Dim light for night/late night
- `read` - Reading-optimized light
- `dimmed` - Soft, dimmed light

## Room Icons

The system automatically assigns appropriate icons:

- `living_room` → `mdi:sofa`
- `kitchen` → `mdi:chef-hat`
- `bedroom` → `mdi:bed`
- `bathroom` → `mdi:shower`
- `hallway` → `mdi:corridor`
- `office` → `mdi:desk`
- `dining_room` → `mdi:table-chair`

## Adding New Rooms

1. **Generate the room schedule**:
   ```bash
   ./generate-room-schedule.sh bedroom
   ```

2. **Add overrides if needed** in `config/room_overrides.yaml`

3. **Add the include to deployment.yaml**:
   ```yaml
   # Room schedule configuration
   !include schedule/{room_name}_schedule.yaml
   ```

4. **Update the ConfigMap** with the new room schedule

5. **Commit and push** for ArgoCD to sync

## Current Rooms

- ✅ **Living Room**: Uses default schedule
- 🔄 **Kitchen**: Can be generated with overrides
- 🔄 **Bedroom**: Can be generated with overrides
- 🔄 **Bathroom**: Can be generated with overrides
- 🔄 **Hallway**: Can be generated with overrides

## Example: Adding Kitchen Schedule

```bash
# 1. Generate kitchen schedule with overrides
./generate-room-schedule.sh kitchen config/room_overrides.yaml > config/kitchen_schedule.yaml

# 2. Add include to deployment.yaml
echo "!include schedule/kitchen_schedule.yaml" >> deployment.yaml

# 3. Update ConfigMap (add kitchen_schedule.yaml to data section)

# 4. Commit and push
git add .
git commit -m "feat: add kitchen schedule with overrides"
git push
```

## Troubleshooting

- **Entities not showing**: Check that the include is added to `deployment.yaml`
- **Wrong times**: Verify the `initial` values match your intended schedule
- **Missing scenes**: Ensure the scene names match your Home Assistant scenes
- **ConfigMap issues**: Make sure the YAML is properly indented in the ConfigMap
