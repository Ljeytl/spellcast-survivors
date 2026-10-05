# Element and spell identity exploration — 29 September 2026

Status: user brainstorming captured after 0.1.36, **documentation only**. This is not approval to implement a new roster, rename runtime spells, impose elemental damage types or remove existing spells. Later corrections below take precedence over earlier suggestions in the conversation and older proposal tables. Current runtime remains 16 learnable bases, seven enabled combinations, automatic Magic Missile and the special Atomic reward.

Use the [populated matrix](16-element-family-matrix.md) for browsing. This page owns details, alternatives and rejections. Labels such as desired, preferred or questioned describe the user's design response, not implementation authorization. Unnamed entries deliberately remain unnamed.

## Confirmed follow-up consolidation

This follow-up supersedes the initial alternatives below. Water/Ice and Earth/Metal are merged schools; Spirit concepts join Plague/Death. Sun and Moon remain combination themes. Multiple spells per school/family cell are welcome. Final school and spell names remain refinable.

- Nova/Wave is one family and column; Slash/Slice/Whip is one family and column. Geometry and propagation are individual spell properties.
- Tsunami is Blast: a broad square/rectangular wave starts behind the player and sweeps forward. The earlier radial description is superseded.
- Shrapnel moves to Blast. Its exact delivery remains open; a grenade is not required.
- Frost/Ice Ray is dropped from proposals in favor of Water Jet. Snowball remains Bolt.
- Sunbeam may combine Fire + Life; that recipe is not final.

## Shared principles and unresolved taxonomy

| Topic | Captured direction | Still open |
|---|---|---|
| Families | Guiding identities, not rigid restrictions; no need to fill every cell with palette swaps | Exact engine-component mappings |
| Combinations | Existing combinations remain available and overlap families; separate/de-emphasize them while designing base identities | New recipe ingredients and acquisitions |
| Name versus delivery | Snowball belongs under Bolt despite its name; Spike can sit in Bolt exploration despite ground delivery | Final player-facing family names |
| Ball versus Strike | Travelling body and called-down impact are useful distinctions; an individual spell can combine components | Final placement of Whirlpool and the unnamed gravity well |
| Nova versus Wave | Merged family; radial/directional geometry is spell-specific | Exact per-spell geometry and control |
| Shower | A moving cloud can be a Shower with persistent area components | Following versus independently moving storms |
| Unique existing spells | Keep them visible in the matrix even when they break the default family lifecycle | No forced mechanical conversion for classification |
| Elements | Arcane/Mana is ordinary magic; schools/themes need not each become a distinct damage type | Final school names; mergers settled above |
| Modifier versus authored spell | Flaming Earth Wall remains Earth Wall plus fire; changing color/damage alone may be a modifier rather than a unique spell | Exact modifiers, numerical strength, compatibility and stacking |

## Arcane / Mana

| Entry | User concept / response | Status and unresolved details |
|---|---|---|
| Bolt / Magic Missile | Manual Bolt and automatic Magic Missile already cover ordinary magic projectiles | Implemented; no separate Arcane Bolt needed |
| Arcane Ball / Mana Spear | Generic additions lack a distinct need | Not selected; do not add just to fill cells |
| Focus Ray | Already expresses concentrated magical energy | Implemented |
| Arcane modifier | Critical chance was recalled as a possible keyword/property | Candidate only; not a settled elemental rule |
| Arcane Slash | Glyphs are slashed into an area, then explode after a short delay and damage touchers | User concept; exact contact versus delayed trigger relationship unresolved |
| Mana Storm | Moving cloud raining mana or dagger-like magic | Shower, not Field as its primary browsing family; movement and payload specifics open |
| Mana Strike | Explicitly unnecessary | Rejected in this pass |
| Arcane Nova | Expanding, high-damage magic wave | User concept |
| Eye of [unnamed] | Large damaging gravity well | Name and Strike/Field ownership unresolved |
| Prism Wall | Reflects some attacker damage; less durable than Earth Wall | User concept; reflection amount and eligible attacks open |
| Rune Trap | Keep current identity | Implemented, no change requested |
| Prismatic Shield | Roughly ten seconds of invulnerability, possibly reflection | New user idea; high-impact tuning unresolved; does not retroactively approve the historical generic Arcane Shield |
| Arcane Seed / Arcane Golem | No desired identity | Rejected; earlier Arcane Seed was an assistant example |
| Arcane Restoration | Possibly always-available XP collection/magnet utility | User proposal; name, family and availability unresolved, not healing by assumption |

