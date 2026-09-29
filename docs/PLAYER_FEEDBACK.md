# Player feedback tracker

**Style art:** colored scratched-stone rank glyphs, meter and Atomic seal are integrated. Simple procedural Atomic VFX is placeholder; polish follows feel testing.

**Style scoring — 0.1.27:** [specification](style-scoring/README.md). F–SSS combo, banked run score, casting bonuses, colored rune HUD, local high scores and S-rank Atomic are implemented for playtesting. Rank cadence and finisher balance still need human feedback.

Single entry point for player feedback, fixes and deferred ideas. Updated 28 September 2026. This tracker changes no gameplay. Earlier detailed feedback remains in the linked source records; rows below consolidate concerns without replacing those records or claiming old fixes still pass today.

## Attributed playtest batch — 2026-09-28

Complete supplied batch, grouped by the contributor names supplied by LJ. This is feedback capture, not approval to implement every suggestion. Repeated cooldown requests are retained as a recurring theme. **Prior implementation** below refers to existing records in this tracker, not a fresh retest or proof that the reporter played the latest build. Reports are not automatically reopened without a build/version or reproduction. Existing explicit deferrals (no rocks, no Swarmer tuning, no opening-pressure changes, no full keyboard overhaul) remain in force.

### LJ

| Feedback | Disposition |
|---|---|
| Rocks / new scenery | Deferred; explicitly excluded for now (F07). |
| XP crystal color | Prior implementation: four value tiers; see approved follow-up and thresholds below. |
| Nerf Swarmers | Recorded suggestion; later instruction explicitly said leave Swarmers unchanged. |
| Item drops | Health potions and boss upgrade chests have prior implementation; broader item variety remains an idea. |
| Focus Ray should rotate instead of blinking | Prior implementation: smooth turning. |
| Movement spells | Deferred spell ideas. |
| Overlapping trees: lower trunk base must draw in front | Prior implementation: depth ordering across chunks. |
| Inventory icons for active, passive and mixed/combination spells | Prior implementation; retain all three categories. |
| Increase scaling after 1:30 | Balance feedback; explicitly excluded from the follow-up fix scope. |
| Mob waves | Review timed waves and encounter pressure; not a request to silently change pacing. |
| Landmarks | Deferred world-design idea. |
| Structured versus procedural map design | Deferred design discussion. |
| Slight difficulty-zero buff: around 2.1 hits to kill instead of 2, scale onward | Tentative tuning suggestion; opening-pressure changes remain deferred. |
| Nerf Seeker | Prior implementation: contact damage 22 → 18; feel still subject to playtesting. |
| What does Space do on the level-up menu? | Prior interaction fix recorded; clarity remains a UX concern. |
| Fully keyboard-available UI | Deferred; not in the approved current scope. |
| Difficulty needs a pass | Open balance assessment, not settled by automated checks. |
| Prism Ray and Focus Ray recasts do not create another cast; Focus should look thinner | Prior implementation: independent visible casts and thinner Focus geometry. |
| More Lightning Bolt spells | Deferred roster idea. |
| How are Prism Ray and Focus Ray different? Maybe Prism should pierce | Prism piercing has prior implementation; communicating their distinct utility remains relevant. |
| Top-left/right spell bar with icons and levels; cannot tell whether Lightning was upgraded six times | Prior inventory/rank implementation and bottom exact-name reference; review legibility with players. |

### Dead

| Feedback | Disposition |
|---|---|
| Flickering on Windows? | Open platform-specific report; needs Windows reproduction and build details. |
| Optional mouse aiming | Deferred control option. |
| Focus Ray is cool | Positive feedback; preserve its utility/feel. |
| Difficult for non-typists | Open accessibility/game-feel concern; study typing pressure before tuning. |
| “Oh shit the pink guys” | Positive panic moment, not a nerf request. |
| First run: 7 minutes 36 seconds | Playtest observation; build and loadout unspecified. |
| No HP drops? | Ordinary potions and guaranteed boss potions have prior implementation; natural-run availability still needs evaluation. |
| Level-up interrupts typing; should finish the cast first | Prior implementation: defer choice until completion/cancellation. |
| Enemy that runs away or keeps distance | Deferred enemy behavior idea. |
| Maybe a spell cooldown; repeated “Cooldown” suggestion | Recurring design feedback; no cooldown change approved. |
| Cannot see combination spells | Prior inventory and exact-name reference implementation; combinations have no numeric casting shortcuts. |
| Likes Cross Blade v1, one big blade | Preference preserved; not approval to revert the current version. |
| A lot of fun | Positive feedback. |
| Small buff for typing speed / style combo meter | Implemented in 0.1.27; latest design supersedes zero-reset: health damage drops one grade, typos reduce only the cast bonus. |
| Spells trigger at combo thresholds, e.g. a nuke at S rank | Atomic implemented: current S required, typed manually, costs 1,500 combo. |
| Summon lots of flying knives that fly at enemies | Deferred spell idea. |
| Typed spell → animation/glyphs → spell | Deferred casting-feedback sequence; preserve the sense of magical invocation. |

### Brad

