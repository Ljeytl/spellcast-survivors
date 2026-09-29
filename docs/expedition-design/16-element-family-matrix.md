# Element × spell-family working matrix

Updated 29 September 2026 after 0.1.36. **Bold = implemented. [U] = user concept, not implemented. [U?] = alternatives, name or classification unresolved. [TBD] = requested exploration without an invented spell.** — means no selected entry, not a missing implementation task.

This matrix is brainstorming, not a new shipping roster. Current code still has **16 learnable bases and seven combinations**. Themes do not assert damage types: current combat uses numeric damage, and school merges remain undecided. See the [detailed design pass](17-element-spell-ideas.md) for every behavior, alternative, rejection and provenance. Families guide identities; names do not dictate geometry.

## Projectiles and directed attacks

| Element / theme | Bolt | Ball | Lance | Ray | Slice | Blast | Wave | Whip |
|---|---|---|---|---|---|---|---|---|
| Arcane / Mana | **Bolt** | — | — | **Focus Ray** | Arcane Slash [U] | — | — | — |
| Fire | Fire Bolt [U] | Fireball [U] | **Ember Lance** | Scorching Ray [U?] | — | — | — | — |
| Ice | Snowball [U] | — | Ice Lance / Glacial Lance [U?] | Frost Ray [U?] | — | **Ice Blast** | — | — |
| Water | — | — | — | Water Jet [U] | — | — | Tsunami; Tidal Push [U] | Water Whip [U] |
| Lightning | — | — | Lightning Lance / rod [U?] | Static Shock [U?] | — | — | Thunderwave [U] | Lightning Whip [U] |
| Earth | Spike [U; ground delivery] | Boulder [U; no splash assumed] | Earth Lance [U] | — | — | Earth Blast [U] | — | — |
| Plague / possible Death | Seeker reclassification [U?] | Unnamed carcass projectile [U?] | — | Ray of Sickness [U] | — | — | — | — |
| Spirit (grouping open) | **Seeker** (current ghost; family open) | — | — | — | — | — | — | — |
| Life / Nature | — | Unnamed vine ball [U?] | Vine Lance [U?] | — | — | — | Expanding vine circle [U?] | Vine Whip [U] |
| Moon (possibly combinations) | — | — | — | — | Moon Slash / Crescent Slash [U?] | — | — | — |
| Sun (possibly combinations) | — | — | — | Sunbeam [U?] | — | — | — | — |
| Metal (grouping open) | Bullet [U] | Shrapnel [U] | — | — | **Cross Blade**; Slash [U] | — | — | Whip [U; school open] |

## Areas and placed effects

| Element / theme | Nova | Strike | Shower | Field | Wall | Trail | Trap / Sigil |
|---|---|---|---|---|---|---|---|
| Arcane / Mana | Arcane Nova [U] | — | Mana Storm [U] | Eye of [unnamed] [U?] | Prism Wall [U] | — | **Rune Trap** |
| Fire | — | Volcano [U?] | **Meteor Shower**; Firestorm [TBD] | **Cinder Field** | Flame Wall [U] | **Firewalk** | — |
| Ice | Frost Nova [U] | Falling icicle [U?] | Blizzard [U?] | — | — | — | — |
| Water | — | — | — | Whirlpool [U?] | — | — | — |
| Lightning | — | **Lightning** | Rain of Lightning [U] | Static Field [U] | Tesla Wall [U] | — | — |
| Earth | Earth Nova [U] | — | — | — | Earth Wall [U] | Muck [U?] | Earth Trap [U] |
| Plague / possible Death | Explore [TBD] | — | Explore [TBD] | Grasping Hand [U]; more [TBD] | Explore [TBD] | Explore [TBD] | Explore [TBD] |
| Spirit (grouping open) | — | — | — | — | — | — | — |
| Life / Nature | Crushing / expanding vines [U?] | Poisonous / exploding flowers [U?] | Poisonous / exploding flowers [U?] | — | — | Flower / vine trail [U?] | — |
| Moon (possibly combinations) | — | — | — | Moonfall [U?] | — | — | — |
| Sun (possibly combinations) | — | — | — | — | — | — | — |
| Metal (grouping open) | — | — | — | — | — | — | — |

