# VFX system plan: every spell, every element, every keyword

Status: proposed plan, 9 October 2026. Documentation only. It changes no spell rules, numbers, or runtime until a build phase below is approved.

Sources: `data/spells.json`, `docs/expedition-design/03-spells.md`, `04-composition.md`, `08-art-feedback.md`, `16-element-family-matrix.md`, `17-element-spell-ideas.md`. Spell statuses follow those documents: listing a proposed spell here specifies how it would look if selected. It does not approve the spell.

Reference implementation: `tools/vfx-reference/spell_vfx_sandbox.html`, a browser demo of every element look, the emissive density field, attach points, and wind. It is a behavior and tuning reference, not engine code.

Port plan: `docs/VFX_PORT_BRIEF.md` (milestones 0–3). Where this plan and the brief disagree on engine details, **the brief wins**; this document owns the look.

---

## Art direction decision — chunky magic (locked 9 October 2026)

**Spell VFX are deliberately drawn on a coarser pixel grid than the world art.** This is intentional: magic reads as its own substance and pops off the background. It is not a resolution bug and must not be "fixed" by redrawing effects at sprite density.

| Layer | Grid at 1920×1080 | Screen pixels per grid pixel | Contents |
|---|---|---|---|
| World art | 640×360 | 3 | wizard (27×35 art px), enemies, terrain, props |
| VFX ("chunky magic") | **160×90** | **12** (= 4 art pixels) | every spell effect, status effect, impact, field, decal |
| UI | native | 1 | text, HUD, menus |

Rules that keep the mix looking intentional:

1. **Camera zoom must give integer art scaling.** Sprite scale 2 × camera zoom **1.5** = 3 screen px per art px. The current `CAMERA_ZOOM = 1.3875` (2.775 px per art px) renders uneven pixels and must change to 1.5.
2. **Every VFX pixel lands on the 160×90 grid**, aligned to the art grid (1 VFX px = exactly 4×4 art px). Effects render into a 160×90 `SubViewport` and are nearest-upscaled ×12.
3. **No off-grid transforms on effects.** Rotation, scaling and sub-pixel motion happen in simulation; the result is rasterized to the grid. Never rotate or scale an effect texture with filtering.
4. **The world never goes chunky.** Sprites, terrain and UI stay on their own grids, so the contrast is always clean.
5. **One shared VFX palette**, distinct from the world palette.
6. **Composition is already correct.** The reference sandbox (`tools/vfx-reference/spell_vfx_sandbox.html`, 192×108) frames the wizard at the same share of the screen as the game. Porting is a uniform rescale of 160/192 ≈ 0.83 on positions, radii and speeds; particle pixel sizes stay as authored.

## Reference sandbox status

`spell_vfx_sandbox.html` is the behavior and look reference for the port: 14 elements × Bolt, Field, Nova, Wave, Spear, Wall, Slash, plus whips, beams, Infection, Meteor Shower and the signature spells (about 120 modes). Look decisions that came out of review:

- **Water** uses its own liquid render (no dark outline, see-through ground water, white highlights, mostly droplets and spray). It must never share the goo renderer.
- **Plague** is bubbles first; goo appears only as small drips and stains.
- **Death** is soul fire (the emissive fire engine with a teal/violet palette) plus bones, skulls rising as souls, skeletal hands and necrotic veins. Not smoke.
- **Lightning Slash** is built from arcs that follow the swing, not a smear.
- **Lightning Bolt** telegraphs: the bolt lands, a ring locks on, a stepped leader descends, then the strike.

## 0. How to read this document

Every spell's visuals come from three things, and none of them is authored per spell:

```
Spell visuals = Σ over the spell's components ( component VFX template × element look ) + keyword accents + optional hero layer
```

- **Component VFX templates** (section 4): `14-spell-system-reference.md` already defines every spell as a graph of components (origin, geometry, delivery, motion, propagation, timing, payload, scheduler, event connections). Each component type gets one VFX template. A spell's visuals are the sum of its components' visuals, so **composite spells come for free**: Meteor Shower is warnings + falling carrier + damage disks + aftermath, and each of those already has a template (section 6.1).
- **Element look** (section 3): the rendering technique, palette, motion personality, particles, impact, status, and decal. One per element: Fire, Ice, Plague, and so on.
- **Keyword accents** (section 5): what an element contributes when it's a modifier word on someone else's spell (Icy Ember Spear), plus the non-element keywords (Big, Swift, MEGA).
- **Hero layer** (section 4.3): an optional per-spell override for the few moments that deserve hand-authored art. Existing custom visuals can stay as hero layers.

So "every spell × every type" doesn't mean hundreds of hand specs. It means: one template per component type, 13 element looks, 6 technique adapters, 13 accent kits, a short reaction table, and a handful of hero layers. The spell list in section 6 records each spell's component chain, native look, and the rare part that is genuinely unique.

---

## 1. What the repo has today

| Area | Current state | Consequence |
|---|---|---|
| Engine | Godot 4.4, Forward+, viewport 1920×1080, `stretch/mode = canvas_items`, `stretch/aspect = expand`, camera zoom 1.3875 (moves to 1.5 in VFX Milestone 0) | No low-res pixel grid, which is why the look is "vector pixel art" |
| Spell bodies | `EffectArt.gd`: one generated 4×4 motif atlas (`spell-motifs.png`), stamped and scaled with nearest filtering | Pixel sprites at arbitrary scale on a 1080p canvas |
| Effects | ~34 `_draw()` overrides; `EffectBurst`, `EmberTrail`, `LingeringArea`, `AreaArt` draw on the CPU | Colors hard-coded per kind (`EffectArt.PALETTE`); no shared material, emitter, or palette system |
| Particles | `ParticleManager.gd` pools `GPUParticles2D` but mostly spawns `EffectBurst` draws | No reusable emitter presets |
| Shaders | `shaders/day_grade.gdshader` only | Every VFX shader is new work |
| Art bible | `08-art-feedback.md`: 640×360 logical composition, integer nearest scaling | This plan's pixel grid uses exactly that |
| Web build | itch builds run on Godot's Compatibility renderer | Every primitive must be tested on the web export early |

Hard constraint, kept from `08-art-feedback.md`: **visual language is a gameplay contract.** Rims show real hitboxes; tails, glows, and particles never imply damage they don't deal; warnings never look active.

---

## 2. Engine

### 2.1 Pixel layer

- The VFX grid is defined **in world units**: 1 VFX px = 8 world px = 4×4 art px. At 1920×1080 and zoom 1.5 that is a 160×90 grid shown ×12. On other window shapes (`stretch/aspect = expand`) the grid grows or shrinks to cover the visible rect; the cell size never changes.
- **Two layers**, because effects sit both under and over actors (the sandbox draws decals, floors and ground liquid under actors, and heat, bodies and airborne liquid over them):
  - `VfxGround`: above terrain, below actors (decals, area floors, rims, warnings, ground liquid).
  - `VfxAir`: above actors, below UI (flames, bodies, particles, flashes, airborne liquid).
- **World lock:** the grid is anchored to world coordinates, not to the camera. Each layer renders the visible rect plus a margin, snapped to whole VFX cells, so effects never swim against the terrain while the camera moves.
- World sprites stay as they are. If the world moves to pure pixel art later, nothing here changes.

