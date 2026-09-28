# SpellCast Survivors — Core Game Design v0.4

> Current direction: **Should Have Joined a Party**, a wizard action game using language to express complex magic. Evolve the existing playable game through keywords, preparation and persistent discoveries. Readable inscriptions replace keycap branding. See the [current design and development roadmap](expedition-design/README.md). Older prototype descriptions, plans and marketing language below are historical, not the current target specification.

Status: implementation authorized September 26, 2026 following user approval of the reconciled plan. The existing roster, confirmed mechanics and simple matching placeholder-art pass are in scope; unresolved concepts are not automatically selected.

This document supersedes earlier conflicting decisions about five spell slots, replacement evolutions, a shared slowdown reserve and an opening that allows indefinite inactivity. Historical documents and changelog entries describe their own revisions, not the current intended rules.

## Core fantasy

Move through a horde, choose a spell, stop to type it under pressure, release a worthwhile effect, and reposition. Completing a longer incantation must earn substantially more useful power per cast and a visibly satisfying outcome. Short spells remain useful because they resolve sooner, waste less output and return control sooner. Every spell needs a distinct fantasy, targeting rule and readable result.

Keep roaming survivors combat. Tower defense, siege management and alchemy are saved alternatives, not a pivot. Elements primarily establish theme; ordinary enemies must not make an entire chosen magic school useless. Strategic advantages come from geometry, timing, persistence, control and sustain rather than compulsory elemental counters.

## Baseline and future selection

Keep the spells already implemented and repair their identities, useful output, acquisition, feedback and readability. Do not remove an existing spell merely because the idea library now offers alternatives. New spells and stronger variants are selected deliberately after reviewing that baseline; a library entry, proposed rename or historical draft does not authorize adding or replacing content.

## Agreed rules

| System | Intended rule |
|---|---|
| Run | Start at 0:00; win immediately at 20:00; lose at zero health before then. Narrative explanation can wait. |
| Encounters | Time advances tiers regardless of surviving bosses. Bosses at 5:00, 10:00 and 15:00. Do not forecast their schedule in the ordinary HUD. |
| Enemy families | Grunts, Runners, Brutes and Shooters, with multiple variants. Skirmisher is a Grunt; Swarmer is a Runner. |
| Opening | Active movement and casting should matter immediately. Latest target: inactivity should become lethal in roughly 30–45 seconds. Preserve fair escape routes and early growth. The strict moving-without-casting target needs separate tuning discussion. |
| Early durability | Ordinary fodder takes roughly 2–3 starting automatic Mana Bolt hits. Fragile runners take one, moving roughly 2–3 times as fast as ordinary melee. |
| Ranged enemies | Introduce around 10–12 minutes; use readable hostile projectiles. |
| Active slots | Six learned active spells. Start with manual Bolt in slot 1; other active slots are empty. No starting Lightning. |
| Passive slots | Six distinct passive families. Further ranks occupy the existing family slot. Map-found overflow is deferred. |
| Bonus spells | All authored combinations unlock additional spells, retain both ingredients and consume no active slot. They are never replacements. |
| Ownership | Only spells owned in the current run can be cast. Discovering a recipe in an earlier run does not grant its spell in a new run. |
| Lightning identities | Bolt = straight non-homing projectile. Lightning = direct strike. Lightning Bolt = bouncing projectile from Bolt + Lightning. |
| Slowdown | Each new cast gets a fresh finite window at fixed slowdown strength. Duration upgrades extend that window. Expiry returns the world to normal while typing may continue. No shared reserve or meaningful recharge wait. |
| Spell geometry | Ice Blast is a directional cone. Specify hit shape, origin, aim, dimensions and hit rules per spell; visuals must match the affected region. Other undecided shapes remain proposals. |
| Healing identities | Life is a separate quick small heal (about 4 HP); Regeneration takes longer to type and gives substantially greater healing over time. |
| Earth Shield concept | Preserve Earth Shield as an existing spell to repair. Damageable, decaying earth protection is a concept; distinguish caster protection from separately placed Earth Wall terrain before deciding geometry and collision. |
| Spell payoff | Longer incantations earn greater useful output, not merely a larger damage number. Preserve quick basics and situational bonuses. |
| Multicast | One extra spell-appropriate unit of output after one completed incantation: another projectile, meteor, jump, pulse or other explicitly defined unit. No extra typing. |
| Presentation | Existing ancient stone/pixel-world direction. Legible large keycaps, concise choices and minimal HUD. Audio work is deferred. |

Automatic Mana Bolt remains a separate automatic attack. Whether its first mastery upgrade consumes a passive slot is an explicit open decision; recommended yes, while the innate attack itself is free.

## Casting contract

Beginning a cast starts its own finite slowdown duration. Finishing early or cancelling ends that cast's slowdown. Expiry must not clear the text, cancel the spell or prevent continued typing. A later cast starts a fresh window. Duration upgrades change the allowance, never the slowdown strength.

The existing shared meter must not be repurposed into this rule. Retire it from normal casting UI; preserve any diagnostic values separately if useful. A configurable, negligible inter-cast debounce may remain for input handling, but must not become a recharge gate without a new decision.

