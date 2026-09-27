# Baseline bot

This developer-only scripted player uses the normal Game scene. It does not change enemy stats, grant XP, unlock spells, set health, teleport, or invoke spell effects directly. It holds ordinary movement actions, sends Space, character and Enter key events, and activates the same upgrade-button signal as a click. It is not a physical mouse/focus/layout test.

Run from a source checkout with Python 3 and Godot 4.4:

```sh
python3 tools/run_bot.py --seeds 11
python3 tools/run_bot.py --headless --seeds 11 29 73
python3 tools/run_bot.py --headless --fast --seconds 60 --seeds 11
python3 tools/run_bot.py --headless --fast --seconds 60 --mode idle --seeds 11 29 73
```

The first command opens a visible bot run. Each run ends at actual death or victory; `--seconds` can deliberately stop a shorter smoke test. Time-limited runs are incomplete, never victories. Reports and engine logs are written under a uniquely named directory in `builds/bot`. Use `--output` or `--godot` to change locations. Close the game window to stop a visible run early; an absent report is incomplete.

## Behavior modes

`--mode active` retains the original moving, typing, randomly upgrading bot. `idle` suppresses movement and typed spells, `movement` suppresses typed spells, and `casting` suppresses movement. Automatic Mana Bolt, enemy behavior, damage, XP and level-up choices stay enabled in every mode. These are behavioral controls, not forced death or invulnerability scenarios. Reports record mode and first damage time; validation rejects typed casts in noncasting modes or movement in stationary modes.

## Policy

Every 0.3 input seconds, flee the closest enemy within 220 world units; otherwise approach the nearest XP orb, or wander if none exists. Every 2–4 input seconds choose a random owned spell, type five characters per second, and stop moving while typing. Choose a random valid level-up card after one input second. This is deliberately unsophisticated, with no projectile prediction or special boss strategy.

Input timing is independent of the normal typing slow-motion effect. The game still controls simulation time. Casting uses Space/Enter and includes named synergies owned in the current run. Reports include per-spell cast counts.

## Interpretation and isolation

The launcher copies the source into a temporary project, configures a unique custom user directory before Godot starts, then imports and launches it. Every seed starts with a fresh profile. Bot saves are deliberately retained in the report's `save_directory` as diagnostic evidence; normal player saves are not used. The temporary project is removed after its process exits. No bot entry point is added to the regular game menu or shipped export.

Reports record outcome, survival time, level, kills, actual health damage (excluding shield absorption), attempts/successful casts/failures, typed characters, distance traveled, acquired spells, upgrade choices, minute checkpoints, revision and dirty-source state. Engine errors fail the launcher rather than silently accepting a report. A one-hour wall-time watchdog labels a stalled run separately.

Seeds make decisions repeatable under comparable conditions, not bit-for-bit deterministic. Frame scheduling, audio/visual random calls, and physics can change outcomes. Compare several seeds and use human playtests for difficulty judgments.

`--fast` is accelerated smoke testing only. It uses fixed 60 FPS simulation steps without real-time pacing. Existing spell cooldowns use wall-clock time and can reject accelerated input; do not compare its survival or casting rates against realtime runs. Configured fixed FPS and observed FPS are reported separately.
