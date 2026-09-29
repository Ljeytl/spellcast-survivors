Current Shield rule: [0.1.36 Earth Shield](../releases/0.1.36-earth-shield.md) supersedes earlier absorption-pool proposals. [Element × family matrix](16-element-family-matrix.md) separates implemented spells, user ideas and unselected examples.

# Combat, clocks and balance model

**Decision precedence:** [Alignment review and open conflicts](13-review-record.md#alignment-review--28-september-2026) supersedes older conflicting proposals below, especially XP/mana, infection/Big and roster counting.

**Development context (28 September):** use [development order](15-development-order.md) for implementation sequencing. Existing gameplay remains the foundation; these target-design tables do not require rebuilding or withholding existing spells. Numeric defaults and unresolved choices remain proposals. Preparation/XP/mana policy and recent spell-identity notes must be reconciled before dependent changes; the first keyword increment retains existing progression.

**Proposed testable tuning, not measured game balance.** Runtime baseline values are only in the spell catalog's first section.

## Casting state machine and clocks

States: `idle → typing → valid_commit → charging? → delayed? → released → idle`. Ongoing effects/repeats are owned by the cast scheduler, not the input state. Failed validation stays in typing. Cancel returns to movement without casting. Backspace edits one code point/grapheme boundary safely; it never resets assistance.

- Enter cast mode with the existing dedicated cast key; movement keys become text only while typing. No input leaks into menus. The exact default key is inherited from current bindings after an input audit, not invented by this document.
- Assist grants 1.25 unpaused **real seconds** at 0.20 world speed for each eligible manual cast attempt. The same amount applies to short and long expressions; no shared tank. The timer advances during typo correction and local/global impact pauses.
- A successful commit ends typing assistance and makes the next cast eligible after 0.15 s UI transition debounce. Recovery is per base spell; modified forms share its recovery. Merely changing words cannot bypass it.
- Cancel, clearing text and invalid Enter do not create a new eligible attempt. Reopening resumes remaining assist; if exhausted, typing proceeds at normal speed. After 3 real seconds continuously outside typing, eligibility refreshes even without a successful cast. This is an anti-toggle rule, not a shared meter; expose only a subtle spent/ready state in casting UI. It is D13 proposed behavior and needs feel testing.
- Charged starts **after** valid submission, roots for 1.20 simulation seconds at normal world speed, and releases only if not cancelled/dead. Movement command cancels charge, consumes no heal/damage output, sets readyAt = max(existingReadyAt, cancelTime + 0.5 simulation seconds), never shortening the recovery already assigned at commit. Damage does not automatically cancel charge; displacement can move the rooted player and is not invulnerability. Charge rooting prevents movement spells until specified otherwise.
- Delayed uses 0.80 simulation seconds after charge if any; movement allowed. Ground anchor stays fixed. Projectile direction selects a live target at release, from the owner's current position. If owner dies before release, discard pending player outputs without rewards.
- Game menu pause stops combat, deadline and assist clock. Hit-stop pauses combat simulation briefly but **not** real-time assist expiry, input or impact animation. Deadline uses unpaused real time independent of slowdown/hit-stop, preventing slow casts from extending 20 minutes. Objective spawn timelines, DoT, charge and projectile motion use simulation time; the director evaluates deadline bands on expedition real time.

This clock split is a major test obligation: repeated typing slows fighting but not extraction. A player may choose survival over discovery; that is a valid 20-minute extraction strategy, but idle assist toggling should not create indefinite near-free safety.

## Targeting and collision

Target selection has explicit range, visibility and policy. Prefer live reachable threats not already covered by **reserved incoming damage**. Reservation is advisory, expires on miss/death/expiry and does not apply damage early. Use actual plan potency and expected contact, not base damage. Area selection scores useful coverage and overkill, with deterministic nearest-center then entity-ID tiebreaks.

Straight projectiles select aim on release then keep it; they do not bend when targets die. Additional outputs release with fresh selection. Seeking/native-guided projectiles reacquire within their own range, turn at bounded rate, retain original expiry and total travel budget. Boss-priority staff indication is a visual preference, not authority to force every spell to ignore immediate threats. Staff smoothly orbits toward boss if present, otherwise nearest threat; no cursor jump causes damage.

Use swept collision for fast bodies. Body radius and rendered solid core share the same resolved geometry; tails, glows and dust do not enlarge damage. Fields query their visible area. Contact fans query individual shards with a per-root + generation enemy ledger. Piercing and returning spells explicitly track contact generations/legs. Big may hit more overlapping targets only if spell's native pierce/area behavior allows it: a larger ordinary Bolt still stops on its first valid contact.

Enemy body hitbox is an ellipse fitted to feet/body, not entire canopy-like sprite. Contact damage rate limited by 0.6 s player hurt immunity. On actual contact, enemy recoils 35 wu over 0.12 s through collision-safe movement; bosses recoil 8 wu. This does not fling enemies through walls or make decorative recoil change collision. Player physical knockback 20 wu; damage and displacement recorded once.

## Enemy families: readable variants

Base values at realm 1, time 0. HP time/realm multipliers apply to ordinary enemies only. Mana yield is fixed per variant; it does not grow with HP.

| Family/variant | HP | Speed wu/s | Contact | Mana | Behavior/read |
|---|---:|---:|---:|---:|---|
|Grunt: Drifter|80|48|8|1|Round medium slime; two Bolt hits; direct pursuit|
|Grunt: Skirmisher|65|60|8|1|Narrower cap; shallow lateral weave, no invisible dodge|
|Grunt: Bulwark|130|38|10|2|Broad flat silhouette; front armor purely visual in v0.1, no hidden damage reduction|
|Runner: Swarmer|30|115|5|1|Small but visible pointed blob; one Bolt; groups of 3–6|
|Runner: Dart|35|135|6|1|Elongated body; commits straight for 0.8 s then turns|
|Runner: Pursuer|60|70|9|2|Tall wisp/slime; 0.65 s warning, dash 260 wu at 360 wu/s, rest 1.4 s|
|Brute: Rootback|240|30|14|4|Large heavy body; normal chase|
|Brute: Crusher|200|36|12|4|0.8 s slam warning, r 65, 16 damage, recovery 2 s|
|Brute: Brood|180|32|12|4|On death releases 3 swarmers; children yield 0 mana to prevent farming|
|Caster: Spark|90|42|7|3|Keep 200 distance; one projectile speed 130, r 6, 10 damage, 0.8 s windup, 2.8 s interval|
|Caster: Fan|75|35|7|3|Three orbs at±20°, speed 110, 8 damage, 1 s warning, 3.5 s interval|
|Caster: Marker|110|28|8|4|r 55 ground circle, 1 s warning, 14 damage, 4 s interval; no homing after mark|

Enemies approach from outside viewport, never directly under player. Initial safety radius 240 wu. Pursuer dash cannot start offscreen and travel into frame without warning; starts only when visible or indicator has shown full 0.65 s. Caster projectile lifetime 4 s, no across-map sniping. Normal ranged enemies respect the realm's introduction time. Challenge substitutions before that time are explicit in levels.

Elite modifier: HP × 2.0, damage × 1.25, speed × 1.05, scale × 1.20, mana × 3 (round up). A crown/shoulder silhouette and distinct windup show elite status; not just a tint. Guardian uses authored values, not elite multipliers.

## Threat director

Separate **escalation amplitude** from **local fight cadence**. Proposed baseline spawn budget in threat points/s is linearly interpolated between anchors, multiplied by realm factor. Costs: grunt 1, runner 1, brute 4, caster 3; elite cost base × 3. Spawn costs consume accumulated budget; bank cap 12 points. Ambient alive cap 90 (mobile floor target); reaching cap pauses spending, does not increase HP or recycle a nearby enemy unfairly.

| Run minute | Points/s | Ordinary HP factor | Contact damage factor | Speed factor |
|---:|---:|---:|---:|---:|
|0|0.8|1.00|1.00|1.00|
|2|1.0|1.10|1.00|1.00|
|3|1.4|1.18|1.05|1.00|
|5|1.8|1.35|1.10|1.03|
|8|2.2|1.60|1.20|1.05|
|9|2.4|1.70|1.25|1.06|
|11|2.8|1.95|1.35|1.08|
|15|3.3|2.40|1.50|1.10|
|20|4.0|3.00|1.70|1.12|

`HP = ceil(baseHP × timeHP × realmFactor)`; damage uses timeDamage only, not realmFactor a second time. Speed onlytimefactor. RealmFactor is 1.0/1.15/1.30/1.45. No hidden player-level scaling. Example realm 1 grunt at 8 min 128 HP, four base Bolt hits; realm 2 same 148 HP. Moving and composing should be needed in 3–8 min, but escalating HP must not turn every grunt into tedious typing. If kills become slow, raise counts/formation complexity and lowerHP before simply raising player damage.

Composition budget weights by cost, not headcount:0–2 min 80% grunts/20% runners; 2–5 min 60/30/10% brutes; 5 min onward 45/30/25 before ranged unlock; after ranged 35/30/20/15% casters. Early runners use Swarmer only; Dart after 2 min, Pursuer after 3 min, Crusher after 4 min, Brood after 6 min. Max simultaneous active caster attacks 3 inrealm 1/2, 4 inrealm 3/4; visible bodies may be waiting, with no fake charge animation.

Local state cycle: build 35 s at 1.0 budget → peak 12 s at 1.5 → fade at 0.25 until nearby threat cost≤6 or 20 s passes → recover 15 s at 0.25 → repeat. If fade times out, enter 15 s recovery but keep existing threats; do not label it safe. No kill-based instant respawn in recovery. Ley encounter suppresses ambient spending within 500 wu and pauses peak advancement; guardian suspends all ambient spending and uses authored adds. On exit discard banked budget beyond 4 points to avoid a spawn explosion.

Effective average budgets depend on fights: this is not a promised spawn count curve. Log spent points, alive counts, nearby threat, spawn failures and time in each state. Patrol elites at 4/8/12/16 min are separate capped events, never additive during a guardian. No random five-minute boss.

Offscreen ordinary enemies remain alive until farther than 1.5 viewport diagonals for 5 s. Then relocate to a valid offscreen entry socket from a different angle at least 300 wu from player, preserving HP/status and entity identity; exclude bosses, challenge enemies, active projectiles and dash commitments. Telegraph re-entry if special attack follows. Do not delete/reward/recreate them or place them in camera. Wave enemies instead finish their authored crossing and may retire without reward after leaving the area; their identity flags are explicit.

## Status and sustain rules

- Burn/plague/poison are damage over time, no critical rolls in v0.1. Multiple roots may coexist up to 3 stacks/target/status; replace the weakest descriptor with a stronger incoming application, otherwise reject that additional application. Settle earned damage before replacement, then use the incoming duration, rate and root ownership; the next tick is one interval later. Same-root repeated contact does not add a stack, reset tick phase or extend expiry; it can only keep an existing eligible exposure active. A new root follows the replacement rule above.
- Slows take minimum movement factor with floor 0.3, then expire independently. Freeze/root maximum 1.5 s; bosses convert to 0.8 move factor and never lose authored attack timelines. After hardCC expires, normal enemy has 1 s hardCC immunity, visibly brief broken-chain cue if recast denied.
- Regeneration permits one active descriptor. A new cast first settles earned unpaid healing, then replaces the old descriptor completely with the incoming rate, duration, remaining budget and root ownership; the first new payment is one interval later. Recasting weaker regeneration can therefore reduce its rate, shown in preview. Earth Shield follows the 0.1.36 charge/retaliation contract; no replacement or absorption comparison. Regeneration proposal above is future-only; current recasts extend one stream. Life has recovery 1.2 s. Healing cannot exceed 100 HP; pluses only on gain.
- Infection travels before applying damage, never jumps invisibly. Host death emits one orphan spore for 3 s; it searches within the selected spread radius (120 wu draft; Big mapping unresolved), once every 0.1 s, and flies to a valid uninfected target. Host/concurrency limits need tuning; the old arbitrary 18 s root ceiling is superseded by the refreshable-infection working proposal. Host infections and orphan spores still expire individually. Reinfection and overload policy require a bounded workload contract before implementation. No target means it visibly fades.
- Friendly/hostile recipient masks are mandatory. Steam Field damages enemies and slows them; green life symbols never appear. Moonfall heals only player/friendly allowed targets and damages only enemies. Golem is not a free healing battery for Soul Bloom.
- Recovery is not typing cooldown: player may type while a spell is recovering, but cannot commit it early. Preview shows ready time; no hidden queue. Derived spells have their own recovery but active-effect family caps still apply.

## Balance experiments, not false certainty

Typing scenarios:20/40/60 words/minute assumed 5 characters/word ⇒1.67/3.33/5 chars/s. `bolt`4 chars takes 2.4/1.2/0.8 s before correction/submit. `meteor shower`13 chars takes 7.8/3.9/2.6 s. `charged meteor shower`21 chars takes 12.6/6.3/4.2 s, plus 1.2 charge and native warning. These arithmetic examples explain commitment; they are not player performance requirements.

At 40 WPM, 1.25 s assist consumes 0.25 simulation seconds whiletyping; remaining 2.65 s for Meteor Shower consumes fullworldtime. Its practical opening requirement is therefore about 2.9 simulation seconds before commit, then visible warnings. A Charged version demands considerably more preparation. If no encounter creates that opening, tune escape tools and pressure before shortening the incantation into meaninglessness.

Do not demand every long spell's single-target DPS exceed Bolt. Compare effective enemieshit, survival gained, healing, route denial, displaced threats and damage per actual opportunity. The proposed Meteor Shower can deal 240 across four contacts or much more across groups; Focus Ray 128 single target; Cross Blade 170 only under favorable dwell. These are distinct strengths.

Candidate failure thresholds: no-movement/no-cast actor should usually die within 30–60 s after tutorial safety ends; a basic movement bot with simple Bolt should face meaningful failure in 3–8 min rather than idle through 8 min; a deliberate player should find some 1–3 s openings without clearing the entire map. These are design probes, not fairness gates. Compare automatic-attack settings in the existing game when that decision is tested; do not tune difficulty from bot survival alone.

## Periodic settlement and event ordering

Rate-based fields, beams, healing and infections integrate actual eligible exposure. Full interval payments occur on schedule; leaving a field, ending a channel, replacement or expiry settles the earned fractional remainder before teardown. This avoids losing damage simply because a target leaves just before a tick. No exposure accrues outside the visible active region. For example, 0.20 s inside a 24 HP/s field earns 4.8 damage, not a free full 12-damage tick.

Discrete pulses are different: Earthquake has four scheduled 45-damage pulses, and Cross Blade has three 20-damage linger pulses at 0.3, 0.6 and 0.9 s. They never gain partial pulses from early interruption. Lasting is not allowed on either, avoiding unspecified extra pulse counts.

At each physics boundary: determine chronological movement/contact and eligibility intervals; accrue/settle due effects; resolve health and absorption; commit deaths; then expire effects and release capacity. If a recipient died earlier in that tick, later heal/damage does not resurrect or re-kill it. Terminal expedition transitions use the death/deadline precedence in progression; presentation follows the committed state. Fixed-step integration and stable entity-ID ordering resolve exact simultaneous ties reproducibly.