| Feedback | Disposition |
|---|---|
| “Can't launch”—actually ZIP files were confusing | Packaging/onboarding friction, not a confirmed launch defect. |
| Cannot click the menu slime to animate it | Deferred playful menu interaction. |
| Confused when to type: “learn seeker” versus “seeker” | Prior learning/casting guidance; observe onboarding again before calling confusion resolved. |
| Typing sound is good | Positive audio feedback. |
| How does one change spells? | Prior exact-incantation and inventory guidance; onboarding concern retained. |
| Starting a second run | Positive replay-interest observation. |
| Second boss spawned while the first remained: nice | Positive overlapping-boss feedback; preserve as input to future encounter design. |
| At zero HP but did not die? | Open, unverified bug report; inspect rounding, health and death transition with reproduction. |
| Two-word spells are hard | Open typing/readability concern; retain alongside non-typist feedback. |
| Better to select a specific spell than use Space? Space does not auto-cast on completion | Open interaction/expectation report; do not assume desired completion behavior without design. |
| Enter at spell completion makes a sound like taking damage | Open sound-cue confusion; distinguish cast confirmation from damage feedback. |

### Guer

| Feedback | Disposition |
|---|---|
| Is mana mana or XP? Slightly confusing | Open terminology concern: progression mana versus a spendable casting resource needs clear communication. |
| Mana as a way to prevent only spamming AoEs? | Deferred resource-system proposal; no mana-cost system approved. |
| Can spam Meteor Shower or Arcane Orbit excessively | Open balance observation; evaluate repeated-cast builds before selecting cooldowns, resource costs or another remedy. |
| Retyping sustained abilities such as Arcane Orbit and Flamewalk should extend duration and display it | Prior implementation: maintained recasts extend duration with timers. Firewalk extends emission time, not existing fire-patch lifetime. |
| Boss drops unique unlocks, e.g. upgraded “burn the world” / Conflagration from Cinder Field | Deferred boss-reward/spell-upgrade idea; current guaranteed potion/chest is distinct. Name is provisional. |
| Konosuba line / “cheese for everyone,” Monogatari neko tongue twister, random Easter eggs | Deferred incantation/Easter-egg ideas. Preserve references as supplied; exact phrases and intended usage need clarification before implementation. |
| Leaderboard | Deferred feature idea; scoring, fairness, persistence and hosting undecided. |
| Typing window at bottom; opening it raises a spell circle with runes as the casting action | Deferred presentation idea, related to Dead's glyph/animation sequence; avoid obscuring threats or spell reference. |

### Follow-up boundaries

No gameplay, art, audio, balance or export changes are part of this logging pass. Existing fixes, open reports, positive reactions and speculative ideas are deliberately distinct. This section preserves every topic in the supplied batch; earlier feedback remains elsewhere in this tracker and linked design records. Next prioritization should identify the actual build played, reproduce unresolved defects, and select a bounded implementation scope with LJ.


## Post-0.1.25 playtest feedback — 2026-09-28

Originally logged as player reports without implementation. Statuses below record subsequent verified fixes; deferred items remain unchanged.

