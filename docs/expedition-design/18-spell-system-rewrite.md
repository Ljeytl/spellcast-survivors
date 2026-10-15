# Spell presentation and shared mechanics

Updated 14 October 2026. The rewrite foundations and existing spell migration are part of 0.3.0. This page now owns the presentation review contract and dependency checklist; the full catalog is in [doc 3](03-spells.md), engine architecture in [doc 19](19-engine-architecture.md), game systems in [doc 20](20-game-systems-architecture.md), and damage/status/keyword rules in [doc 21](21-damage-effects-keywords.md). The older rewrite specification is [historical](archive/2026-10-14/18-spell-system-rewrite.md).

## Presentation contract

Spell identity must remain readable through anticipation, release, travel, contact, sustained effects and expiry. Silhouette, motion and timing all matter. Visible damaging boundaries must agree with gameplay geometry; glow may extend beyond them only when the actual boundary remains clear. Spell fantasy and contact timing take precedence over a uniform animation template.

| Area | Review obligation |
|---|---|
| Casting | Immediate readable input; accepted/rejected words and cancellation; windup proportional to intended commitment. |
| Projectile and wave | Speed, acceleration, arc, copy spacing, target changes and size upgrades communicate the hit. |
| Beam and chain | Start/stop, tracking, target allocation, tick rhythm and branching remain readable. |
| Field, trail and wall | Edge, occupancy, crossing/tick timing, following/fixed behavior and expiry are clear. Flame Wall follows the circular-band design in doc 3. |
| Trap and seed | Distinguishable inscription, armed/growing, triggered/mature and expired states. Frost Sigil must read differently from Rune Trap before detonation. |
| Summon and barrier | Spawn, idle, attack, damaged, broken/death states; ownership, target and collision are understandable. |
| Impact | Damage, contact flash, enemy reaction, sound and shake align; strength fits the spell and does not obscure the next threat. |
| Status and reaction | Coexisting statuses remain distinguishable; buildup, actual reaction and expiry have truthful cues. Frozen differs from chilled. |
| Healing and pickups | Friendly benefit and collection are legible; avoid visuals that imply healing where only enemy damage exists. |
| Keywords | A meaningful change has meaningful feedback; word order must not accidentally hide an effect. Preserve clarity under multiple modifiers. |
| Accessibility and performance | Reduced effects propagates through all renderers and shake; visible enemies take priority under budgets; evaluate native and web frame time. |

The existing VFX layer and art are inputs for refinement, not proof of good feel and not a requirement to replace every asset. The historical grey-value asset pipeline is an option, not a new mandatory rewrite of the current renderer. Element palettes, shapes, stamps, outlines and audio should be shared where useful while preserving authored identity.

## Shared mechanics dependency checklist

These are capabilities to verify when implementing the catalog, not an assertion that they are absent in 0.3.0.

| Capability | Catalog uses |
|---|---|
| Phases and event-driven transitions | Arcane Slash payoff, Flame Seed growth, Grasping Hand, Sunbeam, Yggdrasil, meteor ring. |
| Owner, afflicted and death events | Fire Shield, Firewalk, Infestation, Soul Bloom, Raise Dead and paused lightning rod. |
| Barrier health and collision | Earth Wall, Prism Wall, Tesla coils, Yggdrasil. |
| Chains and target traversal | Static Shock, Lightning Bolt and later chain concepts. |
| Aim and target assignment | Scorching Ray, Water Jet, Ray of Sickness and Prism Ray. |
| Displacement | Pull into Shillelagh's rooting trail, Water Jet push, Whirlpool swirl, Dash. |
| Lob, fall and moving fields | Carcass, Volcano, falling icicle, Mana Storm, Blizzard, Moonfall. |
| Spell references and allied actors | Golems casting from the kit, Raise Dead, Mirror Image. |
| Additional statuses and recipient filters | Polymorph, Time Stop, reflection, taunt, corpses, pickups, allies. Current damage/status contract stays in doc 21. |
| Contact and per-target rehit timing | Flame Wall crossings, orbiting bodies, whips and persistent contact. |
| Linked parts and per-copy variation | Tesla Wall and elemental ray copies. |
| Global scope | Time Stop and ultimate concepts. |

