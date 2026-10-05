## Current prototype: MEGA

The first implemented keyword is **MEGA**, available immediately for every learned manual spell and combination. Type `mega bolt`: **1.5× Spell Power and 1.5× Spell Size**, using existing power/size semantics with matching visible geometry and hitboxes. Healing scales too; duration, speed and count do not. One prefix only; repeated MEGA, unknown/unowned spells, Magic Missile and Atomic are unsupported. Both numbered and Space casting support it. Style credits the longer incantation while repetition remains the base spell. Delayed effects snapshot the cast; duration-extending effects queue the new strength behind existing duration, preserving one effect.

Earlier multi-keyword grammar, unlock progression and Big/Powerful examples below are future proposals, not the current parser.

Latest idea authority: [29 September element exploration](17-element-spell-ideas.md) and [populated matrix](16-element-family-matrix.md). This preserves proposals and rejections without approving a new runtime roster. Older 36-row campaign recipes below are historical drafts where they conflict with that exploration.

Current Shield rule: [0.1.36 Earth Shield](../releases/0.1.36-earth-shield.md) supersedes earlier absorption-pool proposals. [Element × family matrix](16-element-family-matrix.md) separates implemented spells, user ideas and unselected examples.

Prototype release note: [0.1.35 spell scaling](../releases/0.1.35-spell-scaling.md) defines the implemented passive/combination behavior. The keyword and campaign proposals below remain future design, not the current parser.

# Spell language and modular composition specification

