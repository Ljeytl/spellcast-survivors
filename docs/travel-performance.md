# Travel performance and FPS diagnostics — 30 September 2026

Scope: SEP30-02 and SEP30-20. Baseline `e9a7e27`; Godot 4.4.1 on macOS. Candidate adds only a bounded grove cache and optional FPS presentation. No enemy count, spawn interval, recycling rate, enemy stats or difficulty changes.

## Confirmed cause

Every steering query asks for trunks in nine nearby cells. Outside the decoration window, `layout_for` previously generated the deterministic grove without remembering it. Each enemy could regenerate these same groves every physics frame; generating a crowded grove can try 120 placements. Walking away leaves enemies querying terrain outside the visible-decoration cache.

The fix remembers queried layouts in a 256-entry least-recently-used cache independent of scenery nodes. Entries are plain positions, not instantiated trees. Eviction recomputes the same seeded layout. Visible scenery continues to stream/unload normally. A diagnostic generation counter is available for profiles; it does not affect gameplay.

## Actual physics-frame comparison

`tests/travel_runtime_profile.gd`: seed 4217, saturated mid-run setup at 7:30 with 160 pursuers distributed behind the wizard, passive/manual casting disabled, invincibility, then 1,800 actual engine physics frames with 300-world-unit/second travel (9,000 units). Normal enemy physics, encounter processing, recycling and camera/scenery streaming run during the route. Player position advances directly to make the route repeatable; this does not test input or collision-constrained player navigation. Runs were sequential. Baseline differs only by the cache fix and a generation counter; FPS is off.

| Measure | Baseline | Fixed |
|---|---:|---:|
| Engine physics-process median | 17.044 ms | 3.786 ms |
| Engine physics-process p95 | 31.714 ms | 5.243 ms |
| Engine process median | 1.194 ms | 1.223 ms |
| Engine process p95 | 2.679 ms | 3.104 ms |
| Grove generations during route | 1,351,982 | 77 |
| Maximum enemies | 160 | 160 |
| Maximum scene nodes | 2,338 | 2,338 |
| Maximum decoration cells | 49 | 49 |
| Maximum cached layouts | 49 | 126 |
| Recycled enemies | 112 | 116 |
| Wall time for 1,800 physics frames | 37.756 s | 29.813 s |

These are headless engine CPU measurements, **not rendered FPS**. Process cost did not improve. Recycle counts can differ slightly with real process/physics scheduling despite identical seeded setup and distance. The measured evidence supports eliminating redundant terrain-generation work; it does not prove the original tester had this exact cause or establish a GPU/rendering defect. Enemy population and scenery counts were bounded in both runs.

## Targeted steering stress comparison

`tests/travel_component_profile.gd`: seeded 160-enemy trailing distribution, 600 scripted movement/steering steps covering 6,000 units, recycling and scenery streaming. This isolates steering and is not a real-time physics/FPS benchmark. Baseline and fixed preserve 160 enemies, 49 maximum decoration cells and 74 recycled enemies.

| Measure | Baseline | Fixed |
|---|---:|---:|
| Steering-step median | 24.053 ms | 1.609 ms |
| Steering-step p95 | 26.242 ms | 1.683 ms |
| Total steering CPU | 14,413.228 ms | 966.946 ms |
| Grove generations | 693,361 | 76 |

The optional `--natural` mode drives the encounter clock and enemy callbacks in an accelerated scripted loop; it is a behavior/component probe, not a real physics timing measurement. Neither profile script is a pass/fail regression suite.

## Verification and controls

`tests/travel_settings_regression.gd` verifies repeated warm queries generate once, 2,000 distinct queries remain bounded, evicted layouts regenerate identically, FPS defaults off, immediate on/off presentation, saved setting, menu reopening, fresh settings-instance reload and paused disable at desktop/narrow geometry. Its uncached negative control deliberately calls generation ten times and detects ten generations; the warm-query assertion would fail against the old implementation. Test setup requires the isolated Synergy Test profile and restores its prior presentation file.

