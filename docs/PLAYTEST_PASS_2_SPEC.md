# Playtest pass 2 — shared build specification

Status: implementation authorized by the user: “ok build to it.” Boss upgrade chest confirmed; Pursuer means farther/faster dash.
Baseline: main `9588205ebaaa1d9255ed1f000460e626407e5cf0` (Plague host-death / player-only canopy repair).
Owner: integration lead. This is the controlling checklist for this pass; update dispositions here as work proceeds.

## Goal

Deliver a readable, rewarding typing-survival loop: substantial spells earn their typing commitment, effects clearly occupy their gameplay areas, targeted attacks use extra casts intelligently, and encounter pressure rises through the previously flat minutes 3–8. Preserve the opening, Focus Ray's satisfying utility, and the difficulty the user liked around minutes 9 and 11. Enlarge characters and pickups while largely preserving world visibility and the existing background style.

A completed pass means one integrated, reviewed, tested build, not disconnected agent branches or a collection of visual mockups. Every requirement below needs a disposition and evidence. A passing mechanical test alone does not establish visual readability or game feel.

## Authority and scope

- The user explicitly approved implementation after this specification was merged. The confirmed chest reward and farther/faster Pursuer dash resolve both earlier product questions.
- Confirmed describes the user's requested outcome. Proposed describes an implementation/tuning choice awaiting approval of this specification or the specific open choice. Measured values must be recorded before and after tuning.
- Later corrections override earlier suggestions: targeted intelligence applies across the library; effect language is shared across relevant spells; difficulty changes target minutes 3–8, not a global increase or passive nerf.
- Earlier accepted rules remain in force unless explicitly changed here. The previous pass is historical context, not authorization for this new pass.
- Runtime state must be inspected before work: documentation and prior reports are not proof of behavior in the currently running game.

## Rules to preserve

- Core fantasy: movement/dodging competes with time spent typing. Longer incantations should have greater consequential payoff; short basics remain useful. Do not reduce every spell to raw damage or introduce mandatory elemental counters.
- Start with Bolt only. Bolt is a straight projectile; Lightning is distinct; Lightning Bolt is the bouncing combination.
- Six primary active slots and six passive families. Learned combination spells are extra spells, consume no slot, and preserve ingredients and ranks. Only owned spells can be cast.
- Each cast gets its own finite slowdown window at fixed slowdown strength. Duration upgrades extend that window. Do not restore a shared meter or add a meaningful cooldown in this pass.
- Twenty-minute run with immediate victory at 20:00; bosses at five-minute milestones before victory. Do not add a mandatory final encounter beyond the existing victory boundary. Tier advancement follows elapsed time.
- Normal gameplay UI stays minimal; detailed diagnostics belong in debug or menus. No boss countdown added to the HUD.
- Ice Blast remains a cone. Life is the small quick heal; Regeneration the stronger sustained heal. Life Bolt plants collectible healing rather than stealing life. Earth Shield is personal protection; terrain walls remain deferred. Seeker stays available; Reaping Spirit remains deferred.
- Trees block at their trunks; bushes remain decorative. Only the player triggers canopy fading. Preserve authored art, clustered vegetation, and the floating staff behavior.
- Placeholder art stays simple and compatible with the existing pixel-art direction. No shader overhaul, art-direction pivot, or comprehensive audio production pass.

## Requirement register

All P2 requirements start as **planned**, except P2-07's already-merged repair, which is **verify baseline + improve readability**. Do not mark complete until the acceptance evidence exists.

### P2-01 — Intelligent targeting across relevant spells

Confirmed: repeated casts and multiple projectiles should not routinely waste their value on a target that is already going to die. Bolt was an example, not the scope boundary.

