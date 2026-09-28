# Development order: one playable level at a time

**28 September 2026 · development roadmap proposal · documentation only**

This page answers **what we build and can play at each milestone**. It is not a schedule for when a player unlocks vocabulary, a promise of calendar dates, or a requirement to build the entire spell engine before anyone plays.

**Confirmed scope direction: Level 1 starts with normal slimes.** No fire slimes, elemental resistance lesson, ranged enemy barrage or advanced enemy roster is needed to prove that first level. The exact spell lists and later milestones below are recommendations to review. Player spells may use fire, ice or lightning; “normal enemies” does not mean the wizard is restricted to non-elemental magic.

Use the existing prototype as the reference build. Implement the component-based candidate in small increments, preserving working behavior and testing each increment. Availability in a developer fixture does not silently grant a permanent unlock or rewrite campaign rewards.

## Quick view

| Milestone | Playable result | Enemy scope | Main development question |
|---|---|---|---|
| M0 — shared foundation | Small test courtyard and effect previews | Stationary targets and one normal chasing slime | Do shared components, modifiers and visible contact agree? |
| M1 — Level 1 combat slice | A short playable forest clearing | Normal grunt slimes; then small, weak runner slimes | Is moving, typing and choosing a spell enjoyable without elaborate content? |
| M2 — Level 1 complete | One full expedition with objectives, a normal slime guardian and extraction | Same normal slime family, plus a larger slow bruiser and King Slime | Does the complete loop work and invite another run? |
| M3 — Level 2 | Second playable level with lanes, persistent ground effects and commitment casts | Add a telegraphed pursuer and one basic caster; elemental variants only as deliberate later content | Do positioning and longer incantations add useful choices? |
| M4 — Level 3 | Level testing moving fronts, beams and timed combinations | Add one clearly taught ranged pattern at a time | Can more complex combat stay readable and predictable? |
| M5 — Level 4 / advanced systems | Advanced level with infection, autonomous spirits and summons | Mixed existing roles; a guardian using already taught patterns | Do complex recipes compose sustainably without bespoke spell code? |
| M6 — expansion and release | Additional content and polished target-platform builds | Add variants only where they create meaningful decisions | Is expansion justified by playtest evidence and production capacity? |

A milestone is complete only when its named loop works. A component test, an animation preview, a bot run or an attractive screenshot alone is insufficient. No estimated week count is assigned before auditing reusable code and measuring the first migration.

## M0 — shared foundation, narrowly scoped

**Playable fixture:** one wizard, a stationary target and a normal slime in a small clearing; replay and reset controls.

**Build:** origin and body geometry, straight projectile movement, actual contact, damage, immediate healing, bounded lifetime, recipient filters and authoritative impact events. Define typed parameter metadata and modifier bindings. The same recipe must run in combat and the workshop.

**Prove:** Bolt, Life and Big Bolt. Big uses the projectile component's size binding; it must not require a spell-name condition. The recently discussed kill-through bonus for Big is a candidate policy to compare before approving the ordinary-projectile rule. Do not silently hard-code it only for Bolt or pretend it is already settled.

**Not required:** complete spell catalog migration, procedural campaign, persistent library, new art pipeline, summons or elemental tiers.

**Exit gate:** a visible projectile causes damage on contact, misses do not hit, size changes affect gameplay geometry, invalid/unavailable casts produce no effect, and the preview uses the same resolved parameters. A developer can add a differently configured straight projectile without writing a second movement implementation.

## M1 — Level 1 combat slice: normal slimes

**Map:** a small authored forest clearing, quiet floor, a few clustered trees with trunk-only collision, open escape routes. Use existing placeholder art. Start with a short developer test duration, approximately 5–8 minutes, to iterate quickly; this is not a change to the intended 20-minute full expedition.

