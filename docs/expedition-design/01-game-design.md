# Game design: a prepared wizard on an expedition

**Confirmed foundation; concrete loop below is proposed v0.1.**

## The promise

You enter an unfamiliar magical territory carrying a prepared spellbook. You know a handful of useful spells and a growing vocabulary of modifiers. You move, read threats, make space, and type the spell the moment calls for. A quick Bolt rescues a bad position. A carefully earned Charged Meteor Shower breaks a siege. Discovering a word expands what you can express across many spells rather than adding another passive percentage.

The desired emotional sequence is curiosity → preparation → pressure → a deliberate opening → spectacular release → discovery → anticipation of the next expedition. Typing is the physical performance of magic. This is not a spelling test, a words-per-minute race, or a contest to find the longest string on every occasion.

### Design pillars

| Pillar | Player evidence | Failure signal |
|---|---|---|
| Expressive incantations | Player predicts what Big or Repeating will do on a newly learned spell | Memorizing opaque exceptions or typing decorative words |
| Commitment earns payoff | A long cast changes the immediate fight in an unmistakable way | Longer name, same practical result; busy animation with no damage |
| Preparation matters | Different spell orders create different early routes and recovery plans | One mandatory loadout; late slots never become usable |
| Short magic stays useful | Player intentionally uses Bolt, Life or Wave after learning major spells | Basic spells become strictly obsolete |
| Knowledge persists | An unsuccessful expedition still teaches an actionable new possibility | Repeated grind before experiencing a discovery |
| The world tells the truth | Visible shards, fields and marks explain hits and spread | Invisible cone damage, missing range, healing-looking damage |

## Moment-to-moment loop

1. Read the nearby formation and choose a safe heading.
2. Use movement, a short cast or existing terrain to make an opening.
3. Begin an incantation. A finite fresh slowdown window helps each legitimate cast; it then expires even if typing continues.
4. Commit the expression. The preview becomes its visible projectile, ground warning, summon or personal effect.
5. Move while effects resolve, except during an explicitly Charged rooted release.
6. Collect mana, activate the next prepared spell and decide whether to push toward another ley line.

Long casts gain power from meaningful composition, not a hidden per-character damage multiplier. Otherwise a useless alias becomes a balance exploit. Within comparable roles, longer base spells should offer more coverage, persistence, control or potency. They may still be worse emergency answers than short spells. A long healing spell is judged against survival gained, not projectile DPS.

## Expedition loop

**Sanctum → prepare ordered spellbook → enter realm → fight and collect mana → activate prepared pages → complete ley-line rituals → discover permanent knowledge → optional guardian → extract → revise spellbook.**

Each realm offers four authored objectives in a varied route network. Space around them changes between seeds. There is no mandatory sequence between the four objectives. Completing all four permits a guardian encounter; surviving until 20:00 also extracts the player. Discovery is the primary reward; efficient completion, challenge variants and route experimentation support replay after the library is complete.

The proposed primary loss state is player death, which ends the expedition. The proposed retention policy keeps discovered knowledge immediately; uncompleted objectives and current-run mana reset. This supports experimentation with unfamiliar long spells. It is a recommendation, not a confirmed rule.

## Content scope and first playable slice

The full proposed campaign has a tutorial and four realms. Build only the tutorial and one representative realm first. Initial slice: the complete tutorial and Verdant Ruins reward set (11 bases and five derived spells), plus Meteor Shower in a clearly labeled developer test profile: 17 spell identities total. Its eight words are Big, Powerful, Seeking, Lasting, Repulsing, Repeating, Delayed and Charged. The last three words and Meteor Shower are temporary test-profile grants, not changes to campaign acquisition. Ordinary progression tests use the real tutorial/realm rewards; the composition lab tests these later abilities separately. This covers projectile, self-heal, contact fan, area, chaining, persistent field, autonomous summon and rooted delayed artillery.

The full roster preserves all 16 current learnable spells and seven enabled combinations, and promotes 13 ideas/new identities. See the catalog for all 36. The retained automatic Mana Bolt is a separate open decision; the proposal disables it for this new mode to test whether manually creating openings delivers the intended fantasy. The legacy prototype remains a comparison build.

No passive stat-slot system, randomized level-up cards, endless mode, monetization, multiplayer, voice casting or new character class is part of this initial design. Ley lines replace the old random-level-up discovery role. Workshop tools remain developer tools. Later scope includes alternate starter weapons, typed menu navigation, numeric spell parameters and additional realms.

## What makes a build different

A player preparing Bolt → Wave → Life → Firewalk → Meteor Shower → Earth Shield has early mobility/control and a late commitment attack. A player preparing Bolt → Life → Seeker → Plague Seed → Focus Ray → Regeneration has persistent pressure, pursuit and sustain but weaker instant coverage. Their keyword vocabulary is shared; the properties exposed by their chosen spells make it behave differently.

These are hypotheses to test, not a guarantee that either loadout is viable. Realm weaknesses provide bounded efficiency differences, never immunity that invalidates an entire thematic build. Terrain, enemy spacing and ritual demands should distinguish choices more than a color-matching damage chart.

## Product boundaries

The new direction does not require throwing away friend-made assets. It requires checking their readability and tone against the new fantasy. A cohesive simple treatment is preferable to more expensive inconsistent detail. Generated assets and existing audio can remain for testing and early promotion; replacement is a later provenance/budget decision. Do not generate a new art library as a side effect of approving this document.

“Complete design” here means specified enough to build a falsifiable prototype: inputs, outputs, numbers, states, content and acceptance criteria. It cannot mean fun has already been proven. The first milestone must test whether players intentionally compose magic under pressure and want another expedition.