Arcane's theme is overwhelming magical energy, not a requirement for a separate copy of every form.

## Fire

| Entry | User concept / response | Status and unresolved details |
|---|---|---|
| Fire Bolt / Fireball | Desired direct projectile and explosive projectile identities | Ideas, not runtime additions |
| Ember Spear | Existing fire penetration identity | Implemented |
| Scorching Ray | Two or three fire beams, either triangular or aimed at enemies, lingering | Alternatives; geometry/targeting/duration open |
| Flaming / Blaze Slash | Possibly modifier expressions rather than distinct spells | Questioned; no selected standalone identity |
| Fire Cone / Blast / Wave | Generic elemental variants may not justify independent spells | Questioned rather than committed |
| Flame Wall | Passable burning boundary that hurts enemies crossing it | User concept; do not make solid simply because Earth Wall is solid |
| Volcano | Impact/eruption followed by a lingering sentry-like effect; possible alternative to Meteor | Competing delivery/payoff options, not settled |
| Firestorm | User questioned what this historical name meant compared with Meteor Shower | Undefined/questioned; no distinct mechanic selected; inactive JSON is not implementation |
| Fire Nova | Generic Nova may already suffice | No separate fire spell needed in this pass |
| Fire Sigil | Merely changing damage type is a modifier | No unique spell without an additional mechanic |
| Fire Shield | Retaliatory Fire Blast | User concept; exact trigger/protection open |
| Fire Orbit | High damage with damage over time | User concept |
| Flame Seed | Fire turret after growth | User concept; shared Seed lifecycle with an authored payoff |
| Fire Golem | Only worthwhile if distinct | User idea; see shared golem question below |
| Flaming Restoration | Retained elemental restoration/buff concept | Healing versus buff classification and exact benefit unresolved |

Shared golem idea: golems (possibly called elementals) could cast spells from the player's kit; a fire summon might cast Ember Spear. Ownership, eligibility, selection, copied levels, autonomy and balance are undecided. Do not assume every element receives a summon or that generic Arcane Golem is approved.

## Ice

| Entry | User concept / response | Status and unresolved details |
|---|---|---|
| Snowball | Ordinary ice projectile | Bolt family despite the name; replaces the need for an assistant-invented Frostball concept |
| Large lobbed ice ball / Frostball | No need identified | Not selected |
| Ice Spear / Glacial Spear | Push enemies aside or impale with a major debuff; may sacrifice piercing for impalement | Alternatives remain open. Earlier stronger Glacial Spear acquired with Ice Spear remains recorded context, not a new resolved progression decision |
| Frost Ray | Slowing beam | Removed from proposed roster in follow-up; Water Jet takes the Ray slot |
| Ice Slice / Ice Wave | Palette swaps unnecessary | No selected unique spells |
| Ice Blast | Current cone is liked | Implemented; retained |
| Frost Nova | Ice Blast-like effect in all directions | User direction proposal; inactive JSON is not playable implementation |
| Frost Strike | Falling icicle | Working descriptor, final name unknown |
| Blizzard | Moving/following storm with strong slow/freeze and less damage | User concept; moving versus following unresolved |
| Ice Wall | No distinct job from Earth Wall established | Questioned, not approved |

## Water

| Entry | User concept / response | Status and unresolved details |
|---|---|---|
| Water Jet | Tracking jet dealing damage and knockback; upgrades add jets | **Ray**, not Spear; no Water Spear selected |
| Tsunami | Broad rectangular front spawns behind the player and travels forward | Blast family; supersedes radial version |
| Tidal Push | Earlier water Nova/Wave idea analogous to Frost Nova | Removed by user; not Tsunami. Frost Nova remains. |
| Whirlpool | Lasting vortex | Field is the current candidate placement; earlier Ball/Strike uncertainty preserved |
| Plain Rain / Water Field | Lacks a distinct identity | Not selected as standalone spells |
| Water Wall | Uninspiring without another mechanic | Questioned |
| Water Whip | Distinct whip idea | Shares Slice/Whip family; individual motion remains distinct |
| Water + Ice | Merged school | Water and ice spells coexist |