Proposed shared implementation:
- Track expected incoming damage for targeted attacks and prefer another useful nearby living target when committed damage should be lethal.
- Keep concentrating attacks when a target needs them, including a healthy lone boss. Fall back sensibly when no alternate target exists; do not refuse to attack just because all targets are reserved.
- Homing projectiles, including passive Magic Missiles, reacquire a nearby living target if theirs dies. Straight projectiles retain their trajectory after launch; choosing a target does not make Bolt homing.
- AoE target selection favors useful group coverage. Beam, ground, summon and multi-hit spells retain their own targeting contracts; do not apply projectile reservations blindly to every effect.
- Reservations end on impact, miss, expiry, despawn, cancellation or retargeting, and survive no projectile-pool reuse. Estimates must not leave enemies permanently ignored or assume uncertain damage is guaranteed.

Acceptance: real-enemy cases for rapid casts, two shots versus a weak enemy, several enemies, a healthy lone boss, all targets reserved, target death in flight, miss/expiry, retargeting and pooled reuse. Audit every implemented targeted spell and state its selection policy.

### P2-02 — Whole-library spell audit and payoff

Confirmed: each spell should express a recognizable fantasy, useful tactical role and payoff appropriate to typing commitment. Focus Ray is the positive benchmark; preserve its current strength and utility.

Produce one row per implemented spell, including passive and bonus spells, with: current status, incantation, role, targeting, shape, origin, reach, duration, damage/hit cadence, visual boundary and lifecycle, planned change, test evidence. Reference the existing full library for ideas instead of implementing every idea. Audit shared behavior in unnamed spells as well as the examples below.

Acceptance: no implemented spell omitted; longer-name weaknesses and misleading visuals have explicit fixed/open dispositions. Basic spells remain useful. Focus Ray's functional behavior is unchanged unless a separate defect requires a documented correction.

### P2-03 — Lightning circular burst

Confirmed: Lightning targets an area, shows a blue circle, strikes with lightning/thunder feedback, and visibly crackles for about 0.2 seconds before disappearing. Lightning Bolt remains the bouncing projectile.

Proposed origin: a circle centered on the selected enemy/group, consistent with targeted Lightning. Select the exact radius and damage schedule during implementation; record them in spell data. The short active window must not accidentally deal damage every frame. Existing suitable audio may be reused; new audio production is deferred.

Acceptance: enemies inside/boundary/outside the circle; consistent damage under different frame steps; expiry after the brief activity; visible shape matches damage geometry; no change to Lightning Bolt identity or ownership.

### P2-04 — Arcane Orbit

Confirmed: current effect is weak, too close and too small. Increase orbit reach and projectile size, with matching hit areas, until it provides meaningful protection.

Proposed tuning: larger orbit and bodies, with damage/cadence reviewed together. Do not lock an arbitrary doubling before evaluating the new character scale. Keep its orbiting identity and record measured values.

Acceptance: actual protection against approaching enemies, visible bodies match hit regions, useful coverage at normal camera scale, no accidental excessive damage from overlapping checks.

### P2-05 — Cross Blade

Confirmed: stronger payoff needed for its incantation; retain outbound, linger and return identity.

Proposed tuning: wider blade/hit area, stronger outbound and return damage, and a useful lingering phase with controlled repeat damage. Repeat-hit cadence and duration are tuning choices, not already implemented requirements.

Acceptance: real crowd hit on outbound and return, useful linger, bounded per-target damage, readable width, preserved travel distance under projectile-speed upgrades.

### P2-06 — Firewalk and burning-ground spells

Confirmed: Firewalk's individual flames must last long enough for a pursuing boss to reach them. Increase useful trail coverage and damage as needed. Extending only the casting effect's lifetime does not address the complaint.

All fire ground AoEs must look like burning ground across their active region, not isolated candle sprites on tiles. Firewalk forms a connected burning trail; fields occupy a continuous readable area. Supporting embers/flames must not obscure the boundary.

Acceptance: move ahead of an actual boss and lead it through flames; measure damage received before patches expire. Also test ordinary enemies, patch overlap, expiry, frame-step independence, and visual/damage coverage. Overlapping trail samples must not unintentionally multiply damage without limit.

### P2-07 — Plague Seed repair and readability

Already merged: infection transfers on host death within 130 world units, with an eight-host cap and five-second effect lifetime; duplicate death handling is guarded. Markers were enlarged and moved above canopies.