| Content | In this playable build | Explicitly later |
|---|---|---|
| Enemies | Normal Grunt: slow pursuit and contact damage. Small Runner: faster, fragile normal slime, introduced after the grunt is understood | Elemental variants, enemy projectiles, dash attacks, brood spawns, armor systems |
| Spells | Bolt, Life, Ice Blast, Lightning | Persistent fields, traps, summons, infection |
| Keywords | Big, Powerful | Charge/delay/repeat scheduling, elemental word tiers |
| Movement/combat | Walk, evade, type, correct a typo, submit/cancel, per-cast finite slowdown, damage/heal/death/restart | New movement abilities and character classes |
| Feedback | Actual shard contacts, clearly bounded lightning impact, damage flash, readable incantation and health | Comprehensive audiovisual replacement |
| Progression | Fixed test inventory with only Bolt active initially; staged grants for testing the other spells | This fixture does not choose final tutorial rewards or loadout capacity |

Ice Blast tests projectile distribution and contact timing. Lightning tests a ground-selected area. Life tests a non-damaging payload. This small list covers different component paths without needing dozens of spells.

**Proposed enemy starting targets:** a normal grunt survives roughly two or three base Bolt hits; a runner dies in one and moves substantially faster. Reuse the existing tuning as an initial test input, then verify these relationships in the new candidate. Do not introduce hidden elemental resistance to make early combat harder.

**Exit gate:** a fresh tester can identify what each spell does, escape ordinary slimes, recover from a typing mistake, see why a hit occurred and voluntarily try another attempt. Big/Powerful must have observable utility. Test first with one enemy, then groups, then the intended density. No claim of success merely because a bot survives.

## M2 — finish Level 1 before making Level 2

**Map:** expand the same normal-slime level into the first complete expedition. Add four readable ley-line locations, route choices, an optional King Slime encounter after all four, and the 20-minute extraction path. The exact realm name can remain Verdant Ruins; an elaborate environment set is unnecessary.

| Content | Added in M2 | Constraints |
|---|---|---|
| Enemy | Large Bruiser slime | Slow, visibly larger and more durable; still ordinary melee, no elemental trick |
| Guardian | King Slime | Clear windup, body/contact or ground-slam pattern, useful recovery window; no projectiles needed |
| Base spells | Regeneration, Earth Shield, Rune Trap, Wave | Each has a clear role: sustained healing, protection, preparation, displacement |
| Derived spells | Life Bolt, Lightning Bolt, Frost Sigil | Preserve ingredients and the proposed slot-free behavior; validate prerequisites |
| Keywords | Lasting, Repulsing | Bind explicit duration/force properties; persistent Rune Trap does not accept a meaningless duration increase |
| Effect foundations | Periodic healing settlement, persistent trap ownership, native chain guidance and collectible lifecycle | Required here by Regeneration, traps, Lightning Bolt and Life Bolt; later milestones extend these contracts |
| Run systems | Preparation, active-spell availability, progression collection, objective state, death, reward, extraction and saving | Settle the open progression contract before implementation; do not assume XP or mana was removed or repurposed |
| Interface | Minimum preparation, combat HUD, run spellbook, library, pause, result and retry flows | Keep debugging information out of ordinary play |

Life Bolt proves a contact event that creates a collectible. Lightning Bolt proves target traversal and dead-target handling. Frost Sigil reuses the trap with a different payload. Wave proves a visible advancing front. These additions validate reuse in a complete level.

**Required decisions before the full-loop gate:** preparation capacity, whether automatic Mana Bolt remains, XP versus mana roles, discovery retention, boss/deadline precedence and the initial progression thresholds. These are not silently resolved by selecting this development order. User-owned working notes are revising progression; reconcile them before building that subsystem.

**Exit gate:** operate entry → fight → progression → objective → discovery → guardian reward → extraction → prepare again. Also operate death/retry and timeout without boss victory. Verify knowledge/save behavior on reopen, no unavailable casts, no lost collection value and no ordinary menu blockers. All named enemy types are still normal slimes. Hold a focused human playtest before expanding the roster.

## M3 — Level 2: ground control and committed casts

**Map:** a second authored level with wide lanes, flanking paths and open casting pockets. The foundry concept is available, but its production art and final campaign reward placement are separate choices.

