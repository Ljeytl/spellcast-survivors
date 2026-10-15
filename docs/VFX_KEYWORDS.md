# VFX for keywords and element combos

Status: built, 12 October 2026. Companion to `VFX_EVENTS.md` (events, looks, shapes) and `VFX_SYSTEM_PLAN.md` §5 (the rules this implements). Try every row in the VFX arena: **Combos** and **Keywords** pages.

## Element keywords on any spell

The spell's own element owns the **body**; the keyword element is the **accent** (plan §5.1).

| Spell part | Native (spell element) | Accent (keyword element) |
|---|---|---|
| projectile | body shape and palette | rim colour, an extra trail, the impact, the status |
| burst (instant disk) | a small impact at 45% size | the full impact, sized to the real radius |
| field / aura | floor, rim, particles | its particles over the field at half rate |
| nova | the front | its front particles at half rate |
| wave (Tsunami) | the wall of water | its particles thrown off the crest (35%) |
| slash | smear colours and edge particles | its edge particles too (50%) |
| trap | rune ring | the armed ring's colour |

A bare spell's native look is Arcane, so `fiery nova` is an arcane nova with fire on its front. A keyword the parser **rejects** (e.g. an element word on a spell that deals no damage) shows nothing.

## Reactions (plan §5.3)

Pairs where body + accent alone would miss the payoff. Either order.

| Pair | What you see | Where |
|---|---|---|
| Fire + Water / Ice | steam: a burst of dithered steam puffs | impacts; areas and waves steam continuously (`fiery tsunami` boils) |
| Fire + Earth | glowing magma cracks | impacts |
| Fire + Life | burning leaves, ember to ash | impacts |
| Lightning + Water | arcs run across the splash, sparks hop | impacts |
| Earth + Ice | permafrost: frost-blue cracks | impacts |
| Plague + Life | stains bloom into flowers | impacts |
| Fire + Plague, Arcane + Fire | not built (palette swaps need per-particle palettes) | — |

## Shape and behaviour keywords (plan §5.2)

| Keyword | Visual |
|---|---|
| tier words (`mega`, `super`, `omega`, `powerful`), `potent`, `mighty`, `charged`, `sanguine` | impacts scale with the cast's power (×√power, 0.8–1.7); strong casts (>1.3) add shake and hit-stop |
| size words (`big`, `massive`…) | nothing extra: bodies, rims, areas and impacts already read the scaled geometry |
| `delayed`, `charged` | energy gathers at the staff during the delay: sparks fly in, a dashed ring grows; `charged` is bigger and shows a rune |
| `repeating`, `twinned`, `double`/`triple`… | more casts and parts: each gets its own cast flash and effects |
| `sanguine` | blood burst at the caster when the cast fires |
| `blinking` | poof where the caster stood, a spark streak, a flash where they land |
| `repulsing` | a ring and outward streaks at every hit; fields push streaks out from the centre |
| `pulling` | a ring closing in and inward streaks at every hit; fields pull streaks in from the rim |
| `exploding`, `splitting`, `chaining`, `cascading` | the extra parts these add are presented like any part (burst, projectiles) |
| `homing`, `swift`, `orbiting`, `lasting`, `piercing` | nothing explicit: the motion, duration and pierce contacts show it |
| `hunting`, `scattered` | nothing explicit: the targets show it |
| `warding` | not built in the engine yet (rejected by the parser) |

## Engine hooks

`GenericCast.setup` calls `Vfx.cast_queued(cast)` once (read-only): it is how the VFX know a cast is waiting (delayed / charged) and where the caster stood before a blink.
