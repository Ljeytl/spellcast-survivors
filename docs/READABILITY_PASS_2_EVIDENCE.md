# Readability and scale candidate

P2-09/P2-10 and P2-11 appearance implementation; final integrated visual acceptance remains open.

| Property | Baseline | Candidate |
|---|---|---|
| Camera zoom | 1.0 | 1.2 |
| Player/enemy Sprite2D scale | 2.0 | 3.5; enemy archetype/root factors retained |
| Staff orbit / sprite | 54 / 1.5 | 94.5 / 2.625 |
| Player navigation / contact rectangles | 64 / 80 | Unchanged |
| Enemy collision rectangle | 40 | Unchanged; archetype/root factors retained |
| XP sprite | 1.5–1.8 pulse | Stable 2.5 / 2.7 / 2.9 |
| XP tiers | One blue appearance | Blue <25, green 25–99, purple >=100 |
| Cosmetic burst stamp | 14 | 25; radius/count unchanged |
| Typed keys | Wrapped rows, 48px keys | One row, 48px keys, 48–54px spacing, newest key revealed |
| Prompt maximum width | 620/900 | 1000, bounded by viewport |

XP thresholds distinguish ordinary 3–18 XP kills, a few accumulated drops, and large consolidated values. Assignment to XPOrb.xp_value refreshes texture/size immediately; set_xp_value and update_visual are available. Variants preserve source art shading through cached hue conversion, without a shader or per-frame recoloring.

## Verification

- Godot 4.4.1 editor import/parser completed.
- readability_scale_regression: 58 checks, zero failures, headless and native. Includes 1280x720, 800x600, 480x640; long text, backspace, cancellation, color update, stable scale.
- Negative control restoring baseline TypingKeycaps: 13 failures from the same 58-check suite; candidate restored and passes.
- casting_presentation_regression: 244 assertions, zero failures; owned input, placement, shatter, success, rejection, overflow. Prior wrap expectations deliberately migrated to one-row behavior.
- forest_groves_regression: 4949 checks, zero failures; prior pulse expectations migrated to fixed scale. Terrain clearance geometry remains unchanged.
- minimal_interface_regression: 88 checks, zero failures.
- No configured separate lint/typecheck command found; parser and git diff --check used.

Native captures use a no-focus window positioned offscreen, preserving the user's active game. Reproduce with Godot --path . --position 5000,5000 --script tests/readability_scale_regression.gd -- --visual and isolated override userdata. Captures are under builds/readability-evidence. Inspecting actual desktop Regeneration and narrow overflow confirms readable one-row keycaps. The roster capture shows larger characters and distinct blue/green/purple crystals. The baseline-reference image only restores sprite/zoom/pickup scale within the candidate; it is not a full historical-build screenshot.

## Limits and handoff

The physical footprints were deliberately retained: changing them would also change tree clearance/contact behavior. Native static views show the larger slime/body presentation; operated pursuit/contact around trunks and crowded integrated effects still need final integration review. Final sight-range preference is player judgment. Spell origins and spell-specific status markers belong to the spells tranche and must be fitted there. HUD, staff, and sprite geometry are implemented here; no claims of complete P2 visual acceptance.