| Content | Added in M3 | Why now |
|---|---|---|
| Enemies | Pursuer with a visible dash windup; one basic caster with a slow, obvious projectile | Introduce mobility pressure and range separately after normal melee is readable |
| Spells | Cinder Field, Firewalk, Ember Lance, Fire Bolt, Cross Blade, Meteor Shower, Firestorm | Stationary/moving ground effects, piercing, impact explosions, phased trajectories and warned multi-impact attacks |
| Derived spells | Steam Field, Meteor Lance | Reuse fields/status and projectile/event connections; Meteor Lance identity must be selected first |
| Keywords | Delayed, Charged, Fiery, Earthen | Scheduling and explicit conversion become meaningful against more varied positioning |
| Mechanics | Shared release scheduler, scheduled-output reservations/ownership, charge cancellation, delayed ground markers, repeatable encounter fixtures | Time and event ownership must be stable before echoes and infection graphs |

Start the level with already understood enemies, then introduce the pursuer and caster in controlled encounters. New enemy attacks must not all arrive at once. A fire theme does not automatically authorize immunity to fire builds. Any elemental variant needs a clear purpose and its own readable introduction.

**Exit gate:** players can create an opening and land a worthwhile long cast; leaving burning ground stops exposure correctly; Cross Blade's phases match damage; a delayed location remains visibly fixed; charging roots without extending typing assistance. Compare the new level against Level 1 to catch regressions in short spells and contact readability.

## M4 — Level 3: fronts, beams and timed combinations

**Map:** broad bridges/courts or equivalent spaces that support moving fronts and line attacks. No narrow mandatory corridor that makes the increased enemy pressure unavoidable.

| Content | Added in M4 | Why now |
|---|---|---|
| Enemies | One additional ranged pattern, such as an aimed ground marker or slow fan; controlled mixed groups | Test readability and target priority without adding several new enemy systems |
| Spells | Water Jet, Frost Nova, Thunderwave, Frost Ray, Focus Ray, Arcane Orbit, Earthquake | Distinct shape, propagation, rotation and contact-limit behavior |
| Derived spell | Prism Ray | Reuse beam intersections with a different simultaneous-target limit |
| Keywords | Swift, Repeating, Icy, Venomous | Motion scaling, bounded echoes, conversion and simple periodic status |
| Mechanics | Beam turning/occlusion, front arrival, per-generation hit ledgers; extend and harden existing periodic settlement and output reservations for channels and echoes | Build the contracts later autonomous and spreading effects depend on |

Do not accept a cosmetic expanding Frost Nova with instantaneous invisible damage. Select its propagation recipe deliberately. Repeating must schedule an echo once; it must not duplicate unlock rewards, mint another slowdown window or repeat itself.

**Exit gate:** all new shapes match their active hit regions, beams turn visibly, target limits are scoped correctly, and short casts remain useful after major effects are available. Complete a dense encounter at reduced effects without hiding hazard edges or the typing caret.

## M5 — Level 4: autonomous and spreading effects

**Map:** the advanced realm concept can combine existing routes and encounter roles. Avoid adding an entirely new environment-generation system at the same time as complex spells.

| Content | Added in M5 | Dependency / decision |
|---|---|---|
| Spells | Plague Seed, Seeker, Grasping Hand, Moonfall, Mana Storm, Summon Golem, Yggdrasil | Shared events, targeting, recipient routing, lifetime and workload ownership are stable |
| Derived spell | Soul Bloom | Choose healing-carrier versus older leech identity; do not combine contradictory drafts |
| Keywords | Seeking, Duplicating | Expose guidance as a player modifier; native chain guidance already exists from M2. Add concurrent outputs, useful retargeting and explicit output units |
| Mechanics | Infection transfer/refresh/orphans; autonomous attacks; destructible friendly structures; mixed healing/damage zones | Explicit recipient filters, concurrency budgets and teardown behavior |
| Enemies/guardian | Mixed previously taught roles and a guardian with real recovery windows | No surprise hard counters requiring a particular spell school |

This ordering places infection and summons later **in development** because their ownership/lifecycle problems are larger. It does not decree that Seeker or Plague Seed must be a late player unlock. Once reliable, they can be granted earlier in the final campaign if that improves play.

