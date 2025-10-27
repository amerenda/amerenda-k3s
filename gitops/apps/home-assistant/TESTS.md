# Pre-deploy Sanity Tests (adds brightness helper checks)

Run the previous tests, plus:

## Switch brightness helper wiring
1) Set helpers:
   - input_number.<room>_brightness_step_pct = 17
   - input_number.<room>_min_brightness_pct = 5
   - input_number.<room>_max_brightness_pct = 92
2) Press Button 2 (brightness up): brightness should increase by ~17%.
3) Press Button 3 (brightness down): brightness should decrease by ~17%.
4) Long-press Button 2 (brightness max): should set to 92%.
5) Long-press Button 3 (brightness min): should set to 5%.
6) Clear one or more helper inputs in the blueprint to test fallback behavior.