### 2.2 Primitives (built once, used by every element)

| # | Primitive | What it does | Modes |
|---|---|---|---|
| P1 | `VfxEmitter` | The one particle system. Trigger (per time, per distance, burst), shape (point, line, area, ring), velocity (inherit, radial, directional, orbit, spiral), space (world/local), optional **z-physics** (height, gravity, bounce, tumble) for rigid debris | — |
| P2 | `DensityField` | Particles add density into a render target; a shader turns density into pixels | **emissive** (banded palette, glow halo; fire; soul-fire variant for Death), **goo** (one hard threshold, dark outline, 1px highlight, merging blobs; plague only), **liquid** (no dark outline, see-through ground layer, white highlights, droplets and spray; water only), **soft** (dithered translucent puffs, no outline; steam) |
| P3 | `PaletteSwap` | Grayscale sprite values (light, mid, dark, outline) → material ramp, preserving shading | — |
| P4 | `DitherDissolve` | Bayer-pattern spawn-in and fade-out. Replaces alpha fades everywhere | — |
| P5 | `AreaFloor` | Noise in a shape mask, banded into dim palette steps, plus a bright 1–2px rim at the true hitbox | circle, cone, **line mask** (walls), **moving front** (waves) |
| P6 | `PathRenderer` | Lines along points | **beam** (scrolling noise), **jagged** (lightning, regenerated per frame), **whip** (verlet), **growth** (extends over time, buds sprites along it), **rays** (straight radiating lines; sun), **link** (infection, chains) |
| P7 | `Decal` | Pooled floor marks that dissolve over seconds | — |
| P8 | `Juice` | Hit-stop, hit flash, screen shake, tweens (pop, squash, pulse, overshoot). **Hit-stop freezes the VFX simulation only, never game time** (no `Engine.time_scale`): gameplay timing must not change | — |

Each element picks **one body technique**, which is a combination of these primitives:

| Technique | Built from | Elements |
|---|---|---|
| Emissive | P2 emissive + P1 | Fire, Arcane, Sun, Moon |
| Goo | P2 goo + P1 | Plague/Poison |
| Liquid | P2 liquid + P1 | Water |
| Soul fire | P2 emissive (soul palette) + P1 + bone/skull sprites | Death/Spirit |
| Soft | P2 soft + P1 | Steam |
| Rigid | P3 sprites + P1 z-physics | Ice, Earth, Metal |
| Paths | P6 jagged/beam + P1 sparks | Lightning |
| Growth | P6 growth + P1 sway-fall | Life/Nature |

### 2.3 Attach points

Every attach point carries two numbers, independent of element (tunable in the reference demo):

- `inherit` (0–0.8): fraction of the anchor's velocity a particle keeps at birth. 0 is pure lag; 0.3–0.5 gives whip and overshoot.
- `grip` (0–1): particles blend from local to world space over their life. High hugs the anchor; low sheds a trail.

| Anchor | inherit | grip |
|---|---|---|
| Fast projectile | 0.2–0.35 | 0.1–0.3 |
| Heavy projectile (ball, boulder) | 0.3 | 0.4 |
| Weapon or staff tip | 0.35–0.5 | 0.6–0.8 |
| Orbiting body | 0.5 | 0.8 |
| Status on an enemy | 0.1 | 0.9 |
| Static (field, wall, trap) | 0 | 1 |

### 2.4 Lifecycle hooks

| Hook | Fires | Typical content |
|---|---|---|
| `on_cast` | commit | caster flash, glyph, charge-up (Delayed, Charged) |
| `on_warn` | before a delayed impact | AreaFloor fill growing toward the real radius |
| `on_spawn` | body appears | dissolve-in, muzzle burst, scale pop |
| `on_travel` | each frame while moving | body, trail |
| `on_sustain` | each frame while stationary or active | floor, ambient emitter, aura |
| `on_hit` | contact | impact burst, hit flash, hit-stop |
| `on_status` | a debuff ticks on a target | grip-locked emitter on the enemy |
| `on_expire` | lifetime ends or hits terrain | fizzle, decal |

### 2.5 Wind, budget, readability

- Global wind plus optional force zones, scaled by each emitter's susceptibility (soft > goo bubbles > embers > emissive core; rigid barely). Visual only; it never moves hitboxes.
- One global particle budget. As projectile count climbs, `rate` and `perDistance` scale down per emitter, frequent procs first, big spells last.
- Readability bands, all fixed: fields and floors stay dim with bright rims; enemy projectiles keep a reserved hue and value; player VFX never use the hostile red (`EffectArt.PALETTE.hostile`) as a rim.

---

## 3. Element looks (the vibe bible)

Each element is one `VfxMaterial` data resource with these slots: **technique, palette, motion, timing, body, trail, ambient, impact, status, decal, accent kit, signature moment, sprites**. The accent kit is a lighter version of the element used when it's a keyword on another spell (section 5).

Timing scale used below: **snap** (1–3 frames), **quick** (~0.15s), **normal** (~0.3s), **heavy** (0.5s+ with hit-stop).

### Fire
- **Technique:** emissive. **Palette:** white-yellow core → orange → red → dark brown; gray smoke.
- **Motion:** rises, flickers, coherent turbulence (flame tongues), smoke shears in wind.
- **Timing:** quick impacts; bursts bloom and die fast; scorch lingers.
- **Body:** density blob shaped by the family, with a white-hot core.
- **Trail:** dense flame tail emitted per distance, plus sparse embers.
- **Ambient:** low flames, embers, smoke behind.
- **Impact:** radial heat burst, ember debris with z-physics, small smoke puff, shockwave ring on big hits.
- **Status (burning):** small flames gripping the enemy, occasional ember.
- **Decal:** scorch with a noisy edge, dissolving over ~6s.
- **Accent kit:** orange rim, ember trail, small heat burst on hit, burning status.
- **Signature moment:** the explosion bloom.
- **Sprites:** none beyond the shared kit.

### Arcane
- **Technique:** emissive, but motion spirals and orbits instead of rising. **Palette:** white → cyan → violet → deep indigo.
- **Motion:** swirls around the body, pulses on a beat, motes orbit then snap outward.
- **Timing:** quick, crisp; slightly rhythmic pulses.
- **Body:** bright core with an orbiting mote ring.
- **Trail:** spiral twinkles plus a thin streak.
- **Ambient:** slow-orbiting twinkles; faint glyphs rising and dissolving.
- **Impact:** glyph flash (a ring of runes that blinks once), twinkle burst.
- **Status (arcane mark):** small rotating glyph above the enemy.
- **Decal:** a fading rune circle.
- **Accent kit:** cyan rim, twinkle trail, glyph blink on hit.
- **Signature moment:** a rune circle snapping into place.
- **Sprites:** 4 small glyphs (5–7px), shared twinkle and ring.

