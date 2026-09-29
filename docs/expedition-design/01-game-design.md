# Game design: a prepared wizard on an expedition

**Current direction:** working title **Should Have Joined a Party**. Evolve the existing fun game; Earth Shield 0.1.36 is complete; the next playable change is a tutorial introducing meaningful keywords. Typing is the interface for complex magic, not the product identity. Readable ancient inscriptions replace the keycap art direction. See [development order](15-development-order.md).

**Confirmed foundation; concrete loop below is proposed v0.1.**

## The promise

You are a powerful wizard walking into hell alone in pursuit of more spells. You don't know what power waits ahead or whether you'll get out in one piece. You want it anyway. Threats beset you from every side; your magic is devastating, but you may have been reckless enough to meet your match. You move, read threats, make space, and type the spell the moment calls for. A quick Bolt rescues a bad position. A carefully earned Charged Meteor Shower breaks a siege. Every discovered spell or word opens new ways to wield power—and another reason to push deeper instead of getting out alive. The working title captures the predicament: Should Have Joined a Party.


The desired emotional sequence is curiosity → preparation → pressure → a deliberate opening → spectacular release → discovery → anticipation of the next expedition. Typing was chosen to make casting feel like practiced wizardry, not to make a typing game. A wizard coordinates verbal, somatic and other spell components into a precise performance under pressure—closer to playing Dance Dance Revolution than selecting an ability. Typing gives that fantasy a physical expression: learned sequences become muscle memory, but executing the right spell when it matters still takes skill. This is not a spelling test, a words-per-minute race, or a contest to find the longest string on every occasion.


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

1. Read the situation: one large enemy, a horde of fodder or a mixed formation? Do you need focused damage, a concentrated blast, broad coverage, control, a shield, healing or a way out?
2. Choose the available spell that answers that need, then position to use it. Bolt is a quick answer to one or two targets; Fireball handles a clustered group of fodder; Lightning Bolt concentrates damage into a handful of tougher enemies; Meteor Shower answers enemies spread across the map. These are situational roles, not a ladder where longer incantations replace shorter ones.
3. Make an opening if needed through movement, terrain or another spell. Cast immediately when the opportunity already exists; do not force every decision through a setup cast. Choose commitment for the effect the situation needs, not because a longer spell is inherently better.
4. Begin the chosen incantation. A finite fresh slowdown window helps each legitimate cast; it then expires even if typing continues. Commit the expression, turning its preview into a visible projectile, ground warning, summon or personal effect.
5. Move while effects resolve, except during an explicitly Charged rooted release, and reassess. Did the blast clear the fodder but leave a large enemy? Is another attack useful, or do you now need protection, healing or escape? The next cast answers the new situation rather than following a fixed rotation.
6. Collect mana, activate the next prepared spell to expand your available answers and decide whether to push toward another ley line. Judge spells by their value in the situations they serve, not equal damage per cast or incantation length: a reliable Fireball can remain the right choice even after Meteor Shower becomes available.

Long casts gain power from meaningful composition, not a hidden per-character damage multiplier. Otherwise a useless alias becomes a balance exploit. Within comparable roles, longer base spells should offer more coverage, persistence, control or potency. They may still be worse emergency answers than short spells. A long healing spell is judged against survival gained, not projectile DPS.

## Expedition loop

**Prepare your spells in order at your home base → enter an expedition area → fight and collect mana (experience points only; never spent, including on casting) → unlock prepared spells in order as accumulated mana reaches each threshold → complete rituals at magical sites → permanently learn new spells and spell-modifying words → optionally fight the area's boss → return home → revise your spell selection and order.**

Each realm offers four authored objectives in a varied route network. Space around them changes between seeds. There is no mandatory sequence between the four objectives. Completing all four permits a guardian encounter; surviving until 20:00 also extracts the player. Discovery is the primary reward; efficient completion, challenge variants and route experimentation support replay after the library is complete.

The proposed primary loss state is player death, which ends the expedition. The proposed retention policy keeps discovered knowledge immediately; uncompleted objectives and current-run mana reset. This supports experimentation with unfamiliar long spells. It is a recommendation, not a confirmed rule.

## Content scope and first playable slice

The campaign layout is a proposal, not a rebuild sequence. Earth Shield 0.1.36 is complete; next introduce keywords through a playable tutorial using existing spells; preserve other existing content. Then add preparation, ley-line discoveries and connected expeditions. The prior 17-spell replacement slice is superseded by document 15.

The full roster preserves all 16 current learnable spells and seven enabled combinations, and promotes 13 ideas/new identities. See the catalog for all 36. Automatic Mana Bolt is a separate open decision; retain it during the first keyword increment, then compare manual-only play if that experiment is selected. Keep a reproducible comparison build while evolving the current game. Automatic attack removal is not part of the first keyword increment.

No passive stat-slot system, randomized level-up cards, endless mode, monetization, multiplayer, voice casting or new character class is part of this initial design. Ley lines replace the old random-level-up discovery role. Workshop tools remain developer tools. Later scope includes alternate starter weapons, typed menu navigation, numeric spell parameters and additional realms.

## What makes a build different

A player preparing Bolt → Wave → Life → Firewalk → Meteor Shower → Earth Shield has early mobility/control and a late commitment attack. A player preparing Bolt → Life → Seeker → Plague Seed → Focus Ray → Regeneration has persistent pressure, pursuit and sustain but weaker instant coverage. Their keyword vocabulary is shared; the properties exposed by their chosen spells make it behave differently.

These are hypotheses to test, not a guarantee that either loadout is viable. Realm weaknesses provide bounded efficiency differences, never immunity that invalidates an entire thematic build. Terrain, enemy spacing and ritual demands should distinguish choices more than a color-matching damage chart.

## Future-direction commitment

The current development priority is Earth Shield 0.1.36, then a tutorial and meaningful keywords in the existing roguelike; preparation, ley lines and connected expeditions follow. See [feedback tracker](../PLAYER_FEEDBACK.md).

For now, commit to this direction strongly enough to build and test it. That is a working commitment, not a permanent boundary: the design, art direction and asset library may all need to change substantially, and that is fine. Those decisions can wait until the prototype gives us a reason to revisit them. Existing friend-made assets, generated assets and audio are a practical starting point, not a requirement to preserve the current look or a commitment to replace it.


“Complete design” here means specified enough to build a falsifiable prototype: inputs, outputs, numbers, states, content and acceptance criteria. The user reports that the existing game is fun; the proposed additions still require playtesting. The future keyword milestone tests whether composed casts feel worthwhile while preserving existing combat fun. Connected-expedition replay is evaluated when that loop is built.
