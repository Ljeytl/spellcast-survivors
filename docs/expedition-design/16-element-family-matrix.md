# Element × spell-family working matrix

Updated 29 September 2026 after 0.1.36. **Bold = implemented. [U] = user concept, not implemented. [U?] = alternatives, name or classification unresolved. [TBD] = requested exploration without an invented spell.** — means no selected entry, not a missing implementation task.

This matrix is brainstorming, not a new shipping roster. Current code still has **16 learnable bases and seven combinations**. Themes do not assert damage types: current combat uses numeric damage, and the school mergers below are design decisions, not runtime damage-system changes. See the [detailed design pass](17-element-spell-ideas.md) for every behavior, alternative, rejection and provenance. Families guide identities; names do not dictate geometry.

## Projectiles and directed attacks

Multiple spells may occupy any cell. Slice/Whip is one family; differences in shape, reach and motion belong to each spell.

| School | Bolt | Ball | Lance | Ray | Slice / Whip | Blast |
|---|---|---|---|---|---|---|
| Arcane / Mana | **Bolt** | — | — | **Focus Ray** | Arcane Slash [U] | — |
| Fire | Fire Bolt [U] | Fireball [U] | **Ember Lance** | Scorching Ray [U?] | — | — |
| Water / Ice | Snowball [U] | — | Ice Lance / Glacial Lance [U?] | Water Jet [U] | Water Whip [U] | **Ice Blast**; Tsunami [U]; Tidal Push [U?] |
| Lightning | — | — | Lightning Lance / rod [U?] | Static Shock [U?] | Lightning Whip [U] | — |
| Earth / Metal | Spike [U; ground delivery]; Bullet / Spray [U?] | Boulder [U; no splash assumed] | Earth Lance [U] | — | **Cross Blade**; Slash [U] | Earth Blast [U]; Shrapnel [U?] |
| Plague / Death | **Seeker** (ghost identity retained) | Unnamed carcass projectile [U?] | — | Ray of Sickness [U] | — | — |
| Life / Nature | — | Unnamed vine ball [U?] | Vine Lance [U?] | — | Vine Whip [U] | — |

Tsunami is a broad square/rectangular front spawning behind the player and travelling forward, with contact as it reaches enemies. It replaces the earlier radial Tsunami description. Tidal Push may overlap this concept; whether it remains a separate spell is open. Shrapnel is in Blast; exact delivery remains open rather than requiring its earlier grenade proposal.

## Areas and placed effects

Nova/Wave is one family. Radial versus directional shape and propagation are properties, not separate columns.

| School | Nova / Wave | Strike | Shower | Field | Wall | Trail | Trap / Sigil |
|---|---|---|---|---|---|---|---|
| Arcane / Mana | Arcane Nova [U] | — | Mana Storm [U] | Eye of [unnamed] [U?] | Prism Wall [U] | — | **Rune Trap** |
| Fire | — | Volcano [U?] | **Meteor Shower**; Firestorm [questioned] | **Cinder Field** | Flame Wall [U] | **Firewalk** | — |
| Water / Ice | Frost Nova [U] | Falling icicle [U?] | Blizzard [U?] | Whirlpool [U?] | — | — | — |
| Lightning | Thunderwave [U; radial knockback] | **Lightning** | Rain of Lightning [U] | Static Field [U] | Tesla Wall [U] | — | — |
| Earth / Metal | Earth Nova [U] | — | — | — | Earth Wall [U] | Muck [U?] | Earth Trap [U] |
| Plague / Death | Explore [TBD] | — | Explore [TBD] | Grasping Hand [U]; more [TBD] | Explore [TBD] | Explore [TBD] | Explore [TBD] |
| Life / Nature | Crushing / expanding vines [U?] | Poisonous / exploding flowers [U?] | Poisonous / exploding flowers [U?] | — | — | Flower / vine trail [U?] | — |

## Protection and persistent magic

| School | Shield | Orbit | Seed | Golem | Restoration |
|---|---|---|---|---|---|
| Arcane / Mana | Prismatic Shield [U] | **Arcane Orbit** | — | — | XP magnet utility [U?] |
| Fire | Fire Shield [U] | Fire Orbit [U] | Flame Seed [U] | Fire Golem [U?] | Flaming Restoration [U?] |
| Water / Ice | — | — | — | — | — |
| Lightning | — | — | — | — | — |
| Earth / Metal | **Earth Shield** | — | — | Earth Golem [U] | — |
| Plague / Death | — | — | **Plague Seed**; **Soul Bloom¹** | — | — |
| Life / Nature | — | — | — | — | **Life; Regeneration**; Yggdrasil [U] |

## Combination-theme ideas

Sun and Moon are combination themes, not separate school rows. These are unimplemented concepts, separate from the enabled recipes below.

| Spell | Family | Recipe status |
|---|---|---|
| Sunbeam | Ray | Fire + Life is a candidate, not a locked recipe |
| Moon Slash / Crescent Slash | Slice / Whip | Ingredients open |
| Moonfall | Field | Ingredients open |

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
- Nova and Wave share one column; Slash/Slice and Whip share one column. Geometry does not create another family. Tsunami and Shrapnel belong to Blast.
- Seed’s plant → grow → bloom lifecycle is guidance, not a hard gate. Plague Seed and Soul Bloom keep their current infection behavior in this column.
- Golem is a castable-form idea, with “elemental” an alternative name. Summon remains a component; Seeker is not forced into Golem.
- Water/Ice and Earth/Metal are merged schools; Spirit concepts sit within Plague/Death. Sun/Moon are combination themes. Display names remain refinable; these classifications do not change runtime behavior.
- Flaming Earth Wall adds fire while retaining the wall’s earth identity. Restoration/buffs and elemental modifiers need explicit per-spell meanings.
- Whip shares the Slice family, with spell-specific motion. Grasping Hand’s Plague theme is selected for design; its implementation is not approved.

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
| Earthquake / Earth Golem | Earlier user ideas preserved; not rejected in latest pass; no runtime implementation |
| Lightning Shield | Earlier open/historical shield idea; no mechanics approved |

## Examples and historical proposals that are not agreed spells

| Entry | Provenance / latest disposition |
|---|---|
| Arcane Seed | Earlier assistant example; user now rejects it |
| Arcane Golem | Generic candidate rejected in latest user pass |
| Arcane Shield | Historical assistant proposal, unselected; **Prismatic Shield** above is a separate new user idea |
| Life Seed | Assistant illustration, not selected; do not confuse with Life Bolt healing drops |
| Frost Ray / Ice Ray | Removed from the proposed roster; Water Jet occupies the merged school’s Ray slot |
| Frostball / Plague Ball | Assistant names, not selected; user now proposes Snowball and an unnamed carcass concept respectively |
| Arcane Bolt / Arcane Ball / Mana Lance / Mana Strike | Unnecessary generic additions in this pass; existing Bolt/Focus Ray cover ordinary magic |
| Water Lance / Lightning Ball / Earth Wave | Not selected |
| Generic elemental slices, Fire Cone/Blast/Wave, Fire Nova, Fire Sigil | Often unnecessary palette swaps or modifier expressions; no blanket new-spell approval |
| Ice Wall / Water Wall / plain Rain | Distinct useful identity not established |

Inactive data definitions are not proof of acquisition. All proposed additions, renamed schools, modifier words and new recipes await selection and implementation approval. Historical 36-row campaign proposals remain archived design context rather than a mandatory roster.