The design intentionally permits frequent fresh windows. Before implementation, specify real-time versus simulation-time accounting and cancellation behavior consistently. Recommended: real elapsed typing seconds; menu/pause time does not consume them. Test rapid cancel/reopen openly; do not secretly introduce a shared resource to solve it.

Slots, click selection and free typing must all enforce the same current-run ownership. A discovered but unowned combination is visible in the collection as appropriate, but not executable. Details of existing input bindings are implementation facts to preserve or intentionally revise during the UX pass.

## Acquisition and build contract

Learn a new base spell into an available active slot, or upgrade an owned spell in place. Learn a new passive family into an available passive slot, or upgrade its existing rank. When a category is full, stop offering new types from that category; retain valid ranks, eligible bonus spells and the other category's choices.

Both ingredients must be owned in the current run to qualify for their authored combination. Selecting the combination grants a separately castable bonus spell and preserves both ingredients and their ranks. The rule applies globally to the seven legacy recipes and the new Lightning Bolt recipe. Legacy replacement costs require rebalancing in this new context.

Proposed acquisition details: bonus spells start at rank 1, upgrade independently, and appear as eligible level-up choices rather than auto-unlocking. These details require approval. A full build must still yield valid choices; define a simple fallback only after auditing existing reroll, banish and lock behavior.

## Power and visual language

Balance the useful output of a completed cast: actual damage after misses and overkill, relevant targets, space created, useful persistence, healing received or damage prevented. Measure typing exposure, including time spent after slowdown expires. Do not add the same benefit repeatedly as area, target count and total damage.

Long spells should have a clear gathering, release and payoff sequence. Spectacle must correspond to actual hits and preserve hostile telegraphs. A beam must not appear to damage enemies it ignores; infection must visibly travel when it spreads; healing effects must follow actual healing.

Meteor Shower should visibly repay its long commitment through meaningful impacts and crowd clearing. Proposed bounded impact shake is an accent, not the payoff itself. Cross Blade should linger before returning and aim for roughly twice Bolt's useful output in its intended situation. These are starting design targets, not final numeric guarantees.

## Player information

Normal HUD: health, XP/level, elapsed time, owned active shortcuts and casting feedback when relevant. Boss health appears during an actual boss encounter. No permanent control paragraphs, tier labels, future boss timestamps or technical telemetry.

Level-up choices: readable name and one accurate sentence. Show an exact effect, such as “Increase spell damage by 5%,” rather than a range or a paragraph. Preserve essential trade-offs. Keep useful build/spell details in an ordinary pause/spellbook menu; reserve formulas, spawn schedules and diagnostics for debug.

Bonus spells must be easy to find and cast without memorizing hidden names or filling the HUD with icons. Proposed: a bonus section in the spellbook and owned-only suggestions in the casting interface. Typed menu navigation remains deferred.

### Game presentation versus debug tools

| Surface | Intended information and controls |
|---|---|
| Normal game | Minimal HUD, readable combat feedback, concise accurate upgrade choices. No diagnostic controls, technical IDs, collision circles, spawn budgets, hidden timing forecasts or bot status. |
| Ordinary pause / spellbook | Owned spells and bonuses, passive build, understandable mechanics and discovered recipes. Players must not enable debug to understand their tools. |
| Explicit debug mode | Full numerical state, damage/healing and status-event diagnostics, cast/slowdown timing, targets and ranges, colliders, spawn schedules, RNG seeds, bot controls and test scenarios. These are planned diagnostic capabilities, not a claim all exist. |

Debug is explicitly opt-in and visibly identified. Diagnostic overlays must not leak into a fresh normal run. Record any debug commands that change gameplay so the run cannot be mistaken for an ordinary balance sample. Debug visibility must not alter normal combat rules.

## Documents and review boundary

- [Full spell library](SPELL_LIBRARY.md): all named concepts, current counterparts, inactive drafts, alternatives and new suggestions, each with explicit status.
- [Spell and upgrade catalog](SPELL_AND_UPGRADE_CATALOG.md): all current base identities, combinations, passive families and proposals.
- [Art and feedback specification](ART_AND_FEEDBACK_PLAN.md): matching visual lifecycle matrix, non-spell feedback, world and accessibility requirements.
- [Playtest rework plan](PLAYTEST_REWORK_PLAN.md): feedback coverage, agent assignments, dependencies, acceptance gates and unresolved decisions.
- [Casting fantasy notes](CASTING_FANTASY_NOTES.md): preserved future ideas.
- [Encounter design](ENCOUNTER_DESIGN.md) and [baseline bot](BASELINE_BOT.md): historical/current implementation references; new intended decisions here take precedence where they conflict.
- [Archived v0.3](reference/CORE_GAME_DESIGN_V0_3.md): preserves earlier proposals and implementation notes; superseded rules are not current requirements.
- [Original agent draft](reference/CORE_GAME_DESIGN_AGENT_V0_1.md) and [old combination proposal](../combined-spells-design.md): references, not authority over user decisions.

No new spell brainstorm, proposed tuning value or staged art asset becomes approved production scope merely by appearing in these documents.