## Lightning

| Entry | User concept / response | Status and unresolved details |
|---|---|---|
| Lightning Bolt | Existing bouncing combination | Implemented; keep separate from base exploration |
| Lightning Ball | No desired spell | Not selected |
| Lightning Spear | Earlier continuous piercing/bouncing idea refined toward a projectile that embeds in an enemy or ends at a point, becoming a lightning rod that repeatedly calls nearby strikes | Preferred candidate; rod persists after host death. Exact placement, movement and strike behavior open |
| Static Shock | Channeled chain lightning | Provisional Ray name; targeting and channel behavior open |
| Lightning Slash | Unnecessary palette swap | Not selected |
| Lightning Whip | Interesting distinct form | User idea |
| Thunderwave | Thunder knockback wave | User idea retained |
| Rain of Lightning | Distributed lightning impacts | User idea retained |
| Static Field | Desired lightning area identity | Mechanic not fixed by the name; do not silently conflate it with all older storm-aura ideas |
| Tesla Wall | Two solid coils/endpoints connected by a passable but strongly damaging electrical boundary | User concept; endpoint durability and placement open |
| Lightning Shield | Earlier open shield-family idea | Preserve as historical exploration; no shield response or implementation approved |

## Earth

| Entry | User concept / response | Status and unresolved details |
|---|---|---|
| Spike | Ground spike rises, damages and causes bleeding | Discussed under Bolt but explicitly ground-delivered, not a travelling bolt |
| Boulder | Slow heavy projectile, high damage and large knockback | No explosion was specified; do not invent one to fit Ball |
| Earth Spear | Impact shatters into smaller scattering spears | User concept; secondary collision/aim open |
| Earth Blast | Cone analogous to Ice Blast, with knockback and bleed instead of slow | User concept |
| Earth Wave | Unnecessary extra identity | Not selected |
| Earth Nova | Radial ground spikes with damage and bleeding | User concept |
| Earth Wall | Placed barriers | Exact formation open; unclear dictated wording is not evidence for a new block-summoning mechanic |
| Earth Trap | Long-lasting spike trap, brief immobilization and bleeding | Distinct from exploding Rune Trap |
| Muck | Strongly slowing trail or oil-like ground | Name and family placement open; possible fire interaction is a later idea |
| Earth Shield | Stacked one-hit protection with attacker-directed retaliation | Implemented in 0.1.36; no new change in this brainstorm |
| Earthquake / Earth Golem | Earlier ground-shaking and summoned-earth-creature ideas | Preserved; latest brainstorm did not reject them; exact authored behavior remains open |

## Plague / possible Death

| Entry | User concept / response | Status and unresolved details |
|---|---|---|
| School | Keep Plague for now; broader death/undead/infection fantasy may justify Death later | No rename approved |
| Unnamed carcass projectile | Catapult an infected carcass or create a dead zone | Ball exploration; actual name and impact/zone details unresolved |
| Plague Spear | Undecided spear concept | Requested slot; fantasy, name and mechanics to develop |
| Ray of Sickness | Sweep or pivot across many enemies to distribute debuffs rather than focus a kill | Damage over time and slow; reduced enemy outgoing damage is a possibility, not a settled payload |
| Plague Slash | Palette swap unnecessary | Not selected |
| Nova / Shower / Field / Wall / Trail / Trap | User wants these explored | Names and mechanics **TBD**; table cells must not invent spells |
| Grasping Hand | Plague area-control magic | Theme explicitly Plague; precise control behavior still open |
| Plague Seed / Soul Bloom | Keep both visible in the Seed column | Implemented infection-special cases; do not force planted growth or change their runtime mechanics |
| Seeker | Could be Plague/Death Bolt, or a normal-damage ghost | Classification proposal only; preserve current ghost fantasy and runtime. Separate Spirit damage type is not required |
| Spirit | Folded into broader Plague/Death theme | Preserve ghost spells; no runtime damage-type change |

## Life / Nature