| ID | Feedback | Status | Intended result / next verification |
|---|---|---|---|
| F41 | Firewalk appears in front of the wizard, obscuring the character | Fixed — verified | Ground field/trail/trap effects now use an absolute layer below characters. Verified fresh fire, recasting, sibling effects, and before/after rendered evidence in `tests/ground_hud_regression.gd`; Fix revision `e6e96e7` (PR #80); before/after and narrow screenshots retained in `builds/v0.1.26/ground-hud-evidence/`. Original expectation: Burning ground should render beneath the wizard, keeping the character visible. Reproduce walking through fresh and overlapping fire, including after recasting; inspect draw order and check other ground effects for the same issue. Preserve fire collision and lifetime behavior. |
| F42 | Unwanted explanatory text remains at the bottom of the screen | Fixed — verified | Instructional guidance is debug-only. Normal startup/acquisition/resize checks preserve spell names and timers, with rendered evidence in `builds/v0.1.26/ground-hud-evidence/`; fix revision `e6e96e7` (PR #80). Original expectation: Remove normal-game instructional messages such as “Click a spell or press 1–6…” and acquisition messages explaining which key to press. Retain the bottom casting reference: slot numbers, exact incantations, combination names without shortcuts, and active durations. Instructions belong in How to Play. Check startup and spell acquisition. |
| F43 | Bolt is not powerful enough when upgraded | Deferred | Player explicitly wants this saved for later. Evaluate upgraded Bolt's usefulness across ranks; no damage values, opening-strength changes, or progression redesign approved. |

## Status and update rules

- **Open:** recorded, unresolved.
- **Needs verification:** earlier implementation/evidence exists, but current behavior has not been rechecked for this concern.
- **In progress:** an active task is addressing the item; link its branch/PR.
- **Fixed — verified:** attach the fix revision, reproduction journey, observed result and evidence. A code change alone is not enough.
- **Deferred:** intentionally later; retain the idea and any prerequisite.
- **Decision recorded:** a design preference, not a claim of implementation.

Append new feedback as it arrives. Preserve the original observation and date; add clarifications rather than erasing it. Reopen a verified item when a regression is reported. Split a row when its parts can be fixed independently. A closed source report is historical evidence, not automatic closure here. Fixed rows stay in the tracker with their evidence.

## Current slate

**Approved playtest fixes — 2026-09-28:** health potion drops, tree depth ordering, four XP value colors, beam recasts/turning/piercing, Cross Blade return piercing, ingredient-driven combination growth, a modest Seeker nerf, compact inventory including combinations/ranks, casting/learning guidance, level-up deferral during casting, boss direction and version labels. Keep Swarmers and all spawn/difficulty curves unchanged. No rocks or full keyboard-menu overhaul. Web packaging follows verification.

| ID | Feedback / expected result | Status | Priority / evidence needed |
|---|---|---|---|
| F01 | Opening approachable, but standing still and ignoring threats should be unsafe; earlier target was death around 30–45 seconds | Open | Now: measure stationary/no-cast behavior in current build; historical target is tunable |
| F02 | Minutes 3–8 were too easy: around minute 8, four passive Mana Bolt upgrades allowed survival without movement | Open | Now: reproduce this build; inspect actual nearby pressure, spawn throughput, HP and enemy mix |
| F03 | Around minute 9 escalation felt good and minute 11 was hard in a good way | Decision recorded | Preserve as comparison points; this is player-reported historical feel, not current timing verification |
| F04 | Enemies should spawn in increasing numbers/pressure over time, not appear flat around minute 7 | Open | Now: verify emitted spawns, alive caps, offscreen population and enemies reaching player before tuning |
| F05 | Use bot runs plus ordinary and stationary builds; luck/build strength affects survival | Decision recorded | Compare repeated runs; bot survival alone does not establish fun or difficulty |
| F06 | Enemy health potion drops enable recovery without owning a healing spell | Implemented; tuning remains open | PR71: 2% drops, 10 HP, full-health preservation and distant-drop replacement; full natural-run tuning remains open |
| F07 | No rocks in current version; consider adding rocks | Deferred | User observation; obstacle versus decoration and collision remain undecided |
| F08 | Add forest paths and more environmental structure | Deferred | Environment work later; do not bundle graphics overhaul into balance |
| F09 | Keep current roguelike progression and random spells; current game is fun | Decision recorded | Preserve during difficulty work; full expedition design is future scope |
| F10 | Clean development slate before new features; distinguish current bugs, approved work and future design | Open | Reconcile branches/build status and open issues before implementation; no claim this audit is complete |

## Latest balance playtest — 2026-09-28

Recorded from player feedback; source audit at `8123a81732e4c78c0585636d5aed09ddab325e81`. Values below are calculated from current source, not a newly operated runtime test. No balance changes implemented in this documentation pass.

| ID | Feedback / expected result | Status | Findings and next decision |
|---|---|---|---|
| F36 | Rank-one Regeneration heals too much and too quickly | Open | Base 8 HP/second for 5 seconds = 40 HP per cast before missing-health cap. Each cast appends an independent healing effect, allowing overlap. Reduce both total healing and rate; exact amount/duration and repeat-cast policy need a tuning decision. Preserve its stronger sustained-healing identity versus Life. |
| F37 | Meteor Shower should cover more enemies on screen; observed opening count of five is too much; start with two or three; ranks should increase count or damage rather than both | Open | Authored base count is 4; runtime adds rank minus 1, so rank two has 5. Damage also gains 15% of base per rank. Reproduce the observed starting count and inspect acquired rank before calling it a rank-one bug. Targeting scores clusters across all living enemies with no screen/range limit; planned lethal damage lowers weights but does not prevent repeated overlap. Prioritize visible groups and wider useful coverage while keeping committed warning circles truthful. Choose starting count and a single benefit per rank before implementation. |
| F38 | Cross Blade never feels like the right choice for its typing effort; player rarely reaches for it | Open | Preserve the observation as a usefulness/identity problem, not automatically a damage buff. Incantation has 10 letters plus a space. Compare its outbound, linger and return payoff against alternative casts. Stronger return hit remains a deferred candidate under I12, not an approved solution. |
| F39 | Boss two has much less HP than boss one; boss one feels very tanky | Open | Scheduled source-derived HP: Gatekeeper at 5:00 = 1,879.2; Pursuer at 10:00 ≈ 302.6. Both use ordinary variant HP × time scaling × 12; base HP is 135 versus 15. Set deliberate boss-specific health budgets and judge alongside attack danger and player growth. Later boss difficulty need not be raw HP alone; exact budgets await tuning. |

Source locations: `data/spells.json`, `scripts/SpellManager.gd` (`cast_life_spell`, `cast_meteor_shower_spell`, `calculate_spell_damage`), `scripts/SpellTargeting.gd` (`select_area`), `data/encounters.json`, and `scripts/MonsterManager.gd` (`calculate_monster_stats`, `spawn_monster`).

### Follow-up proposals and boss damage context

- **F36 — Regeneration:** player proposes roughly **10–15 total HP over 5 seconds** (2–3 HP/second), rather than 40. Exact choice and overlapping-cast policy remain open. This is total healing per cast, not healing per tick.
- **F37 — Meteor Shower:** target on-screen enemies only, favoring enemies that are closer and stronger. Consider weighted random selection rather than a fixed nearest-first list; nearer/more threatening enemies should be more likely, not guaranteed every strike. Suggested design: visible candidates, bounded proximity/threat weights, then lower weights for areas already covered by this cast. Define strength (current HP, archetype threat, boss priority) and weight limits before coding. Retain warning positions once shown. Prior proposal of 2–3 starting meteors and count-or-damage rank growth still applies.
- **F38 / I12 — Cross Blade:** new candidate is **four smaller, individually weaker spinning blades**, launched in a cross and returning to the caster. Fantasy: returning ninja stars with useful coverage around the wizard. Not four copies at current damage. Preserve this as an alternative to the stronger-return-only idea; orientation, damage budget, linger, and overlapping hits on large enemies are undecided. Check both crowd coverage and maximum single-target damage before selecting values. Player is concerned it could be too strong; no implementation approved.
- **F39 — Boss two:** explicit direction is to make the second boss substantially stronger. Its current ~303 HP versus boss one's ~1,879 is not the intended progression. Choose its health and threat deliberately rather than simply increasing all enemies.

The player asked how many casts boss one's 1,879.2 HP represents. Source-derived examples at baseline `7be9209`, with no passive damage, damage upgrades, other spells or missed hits; ranks are illustrative, not measured five-minute loadouts:

| Spell / hit assumption | Rank 1 damage per cast | Rank 1 casts | Rank 3 damage per cast | Rank 3 casts |
|---|---:|---:|---:|---:|
| Bolt, all projectiles hit boss | 40 (1 bolt) | 47 | 156 (3 × 52) | 13 |
| Cross Blade, outbound + return, no linger ticks | 120 | 16 | 156 | 13 |
| Meteor Shower, every meteor hits boss | 80 (4 × 20) | 24 | 156 (6 × 26) | 13 |

Meteor damage uses the runtime 0.8 multiplier. These are idealized arithmetic counts, not average time-to-kill: nearby enemies split targeting, moving bosses can leave warning circles, blade passes can miss, while passive Mana Bolt and other damage reduce required manual casts. Measure real boss fight duration with representative five-minute builds before assigning a final HP budget.

### Rune Trap and boss target refinement — 2026-09-28

- **F40 — Rune Trap balance (Open):** player asks whether damage, knockback and indefinite persistence together make it too strong. Source audit at `b8b2e55`: base damage 60 in a radius-130 explosion, arms after 0.8 seconds, trigger radius 70; no knockback is applied by its damage path. It waits indefinitely while untriggered, fires once, then expires after about 0.25 seconds. At most three active traps; another replaces the oldest. The authored six-second duration does not expire an untriggered trap. This is persistent placement, not repeated permanent damage. Review damage/radius and pre-placement strength before changing the earlier requested persistence; no nerf selected yet.
- **F39 — proposed boss budgets:** player suggests boss one approximately **1,200 HP** and boss two approximately **1,800 HP**, with boss two faster. These are intended final health values at their scheduled spawn times, not ordinary-enemy base HP to multiply again. Relative to current source-derived values, this is about 36% less HP for boss one and six times boss two's HP. Boss two currently has base movement speed 110 and charge multiplier 3.8 (418 before slow effects); decide chase versus charge speed explicitly, preserving readable warning and dodge opportunity. Exact speed adjustment remains open. Proposed for testing, not implemented.
- At 1,200 HP, illustrative Bolt-only requirement is 30 rank-one casts or 8 rank-three casts if all three projectiles land, before passive damage and other spells. At 1,800 HP those counts are 45 and 12. These are arithmetic comparisons, not representative five-/ten-minute time-to-kill measurements.

## Earlier playtest concerns — retain and verify

These rows point into existing detailed plans/results. They are not all known current failures: verify before changing working behavior.

| ID | Feedback / expected result | Status | Source / closure evidence |
|---|---|---|---|
| F11 | Finite slowdown per cast, duration upgrades; no shared rechargeable meter | Needs verification | [Casting foundations and rework](PLAYTEST_REWORK_PLAN.md); timing/cancel/reopen checks |
| F12 | Tree collision narrow and centered on trunk; avoid canopy trapping | Needs verification | [Pass 2 spec](PLAYTEST_PASS_2_SPEC.md); operate near trunks from several directions |
| F13 | Trees/bushes cluster, vary in size, floor uses variants | Needs verification | [Art plan](ART_AND_FEEDBACK_PLAN.md), [pass 2 results](PLAYTEST_PASS_2_RESULTS.md) |
| F14 | All targeted spells/multicasts avoid wasting output on dead or already-doomed targets; Seeker reacquires | Needs verification | [Targeting](TARGETING_PASS_2.md); repeat casts and kill target mid-flight |
| F15 | Bolt starts available and visible; Bolt, Lightning and bouncing Lightning Bolt are distinct | Needs verification | [Spell catalog](SPELL_AND_UPGRADE_CATALOG.md), [library](SPELL_LIBRARY.md) |
| F16 | Combined spells are extra spells, keep ingredients and use no additional slot | Needs verification | [Rework](PLAYTEST_REWORK_PLAN.md); full inventory and synergy acquisition journey |
| F17 | Only unlocked spells may be cast; test unavailable and bonus spell cases | Needs verification | [Implementation report](PLAYTEST_IMPLEMENTATION_REPORT.md); cast rejection/acquisition tests |
| F18 | Regeneration and healing must work and read distinctly; Steam Field must not heal enemies | Needs verification | [Healing](HEALING_READABILITY_PASS.md), [pass 2](PLAYTEST_PASS_2_SPEC.md) |
| F19 | Plague Seed visibly infects/spreads; host death leaves a finite lingering spore that can infect again | Needs verification | [Pass 2](PLAYTEST_PASS_2_SPEC.md), [spell audit](SPELL_PASS_2_AUDIT.md) |
| F20 | Spell size and actual hit geometry agree; Ice Blast damage occurs on shard contact, size control affects it | Needs verification | [Readability evidence](READABILITY_PASS_2_EVIDENCE.md), [workshop](VISUAL_WORKSHOP.md) |
| F21 | Clear outlined colored AoEs; growing meteor warnings; connected burning ground, visible persistent Rune Trap | Needs verification | [Pass 2 spec](PLAYTEST_PASS_2_SPEC.md), [art plan](ART_AND_FEEDBACK_PLAN.md) |
| F22 | Cross Blade, Arcane Orbit and Firewalk need worthwhile strength, coverage and persistence; Focus Ray is a positive reference | Needs verification | [Spell audit](SPELL_PASS_2_AUDIT.md); compare current casts before tuning |
| F23 | Longer spells earn commitment through useful power; basics stay situationally valuable; each spell has a distinct fantasy | Needs verification | [Spell library](SPELL_LIBRARY.md), [casting notes](CASTING_FANTASY_NOTES.md) |
| F24 | Boss drops an upgrade chest; pursuer dash farther/faster; contact enemies bounce away after hitting | Needs verification | [Pass 2 spec](PLAYTEST_PASS_2_SPEC.md), [results](PLAYTEST_PASS_2_RESULTS.md) |
| F25 | Distant regular enemies recycle from new angles; timed hordes have distinct behavior | Needs verification | [Encounter design](ENCOUNTER_DESIGN.md), [pass 2 results](PLAYTEST_PASS_2_RESULTS.md) |
| F26 | XP persists/consolidates with exact value; distinct gem colors/tiers, stable size without pulsing | Needs verification | [Pass 2 spec](PLAYTEST_PASS_2_SPEC.md), [results](PLAYTEST_PASS_2_RESULTS.md) |
| F27 | Enemies opaque; quick red damage flash, no unnecessary hit clutter or unexplained circles | Needs verification | [Readability evidence](READABILITY_PASS_2_EVIDENCE.md), [art plan](ART_AND_FEEDBACK_PLAN.md) |
| F28 | Actor/projectile/environment proportions readable together; later request shrinks Bolt 20–30% and backs camera out 5–10% | Needs verification | [Readability evidence](READABILITY_PASS_2_EVIDENCE.md), [workshop](VISUAL_WORKSHOP.md); latest adjustment takes precedence over earlier enlargement requests |
| F29 | Ember Lance and Lightning Bolt visual identity need review against liked samples | Needs verification | [Pixel art pass](SPELL_PIXEL_ART_PASS.md); rendered motion matters, not asset presence |
| F30 | Minimal HUD, concise upgrade descriptions, no boss schedule/debug clutter; no clipped or wrapped spell names | Needs verification | [UI pass](UI_UX_PASS.md); desktop/narrow casting and level-up journeys |
| F31 | Run spellbook shows run knowledge; Necronomicon holds broader collection | Needs verification | [Spellbook design](SPELLBOOK_NECRONOMICON.md); new-run/reset and persistence journeys |
| F32 | Workshop previews every effect, with wizard reference, size controls and animated exports; Ice Blast previously failed | Needs verification | [Workshop](VISUAL_WORKSHOP.md), [gallery](SPELL_VISUAL_GALLERY.md); actual preview/export journey |
| F33 | Audio disliked as MIDI-like; improved sound must reach actual gameplay, not just preview | Needs verification | [Audio pass](TACTILE_AUDIO_PASS.md); audible in-game assessment required |
| F34 | Staff floats/orbits smoothly toward nearest threat with boss priority; preserve layered wizard for future animation | Needs verification | [Art plan](ART_AND_FEEDBACK_PLAN.md); motion/target switch review |
| F35 | Shareable playtest builds, consolidated integration and no abandoned task folders | Needs verification | Build/export and branch audit; retained unique work cannot be deleted as cleanup |

## Future design and art ideas

| ID | Idea / preference | Status | Reference / boundary |
|---|---|---|---|
| I01 | Wizard fantasy: language expresses complex magic; readable ancient inscriptions replace keycap branding | Decision recorded | [Art](expedition-design/08-art-feedback.md), [UX](expedition-design/09-ui-accessibility.md); implementation later |
| I02 | Permanent keywords modifying shared spell properties; prepared spellbook and activation order | Deferred | [Component reference](expedition-design/14-spell-system-reference.md); preserve current roguelike loop now |
| I03 | Circular tower room, rotary dial, stained-glass destinations, top portal, tower exit and huge deck-like preparation book | Deferred | [Tower concept](expedition-design/09-ui-accessibility.md#wizard-tower-rotary-destination-chamber); book position/capacity and 3D treatment open |
| I04 | Automatic recall to tower; 20-minute default, potential per-level duration/curves; 25-minute idea deferred | Deferred | [Tower concept](expedition-design/09-ui-accessibility.md#wizard-tower-rotary-destination-chamber) |
| I05 | Ley-line challenges unlock magic; long ritual words; optional guardian after four sites | Deferred | [Levels](expedition-design/06-levels.md), [decision/idea register](expedition-design/02-decisions.md) |
| I06 | Simple floor-color/layout sketch, paths, rocks; possible 3D room blockout | Deferred | Await art/layout exploration; no full rendering migration selected |
| I07 | Slime animation frames/interpolation, shaders, typed menu navigation, alternate characters | Deferred | [Roadmap](../ROGUELITE_ROADMAP.md); later polish/experiments |
| I08 | Spell ideas, paired Ice/Glacial Lance, elemental Wall synonyms, Charged/Delayed/Repeating versus Duplicating | Deferred | [Spell catalog](expedition-design/03-spells.md), [component reference](expedition-design/14-spell-system-reference.md); preserve individual idea entries |
| I09 | Soul Bloom healing carrier, Big infection/AoE, Meteor Lance alternatives, smooth Focus Ray, rotating laser, arcane crit | Deferred | [Open decisions](expedition-design/13-review-record.md#alignment-review--28-september-2026); alternatives are not implemented promises |
| I10 | Siege/tower defense/alchemist format and mouse final boss | Deferred | [Idea register](expedition-design/02-decisions.md); separate ideas, no pivot approved |
| I11 | Eventual generated-art/music replacement; existing assets can remain for current testing | Deferred | [Art direction](expedition-design/08-art-feedback.md); no immediate bulk replacement |
| I12 | Cross Blade should have a stronger return hit that rewards positioning; tentative double-return damage or base damage −25% with return +50% | Deferred | [Return-hit idea](../ROGUELITE_ROADMAP.md#deferred--cross-blade-return-hit-identity-2026-09-28), recorded 2026-09-28; alternatives and percentage reference unresolved; no gameplay change authorized |

## New spell and progression ideas — 2026-09-28

| ID | Idea | Status | Record |
|---|---|---|---|
| I13 | Personal lightning aura with per-enemy 1–1.5-second exposure before an individual direct strike; long incantation appropriate to utility | Deferred design | [Mechanics, names and open decisions](expedition-design/03-spells.md#storm-aura-roots-and-wizard-movement--2026-09-28-ideas); fixed lifetime per cast; level-ups extend duration, kills do not |
| I14 | **Shillelagh** as the confirmed name for a moving directional wave of tree roots | Deferred design | Same spell-idea table; physical/nature fantasy, damage timing and trail behavior undecided |
| I15 | Dash immediately on casting versus a stored dash charge | Deferred design | Same table; separate controls discussion, neither behavior selected |
| I16 | Swiftness temporary movement-speed spell | Deferred design | Same table; magnitude, duration and stacking open |
| I17 | Mana represents accumulated unspent magical power that unlocks progression thresholds, rather than a casting fuel pool | Design direction | [Accumulated mana](expedition-design/03-spells.md#accumulated-mana-as-progression); current gameplay unchanged, naming and run persistence open |

## Naming, local play and Disruptor follow-up — 2026-09-28

- **I18 — The Disruptor (deferred):** boss scrambles/randomizes spell letters while preserving incantation length. Once, periodically or after each cast are alternatives, not a chosen cadence. [Full boss idea and open decisions](expedition-design/06-levels.md#deferred-boss-idea--the-disruptor-2026-09-28).
- **Decision:** prefer evocative magical player-facing names. Functional labels belong in internal documentation; preserve the intended mystical name rather than replacing it with Root Wave; Shillelagh is now confirmed by the user. [Naming rule](expedition-design/03-spells.md#player-facing-spell-naming-rule--2026-09-28).
- **Workflow preference:** prioritize updating the local playable game. Shareable DMG/ZIP packaging is optional, not a gate for ordinary local iteration; build it when requested or useful and inexpensive, rather than routinely delaying delivery.

## Mystical naming and relic follow-up — 2026-09-28

- **I19 — Boots of Hermes (deferred):** an item/relic unlocks the short Dash action. Relics may grant abilities; slot rules, cooldown/charges, acquisition and persistence are not selected. [Full proposal](expedition-design/03-spells.md#mystical-vocabulary-and-relic-granted-abilities--follow-up).
- **Naming preference:** choose evocative magical vocabulary across the roster, potentially drawing on mythology or familiar media. Fast reaction words such as Dash may stay short. Meteor Shower could receive a cooler name later; no replacement selected.
- **Yggdrasil / World Tree:** reaffirm the existing ultimate-healing-tree idea and mystical spelling as part of its appeal. This does not approve the old provisional numeric defaults.
- **Reference confirmed:** the user confirmed Shillelagh. Draw names from mythology, folklore or popular fantasy media; trace older origins where possible while retaining our own mechanics.

## Ritual casting idea — 2026-09-28

- **I20 — multi-stage incantation / Explosion (deferred):** long chant ending in a final word that releases a screen-wide blast; user cites Konosuba as the fantasy reference. [Full idea and open decisions](CASTING_FANTASY_NOTES.md#multi-stage-ritual-casting--2026-09-28-idea). Continuous versus checkpointed casting and per-cast slowdown integration require design before code.

## Detailed source records

The linked plans, catalogs and reports retain original subrequirements and historical implementation evidence. Read those alongside each row rather than collapsing their entire scope into a single fixed checkbox. New reports should reference these IDs and link the exact candidate evidence. If an older conversational detail has no corresponding source or row, add it explicitly; this index does not claim a line-by-line transcript audit or freshly verified closure of every historical issue.

## Current balance pass — 2026-09-28

Supersedes the provisional decisions and historical arithmetic above. Runtime checks and screenshots are in the playtest-balance build evidence; these do not establish final gameplay balance.

- F36: rank-one Regeneration heals 15 HP total over five seconds; Life stays 4 HP. Repeated regeneration casts still overlap.
- F39: scheduled bosses use final HP 1,200 / 1,800. Boss two dashes at 600 speed, with unchanged normal speed and warning duration. Warning reach and slows match actual travel.
- F40: Rune Trap deals 40 base damage; indefinite untriggered placement, single explosion and three-trap cap remain.
- F37: Meteor Shower counts by rank are 2,3,3,4,5,5,6,8. Radius is 220 at ranks 1–2, 250 at 3–5 and 280 at 6–8. Per-meteor damage is fixed across these ranks (20 before player damage bonuses); count and area each have their own upgrades. Visible target selection is weighted toward nearer and higher-current-HP enemies, with capped health weighting and reduced chance for previously covered areas. Warnings stay fixed after placement.
- F38/I12: Cross Blade starts with three radial blades in a triangle. Rank 2: four in an X; rank 3: radius22→26; rank 4: travel350→400; rank 5: radius26→29; rank 6: five in a pentagon; rank 7: travel400→460; rank 8: six in a hexagon. Each blade deals20 base damage per outbound/return hit, with existing controlled half-damage lingering ticks. Three active volleys replace three individual blades as the cap. Old stronger-return-only proposal remains a deferred alternative.
- Both authored spell progressions cap at rank8; upgrade cards stop offering them and use the same data as gameplay. Other spell rank behavior is unchanged.
- Pacing intent: mechanics familiar by5min, established by10, ramp from13, crowding by17. Spawn multipliers at minutes0/3/5/10/13/17/20 are1/1/1.2/1.65/2/3.3333/4.5, interpolated smoothly. The existing two-minute breathing phases, enemy-health curve, tier unlocks, waves and160-alive cap remain. Minute17 phase intervals are0.9/0.6/0.3s; batches remain one normal roll (Swarmer packs still three bodies).
- Two fixed60fps bot runs died at567.2s/388.4s, without runtime errors; casting failures were0/1. They do not validate late-game crowding or boss-two fight feel. Numeric curve checks cover all1200 seconds; human playtesting remains required.

## Approved playtest follow-up — 2026-09-28

This section supersedes broader suggestions from the conversation. Implementation is approved. PR71 covers world/pickups, PR72 casting/progression and PR73 UX. Candidate-bound logs and captures are published under `builds/current/evidence/playtest-followup/`; automated correctness, visual checks and full-run balance remain separate.

| Concern | Acceptance / scope | Initial disposition |
|---|---|---|
| Tree overlap | Lower trunk base draws in front, across neighboring scenery chunks and after movement | Implemented; regression and native evidence recorded |
| XP colors | Four readable value tiers, preserving total XP through consolidation | Implemented; regression and native evidence recorded |
| Health potions | Actual enemy drops allow non-healing builds to recover; bounded count and no wasted full-HP collection | Implemented; regression and native evidence recorded |
| Cross Blade | Return leg pierces and damages multiple enemies; stronger return damage remains a separate deferred idea | Implemented; regression and native evidence recorded |
| Prism Ray / Focus Ray | Recasting creates another visible cast; Prism pierces, Focus turns smoothly with thinner matching damage geometry | Implemented; regression and native evidence recorded |
| Combination progression | Upgrading either ingredient strengthens its combination; retain ingredients and slot-free combinations | Implemented; regression and native evidence recorded |
| Seeker | Modest targeted nerf, retain targeting and fantasy | Implemented; regression and native evidence recorded |
| Inventory | Visible active, passive and combination icons with ranks, clear switching and exact incantations | Implemented; regression and native evidence recorded |
| Level-up while typing | Finish or cancel current incantation before pending choice; no lost choices on pause/resume, no choice after death | Implemented; regression and native evidence recorded |
| Space on level-up | Avoid unexplained accidental choice/typing interaction; no full keyboard overhaul required | Implemented; regression and native evidence recorded |
| Boss direction | Small indicator for living offscreen boss, hidden for visible/dead boss | Implemented; regression and native evidence recorded |
| Version | Shared v0.1.0 Playtest label on menu, pause/results and bottom-right gameplay | Implemented; regression and native evidence recorded |
| Windows flicker | Investigate available evidence; Windows-specific reproduction requires Windows runtime | Open |
| Web / itch | Real gameplay HTML export, browser verification and upload-ready package; hosting/account setup separate | Export pipeline implemented; local browser verification recorded with each build |

Deferred: rocks, movement spells, more lightning spells, landmarks, structured/procedural map changes, mouse aiming, distance-keeping enemy, clickable menu slime and fully keyboard-operated menus. Preserve non-typist difficulty feedback for future study. Pink enemies were a positive panic moment, not a nerf request. Swarmers and opening/post-1:30 pressure changes explicitly excluded from this pass. Focus Ray and typing audio were praised; one reported run lasted 7:36, and another player started a second run. ZIP confusion is onboarding feedback, not a confirmed launch defect.

### Implementation and verification boundaries

- Potions start at 2% per kill and restore 10 HP. Up to 12 remain in the world; a successful drop can replace a distant offscreen potion beyond 2,000 units. Full HP never consumes one. These are initial tuning values, not a claim of final balance.
- XP thresholds are 25 / 100 / 500 for green / purple / gold; smaller values remain blue.
- Cross Blade already pierced enemies on both legs; regression now explicitly covers multiple return hits without duplicate same-leg damage. No return-damage bonus added.
- Focus/Prism support three independent active casts each, distinct emission lanes and smooth rotation; Prism pierces the full line. Seeker contact damage is 18, previously 22.
- Each ingredient rank above one adds 7.5% of combination base damage, additive with its own rank bonus. Life also improves seed healing, Ice improves Steam Field/Frost Sigil area and Regeneration improves Soul Bloom recovery. Player damage modifiers apply once.
- Inventory distinguishes base spells, slot-free combinations and passives with own ranks; ingredient ranks appear in combination tooltips. No full keyboard-navigation overhaul was performed.
- Windows-specific flickering remains open: macOS/native and browser evidence cannot verify that report. Mobile/touch support and a full natural 20-minute balance verdict are not included.
- Browser package creation and local playtesting do not publish an itch page. Account/page access and final visibility are still separate steps.

## Style playtest follow-up — 2026-09-28

Approved combined pass; implementation and focused verification complete; human balance/feel review remains. Earlier ray correctness claims do not close these fresh reports.

| Feedback | Acceptance | Disposition |
|---|---|---|
| Atomic too easy; S reached around 2:30 | 800 raw combo per grade; rank multiplier applies only to run score; Atomic costs 10,000, cap supports it | Implemented; regression verified |
| Empty casting after repeated wipes | Population-aware offscreen replenishment plus bounded sustained-clear pressure; no special Atomic-only reset and no one-clear difficulty spike | Implemented; regression verified |
| Focus/Prism endings look wrong | Inspect both endpoints and expiry; visible beam agrees with damage until it ends | Implemented; contact tests and native visual inspection |
| Prism second target not damaged | Real multi-target geometry and repeated-tick coverage, including edge-of-body intersections | Implemented; contact tests and native visual inspection |
| Channel loses combo when target dies | Active finite beam lifetime suspends decay through retarget gaps; normal grace resumes after final channel; no extra cast awards | Implemented; regression verified |
| SS–SSS gap felt good | Preserve 800 gap, apply it consistently to earlier grades | Implemented; regression verified |

Keep current cast scoring, spell damage, timed enemy tiers, later ranged unlocks and 20-minute extraction. Encounter density and feel require human playtesting after mechanical verification.

Additional accepted feedback in this pass: Focus and Prism share target reservations (including two Prism casts); Lightning Bolt starts with four extra bounces and gains one per own spell rank; the meter must reproduce the connected stone/rune reference; faster cadence and larger groups rise in parallel. Implemented and covered by integrated checks; final human feel review remains.

Open diagnostic follow-up: console `kill_all_enemies` / `explode_all_enemies` remove enemies directly and can leave a stale spawner count. Normal combat and Atomic use the correct death signal. Repair debug removal bookkeeping separately; debug-assisted runs are excluded from scores.

## Follow-up tuning — 2026-09-29

- Implemented: clear-based escalation disabled through a zero-valued setting; retain its code. Respawn/refill and timed growth remain unchanged as requested.
- Pending: rank gaps100/200/400/600/800/1000/1200/1400; Arcane Orbit should respond to projectile speed; Focus duration2or1.5seconds (latest preference1.5, runtime still3); recycle beyond300instead600; acquire/retarget visible enemies only. These are not part of the adaptive-disable change.
- Feedback: sustained rapid casting felt physically tiring and adaptive difficulty became excessive. Do not interpret that as authorization to keep Focus at3or remove respawn.

## Seeker and style follow-up — 0.1.31

Implemented: Seekers distribute among visible targets, release reservations on death/offscreen/expiry, share only when alternatives run out and spread again when new targets arrive. No visible target means return toward the caster. Combo grace is five seconds after a manual cast or final ray channel. Global targeting restrictions for other spells, shorter Focus, graduated rank thresholds and300-unit recycling remain pending.
