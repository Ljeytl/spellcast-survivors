# Expedition spell catalog

Updated 14 October 2026 against release source `6ed65b3` (0.3.0). This is the complete working catalog, consolidated from the former catalogs in docs 3, 16, 17 and 18. It preserves the full set of authored spell ideas; no smaller spell pack has been selected in their place.

**Status:** implemented means available in the current game; design means a recorded future identity, not shipped content; open means a material behavior or naming choice remains; paused means explicitly excluded from implementation until revisited; reserved means preserved exploration; rejected means not selected. Design numbers in the historical specifications are tuning proposals, not current runtime values. Alias names do not automatically create separate spells or accepted incantations. There is no fixed 36-spell shipping cap.

[Release plan](15-development-order.md) owns sequencing. [Damage, effects and keywords](21-damage-effects-keywords.md) owns current damage/status rules. [Spell architecture](19-engine-architecture.md) owns construction. [Presentation and shared mechanics](18-spell-system-rewrite.md) owns quality criteria. New combination recipes and acquisition will be decided later; existing combinations stay available.

## Current playable inventory

All 16 manual bases use the shared engine. Their existence does not certify timing, animation, audio, balance or game feel. `data/spells.json`, `data/spell_damage.json`, `data/recipes.json` and the runtime are authoritative for implemented numbers. The runtime ID `infestation` currently displays as Infection; Infestation and Plague Seed are earlier design names for that same existing identity; Firewalk and Fire Walk refer to one spell.

| Runtime ID | Public name | Status |
|---|---|---|
| `bolt` | Bolt | Implemented manual base |
| `life` | Life | Implemented manual base |
| `regeneration` | Regeneration | Implemented manual base |
| `ice_blast` | Ice Blast | Implemented manual base |
| `earth_shield` | Earth Shield | Implemented manual base |
| `lightning` | Lightning | Implemented manual base |
| `meteor_shower` | Meteor Shower | Implemented manual base |
| `ember_spear` | Ember Spear | Implemented manual base |
| `infestation` | Infection | Implemented manual base |
| `cinder_field` | Cinder Field | Implemented manual base |
| `arcane_orbit` | Arcane Orbit | Implemented manual base |
| `focus_ray` | Focus Ray | Implemented manual base |
| `rune_trap` | Rune Trap | Implemented manual base |
| `seeker` | Seeker | Implemented manual base |
| `firewalk` | Fire Walk | Implemented manual base |
| `cross_blade` | Cross Blade | Implemented manual base |

Magic Missile (`mana_bolt`) is the automatic attack. Atomic is the special style reward; neither is an additional manual base.

### Existing combinations

| Runtime ID | Spell | Ingredients | Status |
|---|---|---|---|
| `lightning_bolt` | Lightning Bolt | Bolt + Lightning | Implemented |
| `life_bolt` | Life Bolt | Bolt + Life | Implemented |
| `meteor_spear` | Meteor Spear | Ember Spear + Meteor Shower | Implemented |
| `soul_bloom` | Soul Bloom | Infection + Regeneration | Implemented |
| `steam_field` | Steam Field | Cinder Field + Ice Blast | Implemented |
| `prism_ray` | Prism Ray | Focus Ray + Ember Spear | Implemented |
| `frost_sigil` | Frost Sigil | Rune Trap + Ice Blast | Implemented |

Current combination behavior is maintained in [doc 21](21-damage-effects-keywords.md), not the archived campaign tables. In particular, Prism Ray refracts into elemental beams and Soul Bloom releases a ghost on infected death that heals or hunts. New combinations are deferred below.

## Full authored spell catalog

Each row is an identity or explicitly unresolved family, not a commitment to an extra acquisition slot. Water/Ice, Earth/Steel (formerly Metal), and Plague/Death are merged schools; Storm includes the older Lightning school label. Life is nature magic. Sun and Moon remain combination themes. Nova/Wave and Slash/Slice/Whip are browsing families, not engine types. Names express fantasy; parts determine behavior.

