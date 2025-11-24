# Home Assistant Scheduling System

This document explains the global and room-level scheduling system used to automate lighting and scenes throughout the house.

## 1. System Overview

The scheduling system is designed to drive room behavior based on four primary time slots: **Morning**, **Day**, **Evening**, and **Night**.

Instead of managing complex automations for every single light, the system works by:
1.  **Defining Global Schedules**: Centralized start times for each slot.
2.  **Dispatching Events**: When a slot changes (e.g., Morning starts), an event is fired.
3.  **Room Configuration**: Each room subscribes to these events and decides how to react (e.g., turn on lights, enable motion sensors, or do nothing).

This allows for a "set it and forget it" experience where shifting the "Evening" time globally affects all rooms, while still allowing individual room overrides.

## 2. Global Schedule Slots

The day is divided into four slots controlled by `schedule` entities:

*   **Morning** (`schedule.scenes_morning`): Early wake-up hours.
*   **Day** (`schedule.scenes_day`): Standard daylight hours.
*   **Evening** (`schedule.scenes_evening`): Transition to sunset/relaxing lighting.
*   **Night** (`schedule.scenes_night`): Late night/sleep hours.

These schedules are mutually exclusive. When one turns `on`, the system calculates which slot is active and triggers the corresponding actions.

## 3. Room Configuration

Each room (e.g., Bedroom, Living Room, Kitchen) can be configured individually via the **Room Schedule Configuration** dashboard.

### Dashboard Usage
Navigate to the **Room Schedule Configuration** view. You will see a selector for **Room** and **Time Slot**. Selecting a combination (e.g., "Kitchen" + "Evening") reveals the specific settings for that period.

### Configuration Options

#### A. Auto-On Mode
Determines if lights should turn on automatically when the time slot begins.
*   **Always**: Lights turn on every day at the start of the slot.
*   **Weekdays Only**: Lights turn on only Monday-Friday.
*   **Weekends Only**: Lights turn on only Saturday-Sunday.
*   **Disabled** (or other): Lights do not turn on automatically.

#### B. Time Overrides
By default, rooms follow the Global Schedule times. However, you can customize this per room.
*   **Use Custom Schedule (Room Master)**: Check this to enable custom timing logic for the room.
*   **Override Global Time**: Check this for a specific slot (e.g., Morning) to set a unique start time.
    *   **Weekday/Weekend Split**: Some rooms support separate start times for weekdays vs. weekends (e.g., wake up later on weekends). When enabled, you will see separate time pickers.

#### C. Scene Selection
Choose which scene should activate during this slot.
*   **Scene**: Selects the specific `scene.<room>_<slot>` entity (e.g., `scene.kitchen_evening`).
*   **Note**: The system dynamically looks for a scene named `scene.<room>_<slot>`. If you select a specific scene in the dropdown, it overrides the default naming convention.

#### D. Motion Settings
*   **Motion Activated**: If checked, motion sensors in the room will trigger this slot's lighting settings.
*   **Motion Auto-Off (min)**: How many minutes of inactivity before lights turn off.

## 4. Technical Architecture (For Maintainers)

### Key Components

#### 1. Global Schedule Dispatcher
*   **File**: `automations/global_schedule_dispatcher.yaml`
*   **Function**: Triggers when any global `schedule` entity turns `on`.
*   **Logic**:
    1.  Identifies the current slot (Morning/Day/Evening/Night).
    2.  Iterates through a defined list of rooms.
    3.  Checks the `input_select.<room>_<slot>_auto_on_mode` for each room.
    4.  Verifies conditions (Weekday vs. Weekend).
    5.  Calls `script.scheduled_light_on` if conditions are met.

#### 2. `scheduled_light_on` Script
*   **File**: `scripts/power_on.yaml` (defines `scheduled_light_on`)
*   **Function**: The central "smart" turn-on script.
*   **Parameters**:
    *   `fallback_lights`: Entity to turn on if the specific scene doesn't exist.
    *   `auto_on`: Boolean to force lights on even if currently off (used by dispatcher).
    *   `timer_mode`: If true, acts as a "refresh" (only updates if lights are already on).
*   **Logic**:
    *   Determines the correct time slot for the room (checking for custom overrides).
    *   Resolves the target scene (`scene.<room>_<slot>` or override).
    *   activates the scene or fallback lights.

#### 3. Naming Conventions
The system relies heavily on strict naming conventions for Helpers (`input_*` entities):
*   **Start Times**: `input_datetime.<room>_s<1-4>_start` (s1=Morning, s2=Day, s3=Evening, s4=Night).
*   **Weekday/Weekend**: `input_datetime.<room>_s<1-4>_weekday_start` / `_weekend_start`.
*   **Auto-On Mode**: `input_select.<room>_<slot>_auto_on_mode`.
*   **Custom Toggle**: `input_boolean.<room>_custom_schedule`.

#### 4. Weekday/Weekend Sync
*   **File**: `automations/sync_weekday_weekend_times.yaml`
*   **Function**: When a user enables "Separate Weekday/Weekend" mode, this automation initializes the new sub-helpers with the current single-start-time value to prevent them from defaulting to 00:00.