### Sun
- **Technique:** emissive in white and gold, plus P6 **rays**. **Palette:** white → pale yellow → gold → amber.
- **Motion:** pushes outward; straight radiating lines; no turbulence (the only "calm" emissive).
- **Timing:** quick flare, slow fade.
- **Body:** very bright core with 4–8 short rays rotating slowly.
- **Trail:** short straight light streaks, no smoke.
- **Ambient:** slow rotating rays, dust motes catching light.
- **Impact:** flare: rays expand outward, white flash frame, glint stars.
- **Status (sunburnt/blinded):** small glint above the enemy.
- **Decal:** bleached pale circle.
- **Accent kit:** gold rim, ray glints on the body, flare on hit.
- **Signature moment:** a burst of radiating rays.
- **Sprites:** 4-point glint (5px). Rays are procedural.

### Moon
- **Technique:** emissive, soft and cool. **Palette:** white → silver-blue → lavender → night blue.
- **Motion:** slow, drifting, quiet; motes float down rather than up.
- **Timing:** normal to slow; nothing snaps.
- **Body:** crescent sprite with a soft halo.
- **Trail:** silver motes drifting down, faint crescent afterimages.
- **Ambient:** slow motes, soft halo pulse.
- **Impact:** crescent burst (crescents spinning outward), silver sparkle.
- **Status (moonlit):** a faint halo on the enemy.
- **Decal:** silver sheen that fades.
- **Accent kit:** silver rim, drifting motes, crescent flick on hit.
- **Signature moment:** a crescent sweeping across.
- **Sprites:** crescent in 2 sizes.

### Plague / Poison
- **Technique:** goo. **Palette:** pale lime highlight → toxic green → deep green → near-black purple outline.
- **Motion:** green bubbles boiling off in all directions; viscous; drips fall with gravity; slow wobble.
- **Timing:** delayed. Bubbles swell, then pop on a lag. Impacts are a splat and then a slow ooze.
- **Body:** a goo blob that wobbles, with bubbles forming on its surface.
- **Trail:** bubbles shed sideways and pop, drips.
- **Ambient:** bubbling floor, bubbles rising and popping into a dot.
- **Impact:** splat (blobs flung outward that stick to the floor), bubble burst.
- **Status (infected/poisoned):** lesion marker plus bubbles boiling off the enemy.
- **Decal:** toxic stain or puddle.
- **Accent kit (Venomous):** green drip from the body, bubble pop on hit, poison status.
- **Signature moment:** a big bubble swelling and popping.
- **Sprites:** bubble ring (2 sizes), drip.

### Death / Spirit
> Decided in sandbox review: Death is **soul fire** (the emissive engine with a teal/violet palette) plus bones, skulls rising as souls, skeletal hands and necrotic veins. Not smoke. Where the bullets below say "soft" or "wisp", the sandbox's Death mode is the reference.
- **Technique:** soul fire (emissive, second heat buffer). **Palette:** white-mint → teal → violet → deep indigo; hollow dark eyes.
- **Motion:** drifting, hollow, slow; tails trail and wave; faces stretch toward targets.
- **Timing:** slow approach, quick strike, long fade.
- **Body:** wisp head with a face, plus a trailing tail.
- **Trail:** soft wisps that wave and dissolve.
- **Ambient:** cold mist creeping on the floor, faint faces forming and dissolving.
- **Impact:** a wail puff (soft burst plus a skull silhouette for 3 frames).
- **Status (haunted):** a small wisp circling the enemy.
- **Decal:** withered patch (desaturated floor).
- **Accent kit:** pale rim, wisp trail, soul puff on hit.
- **Signature moment:** a ghost face lunging.
- **Sprites:** ghost face (2 frames), skull puff. Wisp tails are procedural.

### Water
> Decided in sandbox review: Water uses its **own liquid renderer** (`drawWater`): no dark outline, see-through ground water, white highlights, mostly droplets and spray. It must never share the goo renderer.
- **Technique:** liquid; heavier and faster than plague. **Palette:** foam white → light blue → blue → deep navy.
- **Motion:** flows along direction, splashes outward with gravity, droplets arc and land.
- **Timing:** quick splash, ripples fade.
- **Body:** water blob or stream with a moving highlight.
- **Trail:** droplets arcing down, foam bits.
- **Ambient:** rippling floor, foam lines.
- **Impact:** splash crown (droplets with z-physics), ripple rings.
- **Status (soaked):** drips falling off the enemy.
- **Decal:** puddle that shrinks.
- **Accent kit:** blue rim, droplet trail, splash on hit.
- **Signature moment:** a splash crown.
- **Sprites:** none extra (droplets are the shared dot; foam is the puff).

### Steam
- **Technique:** soft. **Palette:** white → pale gray-blue → gray.
- **Motion:** billows up and outward, expands, obscures, carried strongly by wind.
- **Timing:** slow.
- **Body:** cloud bank of dithered puffs.
- **Trail / ambient:** puffs expanding and rising.
- **Impact:** puff burst.
- **Status (scalded):** puffs rising off the enemy.
- **Decal:** none.
- **Accent kit:** puff trail, puff on hit (used by the Fire + Ice/Water reaction).
- **Signature moment:** a cloud rolling out.
- **Sprites:** none extra (shared puff).

### Ice
- **Technique:** rigid plus mist. **Palette:** white → pale cyan → blue → deep blue outline.
- **Motion:** crisp, sharp, snaps into place; cold mist drifts down slowly; snowflakes sway.
- **Timing:** snap on form and shatter; slow mist.
- **Body:** crystal or shard sprite with a glint sweep.
- **Trail:** frost motes falling, occasional snowflake.
- **Ambient:** crystals jutting from the floor, mist creeping.
- **Impact:** shatter (shards on z-physics with tumble), frost puff.
- **Status (chilled/frozen):** frost motes on the enemy; frozen adds a crystal overlay.
- **Decal:** frost rime that melts away.
- **Accent kit (Icy):** pale cyan rim, frost-mote trail, shard pop on hit, chill status.
- **Signature moment:** a crystal snapping into existence, then shattering.
- **Sprites:** shard ×3, crystal ×2, snowflake.

### Earth
- **Technique:** rigid plus dust. **Palette:** pale stone → tan → brown → dark umber.
- **Motion:** heavy; gravity always; debris bounces once and settles; dust spreads low and slow.
- **Timing:** heavy. Longest hit-stop, screen shake, the floor reacts.
- **Body:** rock, boulder, or spike sprite.
- **Trail:** dust puffs and pebbles dropping.
- **Ambient:** low dust, pebbles skittering.
- **Impact:** eruption (chunks with z-physics), dust ring, cracks spreading.
- **Status (bleeding/staggered):** small dust puffs; bleed uses small red drips (not hostile red).
- **Decal:** cracks.
- **Accent kit (Earthen):** tan rim, pebble trail, rock-chip burst plus small crack on hit.
- **Signature moment:** spikes erupting from cracks.
- **Sprites:** pebble ×3, chunk ×2, spike body, boulder body; cracks ×3 (decals).

### Metal
- **Technique:** rigid plus streaks. **Palette:** white → silver → steel gray → dark iron.
- **Motion:** fast, sharp, linear; streak afterimages; sparks with gravity.
- **Timing:** snap, with a short ringing glint after.
- **Body:** blade or fragment sprite with a moving specular glint.
- **Trail:** afterimage streaks.
- **Ambient:** rare spark.
- **Impact:** spark spray (streak particles with gravity), clang glint.
- **Status (bleeding):** small drips.
- **Decal:** scratch marks.
- **Accent kit:** silver rim, streak afterimages, spark spray on hit.
- **Signature moment:** a clean spark spray.
- **Sprites:** fragment ×2 (the blade already exists).

