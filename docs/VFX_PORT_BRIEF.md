# Spell VFX port: milestone brief

Read first, in order:
1. `docs/VFX_SYSTEM_PLAN.md`: architecture, current fantasy-first art direction, element looks and component templates. This brief governs the original raster renderer; the updated art direction permits other rendering techniques for spell-specific presentation.
2. `tools/vfx-reference/spell_vfx_sandbox.html`: the behavior and look reference. Open it in a browser. Every element and spell has a button; slow-mo and wind are on the toolbar. Its code is already split into engine / element data (`MAT`, `EL`, `FX`) / components / spells. Port that structure.

## Ground rules (apply to every milestone)

- **Gameplay does not change.** Damage, hitboxes, timing, targeting and spell rules stay exactly as they are. VFX only *read* gameplay state and events. Rims must match real hitboxes (`08-art-feedback.md`: visual language is a gameplay contract).
- **Hit-stop is VFX-only.** In the sandbox, hit-stop freezes the whole simulation. In the game it freezes **only the VFX simulation** for N frames. Never touch `Engine.time_scale`, `get_tree().paused`, or anything else that delays gameplay.
- **Original raster renderer.** Existing raster effects render on a coarse grid: **1 VFX px = 8 world px = 4×4 art px** (at 1920×1080 that is 160×90, 12×12 screen px each). Keep this grid stable for effects using that renderer. This is not a universal art restriction: painted spirits and Steam use separate smooth rendering paths; the rejected painted Bolt/Slash strokes have been removed. See the updated art direction in `VFX_SYSTEM_PLAN.md`.
- **Grid is defined in world units, not as a fixed 160×90.** The project uses `stretch/aspect = expand`, so the visible world rect changes with window shape (itch iframe, ultrawide, browser fullscreen). Size the grid from the visible rect plus margin; the cell size never changes. ×12 is an integer only at 1080p and 1440p. That is accepted.
- **Sandbox → game rescale.** The sandbox is 192×108. Multiply sandbox positions, radii and speeds by **160/192 ≈ 0.833**. Particle pixel sizes (1 px, 2 px dots, etc.) stay as authored.
- **Two layers:** `VfxGround` (above terrain, below actors: decals, floors, rims, warnings, ground liquid) and `VfxAir` (above actors, below UI: flames, bodies, particles, flashes, airborne liquid). Follow the sandbox draw order (`render()` near the end of the file) to decide which layer each pass goes to.
- **Before touching a file, check `git status`.** Other agents work in parallel. Do not edit, stage or commit files with someone else's uncommitted changes; stage only your own paths (never `git add -A` / `git add .`). No `checkout`, `reset`, `stash` or `clean`.
- Keep the existing **reduced effects** preference working (`ParticleManager.reduced_effects`, `EffectPreferences`). New emitters must respect a global budget from Milestone 1 on, not Milestone 3.
- Test the **web export** (Compatibility renderer, `tools/export_web.py`) at the end of every milestone, not only desktop.

## Milestone 0: grid and layers (small, do first)

1. Change `VisualDefaults.CAMERA_ZOOM` from `1.3875` to `1.5`. With the player sprite at scale 2 this gives exactly 3 screen px per art px. Update everything that pins the old value (`tests/visual_proportions_regression.gd`, `tests/readability_scale_regression.gd`; `tools/workshop/PreviewFixture.gd` reads it). Note in the changelog that the camera is about 8% closer (≈14% less visible area). Check that enemy spawn distance is not derived from the visible rect in a way that changes pacing; if it is, flag it rather than silently retune.
2. Add `VfxGround` and `VfxAir`: each a `SubViewport` sized to the visible rect in VFX cells + 2 cells margin, nearest filtering, displayed over/under actors as above.
   - World → VFX cell: `floor(world_pos / 8)` in a world-anchored grid.
   - **World lock:** the displayed texture's origin is the world position of its top-left cell, so effects stay fixed to the ground while the camera moves.
3. Implementation suggestion: CPU simulation in GDScript writing into a `PackedByteArray`, uploaded each frame with `Image.set_data` → `ImageTexture.update`. **Profile on the web export in Milestone 0**, with a stress test (several hundred flame particles). If GDScript per-pixel passes (heat accumulate, blur, palette map) don't fit the frame budget on web, move them to a shader now, before Milestone 1 builds on them.

**Accept when** a debug effect (a test flame, console-toggled) renders world-locked at the correct size next to the wizard, on desktop and web, with no jitter while walking, and the stress test stays at target frame rate on the web build.