## Review evidence

Use fresh comparison cases and real moving encounters. Inspect the full timeline, ranks, keyword variants, combined statuses, crowded scenes, supported display sizes, reduced effects, sound and frame time. Record candidate revision and any working-file hashes. Input/menus/progression need actual operated journeys, including settled state, next transition and persistence where relevant.

Keep mechanical checks, visual judgment, audio judgment and performance evidence separate. A registered presenter, successful cast or saved screenshot is not a quality pass. Missing journeys are incomplete. Preserve before/after evidence; use known-bad controls for automated invariants, such as disconnected settings or missing catalog entries, rather than treating an exit code as proof.

## Interface and accessibility direction

Use readable inscriptions for magic, plain readable menu text and restrained ornament. Do not require a substitute alphabet. Keycaps are the existing implementation, not the target identity. Spell names need sufficient width and a readable minimum text size; long typed expressions use a horizontal viewport around the caret rather than wrapping into combat or shrinking illegibly.

Input text updates immediately. Cosmetic animation never delays input or loses rapid characters; reduce animation under load. Typing UI and HUD do not shake with the camera. Accepted/rejected words, current focus and cursor stay legible. Keep canonical spell/availability feedback concise; detailed math belongs in expandable inspection/debug. Current parser behavior is not changed by this design consolidation.

The tower concept rotates the **whole circular room**, not merely a selection highlight. Roughly twelve stained-glass positions are a visual concept, not twelve committed levels. A top-position portal opens for departure; the physical book assembles the prepared order. Existing six-slot preparation is the baseline. Book placement and 2D/3D/hybrid treatment remain open. At recall the wizard returns automatically from wherever they are, **without a return journey or exit interaction**. Test rotation with reduced motion before polishing.

### Required journey inventory

| Surface | Actions and states to review |
|---|---|
| Main menu and saves | No profile, existing profile, interrupted run, corrupt-save recovery, stable keyboard focus. |
| Preparation and realm selection | Pick/reorder/remove, locked/known spells, available recipes, empty slots, invalid duplicates, persisted order, enter/back. |
| Combat and casting | Slot activation, expiry, unknown/inactive/incompatible words, edit/commit/cancel, assist exhaustion, charge and delay, focus loss. |
| Spellbook and knowledge | Active versus prepared-but-inactive, known versus unseen, recipe requirements, honest availability. |
| Ley sites and guardian | Preview/start/decline, attempt/fail/retry, completion, grant once, four-site condition, late timer, already-active/defeated boss. |
| Pause and options | Nested back navigation, retained focus, settings persistence, no gameplay input leakage. |
| Death and extraction | Distinct outcomes, unfinished boss at timeout, reward settlement, crash/reopen and prepare again. |
| Developer workshop | Actual gameplay compiler/runtime, moving targets, player health, mid-flight target death, recast, invalid data, export success/failure. Design-only entries must say not implemented. |

Accessibility review includes independent text scale, cosmetic animation/density, reduced motion, shake and flash controls down to zero, shape-assisted color cues, keyboard-only navigation, remapping, readable focus and predictable Escape/Back. Exact presets remain open. Important sound cues need text/visual equivalents; reward reading must not be timed. Pause must not provide an accidental assist reset. Test non-US layouts, punctuation, IME composition and focus loss; the earlier paste restriction is a proposal requiring review, not an adopted policy.

Combat information prioritizes health/protection, available spells, activation progress, relevant objectives and the expedition timer. Keep developer statistics and permanent control tutorials out of the normal HUD. Telegraphs, healing, harmful fields and interaction rings must be distinguishable without relying only on color.

### Sound and production

Use material-specific release/contact sounds and bounded voice priorities, not a loud sound for every particle. Align audio with authoritative contact, distinguish friendly healing from hostile effects, and keep important information visible. Historical millisecond timelines, voice counts and palette recipes are starting experiments, not accepted quality measurements. Record source/license provenance and preserve supplied art; this plan does not authorize paid commissions or mandate replacing assets.