### Lightning
- **Technique:** paths. **Palette:** white core → pale blue → violet → deep indigo; pure-white flash frame.
- **Motion:** instant, erratic; paths regenerate every 1–2 frames; sparks jump in short straight hops.
- **Timing:** snap. 1–3 frame strikes, flash frame, then afterimage.
- **Body:** a crackling knot of short arcs, or a jagged path.
- **Trail:** short arcs jumping off the body, streak sparks.
- **Ambient:** arcs between random points in the area, a buzzing flicker.
- **Impact:** strike flash, branching arcs to the floor, sparks.
- **Status (shocked):** tiny arcs crawling over the enemy.
- **Decal:** spidering scorch.
- **Accent kit:** pale blue rim, arcs crawling over the body, mini strike on hit.
- **Signature moment:** a full-screen-height strike with a white flash frame.
- **Sprites:** none (fully procedural).

### Life / Nature
- **Technique:** growth. **Palette:** pale leaf → green → deep green → bark brown; flower accents pink and yellow.
- **Motion:** grows and sways; slow-then-sudden (vines creep, then snap tight); leaves on sway-fall; flowers bloom.
- **Timing:** normal growth, quick snap.
- **Body:** vine shoot, seed, or thorn, with leaves budding along it.
- **Trail:** leaves fluttering down, petals.
- **Ambient:** grass and flowers growing, leaves drifting.
- **Impact:** bloom (petals and leaves burst), a vine coil snapping.
- **Status (rooted/entangled):** vines wrapped around the enemy. Healing shows the existing green plus.
- **Decal:** grass or flower patch.
- **Accent kit:** green rim, leaf trail, petal burst on hit.
- **Signature moment:** a vine whipping out and wrapping.
- **Sprites:** leaf ×2, petal, thorn, vine segment and tip, flower (2 frames).

### Shared particle kit (used by every element)
dot 1px, dot 2px, plus 3px, twinkle (3 frames), puff (3 frames), streak 1×3, ring 3–5px. Total: 7 sprites.

---

## 4. Component VFX templates

### 4.0 VFX binds to components and events, not to spell names

The spell compiler in `14-spell-system-reference.md` ends with "execute shared components → emit authoritative events → present." The VFX system is the "present" step: it subscribes to those authoritative events and renders each component instance with that component's template and the spell's element look. This keeps the gameplay contract automatic: visuals are driven by the same data that drives hits.

