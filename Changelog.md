## 2026-09-26 — Integrated casting and compact-window verification

- Integrate owned bonus spells, per-cast slowdown, simple effects and provisional encounter pressure. Correct bonus hints and hide unavailable discoveries.
- Keep enlarged typing keys fully visible in short windows; use the lower casting area and temporarily hide the spell bar while the prompt is visible. Preserve health, timer and player visibility.
- Update UI regression expectations for additive bonuses and per-cast windows; include Regeneration in healing metadata.

## 2026-09-26 — Readable keys and ordinary run spellbook

- Enlarge typed keys and stone menu headings, preserving original artwork and wrapping. Add a pause spellbook with owned active/bonus casting, passive ranks and discovered recipes; keep technical diagnostics separate.
- Replace shared-meter debug copy with per-cast duration language. Verify menus and spellbook flows at desktop and narrow sizes after foundation integration.
## 2026-09-26 — Forest groves and clearer XP crystals

- Replace evenly scattered single trees with deterministic groves of varied sizes, occasional isolated trees, empty stretches, and clustered decorative bushes using the existing art.
- Preserve the starting clearing and broad connected routes between groves. Halve physical trunk radius from 22 to 11 pixels without shrinking canopies, anchor both tree variants on their visible lower trunk, keep bushes nonblocking, and scenery, collision, enemy/chest spawn clearance consistent when cells stream out and return. Spawn clearance checks square enemy footprints so boss corners stay outside trunks.
- Enlarge mana-crystal visuals and their pulse by 1.5× without changing XP values, magnet range, collection shapes, or movement.
- Future: evaluate grove density and canopy fading during crowded human playtests before adding new terrain types or obstacles.
## 2026-09-27 — Casting and acquisition foundations

- Give each cast a fresh finite real-time slowdown window; remove idle refill dependency and add the Focus duration passive at fixed slowdown strength.
- Support six primary spells and six passive families. Passive ranks stay in their family slot; Mana Mastery bundles automatic Mana Bolt rank and attack rate. Only passives with working effects enter the offer pool.
- Learn authored bonus spells separately at rank 1 while preserving both ingredients and their ranks. Add unified owned-spell lookup/library APIs, reject unowned casts, and keep discovery memory separate from run ownership.
- Separate quick Life from Regeneration and Bolt from Lightning. Reserve Lightning Bolt's bouncing-projectile contract and Life Bolt's collectable healing-seed contract for the effects integration; defer Reaping Spirit acquisition.
- Future: integrate the effects contracts and player spellbook, audit remaining passive families, and validate the combined candidate before delivery.
## 2026-09-26 — Simple spell behavior and feedback

- Give Plague Seed bounded visible plant transfers, Cross Blade an outbound/linger/return path, persistent armed traps, and projectile-speed snapshots for lances, hunters and blades.
- Add capped Lightning Bolt ricochets and collectible Life Bolt healing seeds; actual pickup requests six healing over two seconds, with full-health preservation and ten-second expiry.
- Replace oversized projectile circles and animated texture trails with small outlined pixel shapes. Keep functional shield/charge/hazard indicators; hide decorative enemy-family circles outside debug. Bound impact feedback and camera shake.
- Validate focused effect mechanics, legacy magic behaviors, encounter timing and delayed-target teardown in an isolated profile. Integrated ownership/UI validation and final player-healing hooks remain with the combined build.

## 2026-09-26 — Simple combat feedback foundation

- Add bounded pixel-shaped spell, healing, pickup and impact helpers, with directional cone/link feedback and readable hazard telegraphs. Preserve supplied art and pause behavior; no shader or audio additions.

## 2026-09-26 — Implementation authorized

- Begin the approved staged repair of the existing roster, casting/progression, simple matching art, UX/world and integrated balance. Preserve unselected ideas and defer shader/audio polish.

## 2026-09-26 — Simple art matched to supplied assets (documentation only)

- Record the user's direction to follow the friend's supplied art style closely, reuse existing assets and keep additions simple placeholders.
- Limit art work to the repaired current roster and selected additions. Treat effect lifecycles as readability requirements, not demands for elaborate bespoke animation. Shaders and audio remain deferred.

