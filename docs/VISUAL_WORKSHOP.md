# Visual workshop

## Scope and appearance

Use the existing grass clearing as the stage, with the current wizard, authored enemies and scenery. Chrome: forest #253d2a, gray stone #3c4745, edge #68736b, pale lettering #e5e6ca and gold #dcbe76. Georgia titles suggest a spellbook; Verdana controls favor readability. A wide actual-renderer preview sits left of a compact control rail, stacking above it on narrow screens. The spell is the focus.

## Build and launch

From an isolated checkout, run:

    python3 tools/build_visual_workshop.py

This creates an ignored staging project with its own application/save identity, compatibility renderer and workshop main scene. Normal project settings and saves are untouched. Requires Godot 4.4.1 export templates. Run `python3 tools/serve_previews.py --directory builds --port 8766` and open /visual-workshop/. This loopback server supports byte ranges required for video seeking and frame stepping in the browser.

The workshop casts real rank-one spells against stationary durable enemies. Firewalk moves the caster. Pause, Step, Replay, speed and loops control the preview. Selecting an effect or Replay starts playback even after a pause, so short effects do not appear broken on an empty first frame.

Sizing affects wizard/enemy artwork and scenery, projectile artwork (collision shapes inversely compensated), and emitted particle stamp sizes. Particle sizing does not change spell area geometry. Comparison shows all twelve regular variants. Selected-enemy sizing is stored independently per variant within the preview and included in exported settings. Health, damage, range and gameplay difficulty are not tuning controls.

Export downloads JSON with preview multipliers and source revision. It never writes game configuration. Reload starts with defaults; Reset sizes restores current-game proportions, default target and scenery. The developer catalog casts any implemented spell solely in this isolated fixture; actual gameplay still requires acquisition.

## Continuous captures

After building the staging project:

    Godot --path builds/workshop-project --script tools/workshop/CaptureLoops.gd --write-movie builds/spell-gallery/all-effects.avi --fixed-fps 30 --resolution 960x600
    python3 tools/encode_spell_loops.py --movie builds/workshop-project/builds/spell-gallery/all-effects.avi
    python3 tools/build_spell_gallery.py --folder builds/workshop-project/builds/spell-gallery

Use the installed Godot executable in place of Godot. Movie paths are relative to the staging project; Python paths are relative to the checkout. FFmpeg encodes 30fps MP4 previews and 15fps 640px GIF downloads. Durations cover authored effects and tails. Life Bolt's seed remains until expiry; traps trigger against nearby targets. One configured example represents each particle factory. No interpolation invents movement.

Publish catalog, index, PNG posters, MP4s and GIFs under builds/current/spell-gallery, and workshop output under builds/current/visual-workshop. Raw AVI is a reproducible intermediate.

## Verification obligations

- Loading: real renderer ready, no missing assets or script errors; explain unavailable WebGL.
- Selection: every catalog entry captured; search, empty result, clear and select preserve an honest displayed selection.
- Transport: pause holds simulation and delayed meteor timers, step advances, Replay resets, loops repeat, speed changes, selection after pause starts visibly.
- Sizes: independent visible changes, no compounding, reset, comparison and scenery visibility.
- Export: JSON reflects selected controls/source revision; gameplay files unchanged.
- Gallery: filters/counts, empty search, visible-loop playback, modal pause/close/Escape, frame steps, seek, speed, GIF download; offscreen previews pause.
- Lifecycle: desktop/narrow, reload defaults, integrated-source provenance. Books have separate acquisition/reset/menu regressions.
- Negative control: native fixture deliberately compounds scale and must fail that exact invariant.

## Projectile body sizing and impact contract

The **Projectile artwork only** control uses `ProjectileVisual` to scale drawings, never the physics node. Bolts, the Ice Blast shard fan, Ember/Meteor Lance, Cross Blade, Seeker, Arcane Orbit bodies, Plague/Soul Bloom spores and falling meteor rocks all opt into this contract. Orbit centers, cast reach, movement speed, collisions, meteor warning rings and explosion radii remain authored values. Particle size controls decorative fragments separately, including the directional particle demonstration.

Ice Blast applies damage, slow and knockback when a moving shard sweeps across an enemy hurtbox. A shard is consumed on contact; an enemy can take damage only once from one fan. Plague spores attach infection markers only on arrival. Both initial and spread spores travel, including death transfers; pending spores count toward the eight-host cap. Invalidated targets can redirect to another eligible live host within the original acquisition radius, or expire.

Release visual checks should pause Ice Blast before its first contact (no red flashes), then step into contact; compare small/large projectile settings for each registered family while keeping meteor area outlines and orbit paths fixed. Check plague flight, marker arrival, first damage tick and death-spread flight separately.

Native draw verification: after building the staging project, run Godot with `--path builds/workshop-project --script tools/workshop/TestProjectileRendering.gd`. It compares frozen 1x and 2.5x renders for thirteen projectile spell bodies; `-- --known-bad-sizing` disables the size response and must fail. Images are saved under staging `builds/comparison/`.

## Gameplay Spell Size

The **Spell Size (gameplay)** control sets the preview player's real `spell_size_multiplier` and rebuilds the cast. This is the same factor used by the Spell Size passive (+12% per rank, one of six passive families). It increases projectile contact width, beam width, area radius, orbit body size, Cross Blade contact radius, trap trigger/explosion radius and Firewalk width together with their visible drawings. It does not increase travel distance, orbit path, attack count, damage, speed or piercing. Ice Blast grows individual shard bodies, not fan reach. Meteor Shower grows warning and impact radius together. Projectile artwork-only and decorative-particle controls remain art experiments and do not change combat geometry. Export/reset include all three controls; exports never write gameplay files.

Shared `SpellGeometry` dimensions account for the authored opaque stamp body rather than the nominal canvas rectangle. Target hurtboxes are separate and spell edge contact may overlap those hurtboxes. Artistic glow, trails and small fragments remain decoration; they do not inflict extra hits.

Plague and Soul Bloom host deaths immediately launch toward a nearby eligible host or leave one pulsing spore for three seconds. Resting spores cause no damage and acquire within 130 world units (scaled by Spell Size). Infection starts on arrival, then ticks after its interval; each new host receives the spell's authored infection duration. Consequently a late death can outlive the original cast timer. Eight unique successful arrivals per cast bound the chain; dead pending targets consume no arrival, and a fresh death spore finding a host receives up to three seconds to travel, while subsequent pending/resting redirects preserve that absolute flight deadline. An eighth successful host cannot create a ninth infection. At most eight living/pending/resting entities are retained; stale host records are removed. Expired or already visited hosts cannot restart the chain.

Run `tests/spell_geometry_spores_regression.gd` for boundaries and lifecycle. Its `--known-bad-size` control disables the larger gameplay size and must fail 2× boundary checks; `--known-bad-spores` removes the late-death remainder and must fail retention/arrival checks. Native rendering and release browser verification remain separate gates.