FPS lives in Graphics settings, defaults off, persists in `presentation.cfg`, appears above the build label, ignores mouse input and updates every 250 real milliseconds even during focus slowdown/pause. Headless tests cover state/persistence and now enforce at least 17.5 screen pixels of FPS font height, on-screen placement above the version, and a deliberately unscaled negative control at 640×720. The suite now has 124 checks, all passing.

Native operated review of `c15d606` verified enable → Back → gameplay → level-up/death → main menu → Quit → fresh process persistence. At actual 640×720, the toggle and navigation worked but FPS itself was too small and overlapped the version. The responsive-root repair was then operated successfully at exact runtime revision `f3d52b157c2a8e5c3e66319a2a457fe443f5cc52`.

Native retest coverage: actual 640×720 and maximized 3024×1726 client geometry; fresh process restores FPS on; menu → Options reflects checked; off → Back → reopen remains unchecked with no meter; on → Back → Play → Escape shows readable FPS above version while paused; pause Options off → Back → Resume keeps the meter hidden during gameplay; pause Options on → desktop resize keeps the meter readable; Back → pause → main menu → Quit completes correctly. All named FPS toggle, return, persistence and resize obligations passed. This is an FPS-specific operated review, not a full product UX pass.

Candidate-bound evidence is retained at `/Users/ljeytl/.codex/verification/spellcast/travel-performance/`: `fps-narrow-menu.png`, `fps-narrow-options.png`, `fps-narrow-off.png`, `fps-narrow-pause.png`, `fps-desktop-options.png`, and `fps-desktop-pause.png`. Runtime log: `/tmp/travel-operated-final.log`. Baseline/fixed profile and regression log copies are retained in the same verification directory. Final documentation-only commit does not change the tested runtime.

Use the isolated profile described in README, then run `godot --headless --path . --script tests/travel_settings_regression.gd`. The profile scripts use the same guard. No version bump or shareable ZIP update in this tranche.

## Recorded profile output

```json
{
  "stress_before": {
    "alive": 160,
    "enemies": 160,
    "layout_generations": 693361,
    "max_cached_layouts": 49,
    "max_decorations": 49,
    "natural_encounters": false,
    "p50_step_ms": 24.053,
    "p95_step_ms": 26.242,
    "recycled": 74,
    "renderer": "headless",
    "simulated_seconds": 20,
    "steering_ms": 14413.228,
    "steps": 600,
    "travel_distance": 6000,
    "wall_ms": 14498.393
  },
  "stress_after": {
    "alive": 160,
    "enemies": 160,
    "layout_generations": 76,
    "max_cached_layouts": 125,
    "max_decorations": 49,
    "natural_encounters": false,
    "p50_step_ms": 1.609,
    "p95_step_ms": 1.683,
    "recycled": 74,
    "renderer": "headless",
    "simulated_seconds": 20,
    "steering_ms": 966.946,
    "steps": 600,
    "travel_distance": 6000,
    "wall_ms": 1034.011
  },
  "runtime_before": {
    "alive": 160,
    "generations": 1351982,
    "max_cached_layouts": 49,
    "max_decorations": 49,
    "max_enemies": 160,
    "max_nodes": 2338,
    "physics_frames": 1800,
    "physics_p50_ms": 17.044,
    "physics_p95_ms": 31.714,
    "process_p50_ms": 1.194,
    "process_p95_ms": 2.679,
    "recycled": 112,
    "renderer": "headless",
    "seed": 4217,
    "travel_distance": 9000,
    "wall_ms": 37756.005
  },
  "runtime_after": {
    "alive": 160,
    "generations": 77,
    "max_cached_layouts": 126,
    "max_decorations": 49,
    "max_enemies": 160,
    "max_nodes": 2338,
    "physics_frames": 1800,
    "physics_p50_ms": 3.786,
    "physics_p95_ms": 5.243,
    "process_p50_ms": 1.223,
    "process_p95_ms": 3.104,
    "recycled": 116,
    "renderer": "headless",
    "seed": 4217,
    "travel_distance": 9000,
    "wall_ms": 29812.978
  }
}
```