Confirmed next step: verify the current build and make infection unmistakably visible/useful before considering a redesign. Show which enemies are infected and the transfer to the next host. Check damage as well as cosmetic feedback.

Acceptance: real owned cast, invalid/no-target behavior, repeated damage, external host death before first tick, own-kill transfer once, spread boundary, expiry/cap, and visible infection in a crowded scene at the chosen scale. Prior mock tests or the older running process are not sufficient evidence.

Deferred: lingering infectious ground area created by host death. Keep as an idea until selected separately.

### P2-08 — Shared area-effect visual language

Confirmed: summoned/placed circular effects use a translucent colored center and a bold brighter outline in the same color. Generalize across applicable spells, not only Meteor Shower.

- Delayed circular attack: visibly builds toward activation. Meteor example starts as a small red dot/circle and grows to impact size, with dark translucent red center and bright red border; final boundary equals impact range.
- Brief active AoE: clearly shows its affected area during activity, then disappears. Lightning is the blue example.
- Persistent area: remains visibly present for its active lifetime.
- Rune Trap: visible armed rune circle, clear activation, and accurate trigger boundary; preserve persistence until trigger and existing limits.
- Cones, beams and trails use their own actual shapes; do not replace them with circles.

Acceptance: pre-activation/active/expired states, actual affected boundary, multiple simultaneous effects, reduced-effects mode, and readable enemy threats. Distinguish an expanding timing fill from the final impact range; do not silently make a warning ring itself damaging.

### P2-09 — Character, enemy and pickup scale

Confirmed starting candidate, subject to visual review:
- Camera zoom is 1.2 times the baseline zoom, not an absolute zoom setting of 1.2.
- Player and enemy visual scale is 1.75 times baseline. Preserve relative enemy/boss size differences.
- Combined apparent character size is approximately 2.1 times baseline. Viewable world width/height decreases by about 16.7%; background asset world sizes stay unchanged.
- Target XP crystals at roughly twice baseline apparent size, accounting for camera zoom rather than applying it twice. No size pulsation.
- Fit staff orbit/placement, spell origins, health bars and status markers to the larger bodies.
- Deliberately review physical footprints, contact reach and path clearance; do not automatically double every collision shape.

Acceptance: side-by-side baseline/candidate at equal window geometry; preserved useful sight range; player/enemies/bosses through real groves and around trunks; visual bodies versus collision and damage contact; no detached labels/staff. If 20% zoom harms the desired range, reduce it while retaining character growth and record the choice.

### P2-10 — One-line typing and readable particles

Confirmed: long incantations such as Regeneration must not wrap to two lines. Keep keycaps readable, retain placement/backspace feedback, provide horizontal room, and adapt spacing/size only within readable limits. On narrow windows, horizontally reveal the latest typed letters rather than shrink indefinitely or wrap.

Confirmed: enlarge hit, death, pickup, healing and spell-impact particles across the game at the actual camera scale. Prefer size changes over indiscriminately increasing counts. Cosmetic size must not silently change hitboxes.

Acceptance: longest owned spell names, typing/backspace/completion/cancel/reopen, prompt containment at desktop and narrow geometry, spell-bar restoration, visible caret/latest key, crowded effects and reduced-effects mode. Check actual rendered states, not just control rectangles.

### P2-11 — XP appearance and distant consolidation

Confirmed: remove crystal grow/shrink animation; use stable sizes and color to communicate XP value. Color direction: blue low, green middle, purple high. Record threshold choices against actual drops and the leveling curve; colors must reflect stored value after merging.

Proposed consolidation behavior: nearby distant/offscreen stationary crystals combine locally into fewer valuable crystals, preserving exact total XP and remaining in the area where it accumulated. Do not merge across the entire world, teleport XP to the player, merge visible pickups abruptly, or interfere with pickups already attracted/being collected. Higher tiers may have a modest distinct size/shape without pulsing.

