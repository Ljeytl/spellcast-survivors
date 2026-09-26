## 2026-09-26 — Optional evolution tradeoffs

- Keep basic spells useful beside their evolutions. Life Bolt retains equal damage per bolt but gives up ranked Bolt's extra projectiles for healing. Meteor Lance and Prism Ray deal 40% less direct/per-target damage in exchange for crowd coverage; Soul Bloom and Reaping Spirit deal 25% less damage for sustain or kill bursts.
- Steam Field slows enemies but lasts three seconds instead of five. Frost Sigil has a larger slowing burst but arms in 1.4 seconds instead of 0.8; its visual arming progress uses the same delay as damage logic.
- Show both gains and costs before replacement and in discovered collection entries. Damage penalties scale once with retained rank and player bonuses; rank cards identify the evolved base damage.
- Prevent ordinary offers, rerolls, and banishes from forcing three evolutions: preserve a non-evolution choice, preferring an offered recipe's primary rank. Preserve explicit locks and banishes; all three explicitly locked evolutions remain the player's choice.
- Compare basic/evolved damage, healing, crowd coverage, duration, and preparation at equal investment. Preserve basic damage, encounters, spell ownership, catalysts, and run rules. Next: compare ordinary base-heavy and evolved builds before further tuning.

## 2026-09-26 — Tactical spell variety

- Expand the manual catalog from ten to fifteen base spells with Focus Ray, Rune Trap, Seeking Spirit, Ember Trail, and Returning Blade. Their roles reward tracking, preparation, pursuit, movement, and positioning without elemental immunities.
- Add three authored hidden evolutions: Prism Ray, Frost Sigil, and Reaping Spirit. Existing ingredient ownership, primary replacement, retained ranks/catalysts, persistent discovery, and five-slot limits apply.
- Bound effect lifetimes, moving-target tracking, per-leg blade hits, trail spacing, and simultaneous casts. Primary/evolution variants share their family cap; Focus/Prism permits one beam. Show beam endpoints and trap arming truthfully.
- Cover actual owned typing, rank damage, enemy/caster cleanup, pause, ordinary seeded offers, and evolution caps. Seeded strategic offer simulations record failed full-kit attempts as well as successful acquisition; they do not establish natural discovery rates.
- Keep run length, encounter difficulty, offer odds, shared slowdown, and existing spell balance unchanged. Next: ordinary build playtests, discovery-frequency evaluation, and crowded-combat readability before full art direction.

## 2026-09-26 — Gameplay interaction pass

- Preserve incomplete or mistyped numbered incantations on Enter; Escape cancels. Ignore held activation/letter repeats while preserving repeated Backspace editing.
- Let owned spell cards start the same guarded typing flow as number keys; empty cards explain acquisition. Add compact movement, automatic attack, and casting guidance plus a nonmodal acknowledgement after an applied upgrade.
- Focus the first level-up choice and provide deterministic arrows/Tab navigation. Ignore held accept-key repeats across new offers. Right-click consistently locks/unlocks; banishing remains an explicit action.
- Record actual health and bonus-health loss with contact, projectile, area-blast, or unknown source context. Defeat results explain the final hit without attributing aggregate contact to a single enemy.
- Guard the first 350 ms of results from keyboard acceptance and ignore repeated accept keys; deliberate mouse actions remain immediate.
- Add operated-input regressions and known-bad controls. Run length, bosses, difficulty, spell ownership, shared slowdown, camera, and visual direction remain unchanged.

## 2026-09-26 — Gameplay readability pass

- Give gameplay HUD and menus readable window-relative sizing without changing the world camera or combat scale. Use slate panels, parchment text, cyan casting feedback, gold choices, and coral danger.
- Show five spell slots with full names, ranks, selected state, and empty-slot guidance; separate automatic Mana Bolt and always-visible slowdown availability/recharge.
- Keep the incantation prompt above the player, report typing mistakes and owned-name matches, and retain bounded scrolling for long input.
- Label choices as new spells, spell upgrades, passive upgrades, or evolutions; preserve functional descriptions and replacement details.
- Darken the floor and outline enemies; retain conspicuous square hostile projectiles and outlined area warnings without altering their collision, damage, or timing.
- Show final spell kit, survival time, and discoveries made during the current run in scrollable results. Guard result actions against repeated activation.
- Keep pause options interactive in the UI layer and return Escape to the paused menu. Apply the same readable sizing to menu, help, options, and collection.
- Add layout/state regressions with known-bad controls; desktop/narrow operated verification is recorded with the candidate evidence. Full art direction, additional spell effects, and balance changes remain later work.

# Changelog

## 2026-09-26 — Limited typing slowdown

- Give each run a shared three-second typing slowdown budget, refilling fully over ten seconds outside typing. Casting, cancelling, or reopening does not reset it.
- At exhaustion, restore normal world speed while preserving input and the ability to cast. Show remaining time inside the casting box; pause and level-up freeze consumption/refill.
- Restore normal speed and close typing on death or victory. Keep capacity/refill configurable for later duration upgrades.
- Preserve the pre-input time scale when measuring a transition frame; a 15 FPS integration check measured 2.999 seconds. The old calculation failed the same check at 2.733 seconds.
- Correct help text for the 20-minute win and spell names; exclude local build fixtures from exports.
- Stop bot audio before shutdown and detect ANSI-colored engine errors in its report gate; an accelerated smoke run exposed both gaps. Use real-time bot runs for casting cadence because fast mode also compresses cooldown time.
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

## September 26, 2026 — Spell builds and authored evolutions

- Ten base spells compete for five manual slots; automatic Mana Bolt stays separate. Slot keys and HUD names follow actual acquisition order.
- Added piercing Ember Lance, spreading Plague Seed, persistent Cinder Field and close-range Arcane Orbit, each with working rank scaling.
- Added Meteor Lance, Soul Bloom and Steam Field; Life Bolt now evolves Bolt in place. Every evolution retains its primary slot and rank, preserves its catalyst, and remains upgradeable.
- Full kits still receive eligible evolutions, rank upgrades and passives. Consumed primaries cannot be cast or relearned; invalid evolution requests leave ownership intact.
- Bound infection spreading and persistent effect counts/lifetimes; healing uses actual enemy health lost. Collection records only selected discoveries.
- Casting cooldown uses active unscaled run time, keeping accelerated bot tests consistent with ordinary play. Difficulty and art remain unchanged.
- Next: compare complete runs and spell choices across human play and multiple bot seeds before changing balance.

- Reserved HUD space for wrapped spell names above ranks, and made the developer unlock command fill only available slots with truthful output.
- Delayed mana, spread-bolt and chain callbacks now resolve weak target references and disconnect safely when their run ends; freed targets cancel pending hits.
- Verified delayed-target cleanup with 7 targeted assertions, 182 spell-build assertions and 611 acquisition assertions. Diagnostic accelerated seed 11 ended in death at 452.2 seconds with 100 successful casts and no runtime errors; broader final-revision runs remain the next validation step.
- Balance regression now waits for bounded observable level-up transitions instead of fixed timer delays, preserving the queued-choice and duplicate-input assertions under headless scheduling.