### Arcane and Mana

| Spell or family | Status | Fantasy and behavior | Remaining decision |
|---|---|---|---|
| Arcane Slash | Design | Magical sword slashes carve a glyph; each level adds one slash; the final level adds a small explosion at the end. | Tune sweep, targeting, contact timing and final-rank payoff; do not revert to three stationary glyph traps. |
| Mana Storm | Open | A moving cloud rains mana or dagger-like magic. | Following the caster versus independent wandering. |
| Arcane Nova | Design | An expanding powerful wave of magic. | Tune propagation and impact. |
| Black Hole / Eye of [unnamed] | Design | A large damaging gravity well; Black Hole is the later ultimate identity. | Combo threshold and force limits; ultimates are combo-earned. |
| Prism Wall | Open | A fragile barrier reflects some attacker damage. | Reflection amount and eligible attacks; damage reflection versus projectile reflection. |
| Prismatic Shield | Open | Temporary invulnerability, possibly reflection. | Duration and strength; earlier roughly ten seconds is a proposal, not a promise or an approved cooldown exception. |
| XP Magnet / Arcane Restoration | Open | Collect distant experience through attraction. | Castable spell versus always-available utility; not healing by assumption. |
| Time Stop | Open | Stop enemies while the wizard can act; ultimate concept. | Whether new spells wait until time resumes. |
| Mirror Image | Design | Summon wizard decoys that distract enemies. | Decoy targeting, count and lifetime. |
| Polymorph | Design | Transform a target into a different creature. | Target eligibility, behavior and boss limits. |
| Ward | Open | Protective personal ward or barrier. | Independent spell identity versus the implemented WARDING keyword; do not count the keyword as an implemented base spell. |

### Fire

| Spell or family | Status | Fantasy and behavior | Remaining decision |
|---|---|---|---|
| Fire Bolt | Design | A direct travelling fire projectile. | Keep distinct from explosive Fireball. |
| Fireball | Design | A travelling projectile explodes on impact. | Explosion timing and radius. |
| Scorching Ray | Design | Separate lingering beams aim at enemies. | Enemy-aimed beams are the provisional choice; V arrangement remains an alternative, not simultaneous scope. |
| Flame Wall / Fire Wall | Design | A large passable burning ring around the wizard; radius and band thickness scale proportionally with area size. | Following versus fixed placement, lifetime and crossing/rehit timing; not a solid straight wall. |
| Volcano | Open | An eruption leaves a vent that lobs lava at enemies. | Whether it coexists with or replaces a role of Meteor Shower. |
| Fire Shield | Open | A shield retaliates with a fire blast when hit. | Protection and retaliation trigger. |
| Fire Orbit | Design | Orbiting flames damage and burn enemies. | Contact cadence and distinction from a keyword-modified orbit. |
| Flame Seed | Design | Plant an ember that grows into a fire-flower turret. | Growth, maturity, trample and recast rules. |
| Fire Golem | Open | A summoned fire ally, potentially casting Ember Spear from the player kit. | Eligible copied spells, rank, targeting and ownership. |
| Flaming Restoration | Open | Restoration with a fire-related buff. | Healing versus buff and its exact benefit. |

### Water and Ice

| Spell or family | Status | Fantasy and behavior | Remaining decision |
|---|---|---|---|
| Snowball | Design | A compact ice projectile in the Bolt family. | Tune hit and chill. |
| Ice Spear / Glacial Spear / Glacial Lance | Paused | Preserved ice spear family: lateral shove or impale concept. | User paused this family; do not choose a variant or implement it now. |
| Water Jet | Design | A tracking water stream damages and pushes; upgrades can add jets. | Target allocation and push limits. |
| Water Whip | Open | A sweeping water lash. | Contact shape, timing and displacement. |
| Tsunami | Design | A broad rectangular wave begins behind the player and sweeps forward. | Not the superseded radial description. |
| Frost Nova | Design | Cold bursts in every direction. | New authored design, distinct from the old inactive JSON draft. |
| Frost Strike / falling icicle | Open | An icicle falls onto a target with warning and impact. | Final name. |
| Blizzard | Open | A moving storm slows or freezes with lighter damage. | Follows the player or moves independently. |
| Whirlpool / Maelstrom | Open | A lasting vortex pulls inward and swirls enemies. | Name, force strength and limits. |

