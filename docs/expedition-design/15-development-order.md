# Release plan and expedition roadmap

Updated 14 October 2026 for 0.3.0. Preserve the full [expedition spell catalog](03-spells.md). No assistant-selected small spell pack replaces it. New combinations will be decided later. **Release goals agreed with Aditya on 14 October 2026.** The version assignments below are the working release plan. Approval establishes the goals and sequence; it does not mean those releases are already shipped or resolve the explicitly open spell mechanics.

## Version numbers

The latest release is **0.3.1** (15 October 2026), the first combat-feel slice built from 0.3.1-dev.1 to dev.5. It does not complete the whole-roster feel goal below; later builds continue it; development after it is **0.3.2-dev.2** (the release was cut before the dev.6 Steam particles, spirit and meteor work, which ships next). Use separate whole-number components: `0.3.9` is followed by `0.3.10`, not a decimal fraction. “3.0” and “3.1” in conversation mean `0.3.0` and `0.3.1` here. Increment the release version when shipping a changed build; a documentation consolidation does not itself create a gameplay release. Verify tags and distributable builds before calling a release published.

## Agreed release goals

| Version | Goal and scope | Completion evidence |
|---|---|---|
| 0.3.0 | Current foundation: shared spell engine, existing roster, keywords, statuses, preparation and VFX; finish the current playtest fixes and establish the release baseline. | Exact source/build recorded; checks and playable export verified. The changelog already identifies 0.3.0; this plan does not claim a new tag or upload. |
| 0.3.1 | Whole-roster combat feel: casting response, windup, travel, contact, sound, hit reaction, shake, persistence, expiry, readability and keyword feedback. | Compare actual moving combat across the roster, crowded encounters, reduced effects and supported displays; visual size matches hits. Existing effects are open to improvement, not exempt because they exist. |
| 0.3.2 | Data-defined spells, agreed 15 October 2026 as a prerequisite for the catalog: shape, targeting, cast context, combination growth, preparation lists and rank rules move from code to data; a new spell is data plus tests. | Recorded 0.3.0 outputs prove identical behavior (shapes, sizing, combination growth, rank cards, lists); a spell defined only in data is preparable, castable, ranked and keyword-compatible; full suite shows only baseline failures. |
| 0.4.0 and follow-up 0.4.x builds | Implement the full authored catalog as reviewable increments, tracking each identity and its dependencies. Paused spells remain paused; open mechanics are resolved before their implementation. | Every completed spell has its fantasy, progression, keyword behavior, effects, timing and balance verified. No subset or fixed spell count is selected by this roadmap. New combination recipes remain deferred. |
| 0.5.0 | Enemy and encounter foundations plus tutorial: remaining actor/damage work, shared enemy behaviors, elites, boss definitions, normal-slime encounters and King Slime, objective runner and lessons. | Different threats reward different spell choices; attacks and boss phases are readable; tutorial is operated end to end. Reuse completed 0.3 foundations. |
| 0.6.0 | First complete expedition: prepare, explore four ley-line sites, earn knowledge, guardian, recall/death, save, return and reenter. | A complete persistent journey, including failed objectives, duplicate grants, interruption/reload and death under the selected retention policy. |
| 0.7.0 onward | Expand the tested expedition loop with later realms, enemies, rewards and the remaining content dependencies. Discuss combinations separately, then schedule selected recipes. | Distinct routes and loadouts matter, with balanced rewards and complete realm journeys. |
| 1.0.0 | Agreed launch campaign, onboarding, accessibility, performance, balance, art/audio and supported packages. | Operated release builds and player evidence across complete journeys. |

Use these agreed goals to organize implementation and measure release readiness. Dependencies still determine the order of individual changes. Summons, destructible walls, corpse targeting and advanced enemy interactions may require parts of the enemy work before their catalog entries can ship. Track those prerequisites alongside each spell; do not rebuild an existing system or silently drop a spell to fit a release number. Exact batches, estimates and release boundaries beyond 0.7 remain to be selected.

## What 0.3.0 already supplies

- Six prepared slots, ordered activation and saved preparation; tower entry flow already exists.
- Sixteen manual bases, seven enabled combinations, automatic Magic Missile and the Atomic reward.
- Shared spell construction, keyword processing, elements, statuses and a VFX layer.
- Data validation, stats modifiers, gameplay events and seeded randomness foundations.