| Component slot | Component type | VFX template |
|---|---|---|
| Origin | Self / Ground point / Entity | where `on_cast` plays; Entity origin sets the attach point |
| Geometry | Disk, Cone sector, Line/capsule, Ring/front, Body, Trail | the `AreaFloor` mask and rim shape (disk, cone, line mask, front band, body silhouette, trail union) |
| Delivery | Projectile | body + trail (`on_travel`), impact on contact |
| Delivery | Volume | rim and fill for the active region; impact cues on targets inside |
| Delivery | Beam | `PathRenderer` in the element's technique; contact sparks where it really intersects |
| Delivery | Field | dim floor, bright rim, ambient emitter (`on_sustain`) |
| Delivery | Trap | arming fill, armed pulse, trigger (hands off to its connected effect) |
| Delivery | Creature | element aura and status emitters attached to the actor; actor art is separate |
| Delivery | Collectible | ambient sway and glow; collection burst |
| Motion | Straight / Guided / Orbit / Return path | trail shape follows real motion; Guided shows the turn; Return path shows the linger hub |
| Propagation | Instant | one flash of the full rim |
| Propagation | Expanding front | bright moving band; only the band is lit as active |
| Propagation | Travelling | region visuals follow the body |
| Propagation | Sweep | rotating path or sector; no snapping |
| Timing | One-shot | single impact |
| Timing | Periodic exposure | tick shimmer synchronized to real ticks |
| Timing | Discrete pulses | one visible beat per real pulse (Earthquake's 4 rings) |
| Timing | Channel | sustained path or emitter while channeling; dissolve on interrupt |
| Payload | Damage | element impact recipe |
| Payload | Healing | green plus on real gain only (existing contract) |
| Payload | Absorption | shield segments, one per charge; break burst |
| Payload | Displacement | push streak along the real direction |
| Payload | Status | element status recipe gripped to the target |
| Payload | Infection | lesion marker, visible transfer link, orphan lifetime fade |
| Payload | Destructible structure | body with a health marker; crumble on death |
| Scheduler | Volley | more instances, patterned |
| Scheduler | Chain | link path appears only after a real hop |
| Scheduler | Repeat | echo instances with a slight hue shift |
| Scheduler | Charge | `on_cast` anticipation: gathering particles and a growing glyph or rim |
| Lifecycle | Event connection | each connected event (contact, death, expiry, collection) plays its destination component's spawn visuals at the event position |
| Additional (reserved) | Curve/strip, Flow field, Navigation obstacle, Clock influence, Reflection | whip/curved path, spiral-in motion, solid wall body, distortion ring, reflect flash |

### 4.1 Families as presets

The player-facing families (Bolt, Spear, Field...) are common component graphs. They are useful presets and the browsing language of the design docs, and each is still defined once: where the body lives, its attach point, which material slots fire on which hook, and its readability rule. Families never mention an element; they consume whatever look they're given.

| Family | Body and motion | Attach (inherit/grip) | Hooks | Readability rule |
|---|---|---|---|---|
| **Bolt** | small body, straight travel | 0.2 / 0.1 | spawn, travel (trail), hit (impact), expire | body equals collision; tail never damages |
| **Ball** | larger, slower body | 0.3 / 0.4 | travel (heavy trail), hit (big impact, shake) | blast radius flashes as a rim on impact |
| **Spear** | long thin body, fast, pierces | 0.35 / 0.2 | travel, per-contact mini impact, expire | small burst at each real contact |
| **Ray** | path from caster to endpoint | beam | sustain (path), hit (contact sparks per tick) | one clear endpoint; width equals hitbox |
| **Slice / Whip** | sweeping arc or verlet path | 0.5 / 0.8 | cast (anticipation), sweep (path), hit | arc visible only while it can hit |
| **Blast** (cone, front) | cone of particles or bodies outward | radial | cast, travel per fragment, hit | pale cone preview never damages |
| **Nova / Wave** | expanding ring or moving front | radial | spawn, sustain (front), hit | only the bright front edge damages |
| **Strike** | called down from above at a point | falling 0 / 0.3 | warn (fill grows), hit (big impact), expire | warning fill reaches full radius exactly at impact |
| **Shower** | many Strikes over an area, optionally under a moving cloud | per strike | warn, hit, sustain (cloud) | each strike has its own warning |
| **Field** | persistent area | static 0 / 1 | spawn, sustain (floor, ambient), expire | dim floor, bright rim at true radius |
| **Wall** | line-mask area, rises from the floor | static | spawn (rise), sustain, hit | rim along both edges; solid vs passable reads differently |
| **Trail** | chain of small fields behind the caster | static per patch | sustain per patch, expire per patch | one rim around the union of patches |
| **Trap / Sigil** | placed glyph that arms, then triggers | static | spawn, arming (fill), armed (pulse), trigger (Nova) | armed state clearly different from arming |
| **Shield** | segments around the caster | 0.5 / 0.8 | sustain, break (impact plus retaliation burst) | one visible segment per charge |
| **Orbit** | bodies circling the caster | 0.5 / 0.8 | sustain, hit per body | only the bodies collide, not the circle |
| **Seed** | planted or carried object that grows or spreads | status 0.1 / 0.9 | spawn, sustain (growth), spread (link path), payoff | carrier and orphan visibly marked |
| **Pursuer** (spirit) | body that hunts targets | 0.3 / 0.4 | travel, target turn cue, hit | visible turn toward the new target |
| **Returning** | out, linger, back | 0.4 / 0.3 | travel, linger (spin ring), return | linger hub visible while it hits |
| **Chain** | hop between targets | link path | hit per hop (mini impact), link | link appears only after a real hop |
| **Golem / Summon** | an actor (not VFX) | aura 0.1 / 0.9 | spawn (form), sustain (element aura on the actor), attack (impact), expire (crumble) | health marker; aura never looks like an area |
| **Restoration** | on the caster | 0 / 1 | tick (heal cue), sustain | green plus only on real healing |

### 4.2 Technique adapters (how each family's body renders per technique)

This is the table that makes "every spell in every type" work. Any spell takes its family's row and its element's technique column.

> Column note: the table predates the sandbox review. **Water** cells describe the shape only; render them with the liquid technique, not goo. **Death** cells render as soul fire plus bone and skull sprites, not soft mist. Steam keeps the soft column.

| Family | Emissive (fire, arcane, sun, moon) | Goo (plague, water) | Soft (death, steam) | Rigid (ice, earth, metal) | Paths (lightning) | Growth (life) |
|---|---|---|---|---|---|---|
| Bolt | density teardrop + core | wobbling goo drop | wisp head + tail | shard or pebble sprite, spinning | knot of short arcs | thorn or seed with leaf trail |
| Ball | dense sphere, heavy tail | big goo sphere, bubbling | cloud ball | boulder or ice orb sprite | sphere of arcs | seed pod or vine ball |
| Spear | long core with a density sheath | stream with drips | long wisp | crystal, rock, or metal spear sprite | straight bolt path | vine shoot growing to the target |
| Ray | beam with a density sheath | water or ooze stream (beam + drips) | haze beam | crystal line growing out | jagged beam | vine lash, rooted at the caster |
| Slice / Whip | glowing arc smear | water whip (verlet + droplets) | wisp scythe | blade arc, shards along it | lightning whip (jagged verlet) | vine whip (growth verlet + leaves) |
| Blast | flame cone | spray of goo blobs | puff cone | shard or rock fan (sprites) | arc fan | thorn or petal fan |
| Nova / Wave | expanding fire ring | splash ring or wave front | mist ring | ring of spikes or crystals erupting | radial arcs | ring of vines erupting |
| Strike | pillar of flame from above | falling glob, splat | falling ghost | falling icicle, rock, or spike from below | sky strike | flower bursting from the ground |
| Shower | many strikes, ember rain | rain or ooze drops | ghost rain | hail or rockfall | rain of strikes | petal or seed rain |
| Field | flames over a dim floor | bubbling puddle | fog bank | crystals or rubble on the floor | arcs between points | grass and vines growing |
| Wall | line of rising flames | ooze ridge | fog wall | row of crystals or rocks rising | arc between two coils | hedge or root wall growing |
| Trail | burning patches | ooze or muck patches | mist trail | frost or rubble patches | crackling patches | flower or vine trail |
| Trap / Sigil | fire rune | bubbling ring | spectral circle | crystal or spike ring | coil circle | thorn circle |
| Shield | flame shell | bubble membrane | wisp shell | stone or ice segments | crackling shell | bark shell |
| Orbit | orbiting flame motes | orbiting bubbles | orbiting wisps | orbiting shards | orbiting arc nodes | orbiting leaves or petals |
| Seed | ember seed growing into a flame turret | spore spreading | soul spreading | crystal growing | charged node | sprout growing |
| Pursuer | fire wisp | goo slug | ghost | stone or ice bird (sprite) | ball lightning | seed sprite |
| Returning | fire disc | goo boomerang | wisp scythe | blade (existing) | arc ring | leaf boomerang |
| Chain | fire hop | goo hop | soul hop | shard hop | lightning chain | vine hop |
| Golem | fire aura on actor | dripping aura | wisps | stone or ice armor | arcs crawling | moss and leaves |
| Restoration | warm flare | cleansing drops | — | — | — | leaves and green plus |

Cells marked "—" have no meaningful pairing yet; if a spell needs one, add it then.

### 4.3 Hero layers (the escape hatch for custom VFX)

A spell may attach a hero layer to any of its events. It adds to the generated visuals, or replaces one slot of them, and it never changes the gameplay rim. Rules:

- Existing custom visuals that already work stay as hero layers; they migrate only if the generated version is better.
- A hero layer is still palette-swapped where possible, so keyword accents keep working on it.
- Keep the list short. Current candidates: Atomic, Grasping Hand's hand, Yggdrasil's tree, the lightning sky strike, and each element's signature moment (section 3).

---

## 5. Keywords and combinations

### 5.1 The accent rule

From `04-composition.md`: Fiery, Icy, and Earthen convert damage; Flaming adds fire on top; Venomous adds poison. Visually:

- The **native element owns the body**: shape, body technique, body palette. Icy Ember Spear is still a burning spear.
- The **keyword element owns the accent**: rim color, an extra trail emitter, the impact, and the status. Because conversion changes the damage type, the hit feedback must read as the new element.
- Accents always use that element's **accent kit** (section 3), which is deliberately small: it decorates and never competes with the body.

| Case | Rule | Example |
|---|---|---|
| Conversion (Fiery, Icy, Earthen) | body = native; rim + trail + impact + status = keyword element | Icy Ember Spear: fire spear, frost rim, frost-mote trail added, shards on hit, chill status |
| Additive (Flaming) | native visuals unchanged, plus the full fire accent kit | Flaming Earth Wall: rock wall, flames rising along it |
| Status (Venomous) | plague accent kit on hit and status only | Venomous Bolt: arcane bolt, green drip, poison bubbles on targets |
| Same element (Fiery Ember Spear) | no accent; treat as an intensity bump (brighter core, denser trail) | — |
| Two element keywords | rejected by the parser (mutually exclusive), so no third slot is needed | — |
| Future element words (Shocking, Ghostly, Blooming...) | each already has an accent kit, so they work on day one | — |

### 5.2 Non-element keywords

| Keyword | Visual mapping |
|---|---|
| Big | scale body, emitter area, rim, and decal together (all read the same gameplay dimension) |
| Powerful | brighter core, one impact tier up (bigger burst, longer hit-stop) |
| Swift | nothing explicit; velocity already lengthens trails and adds stretch |
| Seeking | nothing explicit; the curve shows up in the trail |
| Repulsing | small Nova ring at impact, plus a push-direction streak |
| Duplicating / Repeating | more instances; repeats can shift hue slightly for readability |
| Delayed / Charged | `on_cast` anticipation: growing glyph or rim and gathering particles |
| Lasting | longer lifetime only |
| MEGA | hero tier: full layer stack, screen shake, signature moment at maximum size |

### 5.3 Reaction table (hand-authored overrides, kept short)

Only for pairs where plain body-plus-accent would read wrong or miss an obvious payoff.

| Pair (body + accent) | Override | Related spell |
|---|---|---|
| Fire + Ice, or Fire + Water | impact becomes a steam burst | Steam Field |
| Fire + Earth | glowing magma crack decal | Meteor Spear |
| Fire + Plague | flames turn cursed green (palette swap) | — |
| Fire + Life | burning leaves on impact, then ash | Sunbeam (gold variant) |
| Ice + Water | water freezes on impact (rigid shards from goo) | — |
| Lightning + Water or Metal | arcs jump along the puddle or metal body | — |
| Earth + Ice | permafrost: rime-coated cracks | — |
| Plague + Life | stains bloom into flowers | Soul Bloom |
| Death + Life | withering: green desaturates to gray on impact | — |
| Arcane + Fire | prism palette (violet core, white rim) | Prism Ray |

---

## 6. Spell-by-spell

Status key: **I** implemented, **C** enabled combination, **U** user concept (17-element-spell-ideas), **P** proposed in 03-spells, **D** inactive data or disabled, **TBD** explicitly unnamed exploration.

"Look" is the element look from section 3, which can differ within a school (Water/Ice spells pick Water or Ice; Plague/Death spells pick Plague or Death). "Unique" lists the only spell-specific work; "—" means fully built from components plus look.

### 6.1 Composite spells (multiple components chained by events)

These are the spells with "a lot going on." Each row is the spell's component chain, with the VFX each stage contributes. Nothing here needs a new template; the richness comes from stacking.

| Spell | Component chain → VFX per stage |
|---|---|
| **Meteor Shower** | ground pattern → scheduled warnings (disk fill growing per meteor) → falling carrier (rock body in Earth look, heat tail in Fire look, ground shadow growing) → damage disk on impact (heat burst, shockwave ring, ember and rock debris, shake) → brief aftermath field (dim ember floor) → scorch and crack decal |
| **Volcano** (U?) | ground point → eruption volume (pillar of flame, rock debris launched up) → lingering field (vent: dim lava floor, rim) → periodic shower emission from the vent (small ember strikes with their own warnings) → magma crack decal |
| **Earthquake** (P) | self → discrete pulses ×4 → expanding front per pulse (crack ring band, dust, rock chips on the band) → displacement on first contact (push streak) → cracks accumulating |
| **Meteor Spear** (C) | projectile spear (Fire) → contact event → small damage disk excluding the victim (mini meteor impact, Earth debris) |
| **Lightning Bolt** (C) | projectile (Arcane body, Lightning accent) → contact → chain traversal (link path after each real hop) → splash disk per hop (mini strike) |
| **Life Bolt** (C) | projectile → contact → collectible seed (leaf sway, glow) → collection (healing plus) |
| **Earth Spear** (U) | projectile spear (Earth) → contact → volley of small spears (Blast fan of rock shards) |
| **Lightning rod** (U?) | projectile spear → embed or land → persistent field around the rod → periodic strikes (sky strikes with warnings) → persists after host death (rod keeps its own ambient arcs) |
| **Earth Shield** (I) | self → absorption charges (one stone segment per charge) → hit event → charge breaks (segment shatters) → cone volume toward the attacker (eruption, knockback streak) |
| **Rune Trap / Frost Sigil** (I/C) | ground point → trap (arming fill → armed pulse) → trigger → disk damage (Nova ring, glyph flash) → Frost Sigil adds slow status and frost decal |
| **Plague Seed** (I) | projectile seed → host infection (lesion, bubbling status) → transfer (spore travels along a visible link) → orphan spore after host death (finite fade) |
| **Soul Bloom** (C) | Plague Seed chain → death event → collectible healing patch (Life look bloom) |
| **Steam Field** (C) | field (Steam look: fog bank floor, puffs) → periodic exposure (tick shimmer) + slow status (scald puffs on targets) |
| **Fire Shield** (U) | absorption (flame shell) → hit → cone volume (fire Blast toward the attacker) |
| **Flame Seed** (U) | ground point → seed (ember grows over time) → creature or turret (flame aura) → its attacks reuse Fire Bolt visuals |
| **Grasping Hand** (U) | ground point → warning disk → hero hand rises (hero layer) → root status (spectral fingers gripping targets) |
| **Yggdrasil** (P) | ground point → structure (tree, hero layer) → field (green rim) → periodic heal pulses on the player + root lashes on enemies (separate recipient filters, separate visuals) |
| **Tsunami** (U) | origin behind the player → line/capsule front, travelling → contact (splash, displacement streak) → foam residue fading |
| **Shillelagh** (U) | self → travelling front along the ground (roots erupting along the band) → contact (vine coil snap, optional pull streak) |
| **Mana Storm / Blizzard** (U) | moving cloud (field attached to a mover, Soft-technique cloud) → shower emission (daggers or hail, each with a small warning) → Blizzard adds a slow-zone floor under the cloud |
| **Atomic** (I) | self → expanding front, screen-wide (hero layer: flare, heat bloom) → maximum juice |

### 6.2 Every spell, by school

### Arcane / Mana
| Spell | Status | Family | Look | Notes | Unique |
|---|---|---|---|---|---|
| Magic Missile | I | Bolt (homing) | Arcane | small core, spiral trail | — |
| Bolt | I | Bolt | Arcane | existing bolt motif as body | — |
| Focus Ray | I | Ray | Arcane | thin stable beam, endpoint sparks | — |
| Arcane Orbit | I | Orbit | Arcane | 3 crystal bodies (existing motif) | — |
| Rune Trap | I | Trap | Arcane | arming fill, armed pulse, glyph-flash trigger | — |
| Atomic | I (reward) | Nova (hero) | Sun + Fire | screen-wide flare and heat bloom | hero tier only |
| Arcane Slash | U | Slice | Arcane | glyph lines cut into the floor, then detonate | glyph-line decal that arms |
| Mana Storm | U | Shower (moving cloud) | Arcane | cloud raining dagger-shaped streaks | dagger streak sprite |
| Arcane Nova | U | Nova | Arcane | expanding ring with orbiting glyphs | — |
| Eye of [unnamed] | U? | Field (gravity well) | Arcane | spiral-in motion, dark center, eye glyph | eye glyph sprite |
| Prism Wall | U | Wall | prism palette | refracting rim; reflected hits flash on the wall | — |
| Prismatic Shield | U | Shield | prism palette | full shell instead of segments while active | — |
| XP magnet | U? | Restoration (utility) | Arcane | link paths from XP to the player | — |
| Time Warp / Arcane Turret / Arcane Missiles | D | Field / Golem / Bolt ×N | Arcane | inactive; templates apply if revived | — |

### Fire
| Spell | Status | Family | Look | Notes | Unique |
|---|---|---|---|---|---|
| Ember Spear | I | Spear | Fire | heat sheath, ember tail, burst per pierce | — |
| Cinder Field | I | Field | Fire | dim ember floor, sparse flames, smoke | — |
| Firewalk | I | Trail | Fire | small burning patches, one union rim | — |
| Meteor Shower | I | Shower | Fire body, Earth debris | warning fills, rock with heat tail, explosion, scorch | — |
| Fire Bolt | U | Bolt | Fire | density teardrop; small burst | — |
| Fireball | U | Ball | Fire | heavy tail; explosion bloom with shake | — |
| Scorching Ray | U? | Ray ×2–3 | Fire | lingering beams, scorch line decal | — |
| Flame Wall | U | Wall (passable) | Fire | line of rising flames; dimmer floor to show passable | — |
| Volcano | U? | Strike + Field | Fire + Earth | eruption then lingering vent emitting embers | vent sprite |
| Firestorm | questioned | Field (moving, self-centered) | Fire | churning ring around the caster | — |
| Fire Shield | U | Shield | Fire | flame shell; breaks into a fire Blast | — |
| Fire Orbit | U | Orbit | Fire | orbiting flame motes, burning on contact | — |
| Flame Seed | U | Seed → turret | Fire | ember seed grows into a small flame turret | turret sprite |
| Fire Golem / Flame Elemental | U? / D | Golem | Fire | fire aura on the actor | actor art |
| Flaming Restoration | U? | Restoration | Fire | warm flare on the caster | — |

### Water / Ice
| Spell | Status | Family | Look | Notes | Unique |
|---|---|---|---|---|---|
| Ice Blast | I | Blast | Ice | shard fan, frost-mote trails, mini shatter | — |
| Snowball | U | Bolt | Ice | snowball body, puff impact | snowball sprite |
| Ice / Glacial Spear | U? | Spear | Ice | crystal spear; impale pins a crystal on the target | — |
| Water Jet | U | Ray | Water | tracking stream with drips; knockback splash at the end | — |
| Water Whip | U | Whip | Water | verlet water whip, droplets fly off | — |
| Tsunami | U | Blast (moving front) | Water | wide wave front from behind the player, foam crest | — |
| Wave | P | Nova (directional front) | Water | crescent ridge; contact only at the front | — |
| Frost Nova | U (D data) | Nova | Ice | ring of crystals snapping outward | — |
| Falling icicle | U? | Strike | Ice | icicle falls, shatters | icicle sprite |
| Blizzard | U? | Shower (moving cloud) | Ice + Steam soft cloud | snow cloud, slow-zone floor | — |
| Whirlpool | U? | Field (vortex) | Water | spiral-in ripples, foam spiral | — |

### Lightning
| Spell | Status | Family | Look | Notes | Unique |
|---|---|---|---|---|---|
| Lightning | I | Strike | Lightning | warning rim, sky strike, spidering scorch | — |
| Lightning Spear / rod | U? | Spear → Field | Lightning | spear embeds; the rod calls strikes around it | rod sprite |
| Static Shock | U? | Ray (chained) | Lightning | jagged beam hopping between targets | — |
| Lightning Whip | U | Whip | Lightning | jagged verlet whip | — |
| Thunderwave | U | Nova | Lightning | radial arcs plus a pressure ring | — |
| Rain of Lightning | U | Shower | Lightning | many small strikes | — |
| Static Field | U | Field | Lightning | arcs between random points in the area | — |
| Tesla Wall | U | Wall (two endpoints) | Lightning + Metal | two coils joined by an arc path | coil sprite |
| Lightning Crown (storm aura) | idea | Field (following) | Lightning | ring around the player; exposure charge cue on enemies, then a zap | charge-cue marker |

### Earth / Metal
| Spell | Status | Family | Look | Notes | Unique |
|---|---|---|---|---|---|
| Earth Shield | I | Shield | Earth | stone segments; break into an eruption cone | — |
| Cross Blade | I | Returning | Metal | blade spin, streak afterimages, linger spark ring | — |
| Spike | U | Strike (from below) | Earth | crack, then spike erupts | spike sprite |
| Bullet / Spray | U? | Bolt (rapid) | Metal | streak bullets, spark impacts | — |
| Boulder | U | Ball | Earth | heavy rolling boulder, dust trail, big shake | boulder sprite |
| Earth Spear | U | Spear (shatters) | Earth | spear shatters into small spears (Blast) | — |
| Slash | U | Slice | Metal | arc smear, sparks | — |
| Earth Blast | U | Blast | Earth | rock fragment cone | — |
| Shrapnel | U? | Blast | Metal | fragment spray | — |
| Earth Nova | U | Nova | Earth | radial spikes erupting from cracks | — |
| Earth Wall | U | Wall (solid) | Earth | rocks rising; solid wall reads heavier than passable walls | — |
| Muck | U? | Trail | Earth + goo | brown goo patches (goo technique, earth palette) | — |
| Earth Trap | U | Trap | Earth | spike ring that snaps up | — |
| Earthquake | P | Nova (pulsed) | Earth | 4 crack rings, one per real damage beat | — |
| Summon Golem / Earth Golem | P / U | Golem | Earth | form from rubble, crumble on expire | actor art |

### Plague / Death
| Spell | Status | Family | Look | Notes | Unique |
|---|---|---|---|---|---|
| Plague Seed (Infection) | I | Seed (spreading) | Plague | lesion on host, spore link, bubbling, orphan dissolve | — |
| Seeker | I | Pursuer | Death | ghost face, wisp tail, visible turn | — |
| Carcass projectile | U? | Ball | Plague | carcass body, splat, dead-zone puddle | carcass sprite |
| Plague Spear | TBD | Spear | Plague | if selected: ooze stream sheath, drip trail | — |
| Ray of Sickness | U | Ray (sweeping) | Plague | haze-green beam, bubbles where it touches | — |
| Grasping Hand | U | Strike + Field | Death | spectral hand rises and closes on the real area | hand sprite (hero) |
| Plague Nova / Shower / Field / Wall / Trail / Trap | TBD | per family | Plague or Death | no spells invented; family × look covers them when named | — |
| Soul Bloom | C | Seed + Restoration | Plague + Life | kills create healing bloom patches | — |
| Skeleton Warrior / Reaping Spirit | D | Golem / Pursuer | Death | templates apply if revived | — |

### Life / Nature
| Spell | Status | Family | Look | Notes | Unique |
|---|---|---|---|---|---|
| Life | I | Restoration | Life | leaf rises, green plus | — |
| Regeneration | I | Restoration (sustained) | Life | orbiting leaves, plus on each real tick | — |
| Vine ball | U? | Ball | Life | vine pod; on impact vines spread and root | — |
| Shillelagh | U | Spear (moving root front) | Life | roots erupt along a directional moving front | — |
| Vine Whip | U | Whip | Life | growth verlet whip with leaves | — |
| Expanding vines / Life Nova | U? | Nova | Life | ring of vines erupting outward | — |
| Poisonous or exploding flowers | U? | Strike or Shower | Life + Plague accent | flowers bloom, then pop or poison | flower sprite |
| Flower or vine trail | U? | Trail | Life | flowers or vines growing behind the player | — |
| Yggdrasil | P | Field (mixed) | Life | tree grows; heal pulses and root lashes | tree (hero) |
| Divine Aura / Chain Heal | D | Restoration / Chain | Life | templates apply if revived | — |

### Combinations and themes
| Spell | Status | Family | Look | Notes |
|---|---|---|---|---|
| Lightning Bolt | C | Bolt + Chain | Arcane body, Lightning accent | mini strike per bounce, link paths |
| Life Bolt | C | Bolt + pickup | Arcane body, Life accent | seed pickup sways with leaves |
| Meteor Spear | C | Spear + Strike | Fire, Earth accent | mini meteor impact per contact |
| Steam Field | C | Field | Steam | fog bank floor, puffs; slow zone readable by rim |
| Prism Ray | C | Ray | prism palette | wider beam, crystal nodes at contacts |
| Frost Sigil | C | Trap | Ice | rune in Ice, frost decal on burst |
| Sunbeam | U | Ray | Sun | beam with radiating rays along it |
| Moon / Crescent Slash | U | Slice ×3 | Moon | three crescent smears |
| Moonfall | P | Field | Moon | crescent above, silver floor, separate green heal pulses |
| Daybreak / Solar Flare | reserved | Nova / Blast | Sun | flare burst / ray fan |

### Player movement (non-spell)
| Ability | Status | Look |
|---|---|---|
| Dash | idea | afterimage streaks of the wizard, dust puff at start and end |
| Swiftness | idea | wind lines behind the wizard, faint speed trail |

---

## 7. Inventory

| Item | Count | Notes |
|---|---|---|
| Primitives | 8 | section 2.2 |
| Techniques | 8 | emissive, soul fire, goo, liquid, soft, rigid, paths, growth |
| Shaders | 7 | `palette_swap`, `density_emissive`, `density_goo`, `density_soft`, `dither_dissolve`, `area_floor`, `beam_scroll` |
| Element looks (data) | 14 | 13 elements + Prism; plus palette-only variant: cursed fire |
| Component VFX templates (code) | ~30 | one per component type in section 4.0 |
| Family presets (data) | 21 | common component graphs, section 4.1 |
| Hero layers | ~5 plus 13 signature moments | section 4.3 |
| Motion presets | 13 | rise-flicker, spiral, drift-down, sway-fall, ballistic-tumble, bounce-settle, radial-burst, orbit, spiral-in, jump-hop, bubble-rise-pop, puff-expand, streak |
| Emitter recipes (data) | 13 looks × 4 slots (trail, ambient, impact, status) = **52** | plus 13 accent kits |
| Shared particle sprites | 7 | section 3 |
| Element sprites | ~33 | Arcane 4, Sun 1, Moon 2, Plague 3, Death 2, Ice 6, Earth 7, Metal 2, Life 6 |
| Spell-specific sprites (only if selected) | ~14 | snowball, boulder, spike, icicle, rod, coil, vent, turret, carcass, flower, dagger streak, eye glyph, charge cue, hand |
| Hero flipbooks | 10 | glyph flash, sun flare, crescent burst, plague splat, ghost wail, splash crown, ice shatter, earth eruption, lightning strike, life bloom. Fire's bloom is procedural |
| Decals | 12 | scorch, rune fade, bleach, silver sheen, stain, withered, puddle, frost rime, cracks ×3, scratch, spider scorch, flowers. Several are procedural |

All sprites are grayscale 4-value and palette-swapped. Most are 3–16px. They can be generated with a pixel-native tool, quantized to the master palette, and hand-cleaned (the motif atlas already came from image generation).

---

## 8. Build order

Fire first because it exercises nearly every primitive. Then one element per remaining technique, so the engine API is proven against all six before the Godot port is locked.

| Phase | Work | Where |
|---|---|---|
| 1 | **Fire complete** across Bolt, Ball, Spear, Field, Trail, Shower, Wall, plus burning status, scorch, explosion, and the Fiery accent on an Arcane Bolt | browser sandbox |
| 2 | **One element per technique**: Plague (goo), Steam (soft), Ice (rigid), Lightning (paths), Life (growth) | browser sandbox |
| 3 | **Engine port** (see `VFX_PORT_BRIEF.md`): VfxGround + VfxAir on the world-locked 160×90 grid, primitives P1–P8, component templates subscribed to the compiler's authoritative events. Extend the existing **Visual Workshop** (`tools/workshop/`) as the Godot sandbox: keyword input, hot-reload of material data, layer toggles. Its spell-gallery captures become the visual regression record | Godot |
| 4 | **Migrate implemented spells** one at a time from `EffectArt`/`EffectBurst`, behind the existing effect preferences. Verify readability in a full late-game horde and on the web build | Godot |
| 5 | **Remaining looks** as data: Arcane, Sun, Moon, Death, Water, Earth, Metal | sandbox → Godot data |
| 6 | **Keyword accents and the reaction table** | Godot |
| 7 | **Hero flipbooks and decals** as Floorman delivers; procedural placeholders until then | Godot |
| 8 | **Budget pass**: global cap, LOD, reduced-effects tied to `ParticleManager.reduced_effects` | Godot |
| 9 | New family modes (whip, line mask, moving front) only when a spell needing them is approved | Godot |

---

## 9. Also in scope (easy to miss)

| Area | What it needs | Why it matters |
|---|---|---|
| Previews and warnings | a "ghost" render mode of any component graph: outline and pale fill only, never the active look | `03-spells.md` requires previews that never look like damage (Ice Blast fan, warning disks) |
| Casting presentation | `on_cast` hooks connect to the existing casting circle and typing feedback | the cast is the wizard fantasy's first frame |
| Audio | the same authoritative events drive sound; VFX timing and sound timing come from one source | impacts that look and sound out of sync feel broken |
| Enemy and boss VFX | same engine, a reserved hostile palette band, never the player's rim colors | readability in dense hordes |
| Pickups and XP | Collectible template (sway, glow, collect burst) | healing seeds, XP crystals, boss rewards |
| Rank and level scaling | nothing new: visuals read the same gameplay dimensions, so bigger and more come automatically | avoids a second size system |
| Accessibility | reduced-effects tier; flash limit (no more than 3 full-screen flashes per second, lightning included); option to dim screen shake | photosensitivity and comfort |
| Performance | global budget, per-emitter LOD, a late-game soup test in the workshop, web-build profiling | the late game is where VFX breaks |
| Regression | gallery captures per spell × look, plus a contract test that every rim matches its hitbox (extending `spell_motif_contract.gd` and `spell_geometry_spores_regression.gd`) | keeps the gameplay contract true as visuals change |

## 10. Open decisions

1. ~~VFX-only 640×360 layer now, or move the whole world?~~ Resolved: VFX on a world-locked 160×90 grid (chunky magic); world stays as is.
2. Master palette from Floorman before tuning, or tune with placeholder ramps and swap later?
3. Confirm the accent rule: native element owns the body; keyword element owns rim, trail, impact, and status.
4. For split schools, confirm the look is chosen per spell (Water vs Ice, Earth vs Metal, Plague vs Death).