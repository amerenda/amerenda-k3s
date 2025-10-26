# Entity Analysis and Configuration Alignment

## ✅ **Fixed Issues**

### **Problem**: Scene name mismatches
- **Issue**: Configuration was trying to use `scene.living_room_day` which doesn't exist
- **Solution**: Updated to use actual available scenes

### **Available Living Room Scenes**:
- ✅ `scene.living_room_energize` - Bright, energizing light
- ✅ `scene.living_room_concentrate` - Focused work light  
- ✅ `scene.living_room_relax` - Warm, cozy light
- ✅ `scene.living_room_nightlight` - Dim night light
- ✅ `scene.living_room_read` - Reading-optimized light
- ✅ `scene.living_room_dimmed` - Soft, dimmed light

## 🏠 **Room Scene Availability**

### **Kitchen Scenes**:
- `scene.kitchen_bright` / `scene.kitchen_bright_2`
- `scene.kitchen_dimmed`
- `scene.kitchen_read`
- `scene.kitchen_nightlight`
- `scene.kitchen_relax`

### **Bedroom Scenes**:
- `scene.bedroom_energize`
- `scene.bedroom_concentrate`
- `scene.bedroom_relax`
- `scene.bedroom_nightlight`
- `scene.bedroom_read`
- `scene.bedroom_sunset_allure`
- `scene.bedroom_bedroom_bright_ideal`

### **Hallway Scenes**:
- `scene.hallway_energize`
- `scene.hallway_concentrate`
- `scene.hallway_relax`
- `scene.hallway_nightlight`
- `scene.hallway_read`
- `scene.hallway_bright`
- `scene.hallway_dimmed`

### **Bathroom Scenes**:
- `scene.bathroom_energize`
- `scene.bathroom_concentrate`
- `scene.bathroom_relax`
- `scene.bathroom_nightlight`
- `scene.bathroom_read`

## 🔧 **Configuration Updates Made**

1. **Updated `schedule_inputs.yaml`**:
   - Replaced `"day"` with `"concentrate"` in scene options
   - Added `"read"` and `"dimmed"` as available scene types
   - Updated default day scene from `"day"` to `"concentrate"`

2. **Updated `default_schedule.yaml`**:
   - Changed schedule 2 scene suffix from `"day"` to `"concentrate"`

3. **Updated `schedule_dashboard.yaml`**:
   - Updated documentation to reflect actual available scene types
   - Added descriptions for all scene types

## 🎯 **Scene Type Mapping**

| Scene Type | Description | Best Use |
|------------|-------------|----------|
| `energize` | Bright, energizing light | Morning wake-up |
| `concentrate` | Focused work light | Daytime activities |
| `relax` | Warm, cozy light | Evening wind-down |
| `nightlight` | Dim night light | Night/late night |
| `read` | Reading-optimized light | Reading activities |
| `dimmed` | Soft, dimmed light | Ambient lighting |

## ✅ **All Entity Names Now Aligned**

The configuration now uses only scene types that actually exist in your Home Assistant system, ensuring no "entity not found" errors.