These are implementation facts from the release source and changelog, not claims that their feel or all dependent systems are finished. Do not repeat the older “MEGA only, preparation next” roadmap. Current damage/status rules live in [doc 21](21-damage-effects-keywords.md); runtime numbers live in data and code.

## Combat feel work

Treat existing implementations as hypotheses, not design authority. Start from each spell's fantasy and intended experience; investigate why current choices exist and keep, reshape or replace them based on that purpose. Readability, performance and technical correctness support the experience rather than substitute for it. Apply this across all visuals, animation, sound, camera and feedback systems.

Review each spell's input response, anticipation, targeting, travel, contact, payoff, sustained phase and expiry. Compare ordinary and modified casts, rank changes, combinations and overlapping statuses. Tune audio alignment, enemy reaction and shake together with visuals. A spell with an identifiable silhouette may still have poor timing.

The 0.3.0 audit raised Steam/Cinder separation and obstruction, armed Rune Trap/Frost Sigil distinction, size-to-hitbox agreement, combined keyword/status cues, status-reaction feedback and reduced-effects propagation. Reproduce against the latest candidate before fixing: parallel playtest work may already have changed a finding. Source/test existence never substitutes for operated visual and auditory judgment.

### 0.3.1 development checkpoint — 15 October 2026

`0.3.1-dev.1` connects Reduced effects to the spell renderer, including restart, and reduces Steam Field mist obstruction. Targeted settings and VFX regressions plus desktop/narrow native captures cover this first change. Full moving-combat, audio, status-overlap and whole-roster qualification remain open; this is not a release-complete claim.

`0.3.1-dev.2` fades enemy hit flashes after their initial red cue, lowers the cold-status flake density and gives Frost Sigil a distinct ice glyph. Targeted moving Steam fixtures and trap arming/trigger captures support this increment; full playthrough and audio qualification remain open.

`0.3.1-dev.3` corrects redraw-dependent landing/ray lifetimes, clears those effects on reset, matches Arcane Orbit sphere size to geometry and removes Seeker scaling gaps/clamps. Other projectile-family sizing and trails remain under review.

`0.3.1-dev.4` replaces scattered Steam particles with overlapping rising vapor plumes and subdues the ground footprint. Reduced effects keeps the same identity with fewer vents. Steam sound and dense burn feedback remain open.

`0.3.1-dev.5` tests a different Steam hypothesis: connected rolling vapor fed by pressure vents, with partial occlusion and gradual breakup. It replaces individual puff stamps and the ground disk with a shader surface. HOMING movement, live reduced-effects changes, pause, reset and expiry are explicit lifecycle checks. Audio remains unfinished; visual success must be judged in motion.

`0.3.1-dev.6` restores particle-driven shared density for Steam after comparing Steam → Field in the reference sandbox, adds Soul Bloom spirit identity and healing/hunting cues, and synchronizes accelerating meteor descent to gameplay time. These are targeted visual changes; sound and full-roster identity qualification remain open.

`0.3.2-dev.2` lowers Cinder flames toward an ember-bed silhouette and gives Soul Bloom flowing twin trails, a directional luminous core and a small arrival cue. Preserve staggered meteor falls and repeated shakes as an explicitly enjoyed part of the fantasy. Damage balance is unchanged.

### Next identity investigations

- Meteor Shower and Meteor Spear: inspect descent against authoritative impact timing during repeated hitstop, then judge warning, weight, sound and camera response together. The dev.6 timing fix has regression coverage and native captures; the broader audio/camera sequence still needs judgment.
- Prism Ray: inspect overlapping contact fans and afterimages in moving crowds. Reconcile doc 21's older angle/length with the current playtest-tuned bridge before changing mechanics.
- Soul Bloom: dev.2 refines the silhouette, trails and arrival. Continue reviewing infected-host departure, crowd readability and sound as one sequence.
- Flame Wall: develop the catalog’s surrounding burning ring and its visuals together; do not polish the current straight line into an assumed final design. Intended damage identity is low direct contact damage and strong damage over time; balance changes belong in a separate implementation pass.

These are source-grounded priorities, not completed visual or auditory qualification.

## Expedition direction

Prepare a deliberate spellbook at the tower → enter a realm → fight, travel and grow during the run → complete magical site challenges → discover spells and words → confront the guardian or reach recall → return and change the next preparation.