Acceptance: total XP conserved through repeated merges, many drops, leaving/revisiting an area, collection, attraction during a consolidation pass, and run reset. Color/shape updates after merging; bounded performance cost. This does not introduce cross-run persistence.

### P2-12 — Difficulty correction only for minutes 3–8

Confirmed user observations: around two minutes is good; minutes 3–8 are too easy/flat; around nine is good; around eleven is hard in a good way. Preserve the early and later curve while progressively filling the middle trough and blending into the existing nine-minute point.

Inspect spawn intervals, batch counts, population caps, archetype composition and approach effectiveness together. More nominal spawns do not help if a cap suppresses them. Preserve timed tiers, approachable opening and delayed ranged enemies.

Rank 4 passive Magic Missile at eight minutes is a modest build that exposed weak encounter pressure. It is NOT a mandate to nerf Magic Missile or force every stationary build to die. Use this as one comparison case alongside movement and active casting. Compare at equivalent builds, seeds and elapsed times.

Acceptance: baseline/candidate data at 0, 2, 3, 5, 7, 8, 9 and 11 minutes: attempted/actual spawns, active population, cap saturation, damage pressure, kills and XP. Bot stationary/moving/actively casting comparisons supplement human play. Verify early/later parameters preserved and observe their outcomes; earlier XP gains can affect later difficulty even when later parameters match. Full-run smoke covers bosses and 20-minute victory. Do final tuning after stronger spells and targeting are integrated.

### P2-13 — Contact-hit recoil and Pursuers

Confirmed: an enemy that lands a physical contact hit should briefly move/bounce away, creating a readable gap before approaching again. Proposed weighting: clear recoil for normal enemies, smaller displacement for heavy enemies/bosses.

Acceptance: recoil follows a successful contact hit, not every overlap frame; no repeated overlap damage, endless stun lock, wall clipping or trapped actors. Verify boss and normal enemy cases near trees.

Confirmed clarification: The Pursuer boss dash should travel farther and faster. This is the charger boss, not the basic grunt named Pursuer. Preserve readable windup and collision with trees. Do not increase unrelated melee reach.

### P2-14 — Boss defeat reward

Confirmed: boss defeat must drop something meaningful and clearly visible, beyond an unremarkable ordinary kill.

Confirmed: guaranteed reward chest that provides an upgrade choice through the existing acquisition system, respecting six active/six passive limits and bonus rules.

Acceptance after selection: real boss defeat, exactly one reward, discoverable drop, collection, valid offers when slots are open/full or upgrades exhausted, application once, return to gameplay and run reset. Handle the 20:00 victory boundary without requiring post-victory collection.

### P2-15 — Maintainable architecture and honest delivery

Confirmed: code should be easy to maintain and modular where useful.
- Tunable damage, size, reach, duration, cadence and encounter values live in data or clearly owned configuration.
- Reuse targeting, shape/geometry definitions and compatible effect lifecycles. Rendering and gameplay consume the same authoritative geometry.
- Keep distinct mechanics explicit; avoid both scattered duplicated conditionals and an over-general spell framework.
- Preserve pooling, time-scaling, pause, reduced-effects and run teardown behavior.
- Refactor touched systems only as needed to support this pass; no unrelated engine rewrite.

Acceptance: independent code/architecture review, project parser/static checks and applicable lint/typecheck (report if not configured), targeted regression tests and operated gameplay evidence. Documentation reflects final behavior, not abandoned proposals.

## Delivery sequence and agent ownership

Implementation starts only after user approval. Use separate purpose-first branches/worktrees for each independently owned tranche. No agents write to the same worktree. Integration lead alone owns the integration checkout. Existing dirty/untracked artwork and the user's running game remain untouched.

