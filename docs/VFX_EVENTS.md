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
| `cast_queued(cast)` | `GenericCast.setup` | once per cast, before any delay | anticipation for delayed / charged casts; caster position before a blink (`docs/VFX_KEYWORDS.md`) |
| `cast_started(cast)` | `GenericCast._start_cast` | once per cast, after aiming | cast flash at the staff (principle 7) |
| `part_spawned(part)` | `SpellPart.setup` | every part instance, roots and event children | start tracking: projectile body + trail, instant burst, field floor + rim |
| `part_hit(part, enemy, at)` | `SpellPart.hit` | each real hit, after payload | contact burst (per pierce for spears), impact recipe |
| `part_finished(part, natural)` | `SpellPart.finish` | once; `natural` = lifetime/range end | fizzle, field erosion (break up, don't fade) |
| `part_ticked(part)` | reserved | periodic payload tick | tick shimmer synced to real ticks (not wired yet) |
| `presents(part) -> bool` | `SpellPart._draw` | every redraw | skip placeholder art when VFX draws the part |

Persistent statuses are read, not evented: each VFX step, the presenter polls enemies in the `enemies` group whose `status` (`StatusComponent`) reports `has("burn")` / `has("chilled")` / `has("shocked")`, nearest the camera first (cap 24).

### Status moments (13 October 2026)

One-off status moments are announced. `StatusComponent` calls `/root/Vfx.status_event(enemy, event, data)` **if that method exists** (no handler yet = nothing happens). Same rules: read-only, one call per moment, no return value. `data.position` is always the enemy's position.

| `event` | `data` | When |
|---|---|---|
| `applied` | `status`, `stacks` | any status lands. `stacks` = chill stacks (1–4; the 5th freezes and announces `applied frozen`), bleed stacks, burn instances, else 1 |
| `reaction` | `name`, `targets` | a reaction fires: `chain` (`targets` = positions it arced to), `conduct`, `thaw`, `shatter`, `toxic_flare`, `overload`, `cleanse`, `hemorrhage`, `grounded` |
| `expired` | `status` | a status ends on its own (timer), not when a reaction consumes it |

Which spells apply what is in doc 18 §6.1b and `data/spell_damage.json`. Looks still missing: **bleed** (persistent, no poll yet; `has("bleed")`, `bleed.stacks.size()`, `bleed_meter` 0–1 toward hemorrhage), and the reaction moments above. Shock is now a 3 s mark (+0.2 s stagger), so `has("shocked")` lasts long enough to read as a mark.

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
- Looks built: Fire, Ice, Lightning (`storm`), Water, Life, Plague, Earth, Arcane (`""` / `arcane`). Every engine element resolves to a look; only unknown elements keep the placeholder.
- **Water vs Ice:** the engine has one `water` element. A spell gets the Ice look when a part's payload applies `chilled` or `frozen`, or a part has `"vfx": {"look": "ice"}`; water keyword accents (`icy`, `frosty`) carry `chilled`, so they are Ice. Other water spells get the Water look.
- **Accents on areas:** on fields and novas the accent element's particles run at half rate over the native look; on bursts the accent owns the impact.

## Shapes presented

| Delivery / geometry | Presented as |
|---|---|
| projectile · body | per look: fire = knot of flames (ball: magma core), ice/earth/life/arcane = drawn body, lightning = held arc knot, water/plague = goo; trails per distance; orbit motion = orbiter crystals |
| volume · disk · instant | the impact look sized to the real radius (fire bloom, ice shatter, sky strike, splash, bloom, rune burst, bubble burst, rubble) |
| volume · ring · expanding | nova on the live front (`part.front`) |
| volume · rect · travelling | Water: Tsunami wall on the hitbox band (shader), spray off the leading edge |
| volume · cone · instant | slash smear over the real arc and radius |
| field / aura · disk | floor + rim at the real radius in the look's palette, look particles; payload-less auras: short + `on_expire` = strike telegraph, long = quiet range ring |
| field / aura · line | wall floor + rim on the rect hitbox, tall flames |
| trap · disk | rune ring draws itself on the real radius while arming, pulses when armed |
| self | Life: bloom at the caster (Regrowth) |

## Wiring status

- Generic spells (doc 18 runner): wired. Hooks are one-line calls guarded by `get_node_or_null("/root/Vfx")`, so engine tests without the autoload are unaffected.
- Legacy spells (old `SpellManager` dispatch): not wired, by design. They move to the generic runner one at a time (doc 18 §14 phase 2) and get VFX for free when they do.

## Debug

Console: `vfx present off|on` (placeholder vs VFX), `vfx learn <id>` (make a data-only generic spell castable, e.g. `fireball`, `flame_wall`, `meteor_ring`), `vfx flame`, `vfx stress <n>`, `vfx twos`, `vfx bench`, `vfx stats`, `vfx clear`.
