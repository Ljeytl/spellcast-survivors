# Tests

`tools/test/run_tests.sh` runs every `tests/*.gd` headless, 4 at a time, and reports failures that are not in `baseline.txt`.

`baseline.txt` lists the tests that fail or cannot run headless on the 0.3.0 release candidate:

- exit 124 / 2: visual tests, audio demos and the long probes (area_rendering, encounter_pressure_probe, pass2_native_journeys) need a display or audio device or run past the 75 s limit headless
- exit 1: known failures carried from before 0.3.0 (evolution_tradeoff "Prepared Frost Sigil reaches the larger-radius target", playtest_ux "Reference clears inventory", readability, tower_arch_views (native renderer), ui_settings_restart, ui_ux_journeys)

When a known failure is fixed, delete its line. Never add a line to hide a new failure.

`cast_balance_regression` and `casting_presentation_regression` are timing-sensitive and can fail under heavy parallel load; rerun them alone before treating a failure as real.