### Storm

| Spell or family | Status | Fantasy and behavior | Remaining decision |
|---|---|---|---|
| Lightning Spear / Lightning Rod | Paused | A spear becomes a lightning rod on an enemy or the ground. | User paused this family; host-death and rod behavior remain for later. |
| Static Shock | Design | A channeled chain of lightning jumps among enemies. | Hop and retarget timing. |
| Lightning Whip | Open | An electrical lash. | Contact shape, timing and status feedback. |
| Thunderwave | Design | A surrounding radial thunder burst throws enemies away. | Not the older travelling directional wave. |
| Rain of Lightning / Lightning Rain | Design | Distributed lightning strikes rain across an area. | Warning rhythm and targeting. |
| Static Field | Open | An electrical hazard area with possible arcing among enemies. | Distinct mechanic beyond ticking damage; do not silently merge with personal storm aura. |
| Tesla Wall | Design | Two solid coils connect a passable damaging electrical boundary. | Coil destruction, pathing and linked-beam behavior. |

### Earth and Steel

| Spell or family | Status | Fantasy and behavior | Remaining decision |
|---|---|---|---|
| Spike | Design | A ground spike erupts at a target and causes bleeding. | Warning and hit timing. |
| Bullet / Spray | Open | Rapid metal shots. | One identity versus variants; cadence. |
| Boulder | Design | A slow heavy rock with strong impact and knockback. | No explosion assumed. |
| Earth Spear | Design | A spear shatters into smaller scattering spears on impact. | Fragment targeting. |
| Slash | Design | A short slash toward the nearest enemy. | Starter/character-weapon proposals remain separate acquisition questions. |
| Lance | Reserved | A close-range piercing thrust. | Name reserved; design later. |
| Earth Blast | Design | A fan of fragments with knockback and bleed. | Different role from Ice Blast control. |
| Shrapnel | Open | A blast of metal fragments. | Delivery remains open; a grenade is not required. |
| Earth Nova | Design | Radial ground spikes damage and bleed. | Propagation and contact. |
| Earth Wall / Earth Walls / Stonewall | Open | Physical destructible barriers. | Single wall versus enclosure, collapse and pathing. |
| Earth Trap | Design | Lasting ground spikes immobilize briefly and bleed. | Arming and activation. |
| Muck | Open | Leave strongly slowing ground behind. | Later fire/oil interaction is undecided. |
| Earth Golem / Summon Golem / Golem | Design | Summon a stone ally. | Golem is the castable-name idea; exact taunt, attacks and ownership. |
| Earthquake | Reserved | Preserved large ground-area disruption idea. | Resolve identity against Earth Nova and other control spells. |

### Plague and Death

| Spell or family | Status | Fantasy and behavior | Remaining decision |
|---|---|---|---|
| Carcass (unnamed) | Open | Hurl infected remains to create a diseased dead zone. | Final name, arc and infection payload. |
| Ray of Sickness | Open | Sweep or pivot a ray across a crowd to spread debuffs. | Damage over time and slow; weakened payload to settle. |
| Grasping Hand | Open | A spectral hand restrains enemies in an area. | Grab, hold, pull and crush sequence. |
| Raise Dead | Design | Raise allied creatures from corpses. | Corpse eligibility, ownership and summon limits. |
| Hex | Design | Curse a target with vulnerability. | Delivery and duration. |
| Plague Spear, Nova, Shower, Field, Wall, Trail, Trap | Open | Requested exploration slots; field exploration is additional to Grasping Hand. | No selected names or mechanics; do not invent spells to fill cells. |

### Life and Nature