## 2026-09-26 — Table coverage audit (documentation only)

- Move remaining modifier phrases and broader saved concepts into explicit status/source tables in the [spell library](docs/SPELL_LIBRARY.md); preserve the full discussion notes as supporting detail.
- Record alternate-name references and unnamed Whip variants without counting them as implemented spells. Correct the historical notes' stale equipped-slot reference to the superseding six-slot rule.

## 2026-09-26 — Spell direction accepted (documentation only)

- Record user acceptance of the spell direction and endorsement of circular Frost Nova alongside cone-shaped Ice Blast. Keep concept endorsement separate from playable status, expansion selection and implementation authorization.

## 2026-09-26 — Defer shaders (documentation only)

- Record shader work as a later roadmap item, explicitly outside the current design and implementation scope. No runtime or asset changes.

## 2026-09-26 — Spell geometry contracts (documentation only)

- Correct Ice Blast to the user-confirmed directional cone and retain radial Frost Nova as a distinct idea.
- Add geometry and targeting to the full library, plus detailed origin, dimensions, timing, collision and upgrade requirements for current spell families.
- Require ordinary VFX to communicate the real affected shape; reserve exact hitbox overlays for opt-in debug. Keep unapproved shape and aim choices explicitly proposed.

## 2026-09-26 — Preserve the baseline and separate debug from play (documentation only)

- Keep and repair the implemented roster; select library expansions separately instead of silently replacing existing spells.
- Define normal play, ordinary spellbook and opt-in debug as distinct information surfaces. Keep technical overlays and test controls out of normal runs.
- Record Earth Wall/Earth Walls separately from Earth Shield, retain Thunderwave as a user concept, and leave protective versus terrain behavior explicit for design selection.

## 2026-09-26 — Complete spell library and naming feedback (documentation only)

- Add the [full spell library](docs/SPELL_LIBRARY.md) with individual status, source, letter count, fantasy and visual identity rows. Preserve user concepts, inactive drafts and name alternatives; add clearly labelled water, sun, earth and arcane suggestions. Rows are not a promised playable spell count.
- Separate quick Life (about 4 HP) from stronger Regeneration, specify straight non-homing Bolt, document Seeker versus stronger Seeking Spirit, recommend Firewalk as a working trail name, and revise Earth Shield toward damageable terrain which decays.
- Reopen affected recipes explicitly rather than silently mapping Life Bolt or Reaping Spirit to new ingredients. Keep implementation, generated art and merges paused for design review.

## 2026-09-26 — Playtest design package (documentation only)

- Consolidate playtest feedback into [core design v0.4](docs/CORE_GAME_DESIGN.md), the [spell/passive catalog](docs/SPELL_AND_UPGRADE_CATALOG.md), [art and feedback matrix](docs/ART_AND_FEEDBACK_PLAN.md), and [agent delivery plan](docs/PLAYTEST_REWORK_PLAN.md).
- Record six active/six passive slots, additional slot-free combinations, distinct Bolt/Lightning/Lightning Bolt, per-cast slowdown, useful long-incantation payoff, readable effects and revised opening pressure. These are intended rules, not completed runtime changes.
- Preserve frozen implementation branches and distinguish canonical build, remote UI changes and candidate evidence. Resume implementation only after design approval.
- Keep Moonfall, Tree of Life, Grasping Hand, modifier words, alternate starters, map challenges, typed menus and audio separately scoped or deferred; do not silently add them to this pass.

## 2026-09-26 — Minimal player interface and retained diagnostics

- Hide tier labels, advance boss schedules, passive/rank/refill telemetry, permanent control paragraphs and empty spell slots during normal play. Show active boss health only after arrival; retain health, XP/level, clock, equipped spells and casting feedback.
- Level-up cards show stone-letter names and one authored sentence; percentages come from the actual upgrade value, damage ranks show the actual added damage, and evolutions state the replacement and essential cost. Retain selection, reroll, banish and lock behavior.
- Shorten help, collection entries and run endings; use compact HUD and ending panels. Keep full original card descriptions, encounter schedules, recipe rules and run summaries accessible through F3 / `ui_debug`, plus the `ui_details` console report.
- Future: human-test the reduced text density and discoverability; typing-based menu navigation remains deferred.

