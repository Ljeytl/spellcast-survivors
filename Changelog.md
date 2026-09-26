# Changelog

## 2026-09-26 — Limited typing slowdown

- Give each run a shared three-second typing slowdown budget, refilling fully over ten seconds outside typing. Casting, cancelling, or reopening does not reset it.
- At exhaustion, restore normal world speed while preserving input and the ability to cast. Show remaining time inside the casting box; pause and level-up freeze consumption/refill.
- Restore normal speed and close typing on death or victory. Keep capacity/refill configurable for later duration upgrades.
- Preserve the pre-input time scale when measuring a transition frame; a 15 FPS integration check measured 2.999 seconds. The old calculation failed the same check at 2.733 seconds.
- Correct help text for the 20-minute win and spell names; exclude local build fixtures from exports.
- Validation: 20 budget, 6 timed integration, 30 layout, 615 acquisition, 36 synergy, and 24 ending assertions. Duration upgrades and revisiting Quick Cast remain future balance work.

## 2026-09-26 — Contained UI text

- Wrap upgrade titles/descriptions inside padded, content-sized cards; scroll long offers while keeping reroll, banish, and lock controls visible.
- Remove duplicate hover descriptions and hover scaling that could clip card edges.
- Wrap casting text, grow its box up to a bounded height, and scroll longer input without truncating it.
- Render How to Play formatting tags correctly.
- Validation: 29 layout assertions (including a known-bad unwrapped control), 615 acquisition assertions, clean Godot import, desktop/narrow three-card fixtures, scroll then select, long casting error, and help scroll/back. Full visual redesign and narrow-window text scaling remain future work.

## 2026-09-25 — Forgiving opening and regeneration

- Lower early XP thresholds to 25, 40, 55, then +15 per level.
- Set opening Goblin/Rat/Hobgoblin base HP to 20/12/25. Rat archetype health is 60% of base. The preserved local playtest previously used 80/60/80.
- Keep tier 1 for the first three minutes; introduce later tiers every two minutes. Keep two-second spawning during the opening and gently increase pressure afterward.
- Use configured base stat scaling rather than the hidden +30% multiplier. Delay additional health/speed growth until after the opening.
- Remove ordinary-letter difficulty, invincibility, and XP cheats; retain console commands.
- Dispatch regeneration for both numbered and freeform casting, clamp healing to remaining duration, and avoid competing HUD tweens.
- Initialize health and XP labels from actual player properties; show the active spawner's tier and interval.
- Preserve every upgrade choice when one XP reward earns multiple levels. Finish closing each modal before opening the next and reject duplicate selections.

Validation: 37 focused Godot assertions passed on the isolated candidate containing the pre-existing local work plus this patch. Known-bad controls failed for wrong XP, premature tiers, and broken regeneration in both casting paths. A visible run reached level 2 at 00:29 and level 3 at 00:39; regeneration cast successfully and health recovered from 75 to 88 between observations. These times are game time and one short run, not a statistical balance qualification.

Integration remains blocked: committed baseline 5735e53 contains a dangling `else` in Player.gd and incomplete SpellManager.gd definitions. Local unfinished work repairs those paths but is not included in this patch. The validation candidate is not the standalone PR revision. Existing enemy-data JSON, console VBox, missing enemy Visual node and collision-callback errors remain open. This is not a full release or UX pass.

Next: integrate the separately owned unfinished baseline, validate the combined revision, then add level-up spell acquisition and the first three spell combinations before art direction. Continue tuning late-run balance after the forgiving opening is playtested.


## 2026-09-25 — Runnable integration baseline

Preserved the existing unfinished work in its own prerequisite commit, then integrated the balance patch. Repaired the enemy catalog structure, invalid console node, enemy hit flash, duplicate death/XP collection, deferred collision cleanup, and pooled-object cleanup. Added the referenced source sprites and bundled license/readme so scene loads do not depend on an ignored local asset pack. Original working files remain unchanged.

The integrated source passes all 37 balance assertions and imports without script errors. Ordinary combat smoke testing no longer reports invalid data, missing Visual nodes, or physics-callback mutations. Forced engine termination with an active scene still reports resource leaks; normal scene teardown in the regression harness exits cleanly. Publication qualification remains pending.

## 2026-09-25 — Timed enemy archetypes

