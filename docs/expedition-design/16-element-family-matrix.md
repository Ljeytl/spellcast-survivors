# Element × spell-family working matrix

Updated 29 September 2026 after 0.1.36. **Bold = implemented. [U] = user concept, not implemented. [U?] = alternatives, name or classification unresolved. [TBD] = requested exploration without an invented spell.** — means no selected entry, not a missing implementation task.

This matrix is brainstorming, not a new shipping roster. Current code still has **16 learnable bases and seven combinations**. Themes do not assert damage types: current combat uses numeric damage, and the school mergers below are design decisions, not runtime damage-system changes. See the [detailed design pass](17-element-spell-ideas.md) for every behavior, alternative, rejection and provenance. Families guide identities; names do not dictate geometry.

## Projectiles and directed attacks

Multiple spells may occupy any cell. Slice/Whip is one family; differences in shape, reach and motion belong to each spell.

| School | Bolt | Ball | Lance | Ray | Slice / Whip | Blast |
|---|---|---|---|---|---|---|
| Arcane / Mana | **Bolt** — a simple bolt of magical energy | — | — | **Focus Ray** — a sustained tracking beam | Arcane Slash [U] — cut glyphs into an area; they detonate after a delay, with contact behavior open | — |
| Fire | Fire Bolt [U] — a travelling bolt of fire | Fireball [U] — a classic explosive fire projectile | **Ember Lance** — a piercing lance of fire | Scorching Ray [U?] — two or three lingering fire beams, in a triangle or aimed at enemies | — | — |
| Water / Ice | Snowball [U] — a compact ice projectile | — | Ice Lance / Glacial Lance [U?] — push foes aside or impale with a major debuff; Glacial is the stronger variant idea | Water Jet [U] — tracking water stream damages and pushes; upgrades may add jets | Water Whip [U] — lash with water; exact contact behavior open | **Ice Blast** — ice shards fan outward in a cone; Tsunami [U] — a rectangular wave spawns behind you and sweeps forward |
| Lightning | — | — | Lightning Lance / rod [U?] — embeds or lands as a rod calling down strikes; persists after its host dies | Static Shock [U?] — a channeled chain of lightning | Lightning Whip [U] — lash with lightning; exact behavior open | — |
| Earth / Metal | Spike [U; ground delivery] — a ground spike erupts and causes bleeding; Bullet / Spray [U?] — rapid travelling metal shots | Boulder [U; no splash assumed] — a slow heavy rock with high damage and knockback | Earth Lance [U] — shatters on impact into smaller scattering lances | — | **Cross Blade** — a blade lingers before returning; Slash [U] — slash toward the nearest enemy | Earth Blast [U] — a cone of fragments with knockback and bleed; Shrapnel [U?] — a blast of metal fragments; delivery open |
| Plague / Death | **Seeker** (ghost identity retained) — a pursuing ghost that seeks enemies | Unnamed carcass projectile [U?] — hurl infected remains to create a diseased dead zone | Plague Lance [TBD] — fantasy and mechanics undecided | Ray of Sickness [U] — sweep across a crowd spreading damage over time, slow and possibly reduced enemy damage | — | — |
| Life / Nature | — | Unnamed vine ball [U?] — a ball of vines damages and immobilizes an area; bleed is possible | Shillelagh [U] — Life Lance; preserve the vine/root fantasy, with final attack and pulling behavior open | — | Vine Whip [U] — lash with a living vine | — |

Tsunami is a broad square/rectangular front spawning behind the player and travelling forward, with contact as it reaches enemies. It replaces the earlier radial Tsunami description. Shrapnel is in Blast; exact delivery remains open rather than requiring its earlier grenade proposal.

## Areas and placed effects

Nova/Wave is one family. Radial versus directional shape and propagation are properties, not separate columns.