**Decision precedence:** [Alignment review and open conflicts](13-review-record.md#alignment-review--28-september-2026) supersedes older conflicting proposals below, especially XP/mana, infection/Big and roster counting.

**Development context (28 September):** use [development order](15-development-order.md) for implementation sequencing. Existing gameplay remains the foundation; these target-design tables do not require rebuilding or withholding existing spells. Numeric defaults and unresolved choices remain proposals. Preparation/XP/mana policy and recent spell-identity notes must be reconciled before dependent changes; the first keyword increment retains existing progression.

**All grammar and tuning in this chapter are proposed v0.1, pending D02/D08/D14.** The confirmed requirement is modular properties and meaningful modifiers, not these particular caps.

## Parser contract

Canonical form: `[keyword ...] [base incantation]`. Normalize case and repeated spaces, trim outer spaces, accept Unicode input in the editor but match the English v0.1 vocabulary explicitly. Do not strip arbitrary punctuation into a valid powerful cast. Maximum four distinct keywords and 80 Unicode code points; over-limit input remains editable and shows a concise reason. No damage bonus derives from character count.

Resolve the longest known **base suffix** first, then tokenize the remaining prefix against the keyword dictionary. `powerful lightning bolt` resolves Powerful + Lightning Bolt, not Powerful + Lightning + Bolt. `fiery bolt` is a fire-converted ordinary Bolt; **Fire Bolt** is a separately discovered explosive spell. `fire bolt` therefore always selects Fire Bolt. Legacy internal IDs and names are not public aliases. Base incantations are lower-case labels from the catalog.

**29 September clarification:** Golem is the castable word; Summon is an internal category. Use `big golem`, not a special summon-word grammar. [The family reference](14-spell-system-reference.md#14-spell-forms-identities-and-additive-modifiers) also distinguishes additive Flaming from element conversion: `flaming earth wall` preserves Earth Wall and adds fire. Exact fire payload and compatibility remain open. No general natural-language parser, language model, numerical parameters, free word invention or implicit substring match is involved.

Keyword order does not change mechanics in v0.1; the preview presents canonical order: commitment → schedule → output → guidance → geometry → potency → element → status. Multiple mutually exclusive words are rejected, not resolved by whichever came last. Unsupported words display one reason before commit. An unknown spell or inactive page cannot cast even if the text is valid.

## Property schema

| Property group | Fields | Unit / interpretation |
|---|---|---|
| Identity | spell_id, recipe_id, capabilities | Stable IDs; presentation name separate |
| Potency | damage, heal, shield, summon_attack | HP per event; not DPS unless explicitly a rate |
| Geometry | body_radius, impact_radius, beam_half_width, cone_angle, path_radius | wu/degrees; each component declares its scaling binding |
| Motion | travel_speed, turn_rate, travel_range, lifetime | wu/s, radians/s, wu, seconds |
| Count | native_count, output_count, bounce_count, pierce_count | Integers with independent limits |
| Time | active_duration, tick_interval, recovery, charge_time, release_delay | Simulation seconds except cast UI assist |
| Control | knockback_distance, slow_factor, slow_duration, root_duration | Real collision-safe displacement; multiplicative move factor |
| Affinity | damage_element, native_status, added_status | Conversion never erases defining native behavior |
| Targeting | selection, acquisition_range, retarget_policy, ground_anchor | Data-driven policies, no arbitrary per-frame global nearest query |
| Ownership | root_cast_id, generation, hit_ledger, active_family | Deduplication, cap policy, lifecycle |
| Summon | health, acquisition range_range, attack_interval, formation, leash | Summon health is not spell damage |

A spell is a graph of effect components. Example: Meteor Shower owns a volley scheduler and individual falling area impacts. Big scales each impact radius; Duplicating adds one meteor, not a second complete shower; Repeating adds a smaller follow-up shower with the resolved meteor count. Each spell's mapping is part of its data, not a renderer guess.

## Keywords: initial catalog

`P` is the additive base-relative potency multiplier. Every coefficient below is a proposal.

| Word | Property change | Compatibility | Tradeoff / clarity |
|---|---|---|---|
| Big | ×1.35 linear effect dimensions | Only spells with a scalable gameplay area/body; see authoritative allowlist | More coverage, unchanged potency; golem body/reach grow, health unchanged |
| Powerful | P += 0.50 | Damage/heal/shield/summon attack | Longer input; brighter contact, no false area growth |
| Swift | travel speed ×1.35 | Travelling projectiles, moving spirits | Same range; shorter flight lifetime; not movement speed or faster typing |
| Seeking | turn rate 4 rad/s, acquire within 320 wu of projectile | Bolt, Fire Bolt, Ember/Meteor Spear, Water Jet | No extra damage, range or pierce; native seeking retains greater native turn if any |
| Repulsing | +70 wu collision-safe push per target per root cast | Contact damage, fields, beams | Displacement not extra DPS; no repeated tick pinball |
| Duplicating | +1 native output, each initial output ×0.80 potency | Projectile volleys/meteors/spirits/golem/orbit; instant heal/shield excluded | One bolt becomes two; 9 shards become 10, not 18; broad utility differs by spell |
| Repeating | One follow-up 0.60 s after initial release; ×0.40 potency, ×0.75 geometry | Instant attacks, volleys, fields; self heal/shield/summons/persistent traps excluded | Never recursive; child follows same target rules, never fresh assist |
| Delayed | +0.80 s after commit/charge; P += 0.15 | All except channels, Firewalk, regeneration and ongoing personal orbit | Ground position locks at commit; projectile origin and aim resolve at release from the live owner; free movement after commit |
| Charged | Root player 1.20 s after commit; P += 1.50 | Eligible burst/projectile damage, instant Life, Earth Shield; excludes channels, traps, Firewalk, orbit, summons and regeneration | World normal speed after typing; movement input cancels charge, no effect |
| Lasting | Duration ×1.40 | Eligible finite fields, channels, spirits, Firewalk, Regen, shield, orbit, summons | Same tick strength; explicit total-root potency cap below |
| Fiery | Convert eligible native damaging components, including supported periodic damage, to fire | Damaging components | No free burn; preserve Ice Blast's native slow and geometry |
| Icy | Convert eligible native damaging components, including supported periodic damage, to ice | Damaging components | No implicit freeze |
| Earthen | Convert eligible native damaging components, including supported periodic damage, to earth | Damaging components | No automatic shield |
| Venomous | Add poison totaling 0.20 × resolved initial direct hit over 3 s | Direct-hit projectile/area/beam first hit per target/root | No heal conversion; native plague cannot add poison to its own ticks |

For clarity, v0.1 reserves Fast → Swift, Following → Seeking, Rotating → Orbiting and Replicating → Duplicating as **documented naming candidates**, not accepted parser aliases. Orbiting is reserved pending orbit-path ownership rules. Super/Omega/Giant/Wide/Piercing and Quick Cast are reserved; MEGA now has the implemented contract above; see below. Only one elemental conversion is allowed. Only one added status package is allowed initially.

## Resolve order and limits

1. Validate learned base, active prepared page or active recipe, keywords learned, count and compatibility. No resources are spent on invalid submit.
2. Read immutable base data. Apply native behavior and choose element conversion.
3. `P = min(3.0, 1 + 0.50*Powerful + 0.15*Delayed + 1.50*Charged)`.
4. Resolve each component's geometry from base ×Big; clamp total linear scale at 1.60. Apply repeat's 0.75 afterward. Big radius 1.35 means area 1.8225, not 35% more area.
5. Resolve duration ×Lasting, speed ×Swift, guidance, displacement and native control. Control durations do not increase with Powerful. Longest slow duration/strongest slow applies, not multiplicative permanent immobilization.
6. Resolve native output count +1 if Duplicating, capped per spell. Apply 0.80 initial coefficient to all outputs when duplicated. Repeating schedules one follow-up of the resolved output pattern at 0.40 of that initial coefficient.
7. Clamp total healing per root to 2.5 × unmodified base total, shield to 2.5 × base, summon population by family, damaging field duration to 8 s. Damage has no hidden global root-HP cap because target count matters; output/size/lifetime caps bound workload.
8. Freeze the cast plan. Child outputs carry generation 1 at most, cannot parse new words, reset assist, trigger cast rewards, or reschedule repeats.

Workload limits are defined once in “Authoritative compatibility and timing” below. At a cap, reject the new root before commit with a readable reason. Persistent traps may replace the oldest only when the preview explicitly says so. No scheduled child may silently disappear; reserve its capacity at commit.

A pending Delayed release does not block the next cast; it counts toward eight pending roots. A Charged cast owns the player's commitment state and does block another cast until release/cancel. Scheduled repeats may coexist with the next cast. If a projectile cap is reached between preflight and a scheduled release, reserve capacity at commit; otherwise reject at commit, never erase a later child silently.

## Geometry mapping matrix

| Shape | Big affects | Swift affects | Duplicating creates | Repeat behavior |
|---|---|---|---|---|
| Bolt/spear/jet | Visible body and swept collision width | Travel, with fixed max range | +1 emitted body | Second volley from current caster location at its scheduled time |
| Ice Blast fan | Shard body and collision only, not fan angle/range | Shard speed | +1 shard across same fan | New fan; fresh target ledger only for follow-up generation |
| Meteor Shower | Impact disk and rock body | Incompatible; descent belongs to warning schedule | +1 impact | New smaller marked shower; each generation preserves the original 0.65 + 0.25 i warning schedule |
| Lightning / radial burst | Actual active disk | Incompatible | Incompatible for pure single-disk burst | New disk; location policy below |
| Beam / ray | Beam half-width | Incompatible | Incompatible pending split-beam design | Channels excluded; no opaque double channel |
| Stationary field | Disk; tick collision uses same disk | Incompatible | Incompatible | Smaller field with separate root + generation target cadence |
| Personal orbit | Satellite radius AND orbit path ×1.35 | Incompatible | +1 satellite | Excluded: avoid duplicate orbit clutter |
| Trap | Trigger and blast radii | Incompatible | Incompatible | Excluded: persistent trap family owns count |
| Firewalk | Patch width; path follows actual movement | Incompatible | Incompatible | Excluded |
| Life / regeneration | Life none; Regen leaf ring cosmetic only, so Big incompatible | Incompatible | Incompatible | Incompatible |
| Earth Shield | Eruption reach; never enlarge player hurtbox | Incompatible | Incompatible | Incompatible |
| Seeker / golem | Body/reach; not acquisition or HP | Spirit travel; golem excluded | +1 creature | Excluded |
| Moonfall / Yggdrasil | Damage/heal zone disk | Incompatible | Incompatible | Moonfall yes, Yggdrasil no |

Ground spells lock their selected location at commit. Repeat reuses the location for fields and radial impacts; repeated Meteor Shower uses its original pattern center with fresh warned offsets. Moving projectile repeats originate at current caster position and select a fresh valid direction; they do not teleport already-launched shots. Charged ground casts lock their mark at commit, giving enemies time to leave. The player sees this risk.

## Worked examples using the proposed catalog

- **Powerful Big Bolt:** base 40 damage, radius 7 →60 damage, radius 9.45. Range 480 unchanged. Thirteen extra characters buy damage and coverage, not aim immunity.
- **Duplicating Repeating Bolt:** two 32-damage bolts now; two 12.8-damage bolts 0.60 s later; theoretical four-contact total 89.6. Repeat radius 5.25. Incoming-hit reservations choose distinct useful targets; straight shots stay straight. No guarantee all four hit one enemy.
- **Charged Delayed Lightning:** base 80 →`80×(1+1.50+0.15)=212` damage. Root 1.20 s, delay 0.80 s, then 0.25 s native warning and 0.20 s active disk. Radius 80 unchanged; all targets in disk once. The 2.25 s pre-impact commitment is visible.
- **Big Duplicating Meteor Shower:** five impacts instead of four, each 48 damage instead of 60; impact radius 108 instead of 80. Maximum overlap 240 initial damage, versus 240 base; advantage is wider distribution, not free boss DPS. Repeating would add five 19.2-damage impacts; it uses one of four keyword slots.
- **Lasting Powerful Regeneration:** base 4 HP/s × 6 s = 24; modified 6 HP/s × 8.4 s = 50.4, within 60 root cap. Effect is not “Big” merely because leaves orbit farther. Refresh policy prevents unlimited parallel stacks.
- **Charged Powerful Life:** base 4 × 3.0 = 12, capped to 10 HP/root. UI previews 10. A short emergency Life still releases sooner; repeated Life spam is evaluated against recovery and exposure.
- **Summon Big Fiery Golem:** one 80-HP golem, enlarged body/reach, fire-converted 25-damage melee attack; health unchanged. No free burn. Native summon remains 20 s.

## Reserved keyword experiments

| Candidate | Intended distinct contribution | Why not first slice |
|---|---|---|
| Orbiting / Rotating | Projectile adopts caster-relative orbit, limited contacts | Changes hit opportunities radically; needs own collision/expiry rule |
| Piercing | +2 unique contacts at decreasing potency | Must not duplicate native spear identity without tradeoff |
| Wide | Fan angle or beam width without radial-size change | May overlap Big; require useful decision |
| Super / Omega (beyond implemented MEGA) | Higher commitment tiers with distinct release patterns | Avoid mandatory synonym stack; aspiration is real but mechanics need testing |
| Quick Cast | Recognized initials, sharply weaker cast | Undermines typing commitment if too efficient; separate accessibility discussion |
| Numeric Delayed | Explicit scheduled seconds | Parser/UX complexity and queue abuse; user deferred |
| Burning / Freezing | Explicit status package separate from element | Native status and stacking interactions need first-slice results |

No arbitrary maximum word count should permanently block the fantasy. Four keywords is an initial readability/testing limit; later expansion must demonstrate more expressive choices, not a longer compulsory damage formula.

## Authoritative compatibility and timing

The per-spell allowlist below is authoritative. The family tables explain how an allowed keyword behaves; they do not grant additional compatibility. An omitted keyword is rejected with its capability reason. This avoids accidental acceptance of a cosmetic-only Big Shield or a recursively repeating summon. Redundant native guidance rejects Seeking explicitly. All fourteen keywords must resolve through a defined property operation before acceptance.

Initial release time is `commit + charge_time + release_delay`. Repeat release is `initial_release + 0.60 s`. Each generation starts its own native warning/volley schedule at its release. Charged and Delayed bonuses are inherited once; the child does not root the player again or add another delay. Meteor repeats use the same 0.65 + 0.25 i warning durations, so volleys can overlap in time. Reserve capacity for both generations before commit.

Duplicating is situational, particularly on native volleys: ten Ice Blast shards at 14.4 damage each may cover gaps better than nine at 18, but a target still takes only one shard hit per generation. The preview must show this cost. Test whether it is a useful coverage choice; if it is consistently a trap, change the per-family coefficient before adding more words. No description may claim it always doubles damage.

Capacity categories are separate: at most 32 launched projectile/impact bodies per root across both generations, 96 reserved-or-active player projectile/impact bodies globally, eight pending roots, three field instances per family, three traps, three spirits and two golems. Fields and creatures do not consume projectile capacity. Infection has six admitted hosts and at most six travelling/orphan spores per root. Firewalk samples one circular ground patch every 0.10 simulation seconds, including its initial patch. Maximum emission duration is 7 seconds with Lasting, giving at most 71 patches; reserve 72 patch records per root. At normal movement speed, centers are 18 wu apart and radius-32 patches overlap. Use the same union of circles for rendering and damage; abrupt displacement may leave a real visible gap rather than inventing a connecting damage line. Each patch retains its own expiry, capped at 8 seconds with Lasting. No lossless path-merging assumption is required. Field and creature caps include reserved future instances; reserved capacity releases on cancellation, output expiry or generation completion. If preflight cannot reserve the entire plan, reject it visibly.

A scheduled area impact counts as an impact body from reservation through active-area expiry. A ray is a channel instance (maximum one), not a projectile. Orbit motes count as spirit-like persistent bodies in a separate orbit family cap of eight; this permits two overlapping native three-mote orbits but rejects a third. These workload caps are initial test limits, not player progression upgrades.

| Spell | Accepted keywords |
|---|---|
|Bolt|Big, Powerful, Swift, Seeking, Repulsing, Duplicating, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Life|Powerful, Delayed, Charged|
|Ice Blast|Big, Powerful, Swift, Repulsing, Duplicating, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Lightning|Big, Powerful, Repulsing, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Regeneration|Powerful, Lasting|
|Earth Shield|Big, Powerful, Lasting, Charged|
|Meteor Shower|Big, Powerful, Repulsing, Duplicating, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Ember Spear|Big, Powerful, Swift, Seeking, Repulsing, Duplicating, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Plague Seed|Big, Powerful, Swift, Delayed, Lasting, Fiery, Icy, Earthen|
|Cinder Field|Big, Powerful, Repulsing, Repeating, Delayed, Charged, Lasting, Fiery, Icy, Earthen|
|Arcane Orbit|Big, Powerful, Repulsing, Duplicating, Lasting, Fiery, Icy, Earthen|
|Focus Ray|Big, Powerful, Repulsing, Lasting, Fiery, Icy, Earthen, Venomous|
|Rune Trap|Big, Powerful, Repulsing, Fiery, Icy, Earthen, Venomous|
|Seeker|Big, Powerful, Swift, Lasting, Duplicating, Fiery, Icy, Earthen|
|Firewalk|Big, Powerful, Repulsing, Lasting, Fiery, Icy, Earthen|
|Cross Blade|Big, Powerful, Swift, Delayed, Charged, Duplicating, Repeating, Fiery, Icy, Earthen, Venomous|
|Wave|Big, Powerful, Repulsing, Repeating, Delayed, Charged, Fiery, Icy, Earthen|
|Water Jet|Big, Powerful, Swift, Seeking, Repulsing, Duplicating, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Frost Nova|Big, Powerful, Repulsing, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Fire Bolt|Big, Powerful, Swift, Seeking, Repulsing, Duplicating, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Firestorm|Big, Powerful, Repulsing, Lasting, Fiery, Icy, Earthen|
|Earthquake|Big, Powerful, Repulsing, Delayed, Charged, Fiery, Icy, Earthen|
|Thunderwave|Big, Powerful, Repulsing, Repeating, Delayed, Charged, Fiery, Icy, Earthen|
|Frost Ray|Big, Powerful, Repulsing, Lasting, Fiery, Icy, Earthen, Venomous|
|Moonfall|Big, Powerful, Repulsing, Repeating, Delayed, Charged, Lasting, Fiery, Icy, Earthen|
|Grasping Hand|Big, Powerful, Repulsing, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Mana Storm|Big, Powerful, Repulsing, Duplicating, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Summon Golem|Big, Powerful, Lasting, Duplicating, Fiery, Icy, Earthen|
|Yggdrasil|Big, Powerful, Delayed, Fiery, Icy, Earthen|
|Lightning Bolt|Big, Powerful, Swift, Repulsing, Duplicating, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Life Bolt|Big, Powerful, Swift, Seeking, Repulsing, Duplicating, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Meteor Spear|Big, Powerful, Swift, Seeking, Repulsing, Duplicating, Repeating, Delayed, Charged, Fiery, Icy, Earthen, Venomous|
|Soul Bloom|Big, Powerful, Swift, Delayed, Lasting, Fiery, Icy, Earthen|
|Steam Field|Big, Powerful, Repulsing, Repeating, Delayed, Charged, Lasting, Fiery, Icy, Earthen|
|Prism Ray|Big, Powerful, Repulsing, Lasting, Fiery, Icy, Earthen, Venomous|
|Frost Sigil|Big, Powerful, Repulsing, Fiery, Icy, Earthen, Venomous|