## 2026-09-26 — Stone-letter menus

- Reuse the generated stone letters for menu actions and headings, upgrade names, and discovered recipe titles across the main menu, settings, instructions, pause, collection, level-up, and run-end screens. Keep descriptions in readable body text.
- Add a reusable bitmap font with printable ASCII coverage, wrapping, hover/focus/disabled states, and responsive upgrade-card spacing. Preserve click and keyboard controls.
- Future: typing to activate menu choices remains deferred; tune visual density through human playtests.

## 2026-09-26 — Mana-crystal XP pickups

- Replace yellow square XP drops with a transparent cyan mana-crystal sprite, a dark outline and pale facet highlights for contrast against grass. Preserve the existing pulse, magnet movement, collection radius, sound, and XP values.
- Keep the source artwork outside runtime imports and export a compact 24×24 texture with nearest-neighbor sampling.
- Future: consider distinct crystal clusters for larger XP drops once value tiers are designed.

## 2026-09-26 — Stone typing keys and orbiting staff

- Add matching 32×32 stone keys for A–Z, digits, and all standard keyboard punctuation. Typed combat letters drop into place with a soft impact; backspace breaks the removed key into fading fragments with a crumble sound. Long incantations wrap and scroll; successful casts briefly retain their completed word.
- Add the supplied floating staff around the wizard, smoothly orbiting toward the nearest visible living enemy and prioritizing visible bosses. Preserve existing attacks, spell ownership, input acceptance, and menu controls.
- Keep the high-resolution source atlases out of runtime exports and provide a repeatable native-size export tool. Retain symbol assets for future incantations that use them.
- Future: tune sound and impact feel in human playtests; keep layered character animation and typing-based menu navigation on the roadmap.

## 2026-09-26 — Save friend-proposed ritual and boss concepts

- Document map unlock locations, timed long-word rituals and leylines, possible XP risk, the mouse final boss, skill-versus-speed lore, and a keyboard-sized spell-catalog Easter egg. Preserve attribution, example words, and open decisions; no mechanics or run rules change.

## 2026-09-26 — Defer typing-based menu navigation

- Add typing to navigate menus and select upgrades/spells to the later roadmap. Preserve current controls; keep this separate from keycap visuals while typing combat spells. No gameplay changes.

## 2026-09-26 — Authored keycaps and remaining art

- Use the supplied worn keycap art for menu/action buttons and blank keys behind numbered spell shortcuts, with readable ink and distinct hover, pressed, disabled, and keyboard-focus states. Keep long upgrade descriptions on high-contrast panels.
- Add supplied grass and resting flower-slime art to the main menu. Use both tree drawings and both king-slime designs in the arena. Preserve existing control behavior and readable body typography.

## 2026-09-26 — Typecast art and forest arena

- Integrate the supplied assembled wizard, nine slime variants, king-slime bosses, ranged wisps, nine grass tiles, trees, bushes, keyboard logo, and health-bar art with nearest-neighbor sampling.
- Add sparse deterministic trunk obstacles, an open starting clearing, bounded scenery streaming, enemy steering, and spawn clearance. Trees block movement while spells continue through foliage; nearby canopies fade to preserve player visibility.
- Preserve the separate wizard components and alternate exported designs under assets/typecast for future animation. Keep unsupplied spell effects as placeholders and retain combat stats, encounter timing, and hitbox sizes.
- Record future layered wizard animation and obstacle-aware bot improvements in the roadmap.

## 2026-09-26 — Casting decisions and branch reconciliation