- Added four families with three behavior variants each, including the agreed Grunt Skirmisher and Runner Swarmer.
- Added timed introductions, a ten-minute ranged gate, and independently scheduled bosses at 5/10/15/20 minutes.
- Replaced enemy spell sprites with red-square projectiles; added charge, shot and area-attack warnings.
- Kept elemental matchups optional: shields reduce frontal projectiles rather than creating immunities, and positioning/area attacks provide alternatives.
- Unified the visible timer with the encounter manager, removed the disabled legacy spawner, and retained source sprites matching each roster entry.
- Retuned the opening after a poor first playtest: two-hit Pursuers, higher fodder XP and slower initial spawning. Prevented duplicate player deaths from simultaneous attacks.
- Added encounter behavior tests and three seeded opening simulations. Final victory rules remain pending; this is an encounter-system milestone, not a production release.

Validation: 33 balance checks, 3,321 encounter assertions and three seeded opening simulations pass. The simulations reached the first upgrade around seventeen seconds at full health. Exclude test evidence from resource imports. Headless encounter/pacing teardown still reports unfinished Tween/SceneTreeTimer leaks; release lifecycle qualification remains open.

## 2026-09-25 — Encounter shutdown cleanup

- Removed suspended damage-number animation awaits and initialize damage numbers after adding them to the scene.
- Give pooled particles a resettable child timer, so reuse cancels stale cleanup and pausing freezes the effect lifetime.
- Encounter and opening simulations now exit without the previous Tween/SceneTreeTimer leaks. Added reuse, pause and expiry assertions.
- Include the runtime JSON catalogs in the playtest export and exclude test scripts and local overrides.

## 2026-09-26 — Immediate twenty-minute victory

- Win immediately at 20:00; stop the clock, spawning and combat, and show VICTORY with run statistics.
- Keep zero health as a loss and record progression once for either outcome. Ignore late level-up callbacks after a result.
- Keep bosses at 5/10/15 minutes and remove the 20-minute boss, which would coincide with victory.
- Leave the narrative reason for winning to later design work.
- Verify cutoff, no early victory, losses, duplicate results and post-result guards with twenty-four ending assertions.

## 2026-09-26 — Reconciled core design draft

- Added Core Game Design v0.2 and preserved the original agent draft for reference.
- Incorporated immediate twenty-minute victory and agreed encounter/playstyle principles.
- Separated approved direction, current prototype behavior, proposed content and experimental tuning.
- Added typing/input constraints, the upgrade-choice budget, combination alternatives and a focused list of remaining product choices.
- Documentation only; proposals do not change or approve game behavior.

## 2026-09-26 — Learn spells during a run

- Start with manual Bolt and the passive Mana Bolt; learn Regeneration, Ice Blast, Earth Shield, Lightning Arc and Meteor Shower from level-up choices in their existing six numbered slots.
- Offer an eligible learning card while unlearned, unbanished spells remain. Once learned, spells receive rank upgrades instead; ownership and ranks reset each run.
- Share acquired spell state between numbered and freeform casting. Fix ID/name mismatches that prevented upgrades from applying and remove the ordinary Y unlock cheat.
- Repair reroll, banish and lock actions to use eligible, unique, applicable cards; prevent changes while a choice resolves. Remove unimplemented passive effects from the offer pool.
- Describe actual rank benefits and dim unlearned HUD icons. Authored combinations and the wider proposed spell library remain follow-up work.

## Casting playtest follow-up

- Keep the player fully visible during typing.
- Consume cast cancellation before pause handling and remove the duplicate polled Escape handler.
- Live playtest reached 1:28 with full health; movement and normal XP collection remain unverified because the UI controller could not hold movement keys.

## Developer baseline bot

- Added an opt-in scripted player that flees threats, seeks XP, types owned spells and randomly chooses normal level-up buttons.
- Added per-seed isolated launch profiles and JSON/log reports, with explicit death, victory and incomplete outcomes.
- Kept bot tooling outside normal exported builds; accelerated mode is smoke testing only.
- Next: exercise Space casting and authored synergies after those mechanics land, then compare several realtime seeds and human playtests.

## Space casting and first hidden synergy

- Space opens an owned-spell casting box; Enter commits the name, Backspace edits, and Escape cancels. Numbered shortcuts remain available. Typing stops movement.
- Added authored Life Bolt recipe: Bolt + Regeneration makes a learning card eligible. Selection unlocks the spell for the run and records a permanent discovery for the current save slot. Ingredients remain usable.
- Life Bolt fires one green homing projectile using Bolt damage scaling and heals up to 6 HP on actual damage, capped by damage dealt. No healing on misses or defeated enemies; no rank choices for this first synergy.
- Added Spell Collection with hidden undiscovered recipes, persisted requirements/effects/incantations, empty state and Back/Escape navigation.
- Clear profile state before loading another slot, preventing discoveries from leaking into missing/malformed saves. Older saves default to no discoveries.
- Updated the baseline bot to type owned spell names via Space/Enter and report casts per spell.
- Next: more authored recipes, richer behavior upgrades and full-run balance; difficulty numbers remain unchanged.