## Protection and persistent magic

| Element / theme | Shield | Orbit | Seed | Golem | Restoration |
|---|---|---|---|---|---|
| Arcane / Mana | Prismatic Shield [U] | **Arcane Orbit** | — | — | XP magnet utility [U?] |
| Fire | Fire Shield [U] | Fire Orbit [U] | Flame Seed [U] | Fire Golem [U?] | Flaming Restoration [U?] |
| Ice | — | — | — | — | — |
| Water | — | — | — | — | — |
| Lightning | — | — | — | — | — |
| Earth | **Earth Shield** | — | — | — | — |
| Plague / possible Death | — | — | **Plague Seed**; **Soul Bloom¹** | — | — |
| Spirit (grouping open) | — | — | — | — | — |
| Life / Nature | — | — | — | — | **Life; Regeneration**; Yggdrasil [U] |
| Moon (possibly combinations) | — | — | — | — | — |
| Sun (possibly combinations) | — | — | — | — | — |
| Metal (grouping open) | — | — | — | — | — |

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

## Reading the boundaries

- Snowball is Bolt, Water Jet is Ray, Mana Storm is Shower. These placements follow the user’s explicit correction.
- Ball suggests projectile delivery into an area payoff; Strike suggests an effect appearing at a chosen location. Boulder is a heavy-body exception: no splash/explosion is invented.
- Nova suggests a radial burst; Wave a travelling front. They overlap deliberately: Tsunami can expand around the caster and still be called a Wave.
- Seed’s plant → grow → bloom lifecycle is guidance, not a hard gate. Plague Seed and Soul Bloom keep their current infection behavior in this column.
- Golem is a castable-form idea, with “elemental” an alternative name. Summon remains a component; Seeker is not forced into Golem.
- Spirit, Water/Ice, Metal/Earth and Moon/Sun groupings remain open. Seeker’s Plague/Death placement is a duplicate design reference, not a second spell or runtime rename.
- Flaming Earth Wall adds fire while retaining the wall’s earth identity. Restoration/buffs and elemental modifiers need explicit per-spell meanings.
- Whip is a candidate distinct form, not a new runtime subsystem. Grasping Hand’s Plague theme is selected for design; its implementation is not approved.

## Other existing content and preserved ideas

| Entry | Status |
|---|---|
| Mana Bolt | Implemented automatic attack, separate from manual Bolt |
| Atomic | Implemented style reward, outside base acquisition pool |
| Seeking Spirit / Reaping Spirit | Earlier spirit ideas; Reaping Spirit acquisition disabled; preserve despite school discussion |
| Shillelagh | User-named directional root wave; school open |
| Dash / Swiftness | Earlier user mobility ideas; activation/duration design open |
| Personal storm aura | Earlier dwell-triggered lightning idea; name and following behavior open; not automatically identical to Static Field |
| Homing Bolt, stronger Glacial Lance and elemental-tier words | Earlier composition/tier concepts, not new runtime casts |

## Examples and historical proposals that are not agreed spells

| Entry | Provenance / latest disposition |
|---|---|
| Arcane Seed | Earlier assistant example; user now rejects it |
| Arcane Golem | Generic candidate rejected in latest user pass |
| Arcane Shield | Historical assistant proposal, unselected; **Prismatic Shield** above is a separate new user idea |
| Life Seed | Assistant illustration, not selected; do not confuse with Life Bolt healing drops |
| Frostball / Plague Ball | Assistant names, not selected; user now proposes Snowball and an unnamed carcass concept respectively |
| Arcane Bolt / Arcane Ball / Mana Lance / Mana Strike | Unnecessary generic additions in this pass; existing Bolt/Focus Ray cover ordinary magic |
| Water Lance / Lightning Ball / Earth Wave | Not selected |
| Generic elemental slices, Fire Cone/Blast/Wave, Fire Nova, Fire Sigil | Often unnecessary palette swaps or modifier expressions; no blanket new-spell approval |
| Ice Wall / Water Wall / plain Rain | Distinct useful identity not established |

Inactive data definitions are not proof of acquisition. All proposed additions, renamed schools, modifier words and new recipes await selection and implementation approval. Historical 36-row campaign proposals remain archived design context rather than a mandatory roster.