- Confirm the existing survivors premise, long-incantation power fantasy, and fixed-strength per-cast slowdown with upgradeable duration. Record that the shipped shared budget/refill still needs replacement.
- Document thirteen supporting upgrade categories, bundled Mana Bolt mastery, enemy population as risk/reward growth, and spell-appropriate Multicast instead of a projectile-only stat. Preserve open Mana Bolt interactions and secondary-slot rules.
- Refresh stale core-design descriptions of movement, incorrect input, passive slots, and the repaired attack-rate stat. Mark prior pivot discussions and roadmap milestones as historical.
- Reconcile the original opening-balance branch only after auditing its already-reapplied changes against the recovered and subsequently tested mainline; retain current gameplay behavior.

## 2026-09-26 — Creator pitch and alchemist concept

- Expand the [casting fantasy notes](docs/CASTING_FANTASY_NOTES.md) with the creator’s full explanation: frantic typed spells, siege/PvZ-like alternatives, the desired swing from panic to crowd-erasing power, and an alchemist defending a tower with about ten ingredients and four-to-five-ingredient potions. Preserve open questions about input, recipes, preparation and resources; no gameplay changes or approved pivot.

## 2026-09-26 — Casting fantasy discussion preserved

- Record the creator’s movement-versus-casting panic, possible defense pivots, language composition ideas, and proposed playtest questions in [casting fantasy notes](docs/CASTING_FANTASY_NOTES.md). Distinguish user priorities, assistant suggestions, current mechanics, and unresolved decisions; no gameplay changes or pivot approval.

## 2026-09-26 — Playtest-driven balance corrections

- Rename Quick Cast to Mana Tempo and describe its actual +10% automatic Mana Bolt attack-rate benefit. Preserve the internal upgrade key and existing attack cadence while keeping typing slowdown at 20% world speed regardless of attack-rate upgrades.
- Ignore dying, zero-health, queued-for-removal, and freed enemies when computing contact damage and its attacker count. Live enemies still deal their normal damage.
- Extend ordinary bot reports with contact/projectile/blast damage, damage while typing, recent hits, boss arrivals/defeats/surviving health, and uncollected XP. Validate contradictory damage reports rather than infer balance from survival time alone.
- Add real-time typed-cast and physical-contact regressions with baseline failure evidence. Preserve the three-second typing budget, ten-second recharge, encounter curve, spell damage, and twenty-minute ending.
- Next experiments: distinguish boss target access from boss durability, and XP left behind from insufficient XP rewards before changing middle-run pressure. Small random bot batches do not establish human difficulty or final balance.

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

- Follow-up: Ice Blast now uses a forward 90-degree cone with matching damage/control bounds; Lightning is one direct strike. Personal stone protection follows the player through the effects API; heal/hurt visuals respond to actual health changes.

- Integrated healing seeds and bouncing-projectile effect contracts for regression validation. Migrated old replacement/shared-reserve tests to additive bonuses and fresh per-cast timing; coalesce healing feedback to one burst per 150 ms while preserving all health restoration.
## September 26, 2026 — Opening pressure and behavioral controls

- Replaced the flat early spawn grace period with opening pressure and recovery windows, then the existing exponential density growth.
- Kept early enemies at two passive hits for grunts and one for runners; introduced runners after twelve seconds, below player speed. Health, contact damage, ranged gates, boss times and immediate twenty-minute victory remain unchanged.
- Added isolated bot modes for idle, movement only, stationary casting and active play, with first-damage telemetry and checks against mode contamination.
- Added deterministic checks for the pressure/recovery transitions. Full behavioral evidence and remaining balance limitations accompany this change.

### Opening pressure timer follow-up

- Spawn phase boundaries restart the running timer with the new interval, so pressure/recovery changes no longer wait for the previous deadline. Stopped timers remain stopped.
- Unsorted phase rows use the latest valid start; invalid/nonpositive rows are ignored and missing configuration retains safe baseline defaults. Pressure values remain provisional.
- Bot reports must match the requested behavior mode.
- Verified 7 real-timer assertions, 44 balance assertions and 8 Python report tests. Removing the boundary update makes four timer assertions fail.

- Migrated seeded magic, acquisition and typing-presentation fixtures to six active slots, separate Life/Regeneration, additive bonus spells and distinct Bolt identities. Preserve real input, reroll/banish, effect-cap and deferred-recipe coverage.
