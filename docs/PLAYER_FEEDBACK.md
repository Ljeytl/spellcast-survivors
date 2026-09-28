# Player feedback tracker

Single entry point for player feedback, fixes and deferred ideas. Updated 28 September 2026. This tracker changes no gameplay. Earlier detailed feedback remains in the linked source records; rows below consolidate concerns without replacing those records or claiming old fixes still pass today.

## Status and update rules

- **Open:** recorded, unresolved.
- **Needs verification:** earlier implementation/evidence exists, but current behavior has not been rechecked for this concern.
- **In progress:** an active task is addressing the item; link its branch/PR.
- **Fixed — verified:** attach the fix revision, reproduction journey, observed result and evidence. A code change alone is not enough.
- **Deferred:** intentionally later; retain the idea and any prerequisite.
- **Decision recorded:** a design preference, not a claim of implementation.

Append new feedback as it arrives. Preserve the original observation and date; add clarifications rather than erasing it. Reopen a verified item when a regression is reported. Split a row when its parts can be fixed independently. A closed source report is historical evidence, not automatic closure here. Fixed rows stay in the tracker with their evidence.

## Current slate

**Keep the current roguelike alpha and random spell/build progression. Difficulty scaling is the next priority.** First reproduce the current pacing before changing numbers. Keyword composition is a deferred experiment, not the next approved implementation. The expedition package describes a possible fuller game, not a mandatory current backlog. No new balance changes are authorized merely by logging this feedback.

| ID | Feedback / expected result | Status | Priority / evidence needed |
|---|---|---|---|
| F01 | Opening approachable, but standing still and ignoring threats should be unsafe; earlier target was death around 30–45 seconds | Open | Now: measure stationary/no-cast behavior in current build; historical target is tunable |
| F02 | Minutes 3–8 were too easy: around minute 8, four passive Mana Bolt upgrades allowed survival without movement | Open | Now: reproduce this build; inspect actual nearby pressure, spawn throughput, HP and enemy mix |
| F03 | Around minute 9 escalation felt good and minute 11 was hard in a good way | Decision recorded | Preserve as comparison points; this is player-reported historical feel, not current timing verification |
| F04 | Enemies should spawn in increasing numbers/pressure over time, not appear flat around minute 7 | Open | Now: verify emitted spawns, alive caps, offscreen population and enemies reaching player before tuning |
| F05 | Use bot runs plus ordinary and stationary builds; luck/build strength affects survival | Decision recorded | Compare repeated runs; bot survival alone does not establish fun or difficulty |
| F06 | Enemies could randomly drop health potions | Deferred | Gameplay experiment after baseline pacing; chance, heal amount, pickup rules and interaction with healing spells undecided |
| F07 | No rocks in current version; consider adding rocks | Deferred | User observation; obstacle versus decoration and collision remain undecided |
| F08 | Add forest paths and more environmental structure | Deferred | Environment work later; do not bundle graphics overhaul into balance |
| F09 | Keep current roguelike progression and random spells; current game is fun | Decision recorded | Preserve during difficulty work; full expedition design is future scope |
| F10 | Clean development slate before new features; distinguish current bugs, approved work and future design | Open | Reconcile branches/build status and open issues before implementation; no claim this audit is complete |

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

## Detailed source records

The linked plans, catalogs and reports retain original subrequirements and historical implementation evidence. Read those alongside each row rather than collapsing their entire scope into a single fixed checkbox. New reports should reference these IDs and link the exact candidate evidence. If an older conversational detail has no corresponding source or row, add it explicitly; this index does not claim a line-by-line transcript audit or freshly verified closure of every historical issue.