| Entry | User concept / response | Status and unresolved details |
|---|---|---|
| Life Bolt | Existing projectile plus healing pickup/patch | Implemented combination |
| Unnamed vine ball | Area immobilization and damage, possibly bleed | User concept; final name and bleed undecided |
| Shillelagh | Life Spear; retain the earlier vine/root attack fantasy and nearby-enemy pulling idea | Placement and name selected; exact attack, pull destination and shape still open |
| Vine Whip | Whip rather than Vine Slice | User concept in shared Slice/Whip family |
| Expanding vine circle | Roiling vines expand, damage and immobilize or slow | Shared Nova/Wave family; control choice open |
| Life Nova | Crushing vines | User direction; may overlap the expanding-circle concept rather than a separate spell |
| Life Strike / Shower | Poisonous or exploding flowers | Concepts without final delivery or names |
| Life Trail | Poisonous flowers or roiling vines left behind | Alternatives, not two confirmed spells |
| Life / Regeneration / restoration buffs | Current healing remains; broad restoration/buff classification unresolved | No automatic shift to resistance or damage |

## Moon, Sun and Metal

| Entry | User concept / response | Status and unresolved details |
|---|---|---|
| Moon / Sun | Combination themes rather than independent schools | Preserve individual spell ideas |
| Moonfall / Crescent Slash | Possible combination identities | Ingredients unresolved; speculative Life/Plague/Slash pairings are not recipes |
| Sunbeam | Combination concept | Fire + Life candidate; recipe open |
| Bullet | Rapid shots | Metal concept |
| Shrapnel | Blast-family metal fragments | Earth/Metal school; exact delivery/fragmentation open |
| Metal + Earth | Merged school | Multiple Earth/Metal spells can share a family |
| Metal Spear | No finalized new identity | Do not invent one |

## Decisions to make after this capture

1. Refine names within the settled school groupings without deleting working spell identities.
2. Select a small set of authored spells and modifier expressions; leave other cells open.
3. Define shapes, contact timing, payoff and keyword properties for selected candidates.
4. Resolve Restoration versus buffs, golem spell ownership and unique infection placement.
5. Only then approve implementation scope and tuning. This pass authorizes documentation, not a new spell implementation batch.

## Earlier ideas and provenance

The following preserves prior ideas and exclusions outside the main browsing matrix. Latest decisions above take precedence.

## Other existing content and preserved ideas

| Entry | Status |
|---|---|
| Magic Missile | Implemented automatic attack, separate from manual Bolt |
| Atomic | Implemented style reward, outside base acquisition pool |
| Seeking Spirit / Reaping Spirit | Earlier spirit ideas; Reaping Spirit acquisition disabled; preserve despite school discussion |
| Shillelagh | Possible distinction from Life Spear: Life Spear uses vines to pull enemies toward a destination, while Shillelagh forms a root wall that immobilizes enemies; exact pull destination and wall shape remain open |
| Dash / Swiftness | Earlier user mobility ideas; activation/duration design open |
| Personal storm aura | Earlier dwell-triggered lightning idea; name and following behavior open; not automatically identical to Static Field |
| Homing Bolt, stronger Glacial Spear and elemental-tier words | Earlier composition/tier concepts, not new runtime casts |
| Lightning Shield | Earlier open/historical shield idea; no mechanics approved |

## Examples and historical proposals that are not agreed spells

| Entry | Provenance / latest disposition |
|---|---|
| Life Seed | Assistant illustration, not selected; do not confuse with Life Bolt healing drops |
| Frost Ray / Ice Ray | Removed from the proposed roster; Water Jet occupies the merged school’s Ray slot |
| Frostball / Plague Ball | Assistant names, not selected; user now proposes Snowball and an unnamed carcass concept respectively |
| Arcane Bolt / Arcane Ball / Mana Spear / Mana Strike | Unnecessary generic additions in this pass; existing Bolt/Focus Ray cover ordinary magic |
| Water Spear / Lightning Ball / Earth Wave | Not selected |
| Generic elemental slices, Fire Cone/Blast/Wave, Fire Nova, Fire Sigil | Often unnecessary palette swaps or modifier expressions; no blanket new-spell approval |
| Ice Wall / Water Wall / plain Rain | Distinct useful identity not established |

Inactive data definitions are not proof of acquisition. All proposed additions, renamed schools, modifier words and new recipes await selection and implementation approval. Historical 36-row campaign proposals remain archived design context rather than a mandatory roster.