| Spell or family | Status | Fantasy and behavior | Remaining decision |
|---|---|---|---|
| Vine Ball (unnamed) | Open | Vines damage and immobilize an area. | Final name and whether it bleeds. |
| Shillelagh / Life Spear | Design | One spell leaves a rooting line or trail and uses vines to pull enemies into it. | Tune line, travel and pull; not two separate spells, and not the superseded point-pull-only version. |
| Vine Whip | Open | Lash with a living vine. | Contact, motion and status timing. |
| Crushing Vines / expanding vine circle / Life Nova | Open | Roiling vines expand, crush and control enemies. | Root versus slow and whether these names are one identity. |
| Exploding Flowers / poisonous flowers | Open | Flowers poison or burst in a strike or shower. | Delivery and payload; alternatives are not separate confirmed spells. |
| Flower Trail / vine trail | Open | Leave poisonous flowers or roiling vines behind. | Choose the trail behavior. |
| Yggdrasil / Tree of Life / World Tree | Design | Grow a visible tree of life that heals the wizard and harms nearby enemies. | Growth, maturity, destructibility and combo threshold if ultimate; one identity. |

### Mobility and additional identities

| Spell or family | Status | Fantasy and behavior | Remaining decision |
|---|---|---|---|
| Dash | Open | A quick movement action for the wizard. | Immediate cast versus stored charge, direction, collision, invulnerability and limits. |
| Swiftness | Open | Temporary movement-speed magic. | Magnitude, duration and refresh rules. |
| Personal storm aura | Open | Each enemy that dwells in a circle is struck individually after exposure; the circle itself deals no contact damage. Level-ups extend duration, kills do not. | Name, following versus stationary, exposure reset and repeat rules; separate from Static Field. Naming candidates: Lightning Shield, Static Shield, Lightning Tower, Channel Lightning, Channel the Storm, Lightning Crown. |

## Signatures and new combinations

| Name | Status | Preserved idea |
|---|---|---|
| Homing Bolt | Signature concept | Bolt with a special HOMING expression; not an extra base spell by default. Spiral/home and smaller guided projectiles remain the showcase idea. |
| Ring of Meteors | Signature concept | Meteors orbit, then release toward enemies; potentially an upgraded Meteor Shower rather than an independent acquisition. |
| Sunbeam | Combination deferred | A powerful solar ray; ingredients and acquisition will be decided later. The older Fire + Life suggestion is not a selected recipe. |
| Moon Slash / Crescent Slash | Combination deferred | Multiple purple crescent slashes; ingredients undecided. |
| Moonfall | Combination deferred | Falling moon magic leaves an area that harms enemies and heals the wizard; ingredients undecided. |

No release assignment or recipe selection is implied for the new combinations. Preserve the existing seven recipes unchanged.

## Historical and reserved ideas

These are retained for future design, not silently promoted into the selected authored roster. Where an idea overlaps a row above, the current row owns that identity.