1. Baseline and inventory: inspect current source/runtime, list every implemented spell and affected surface, record tuning and running revision. Reproduce reported problems and establish tests/visual baselines.
2. Agree shared contracts: targeting reservations, authoritative effect geometry, scale configuration, XP ownership. Identify exact file ownership before dispatch.
3. Run available agent slots in waves: targeting; UI/world-scale; then spell mechanics/effects on integrated targeting. Related shared casting changes occur sequentially. XP/rewards/encounters follow agreed scale and geometry contracts.
4. Integrate functional mechanics before difficulty tuning. Stage dependencies through the integration owner and run gates on each candidate.
5. Independently review and operate the final build, including crowded visual states and a full-run smoke. Record final values and remaining product judgments.
6. Push/review PRs, merge verified exact revisions, package one canonical current build and launcher, preserve evidence, and clean completed worktrees/merged branches. Retain a checkout only when it contains unique work or a live process still uses it, and report why.

| Workstream | Responsibility | Dependencies / boundaries |
|---|---|---|
| Targeting | P2-01, targeted-spell audit contribution | Own shared targeting/projectile lifecycle; coordinate casting entry points sequentially with spells agent |
| Readability and scale | P2-09, P2-10, XP visual portion of P2-11 | Preserve background scale, own UI/visual configuration; avoid concurrent gameplay geometry edits |
| Spell mechanics and feedback | P2-02 through P2-08 | Consume targeting and scale contracts; own spell tuning and shared AoE rendering/gameplay geometry |
| Encounters and rewards | P2-11 mechanics, P2-12 through P2-14 | Final tuning after combat integration; open Pursuer/reward choices remain blocked individually |
| Integration lead | Spec, shared contracts, merge order, runtime verification and packaging | Sole integration writer; track requirement dispositions and evidence |
| Independent reviewer | P2-15, correctness/architecture/coverage review | Read-only review against exact revisions; reproduce suspected defects before sign-off |

At most four concurrent agents including the lead. Workstreams describe responsibilities, not a requirement to run six agents at once. Handoffs record ownership, revision, completed requirements, tests, dependencies and open findings. Coordination bookkeeping stays proportional and must not replace gameplay work.

## Evidence and completion gate

For each P2 ID record: agreed behavior, reproduction journey, baseline observation, candidate observation, exact revision, test/assertion counts where applicable, screenshot/video/log path, sibling-spell sweep, and disposition (planned, running, blocked, failed, verified, deferred). Do not equate merged with verified.

- Use real Enemy/EncounterEnemy nodes and owned casting paths for material combat cases.
- Capture UI/effects at desktop and narrow geometry; inspect immediate, settled and next-transition states, plus persistence where applicable.
- Include negative controls proving new tests fail for the old defect where practical. Zero tests collected or skipped material coverage is not a pass.
- Separate automated mechanics, visual readability and subjective balance findings. Unavailable native coverage remains incomplete.
- Do not interrupt the user's active run. An older open process does not automatically load the new build; identify revision and relaunch needs accurately.
- No successful completion claim while a selected requirement has unexplained missing evidence. Explicitly deferred ideas are not implementation failures; unresolved required choices remain open.

## Open choices and deferred ideas

1. Resolved: Pursuer boss dash farther and faster.
2. Resolved: boss drops an upgrade-choice chest.
3. Exact spell strengths, XP thresholds, consolidation distances and middle-curve values — routine measured tuning after scope approval, recorded in data and this pass's results.
4. Scale candidate 1.2x zoom / 1.75x character visuals — approved starting experiment; verify view range before finalizing.
5. Plague death-ground infection area — idea only, rework deferred until current spell works and reads well.
6. Shader overhaul, new characters, modifier words, typed menu navigation, alternate siege/alchemist mode, world ritual sites and new-library expansion — remain roadmap items, not additions to this pass.

## Progress ledger

Implementation is integrated. Per-requirement dispositions, measured tuning, verification evidence and explicit human-review limits are recorded in [PLAYTEST_PASS_2_RESULTS.md](PLAYTEST_PASS_2_RESULTS.md). The full implemented spell table is [SPELL_PASS_2_AUDIT.md](SPELL_PASS_2_AUDIT.md).

All P2 requirements have an implementation and evidence disposition. The two product choices are resolved: farther/faster Pursuer boss dash and upgrade-choice boss chest. Balance and final scale preference remain human playtest judgments rather than automated pass claims. Deferred ideas remain deferred.