**Status: built (10 October 2026).** What exists, and where it differs from the suggestion above:
- `scripts/vfx/Vfx.gd` autoload. Instead of a SubViewport, each layer is a world-space `Sprite2D` (scale 8, nearest) whose texture is the cell buffer and whose position is the world position of its top-left cell. The camera transform then world-locks it for free, and `z_index` (ground −1, air 50) orders it against actors. Same pixels, no camera-sync code to jitter.
- Air layer: CPU writes heat (`FORMAT_RF`) plus two RGBA8 buffers (under = smoke, over = embers); `shaders/vfx_heat.gdshader` does the blur halo, banded palette and world-locked dither parity.
- Decals are rasterized once into small world-space sprites; their dissolve is a shader uniform (`shaders/vfx_decal.gdshader`), so they cost no CPU per frame.
- Particles are stored in one interleaved `PackedFloat32Array`; turbulence uses a 256×256 lattice of `hs()` values (`vn_fast`).
- Console: `vfx flame | stress <n> | bench [frames] | stats | clear`. Test: `tests/vfx_layer_regression.gd`.
- Web numbers (Chromium, M-series Mac): 1 field 0.6 ms; 1500 flames 6.1 ms; minute-14 horde 11.2 ms without VFX and 18.7 ms with 1500 flames. Flame cap set to 1000 (400 reduced). **Milestone 1 must re-measure with real spells**; if a real horde plus spells breaks 60 fps on web, move the flame sim and splat to the GPU before porting more families.

## Milestone 1: engine core + five reference effects

Port the engine pieces from the sandbox:
- noise (`hs`, `vn`)
- particle pools: flames (with attach `inherit`/`grip`), embers, smoke, debris with z-physics, motes, rings, flashes, decals
- the **heat field** (emissive fire) and the soul-fire variant (second buffer, `SOUL` palette)
- the **liquid** renderer for water (`drawWater`) and the goo renderer (`drawGoo`), kept separate
- juice: VFX-only hit-stop and screen shake, hooked to the existing camera shake and its reduced-effects setting
- wind (visual only)
- a global particle budget wired to `ParticleManager.reduced_effects`

Then wire five effects to the **real** spells and events:

| Effect | Game spell / hook | Sandbox mode |
|---|---|---|
| Fire projectile + impact + burning status | Ember Spear contact, burn status | Fire → Ember Spear, Fire Bolt |
| Big impact | Meteor Shower impact | Fire → Meteor Shower |
| Persistent field | Cinder Field | Fire → Cinder Field |
| Liquid | (no water spell yet) debug-cast only | Water → Bolt |
| Soul fire | Seeker contact | Death → Bolt |

Hook points: `SpellProjectile.gd`, `ProjectileVisual.gd`, `EffectBurst.gd`, `EmberTrail.gd`, `LingeringArea.gd`, `AreaArt.gd`, `ParticleManager.gd`, `EffectArt.gd`. Replace the old visual for each migrated spell behind a toggle, so old and new can be compared.

**Accept when** these five match the sandbox in motion and timing on the grid, rims match hitboxes, and a late-game horde (bot or console spawn) stays at target frame rate on the web build.

## Milestone 2: all techniques and families, migrate implemented spells

- Remaining renderers and primitives: soft (steam), bubbles, rigid shards and crystals (any palette), lightning paths, growth (grass, vines, leaves), rays, crescents, glyphs, streaks, area floors (disk / line mask / moving front), walls (solid vs passable), beams, slashes, whips.
- Element data for all 14 looks (13 elements + Prism; `EL`, `FX` in the sandbox), kept as data resources, not code branches.
- Migrate **every implemented spell** one at a time, using the matching sandbox mode:

| Game spell | Sandbox reference |
|---|---|
| Magic Missile, Bolt | Arcane → Bolt (homing variant for Missile) |
| Ice Blast | Ice → Ice Blast |
| Lightning | Lightning → Bolt impact (the telegraph is the reference for strike visuals only; do not change gameplay timing) |
| Meteor Shower | Fire → Meteor Shower |
| Ember Spear | Fire → Ember Spear |
| Plague Seed (Infection) | Plague → Infection |
| Cinder Field / Firewalk | Fire → Cinder Field / Firewalk |
| Arcane Orbit | Arcane → Arcane Orbit |
| Focus Ray / Prism Ray | Arcane → Focus Ray / Prism → Prism Ray |
| Rune Trap / Frost Sigil | Arcane → Rune Trap (Frost Sigil = same trap in Ice look) |
| Seeker | Death → Seeker |
| Cross Blade | Metal → Cross Blade |
| Steam Field | Steam → Field |
| Lightning Bolt (combo) | Lightning → Chain Lightning |
| **Not in the sandbox yet** | Earth Shield, Life, Regeneration, Meteor Spear, Life Bolt, Soul Bloom: compose from the families and element looks per `VFX_SYSTEM_PLAN.md` §4 and §6.1, and flag them for visual review |

**Accept when** every implemented spell uses the new system, each one has been checked against its sandbox mode, and the old `_draw()` effect paths are removed or disabled.

## Milestone 3: keywords, reactions, polish

- Keyword accents (`VFX_SYSTEM_PLAN.md` §5): native element owns the body; the keyword element owns rim, trail, impact and status. Fiery is demonstrated in the sandbox (Fire → Fiery Bolt).
- Reaction table overrides (§5.3).
- MEGA tier, previews and warnings in ghost mode, hostile palette band for enemy projectiles.
- LOD tuning; flash limit (no more than 3 full-screen flashes per second) and screen-shake toggle.
- Visual Workshop captures per spell as the regression record.

## Out of scope for now

Hero-sprite spells (Grasping Hand, Yggdrasil, Volcano, Eye of [unnamed], Whirlpool, Lightning Rod) and any new spells: they need design approval and art first.