| Names | Preserved idea or disposition |
|---|---|
| Arcane Orb | Slow travelling impact body; distinguish from existing orbit and other projectiles. |
| Pulse; Wave; Splash | Short radial or local emergency magic; identities remain unresolved. |
| Gravity Well | Older pulling-field idea; relationship to Black Hole unresolved, not an automatic duplicate. |
| Arcane Missiles; Time Warp; Arcane Turret | Older inactive volley, time and stationary summon drafts; not automatically ported. |
| Plague / Plague Nut | Small area-infection experiment and naming idea; not silently deleted into Infestation. |
| Thorn Volley; Venom Mark; Spore Bloom | Plant fan, delayed poison mark and stationary infection nursery. |
| Chain Heal | Inactive allied healing draft; needs allied recipients. |
| Seeking Spirit | Stronger persistent-spirit concept, distinct from current Seeker until selected. |
| Reaping Spirit | Disabled combination; explicitly deferred, not one of the seven enabled recipes. |
| Skeleton Warrior; Flame Elemental | Inactive summon concepts. |
| Fire | Standalone grammar/base-word idea; FIERY already exists as a keyword. |
| Undertow; Tidal Wave; Ice Shard | Returning water band, major travelling wave and short ice projectile; do not equate names with Tsunami or Snowball without a decision. |
| Chain Lightning; Thunder Spear; Tempest | Immediate chain, delayed discharge spear and moving weather concepts; Lightning Spear remains paused. |
| Earth Bolt; Stone | Earth projectile and short thrown-stone concepts. |
| Slash / Whip starters; Crescent | Alternate character weapon ideas and a possible moon ingredient identity. |
| Daybreak; Solar Flare | Historical solar burst/fan concepts; Sun stays a combination theme, not a new school. |
| Explosion — ritual incantation | Multi-stage chant followed by a release word and screen-wide payoff; interruption, text and damage not selected. |
| Super Extreme Meteor Shower Deluxe | Elaborate incantation/mastery fantasy, not an approved free alias. |
| Boots of Hermes | Proposed relic granting Dash; equipment, acquisition, charges and persistence undecided. |
| Regrowth / Heal; Lightning Arc / Thunder; Returning Blade / Boomerang; Fire Trail / Ember Trail | Historical names for existing identities, not approved short aliases or extra spells. |

### Rejected or unselected examples

Frost Ray / Ice Ray was removed in favor of Water Jet. Tidal Push was removed; it is not Tsunami. Firestorm / Fire Storm remains questioned and undefined beside Meteor Shower. Divine Aura is dropped. Arcane Shield is a historical unselected idea, distinct from the authored Prismatic Shield.

Arcane Bolt, Arcane Ball, Mana Spear, Mana Strike, Arcane Seed, Arcane Golem, Water Spear, Lightning Ball, Earth Wave, generic elemental slices, Fire Cone/Blast/Wave, Fire Nova, Fire Sigil, Ice Wall, Water Wall and plain Rain/Water Field have no selected independent identity. Life Seed, Frostball and Plague Ball were assistant examples, not selected names. Do not manufacture palette swaps to complete a matrix.

The nine inactive prototype drafts (Fire Storm, Time Warp, Chain Heal, old Frost Nova, Divine Aura, Arcane Missiles, Skeleton Warrior, Arcane Turret and Flame Elemental) are not evidence of playable acquisition. The new Frost Nova design above is separate from its inactive predecessor.

## Retained design decisions

Magic is learned knowledge of natural forces, not gods or faith; dark and esoteric knowledge fits that theme. Life is druidic/nature magic. A holy/light school is parked. Names describe fantasy while parts define mechanics.

Ultimates are **earned by combo, like Atomic**, with thresholds still open per ultimate. This is distinct from combining two spell ingredients; deferring new combination recipes does not reopen the combo-earned ultimate decision. **No cooldowns for now**; revisit tier-word cooldowns only if playtests demonstrate a spam problem. Bare forms such as `spear` and `nova` are allowed in the target design and deliberately weak, with strength determined by their purpose; this does not assert that every form is currently implemented. Current keyword semantics and reaction rules are owned by doc 21, which supersedes the earlier Overload-as-arcane description.

## Naming and implementation contract

Keep magical names, typed incantations and plain effect descriptions distinct. Shillelagh is the selected spelling; Shalali/Shillali were transcription variants, not additional spells. Mystical names may draw on mythology and fantasy, with provenance kept separate from another work's mechanics. Short urgent commands such as Dash are valid. No bulk rename or shorter alias is authorized here.

For each future spell, settle targeting, shape, cast/windup/contact/expiry timing, progression, recast rules, status payload, compatible keywords, preview and sound, then test it at real gameplay scale and in crowded moving combat. Paused and open choices remain explicit. Existing engine support must be inspected before scheduling a new reusable system. Proposed numbers and detailed earlier experiments remain in the [historical specification](archive/2026-10-14/18-spell-system-rewrite.md); they cannot override this catalog or doc 21.