- **Four ley-line sites** are the target, reachable in different orders through an authored route network with restrained variation. Existing ley-line implementation is not assumed to match that final contract.
- Completing all four permits the realm guardian encounter. The default expedition recall is **20 minutes**; the intended deadline still applies during a late boss attempt. This target is distinct from the current prototype's day/night or endless modes.
- **Level 1 starts with normal slimes:** grunt, runner and bruiser patterns, then King Slime. Elemental counters, ranged barrages and the older Rootbound Colossus proposal do not become simultaneous first-level requirements.
- Knowledge gives exploration purpose. Ritual attempts must support clear threats, failure/retry, completion and grant-once rewards.
- Discovery retention on death remains a decision. Immediate retention is the recorded recommendation, not a settled rule. Preserve current saves until a tested migration exists.
- Mana as cumulative progression, XP terminology, ranks and upgrades must be reconciled with the current functioning level system. Do not introduce a spending resource or remove working upgrades by interpreting an older draft as approval.
- The tower concept is a walkable rotary destination chamber, stained-glass destinations/top portal and a preparation book. Adapt the existing hub; unresolved layout/art-medium choices remain open.
- Tutorial plus four realms is the recorded campaign proposal, not a locked launch-size commitment. Additional guardian concepts and detailed old realm layouts remain available in the historical design.

## Retained direction and implementation discrepancies

Permanent spell and keyword knowledge, deliberate preparation and useful short spells remain the direction. Vocabulary replaces passive-item expression in the expedition design; this does not settle how existing XP, spell ranks and wizard upgrades transition. Preserve the playable progression until that transition is designed.

The earlier confirmed target used finite **per-cast slowdown, not a shared meter**. The current 0.3.0 README describes a **shared refillable typing budget**. This is an explicit design-versus-implementation discrepancy to reconcile before changing casting assistance; neither wording silently overrides the other in this documentation merge. Numeric assist presets in older drafts remain proposals.

The preserved Disruptor boss idea scrambles incantations while retaining their length. It is not assigned to King Slime or a current realm. Timing, shuffle versus replacement, affected spell scope and interaction with input modifiers remain open. The keyboard-wizard versus mouse-fighter final-boss idea is an optional later chapter, not part of the first expedition.

## Remaining systems and decisions

[Game systems architecture](20-game-systems-architecture.md) owns actor integration, enemy behaviors/attacks, elites, bosses, level/objective data, saves, progression and run flow. Its G1–G7 sequence is a dependency plan, not evidence that each item is still missing or already built. Inspect completion before assigning work; the validator/event/stat foundations are already in 0.3.0.

| Decision | Current disposition |
|---|---|
| New combinations and recipes | Deferred for a future discussion; preserve current seven combinations and new theme ideas. |
| Paused spears | Ice/Glacial Spear and Lightning Spear/Rod remain paused. |
| Full catalog implementation | Preserve all authored identities; remaining per-spell questions are in doc 3, not a second list here. |
| Death retention and persistent rewards | Select policy before expedition save implementation; test idempotent rewards and recovery. |
| Progression terminology and upgrade roles | Reconcile existing six-slot activation, ranks and XP with expedition mana/knowledge; no silent replacement. |
| Automatic Magic Missile | Retain current behavior; any manual-only experiment is separate. |
| Summons, barriers and advanced magic | Verify shared actor/targeting/event support first; no assumption that all recorded engine gaps are still missing. |
| Presentation direction | Wizardry and readable inscriptions; existing keycaps are implementation, not a prohibition on refinement. Keep useful art while evaluating alternatives. |
| Campaign size and art medium | Four realms and later 2D/3D/hybrid exploration remain proposals. |

## Delivery rules

Each implementation increment keeps the game playable, uses isolated work, updates the changelog and version for its shipped build, receives review, and cleans up its worktree after merge. Record exact-candidate test evidence and distinguish completed, failed, blocked and untested journeys. Do not infer balance from equal damage or incantation length alone: short emergency magic and longer committed casts serve different purposes.

This is a development sequence, not a schedule for when a player unlocks vocabulary. Acquisition is designed with the expedition challenges. Historical draft numbers and realm content are retained in the [dated archive](archive/2026-10-14/README.md), not parallel current requirements.
