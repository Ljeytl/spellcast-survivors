# Element × spell-family working matrix

29 September 2026. This is the editable Markdown design reference, not a promise to implement every intersection.

**Bold = implemented/acquirable in the current prototype.** *Italic = user-discussed idea, not implemented.* Empty intersections use —. Themes are descriptive, not verified damage types or elemental resistance rules. Families guide identities; shared components implement them without forcing identical shapes. Source inventory: `SpellManager.BASE_SPELL_IDS` (16), `SynergyCatalog` (seven enabled recipes), `CombinationScaling` and effect scripts at baseline `4edb268`. The 0.1.36 shield redesign is the only new runtime scope here.

## Projectiles and directed attacks

| Element / theme | Bolt | Ball | Lance | Ray | Slice | Blast | Wave |
|---|---|---|---|---|---|---|---|
| Arcane / Mana | **Bolt** | — | — | **Focus Ray; Prism Ray¹** | — | — | — |
| Fire | *Fire Bolt* | *Fireball* | **Ember Lance; Meteor Lance¹** | — | — | — | — |
| Ice | — | — | *Ice Lance; Glacial Lance* | *Frost Ray* | — | **Ice Blast** | — |
| Water | — | — | — | — | — | — | *Wave* |
| Lightning | **Lightning Bolt¹** | — | — | — | — | — | *Thunderwave* |
| Earth | — | — | — | — | — | — | — |
| Plague | — | — | — | — | — | — | — |
| Spirit | — | — | — | — | — | — | — |
| Life | **Life Bolt¹** | — | — | — | — | — | — |
| Moon | — | — | — | — | *Moon Slash; Crescent Slash* | — | — |
| Sun | — | — | — | — | — | — | — |
| Metal | — | — | — | — | **Cross Blade**; *Slash* | — | — |

## Areas and placed effects

| Element / theme | Nova | Strike | Shower | Field | Wall | Trail | Trap / Sigil |
|---|---|---|---|---|---|---|---|
| Arcane / Mana | — | — | — | *Mana Storm* | — | — | **Rune Trap** |
| Fire | — | — | **Meteor Shower** | **Cinder Field**; *Firestorm* | *Fire Wall / Flame Wall* | **Firewalk** | — |
| Ice | *Frost Nova* | — | — | — | — | — | **Frost Sigil¹** |
| Water | — | — | — | **Steam Field¹** | — | — | — |
| Lightning | — | **Lightning** | *Rain of Lightning* | — | *Lightning Wall* | — | — |
| Earth | — | — | — | *Earthquake* | *Earth Wall* | — | — |
| Plague | — | — | — | — | — | — | — |
| Spirit | — | — | — | — | — | — | — |
| Life | — | — | — | — | — | — | — |
| Moon | — | — | — | *Moonfall* | — | — | — |
| Sun | — | — | — | — | — | — | — |
| Metal | — | — | — | — | — | — | — |

## Protection and persistent magic

| Element / theme | Shield | Orbit | Seed | Golem | Restoration |
|---|---|---|---|---|---|
| Arcane / Mana | — | **Arcane Orbit** | — | — | — |
| Fire | *Fire Shield* | — | *Flame Seed* | — | *Flaming Restoration* |
| Ice | — | — | — | — | — |
| Water | — | — | — | — | — |
| Lightning | *Lightning Shield* | — | — | — | — |
| Earth | **Earth Shield²** | — | — | *Golem* | — |
| Plague | — | — | — | — | — |
| Spirit | — | — | — | — | — |
| Life | — | — | — | — | **Life; Regeneration**; *Yggdrasil* |
| Moon | — | — | — | — | — |
| Sun | — | — | — | — | — |
| Metal | — | — | — | — | — |

¹ Bonus combination, keeping both ingredients and using no additional active slot. Prism Ray is a very slowly rotating penetrating laser, not fixed. Steam Field is grouped under Water for browsing but is a Fire/Ice recipe. Cross Blade, Earthquake and Moonfall family positions are provisional rather than forced engine classifications.

² Earth Shield existed as overheal in 0.1.35; its approved 0.1.36 replacement stacks single-hit protection and retaliates toward the attacker. See [release specification](../releases/0.1.36-earth-shield.md) for implementation status and tuning.

## Unique spells, automatic attacks and special rewards

| Name | Theme / identity | Status |
|---|---|---|
| Plague Seed | Spreading host infection and lingering spores | Implemented; Infestation is an undecided rename, not another spell |
| Soul Bloom | Plague/Life infection; deaths leave healing ground patches | Implemented combination |
| Seeker | Independent pursuing spirit | Implemented; not forced into Golem |
| Seeking Spirit | Stronger spirit idea | User idea; separate from current public Seeker name |
| Reaping Spirit | Spirit combination | Deferred; acquisition disabled |
| Grasping Hand | Area control by a summoned hand | User idea; theme unresolved |
| Whip | Alternative basic weapon magic | User idea deferred with alternative characters |
| Mana Bolt | Automatic attack | Implemented separately from manual Bolt |
| Atomic | Screen-clearing style reward | Implemented; not part of the 16 base-spell acquisition pool |

## Family and element rules

- Bolt emphasizes direct contact; Ball is projectile delivery into an area payoff; Lance emphasizes penetration.
- Shield is personal protective action. Wall is world placement and can have element-specific geometry, collision and behavior. They are not interchangeable.
- Seed is plant → grow → bloom. Buff plants and turrets are user ideas. The final effect may vary; current Plague Seed does not need to be forced into this lifecycle.
- Golem is the player-facing word; summon remains a technical component, and Seeker remains a distinct identity.
- Restoration covers healing and recovery. Flaming Restoration is the user’s concept for restoration with a beneficial fire-related effect; resistance versus another benefit is undecided.
- Flaming Earth Wall retains Earth Wall’s identity and adds fire. It does not simply replace earth damage with fire. Conversion and additive modifiers require separate explicit contracts.
- Storm and Aura remain open classifications. Fire/Flame/Glacial and other stronger words are potential tiers, not automatically accepted aliases. Glacial Lance as a stronger Ice Lance acquired together is a user-approved design direction, not implemented.
- Longer typing should yield meaningfully greater useful output: damage, coverage, control, persistence or healing. Keywords should be significant and preferably multiplicative. Exact numbers and stacking are not settled.

## Examples and historical proposals that are not agreed spells

These are deliberately outside the main matrix. The user did not approve Arcane Seed or Arcane Shield.

| Entry | Provenance | Disposition |
|---|---|---|
| Arcane Seed | Assistant example of a mature spell-buff plant | Unselected illustration; no agreed behavior or implementation |
| Life Seed | Assistant seed-family example | Unselected illustration; do not confuse with implemented Life Bolt healing drops |
| Arcane Shield | Older reserved reflect/interception proposal | Unselected; no agreed spell behavior |
| Frostball / Plague Ball | Assistant examples of the Ball family | Unselected illustrations |
| Water Jet / Sunbeam | Earlier proposed catalog entries | Preserve in catalog for review; not user-selected additions |

## Implementation status discipline

The populated matrix covers all 16 acquirable bases and seven enabled combinations, with unique spells listed separately. Legacy JSON entries (Fire Storm, Frost Nova, Time Warp, Chain Heal, Arcane Missiles, Divine Aura, Skeleton Warrior, Arcane Turret, Flame Elemental) are not acquisition evidence. Frost Nova and Firestorm remain ideas here despite existing inactive data. No general keyword parser, elemental matrix, tower or expedition system is claimed shipped.
