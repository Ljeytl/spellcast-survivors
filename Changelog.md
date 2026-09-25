# Changelog

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
