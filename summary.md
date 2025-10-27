# 🏠 Home Assistant Lighting Control System (Final Implementation Plan)

## Overview
A modular, fault-tolerant lighting automation system for **Home Assistant (HA)** using:
- **Philips Hue** lights & Hue Bridge  
- **Hue 4-button dimmer switches** (via Hue integration)  
- **Hue motion sensors**  
- **Shared schedule logic** and **per-room helpers**  
- **Jinja-based helper generator**  
- **Hue app fallback or Hubitat backup**  

All automations (switch, motion, timer) share one central schedule logic to avoid duplication and ensure consistency.

---

## 🔧 Core Components

### 1. Scenes (per room)
Each room defines four base scenes:
```
scene.<room_key>_morning
scene.<room_key>_day
scene.<room_key>_evening
scene.<room_key>_night
```
Optional overrides via `input_select.<room>_<slot>_scene`.

---

### 2. Shared Scripts

#### 🟢 `scheduled_light_on`
- Determines which scene to activate based on current time.
- Reads from shared helpers:
  - `input_boolean.<room>_custom_schedule`
  - `input_datetime.<room>_s1_start .. _s4_start`
- Optionally uses scene overrides via `input_select.<room>_<slot>_scene`.

#### 🟡 `room_toggle`
- Smart toggle logic for any light group:
  - If **on**, turns all **off**.
  - If **off**, calls `scheduled_light_on`.
- Normalizes input entities; works across multiple rooms.

---

### 3. Blueprints

#### 🟩 `room_switch_control.yaml`
Hue 4-button dimmer control.

**Features:**
- Hue **device triggers** + legacy **`hue_event`** support.  
- Scene cycle: `morning → day → evening → night`.  
- Per-button override support via optional `input_select`s.  
- Brightness control via optional helpers:
  - `input_number.<room>_brightness_step_pct`
  - `input_number.<room>_min_brightness_pct`
  - `input_number.<room>_max_brightness_pct`  

**Default button mappings:**

| Button | Short Press | Long Press |
|--------|--------------|-------------|
| 1 | Toggle lights | All off |
| 2 | Brightness up | Brightness max |
| 3 | Brightness down | Brightness min |
| 4 | Scene cycle | Default scene |

---

#### 🟧 `room_motion_control.yaml`
Handles motion-triggered lighting per room.

- Shared schedule logic.  
- Per-window motion control:
  - `block` (boolean): disable motion activation.  
  - `auto_off` (number): minutes before turning off.  
- Disable motion globally via `input_boolean.<room>_motion_enabled`.

---

#### 🟦 `room_timer_control.yaml`
Time-triggered per room (no motion or switches).

**Logic per window:**
- If window **enabled**:  
  - Lights **on** → apply scene immediately.  
  - All lights **off** and **auto_on** = on → turn on scene.  
  - All lights **off** and **auto_on** = off → do nothing.

---

## 🧩 Helper Generator

### Template: `_room_helpers_template.yaml.j2`
Defines per-room helpers for schedules, motion, timer, brightness, and scenes.

### Script: `generate_helpers.sh`
Generate helper files for:
```
bedroom
bathroom
living_room
kitchen
hallway
```
Run:
```bash
pip install jinja2-cli
bash packages/helpers/generate_helpers.sh
```

Result:  
`packages/helpers/generated/<room>_helpers.yaml`

---

## 🖥 Dashboard (Living Room Example)
Located at:  
`dashboards/lovelace/views/living_room_lighting.yaml`

Controls:
- Schedule (toggle + times)
- Scene selection
- Brightness settings
- Timer enable/auto-on toggles
- Motion enable + auto-off settings

Add view:
```yaml
views:
  - !include dashboards/lovelace/views/living_room_lighting.yaml
```

---

## ⚡ Physical & Fallback Behavior

### Hue App
- Dimmer switches set to **“Configured by another application”** to prevent conflicts.
- Use **Power loss recovery** for bulbs to stay off after power is restored.  
- Optionally set key areas (kitchen/hallway) to **“Power on to custom”** for outage fallback.

### Hubitat Backup (optional)
- Use **CoCoHue** integration to talk directly to the Hue Bridge.  
- Keep Hubitat unplugged normally; plug in only if HA is down.  
- Simple rule:  
  - Button 1 short → activate “backup” scene.  
  - Button 1 long → turn off room.  

---

## ✅ Pre-Deploy Sanity Tests

### 1️⃣ Scenes
- Confirm all 4 scenes per room exist and work.

### 2️⃣ Schedule Helpers
- Verify toggling custom schedule changes scene timing.

### 3️⃣ Switch Triggers
- Check traces for buttons 1–4.  
- Legacy `hue_event` mapping:
  - Button 1 & 2 → `initial_press`  
  - Button 3 & 4 → `short_release`  
  - Long → `long_press`

### 4️⃣ Motion Logic
- With motion enabled, wave to trigger; verify on/off and idle behavior.

### 5️⃣ Timer Logic
- Set upcoming time window; confirm on/off logic matches Enabled/Auto-on flags.

### 6️⃣ Brightness Helpers
- Adjust step/min/max helpers; verify switch behavior updates dynamically.

### 7️⃣ Dashboard View
- Confirm all helper controls display and sync correctly.

---

## 🧠 Implementation Files

```
scripts/
  power_on.yaml
  room_toggle.yaml

blueprints/automation/
  room_switch_control.yaml
  room_motion_control.yaml
  room_timer_control.yaml

packages/helpers/
  _room_helpers_template.yaml.j2
  generate_helpers.sh

dashboards/lovelace/views/
  living_room_lighting.yaml
```

---

## 🏁 Summary
This system provides a **unified, DRY, and fault-tolerant lighting automation stack** where:

- All automations share a **common schedule logic**.  
- Each room’s configuration is generated automatically from templates.  
- **Brightness controls** and **scenes** are user-configurable via dashboard.  
- **Hue’s built-in recovery** and **Hubitat or Hue app fallback** ensure lights remain usable even when HA is offline.