| School | Nova / Wave | Strike | Shower | Field | Wall | Trail | Trap / Sigil |
|---|---|---|---|---|---|---|---|
| Arcane / Mana | Arcane Nova [U] — an expanding burst of powerful magic | — | Mana Storm [U] — a moving cloud rains mana daggers | Eye of [unnamed] [U?] — a large damaging gravity well | Prism Wall [U] — a fragile barrier reflects some attacker damage | — | **Rune Trap** — a visible persistent rune triggers when enemies enter |
| Fire | — | Volcano [U?] — an eruption leaves a lingering sentry-like hazard | **Meteor Shower** — warned impacts rain down and explode; Firestorm [questioned] — distinct identity versus Meteor Shower unresolved | **Cinder Field** — a persistent patch of burning ground | Flame Wall [U] — a passable wall of fire burns crossing enemies | **Firewalk** — leave lasting burning ground behind you | — |
| Water / Ice | Frost Nova [U] — Ice Blast-like cold bursts in all directions | Falling icicle [U?] — an icicle strikes from above | Blizzard [U?] — a moving storm strongly slows or freezes, with lighter damage | Whirlpool [U?] — a lasting vortex; exact pull behavior open | — | — | — |
| Lightning | Thunderwave [U; radial knockback] — a surrounding thunder burst pushes enemies away | **Lightning** — a brief ground circle zaps enemies within it | Rain of Lightning [U] — lightning rains across an area | Static Field [U] — an electrical hazard area; mechanics open | Tesla Wall [U] — solid coils join a passable, highly damaging electrical boundary | — | — |
| Earth / Metal | Earth Nova [U] — radial ground spikes damage and bleed | — | — | — | Earth Wall [U] — raise physical barriers | Muck [U?] — leave strongly slowing ground; later fire interaction possible | Earth Trap [U] — lasting spikes briefly immobilize and bleed enemies |
| Plague / Death | Explore [TBD] | — | Explore [TBD] | Grasping Hand [U] — a spectral hand restrains enemies in an area; more [TBD] | Explore [TBD] | Explore [TBD] | Explore [TBD] |
| Life / Nature | Crushing / expanding vines [U?] — vines spread around you, damaging and rooting or slowing | Poisonous / exploding flowers [U?] — flowers poison or burst; delivery open | Poisonous / exploding flowers [U?] — flowers poison or burst; delivery open | — | — | Flower / vine trail [U?] — leave poisonous flowers or writhing vines | — |

## Protection and persistent magic

| School | Shield | Orbit | Seed | Golem | Restoration |
|---|---|---|---|---|---|
| Arcane / Mana | Prismatic Shield [U] — temporary invulnerability, perhaps reflection; roughly ten seconds proposed | **Arcane Orbit** — orbiting magic strikes nearby enemies | — | — | XP magnet utility [U?] — draw distant XP toward you |
| Fire | Fire Shield [U] — retaliate with a fire blast | Fire Orbit [U] — orbiting fire damages and burns | Flame Seed [U] — grows into a fire turret | Fire Golem [U?] — a fire ally, possibly casting Ember Lance from your kit | Flaming Restoration [U?] — restoration with a fire buff; payoff open |
| Water / Ice | — | — | — | — | — |
| Lightning | — | — | — | — | — |
| Earth / Metal | **Earth Shield** — stack one-hit blocks that erupt toward the attacker | — | — | Earth Golem [U] — summon a stone ally | — |
| Plague / Death | — | — | **Plague Seed** — infection spreads between enemies and lingers after death; **Soul Bloom¹** — spreading infection produces healing blooms | — | — |
| Life / Nature | — | — | — | — | **Life; Regeneration** — quick small heal; stronger sustained healing; Yggdrasil [U] — grow a tree of life that heals and harms nearby enemies |

## Combination-theme ideas

Sun and Moon are combination themes, not separate school rows. These are unimplemented concepts, separate from the enabled recipes below.

| Spell | Family | Fantasy / recipe |
|---|---|---|
| Sunbeam | Ray | A powerful sunbeam; Fire + Life candidate, recipe open |
| Moon Slash / Crescent Slash | Slice / Whip | Multiple purple crescent slashes; ingredients open |
| Moonfall | Field | A moonlit area damages enemies and gently heals you; ingredients open |

## Existing combinations — secondary to the base-spell exploration

| Implemented spell | Ingredients | Current identity / family overlap |
|---|---|---|
| Lightning Bolt | Bolt + Lightning | Bouncing projectile with impact lightning areas |
| Life Bolt | Bolt + Life | Projectile plus healing ground patch |
| Meteor Lance | Ember Lance + Meteor Shower | Piercing lance plus impact explosions |
| Soul Bloom | Plague Seed + Regeneration | Infection and healing ground blooms; also shown in Seed by user request |
| Steam Field | Cinder Field + Ice Blast | Damaging slowing field |
| Prism Ray | Focus Ray + Ember Lance | Broad piercing ray with very slow rotation |
| Frost Sigil | Rune Trap + Ice Blast | Persistent placed trap with freezing-themed burst/slow |

¹ Soul Bloom is shown in the main Seed column deliberately, not reclassified as a planted turret. Ingredients remain available; combinations consume no additional active slot.

For earlier ideas, rejected examples and unresolved details, see the [design notes](17-element-spell-ideas.md).
