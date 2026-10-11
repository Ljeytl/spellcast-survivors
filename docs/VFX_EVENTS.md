# VFX event contract

Status: in use, 11 October 2026. Companion to `VFX_SYSTEM_PLAN.md` (looks) and `VFX_PORT_BRIEF.md` (engine).

The spell engine (`scripts/engine/GenericCast.gd`, `SpellPart.gd`) announces moments. The VFX layer (`scripts/vfx/Vfx.gd` + `VfxPresenter.gd`) decides how they look, from the cast plan. This is the "present" step in doc 18 §3: *casting circle + VFX read the same plan*.

## Rules

1. **VFX only read.** Handlers read positions, geometry, plan data and statuses. They never write to a part, a cast, an enemy or a status, never change timing (`Engine.time_scale`, pausing), and never spawn gameplay. `tests/vfx_presenter_regression.gd` casts the same spells with the presenter on and off and requires identical damage.
2. **One call per moment, no return values** (except `presents`). The engine never waits on VFX.
3. **Missing VFX is never invisible.** A part whose look or shape is not built yet keeps `SpellPart`'s placeholder drawing. `presents(part)` is how the placeholder knows to step aside.
4. **Hitboxes are the truth.** Every rim, warning and area is drawn from the part's real geometry (`geo()`, `contains()` inputs), never from a separate visual size.

## Events (engine → `/root/Vfx`)

| Call | Fired from | When | VFX use |
|---|---|---|---|
| `cast_started(cast)` | `GenericCast._start_cast` | once per cast, after aiming | cast flash at the staff (principle 7) |
| `part_spawned(part)` | `SpellPart.setup` | every part instance, roots and event children | start tracking: projectile body + trail, instant burst, field floor + rim |
| `part_hit(part, enemy, at)` | `SpellPart.hit` | each real hit, after payload | contact burst (per pierce for spears), impact recipe |
| `part_finished(part, natural)` | `SpellPart.finish` | once; `natural` = lifetime/range end | fizzle, field erosion (break up, don't fade) |
| `part_ticked(part)` | reserved | periodic payload tick | tick shimmer synced to real ticks (not wired yet) |
| `presents(part) -> bool` | `SpellPart._draw` | every redraw | skip placeholder art when VFX draws the part |

Statuses are read, not evented: each VFX step, the presenter polls enemies in the `enemies` group whose `status` (`StatusComponent`) reports `has("burn")`, nearest the camera first (cap 24). Status *moments* (applied, tick, reaction) can be added as events when a look needs them.

## What a handler may read

| From | Fields |
|---|---|
| `cast` | `plan` (`element`, `elements` = keyword accents with share and status, `parts`, `flags`, `arrangement`), `caster` |
| `part` | `global_position`, `direction`, `delivery`, `def` (`geometry`, `motion`, `limits`, `events`, `timing`, optional `vfx`), `geo(key)`, `geo_type()`, `_propagation()`, `size_scale`, `power_scale`, `front` (expanding/travelling), `armed` (traps), `phase` |
| `enemy` | `global_position`, `status` (read-only queries) |

Optional per-part hint in `data/generic_spells.json`: `"vfx": {"family": "spear"}` overrides the family guess (bolt / spear / ball from pierce and radius).

## Look resolution

- **Native look** = `plan.element` (`""` and `arcane` → Arcane, `fire` → Fire). It owns the body shape and palette.
- **Accent look** = the first keyword element in `plan.elements` that differs from the native one. It owns the rim colour, an extra trail, the impact and the status (plan §5.1). `fiery spear` = Arcane spear body with an orange edge, a light flame trail, fire bursts on each contact, burning enemies.
- Looks built so far: Fire (full), Arcane (body + twinkle trail + spark impact). Water, Storm, Earth, Plague, Life keep the placeholder until their looks land.

## Shapes presented so far

| Delivery / geometry | Presented as |
|---|---|
| projectile · body | shaded body (bolt / spear / ball), trail per distance with attach `inherit`/`grip`, contact bursts |
| volume · disk · instant | impact recipe sized to the real radius: designed star, flash, flame bloom, ring that breaks into segments, 1:3:9 debris, smoke, scorch, VFX-only hit-stop, camera shake on big hits |
| field / aura · disk | banded floor + bright rim at the real radius, flame tongues, embers, smoke; follows the part; erodes when it ends |
| everything else (rings, cones, lines, rects, traps) | placeholder for now |

## Wiring status

- Generic spells (doc 18 runner): wired. Hooks are one-line calls guarded by `get_node_or_null("/root/Vfx")`, so engine tests without the autoload are unaffected.
- Legacy spells (old `SpellManager` dispatch): not wired, by design. They move to the generic runner one at a time (doc 18 §14 phase 2) and get VFX for free when they do.

## Debug

Console: `vfx present off|on` (placeholder vs VFX), `vfx learn <id>` (make a data-only generic spell castable, e.g. `fireball`, `flame_wall`, `meteor_ring`), `vfx flame`, `vfx stress <n>`, `vfx twos`, `vfx bench`, `vfx stats`, `vfx clear`.