**Exit gate:** killing an infected host does not erase a valid spread opportunity; refresh does not stack accidental damage or postpone ticks indefinitely; player healing never heals an enemy; summons reacquire targets; repeated/duplicated outputs respect capacity and clean up on death/scene change. Big's infection/AoE policy and the unsupported-keyword policy must be explicitly approved rather than inferred from old tables.

## M6 — expansion, experiments and release

Once the earlier levels work, introduce reserved spells by reusing proven components. Do not implement the entire idea appendix just because a row exists.

| Work item | Development placement | Prerequisite / disposition |
|---|---|---|
| Ice Lance / Glacial Lance together | M6 expansion candidate using the projectile foundation established in M3 | Shared recipe with stronger long incantation; one prepared family provides both, as discussed; tune before broad tier rollout |
| Additional walls, rays, storms and cuts | After relevant field/beam/front components pass their level gates | Every added identity needs a useful role or an intentional incantation tier |
| Base Wall + elemental word tiers | Experiment after ordinary elemental conversion and incantation tiers are understood | Idea only; compare with named families, no automatic scope expansion |
| Orbiting/Rotating, Wide, Piercing | Separate modifier experiments after their component properties are stable | Preserve explicit size versus contact/trajectory meanings |
| Mega / Super / Omega / Giant | Later vocabulary experiment | Must earn commitment and avoid obligatory synonym stacking |
| Quick Cast, numeric Delay, Time Warp | Later design research | Input commitment, scheduling or clock semantics need deliberate review |
| Earth Wall terrain, reflection, complex Whip paths | Later component work | Navigation, ownership or curve-contact contracts first |
| Reaping Spirit, alternate characters and other reserved ideas | Backlog, not first-release commitments | Promote only after a clear identity and acceptance scenario exist |
| Slime/wizard animation, richer art/audio, shaders | Polish staged around a proven loop | Early readability fixes are immediate; broad production replacement waits for direction/budget |
| Release exports, persistence migration, accessibility and performance | Incremental checks throughout; full release gate after content stabilizes | Operate actual packages; do not claim a completed game from document or bot checks |

## Dependency and delivery rules

- **Cumulative candidate:** each milestone retains earlier verified content unless an explicit design revision removes it. A new level is not a reason to stop regression-testing Level 1.
- **Two statuses:** record `development milestone` separately from `player acquisition`. Early development does not mean every player starts with the spell. Late development does not force late acquisition.
- **Status vocabulary:** proposed → designed → implemented → operated/verified → playtested. Existing prototype implementation and component-based migration are separate status fields.
- **No wholesale rewrite gate:** migrate the minimum components for the next playable build. Complex existing spells may remain in the comparison build until their candidate migration milestone.
- **Exceptions only:** shared component bindings are the default. Per-spell tables explain resolved behavior; record only deliberate overrides as exceptions. Do not hand-maintain an unrelated modifier implementation for every spell.
- **Scope control:** add a new keyword only after its operation, compatibility and feedback can be demonstrated in the current build. No accepted no-op words.
- **Integration:** separate worktrees/branches for independently releasable tranches; review the exact candidate, merge in dependency order and clean up after integration. Documentation approval is not authorization to start gameplay implementation.

Before starting each milestone, record its exact included roster, unresolved decisions, inherited candidate revision and operated acceptance journeys. After testing, record failures and necessary revisions rather than silently expanding the milestone to include the whole roadmap.

## Relationship to the other documents

This page replaces the earlier generic development sequence with **concrete playable increments**. [Document 11](11-validation.md) still supplies the validation obligations. [Document 6](06-levels.md) contains a proposed campaign/reward layout, not a requirement to implement all those rewards before the first playable level. Its final reward placement must be reconciled after deciding which completed systems should be available to players early.

[Document 13](13-review-record.md) records prior review and unresolved tuning. [Document 14](14-spell-system-reference.md) defines the components and includes exploratory ideas. Neither is evidence that the system is implemented. The lists here account for the named entries in the existing catalog without settling the separate open question of final roster counting or which concepts become family tiers rather than separate spells.
