# Full spell library — current spells, redesigns and ideas

This is the comprehensive design library, **not a promise to implement every row**. User ideas belong here even when outside the next build. Read alongside the [mechanics catalog](SPELL_AND_UPGRADE_CATALOG.md) and [art plan](ART_AND_FEEDBACK_PLAN.md). Last revised September 26, 2026 after the library/naming feedback.

## Spell direction accepted — September 26

The user approved the overall spell design direction and specifically liked Frost Nova as the radial counterpart to Ice Blast. Preserve the distinction: Ice Blast is a directional cone; Frost Nova is a circular burst around the caster. This endorses the concept, not a claim that Frost Nova is playable or that every library entry is selected. Keep and repair existing spells first; choose additions deliberately. Detailed values, unfinished geometry/aiming rules and recipe migrations remain to specify.

## Selection policy

Keep and fix the currently implemented roster first. This library preserves every concept for later selection; it is not a replacement roster or automatic expansion plan. Decide separately which ideas to add, which names to change and which overlapping concepts to combine. Thunderwave is a user-originated concept already preserved here, not a newly invented suggestion.

## Reading the status column

- **Current / rework:** an acquirable counterpart exists, but the intended description may require changes. It does not certify that the listed fantasy is implemented.
- **Current bonus / rework:** a replacement recipe exists; conversion to an additional slot-free spell is pending.
- **Rework / Rework proposal / Rework direction:** migration of an existing identity; not yet delivered.
- **Idea / New bonus design:** designed or suggested only, no claim of implementation. “User decision” is stronger than “New proposal” in the source column.
- **Inactive data:** data exists without an available acquisition path; not playable content.
- **Legacy current name / Naming alternative:** preserved for traceability, not another distinct spell or freely accepted alias.

Letter counts exclude spaces. They expose mismatches, not a universal damage formula. Compare total useful damage, coverage, protection, healing, persistence and control for the actual typing commitment. Longer same-role spells must earn more useful effect; short spells win on responsiveness. Do not make “Ember” automatically stronger than “Fire,” or treat an unfamiliar word as permanently difficult once learned.

Life and Regeneration are separate effects. Seeker is the recommended short summon; the larger Seeking Spirit remains a separately marked possibility. Firewalk is a working replacement name, not an additional trail spell. Lightning Arc is legacy terminology, not a new lightning identity. Bolt aims once and then travels straight; Homing Bolt is a future separate concept.

Water is a requested gap in the library. Splash, Water Jet, Undertow, Tidal Wave and Maelstrom below are **new proposals**, not names the user previously committed to. Water emphasizes currents, displacement and directed flow; ice emphasizes bursts, slow and frozen control. These schools remain themes, not required elemental counters.



Geometry and aim columns describe intended contracts, not verified runtime hitboxes. Unsettled entries remain **undecided** or **proposed**. A moving projectile also needs a collision footprint; effects with bursts or spread have additional independent regions. See the [detailed geometry specification](SPELL_AND_UPGRADE_CATALOG.md#spell-geometry-and-targeting-contracts).

## Naming and commitment examples

| Shorter commitment | Longer commitment | Why typing more is worthwhile |
|---|---|---|
| Life — 4 letters | Regeneration — 12 | About 4 HP immediately versus substantially more total healing over time. These are separate spells, not aliases. |
| Bolt — 4 | Homing Bolt — 10, idea | Straight shot versus costly steering/reliability. Lightning Bolt — 13 separately buys bouncing group damage. |
| Seeker — 6, proposed | Seeking Spirit — 13, proposed | One modest hunter versus several useful hunters or substantially longer service; both names only stay if both roles are worthwhile. |
| Wave — 4, idea | Tidal Wave — 9, proposal | Narrow modest push versus broader, more damaging displacement. |
| Slash — 5, deferred | Crescent Slash — 13, idea | One quick cut versus multiple substantial cuts with broader coverage. |
| Firewalk — 8, working name | Cinder Field — 11 | A movement-drawn trail versus a stronger prepared area in its intended use. Different geometry still matters; don't force a universal winner. |

These are reviewable design relationships, not final damage ratios. A longer title attached to the same weak effect fails the design. Shortening an incantation is appropriate when the intended effect is modest; stronger effects need real useful output, not filler words.

## Mana and arcane

| Spell | Letters | Status | Source | Intended effect / typing payoff | Hit geometry | Targeting / origin | Visual identity |
|---|---:|---|---|---|---|---|---|
| Magic Missile | 8 | Automatic | Current game | Automatic support projectile; stays separate from typed Bolt. | Projectile; collision size open | Automatic acquired target; audit steering | Tiny staff spark, flat cyan projectile. |
| Bolt | 4 | Rework | User decision | Short, straight projectile; aim once at cast, no steering or homing after launch, no bounce. | Straight projectile; no homing | Aim once at release; fallback open | Clean forward bolt and one contact spark. |
| Homing Bolt | 10 | Idea | User concept | A separate later projectile which steers toward living targets; reliability earns the longer name. Not an alias for Bolt. | Proposed steering projectile | Proposed living-target tracking | Readable curved travel and target changes. |
| Arcane Orbit | 11 | Current / rework | Current game | Orbiting satellites damage nearby enemies while the wizard moves. | Proposed moving satellite hitboxes | Orbit caster; gaps not damage | Distinct satellites, not spirit creatures. |
| Focus Ray | 8 | Current / rework | Current game | Sustained concentrated beam; target contact and actual damage stay aligned. | Proposed finite-width beam | Track one acquired target | Stable beam and concentrated endpoint. |
| Prism Ray | 8 | Current bonus / rework | Current game | Piercing beam for lined-up targets; less individual damage than Focus Ray in current tuning. | Proposed piercing finite-width beam | Aligned targets; direction policy open | Faceted origin and multiple real contact points. |
| Mana Storm | 9 | Idea | User concept | Proposed sustained storm of arcane volleys over a crowd; choose a pattern distinct from orbit and spirits. | Undecided; see concept | Undecided | Sweeping coordinated projectile volleys. |
| Pulse | 5 | Idea | New proposal | Short, small close-range push; buys a little room without matching Ice Blast coverage. | Proposed small radial push | Caster-centered proposed | One brief outward ring, no lingering aura. |
| Gravity Well | 11 | Idea | Agent draft / new detail | Pull a group toward a focal point for follow-up attacks; deliberate delayed control rather than direct burst. | Proposed circular pull region | Ground placement; aim open | Enemies visibly pulled toward a dark focal point. |
| Magic Missile | 12 | Idea | Agent draft | Alternative guided-projectile concept; compare against Homing Bolt before keeping both. | Undecided; see concept | Undecided | Guided arcane dart. |
| Arcane Orb | 9 | Idea | Agent draft | Slow moving damage volume; must differ from satellites and a small bolt. | Undecided; see concept | Undecided | One large travelling orb with local contacts. |
| Arcane Shield | 12 | Idea | Agent draft | Possible magical absorption protection; distinguish from Earth Shield terrain. | Undecided; see concept | Undecided | Close personal barrier, no false ground wall. |
| Arcane Missiles | 14 | Inactive data | Old data | Existing draft volley concept; no available acquisition path. | Undecided; see concept | Undecided | Multiple distinct projectiles, not one larger glow. |
| Time Warp | 8 | Inactive data | Old data | Separate time-magic concept; cannot redefine ordinary per-cast slowdown. | Undecided; see concept | Undecided | A distinct localized distortion if later designed. |
| Arcane Turret | 12 | Inactive data | Old data | Placed autonomous attacker; health, duration and attack pattern undecided. | Undecided; see concept | Undecided | Visible placed construct and actual shots. |

## Life, nature and plague

| Spell | Letters | Status | Source | Intended effect / typing payoff | Hit geometry | Targeting / origin | Visual identity |
|---|---:|---|---|---|---|---|---|
| Life | 4 | Idea / requested split | User decision | Quick small immediate heal, target about 4 HP. A genuinely separate short spell, never an alias for Regeneration. | Self; no damage volume | Caster | One compact healing pulse. |
| Regeneration | 12 | Current / rework | User decision | Longer cast buys substantially greater total healing over time; current 40 HP over 5 seconds is a baseline, not newly approved tuning. | Self over time | Caster | Repeated restorative pulses when HP is gained. |
| Life Bolt | 8 | Current bonus / rework | Current game | Bolt + Life: projectile impact plants a healing seed. Move to collect it for a short heal; no automatic life-steal. | Projectile contact + collectable seed | Impact position; move to collect healing | Plant-like seed at impact, collection bloom and actual healing pulses. |
| Plague Seed | 10 | Current / rework | User decision | Plant infection in a host, then spread visibly through nearby enemies. | Host + local spread radius | First host then neighbors; range open | Seed planting, growth and host-to-host transfer. |
| Plague | 6 | Idea | User concept | Alternative area infection concept; must remain smaller/less expansive than longer spreading spells if retained. | Proposed area infection | Placement/shape open | Localized infected area; clearly bounded initial reach. |
| Soul Bloom | 9 | Current bonus / rework | Current game | Spreading infection plus earned healing; less restorative than specialist Regeneration. | Host + spread radius; self healing | First host then neighbors | Flowering infected markers and separate healing motes. |
| Yggdrasil | 9 | Idea | User concept | Tree of Life: grow a powerful restorative landmark. Preserve the idea; choose access/commitment and balance rather than dismissing it for its 9-letter name. | Proposed landmark + restorative area | Placement and area shape open | A tree grows into a readable healing landmark. |
| Tree of Life | 10 | Naming alternative | User concept | Alternate name for the Yggdrasil concept, not automatically a second spell or alias with identical cost. | Alternative landmark concept | See Yggdrasil | Same living-tree fantasy pending name decision. |
| Thorn Volley | 11 | Idea | Agent draft | Nature projectile fan; line coverage and contact behavior need definition. | Proposed projectile fan | Aim/spread open | A fan of visible thorns. |
| Venom Mark | 9 | Idea | Agent draft | Focused damage-over-time mark, distinct from spreading Plague Seed. | Proposed single-host effect | Target acquisition open | Persistent single-host venom marker. |
| Spore Bloom | 10 | Idea | Agent draft | Potential spore burst that seeds an area; distinguish from healing Soul Bloom. | Undecided; see concept | Undecided | Burst of spores followed by truthful infection states. |
| Regrowth | 8 | Naming alternative | Agent draft | Historical healing name; evaluate alongside Life and Regeneration, not three interchangeable heals. | Undecided; see concept | Undecided | Nature restoration if retained as a distinct behavior. |
| Heal | 4 | Naming alternative | Old combination notes | Historical short-heal label; prefer Life for the proposed 4-HP identity. | Undecided; see concept | Undecided | Small restorative pulse. |
| Chain Heal | 9 | Inactive data | Old data | Draft healing-chain concept; meaningful recipients must exist before it fits this single-player game. | Undecided; see concept | Undecided | Visible transfer between real eligible recipients. |

## Spirits and control

| Spell | Letters | Status | Source | Intended effect / typing payoff | Hit geometry | Targeting / origin | Visual identity |
|---|---:|---|---|---|---|---|---|
| Seeker | 6 | Rework proposal | User concept | Short basic summon: one small pursuing hunter. Rename/rebudget the current single-spirit behavior rather than calling it a grand summon. | Proposed moving hunter contact shape | Pursue acquired living targets | One distinct hunter with readable pursuit. |
| Seeking Spirit | 13 | Long-form idea / legacy current name | User concept | Proposed stronger separate summon with several useful hunters or substantially longer service. Do not keep it as a free alias for Seeker. Whether both stay is open. | Proposed multiple hunter contact shapes | Independent pursuit proposed | Multiple visible hunters if multiple exist mechanically. |
| Reaping Spirit | 13 | Deferred by user | Current game | Spirit whose qualifying kills cause local bursts. Recipe must be reviewed against Seeker versus Seeking Spirit. | Hunter contact + conditional kill-burst area | Pursuit; burst at qualifying kill | Distinct hunter and earned kill burst. |
| Grasping Hand | 12 | Idea | User concept | Powerful area-control hand; hold, root, pull or crush remains undecided. | Undecided area-control shape | Choose action and aim before geometry | Large hand visibly performing the chosen control action. |
| Skeleton Warrior | 15 | Inactive data | Old data | Draft summoned fighter; overlaps hunter role unless blocking/melee behavior differs. | Undecided; see concept | Undecided | A legible summoned fighter, not a wisp recolor. |

## Fire

| Spell | Letters | Status | Source | Intended effect / typing payoff | Hit geometry | Targeting / origin | Visual identity |
|---|---:|---|---|---|---|---|---|
| Ember Spear | 10 | Current / rework | User concept / current game | Piercing spear through aligned enemies; keep the strong existing fantasy. | Proposed narrow piercing swept projectile | Release direction; acquisition open | Long fire spear and real piercing contacts. |
| Cinder Field | 11 | Current / rework | User concept / current game | Persistent burning ground; total damage must justify the longer phrase. | Proposed persistent ground circle | Acquired ground position proposed | Low irregular ground flames with clear gaps. |
| Firewalk | 8 | Rework proposal | User naming suggestion | Preferred working name for movement-laid fire; terrain you draw while kiting. Tune for its shorter commitment. | Proposed chain of ground patches | Along actual player movement | Flaming tracks laid on the actual route. |
| Ember Trail | 10 | Legacy current name | Current game | Current movement-trail identity; replacement candidate Firewalk. Not another required spell. | Legacy movement-trail patches | See Firewalk proposal | Aging fire tracks. |
| Fire Trail | 9 | Naming alternative | User concept | Alternative to Firewalk; not a second identical trail spell. | Alternative movement-trail patches | See Firewalk proposal | Movement-laid flame tracks. |
| Meteor Shower | 12 | Current / rework | User concept / current game | Several substantial delayed impacts with reliable crowd payoff. | Proposed separate impact circles | Proposed target-area landings | Descending meteors, distinct impacts, bounded shake. |
| Meteor Spear | 11 | Current bonus / rework | Current game | Piercing spear creates local explosions; useful against aligned clusters. | Piercing projectile + impact areas | Acquired line proposed | Molten spear and separate hit explosions. |
| Fire Bolt | 8 | Idea | User concept | A distinct longer-than-Bolt fire projectile; proposed impact burst or burn, not mandatory elemental coverage. | Proposed projectile + impact area or burn | Release direction; aim open | Projectile plus truthful burn/burst on contact. |
| Fireball | 8 | Idea | Agent draft / new detail | Proposed compact impact explosion; distinguish from piercing Ember Spear and delayed meteors. | Proposed projectile + circular impact | Release direction; aim open | Round projectile with readable local blast. |
| Fire Wall | 8 | Idea | User concept | Directional lane of flame that controls crossing enemies, unlike round Cinder Field. | Proposed persistent ground strip | Placement/orientation open | Clearly oriented ground-fire line. |
| Flame Wall | 9 | Naming alternative | Agent draft | Alternative name to Fire Wall, not automatically another spell. | Alternative ground-strip concept | See Fire Wall | Same lane concept until distinguished. |
| Firestorm | 9 | Inactive data / idea | User concept + old data | Large moving or sustained fiery storm; pattern undecided. Name alone does not justify being stronger than longer Meteor Shower. | Undecided; see concept | Undecided | Coherent moving storm, not enlarged field texture. |
| Flame Elemental | 14 | Inactive data | Old data | Draft fire summon; autonomous role and lifetime need differentiation from spirits. | Undecided; see concept | Undecided | A distinct fiery creature with actual attack cues. |

## Water and ice

| Spell | Letters | Status | Source | Intended effect / typing payoff | Hit geometry | Targeting / origin | Visual identity |
|---|---:|---|---|---|---|---|---|
| Ice Blast | 8 | Current / rework | User concept / current game | Directional cone buys space through push and slow in front of the caster. | Confirmed cone; angle/reach open | From caster; aim-at-release proposed | Forward fan of shards, real knockback, frost on affected survivors. |
| Steam Field | 10 | Current bonus / rework | Current game | A short damaging ground cloud that also slows enemies; current design trades duration for control. | Proposed persistent ground circle | Acquired ground position proposed | Low moving vapor, transparent gaps and contact cues. |
| Frost Sigil | 10 | Current bonus / rework | Current game | Persistent prepared trap with a wider slowing burst and slower arming. | Trigger region + separate wider burst | Ground placement policy open | Frost inscription, armed state, triggered shards. |
| Ice Spear | 8 | Idea | User concept | A line attack with meaningful control versus Ember Spear damage; not a color swap. | Proposed piercing projectile | Release direction; aim open | Ice spear and actual survivor frost state. |
| Splash | 6 | Idea | New water proposal | Short close-range water slap with light damage and a small push. Less reach/control than longer spells. | Proposed short fan/cone | Directional from caster | Compact fan of water droplets and actual displacement. |
| Wave | 4 | Idea | User concept; water interpretation proposed | A short travelling front pushes a narrow group. Potential ingredient for Thunderwave, recipe unapproved. | Proposed moving front | Directional from caster; aim open | Low directional water front. |
| Water Jet | 8 | Idea | New water proposal | Sustained narrow stream damages and pushes along a line. Distinct from instant Wave. | Proposed sustained finite-width stream | Direction/tracking open | Continuous stream with visible contact spray. |
| Undertow | 8 | Idea | New water proposal | A bounded current draws enemies backward toward its origin, setting up a follow-up cast. | Proposed directional current region | Ground placement; aim open | Directional current and visibly displaced enemies. |
| Tidal Wave | 9 | Idea | New water proposal | Broad advancing wave carries substantial damage and displacement across a crowd; pays more than Wave. | Proposed broad moving front | Release direction; aim open | Large readable travelling front with open sight lines. |
| Maelstrom | 9 | Idea | New water proposal | Persistent swirling water gathers enemies and repeatedly damages the gathered group. Compare with Gravity Well; avoid duplicate control spells. | Proposed persistent circular vortex | Ground placement; aim open | Clear vortex motion and actual enemy paths. |
| Ice Shard | 8 | Idea | Agent draft | Simple damaging ice projectile; add only if its behavior differs from Bolt and Ice Spear. | Proposed projectile contact | Aim policy open | Sharp projectile and truthful hit cue. |
| Frost Nova | 9 | Endorsed concept / inactive data | User endorsed; agent draft + old data | 360-degree radial frost concept; distinct from the confirmed directional Ice Blast cone. | Proposed 360-degree radial area | Caster-centered proposed | Radial freeze/slow only as actually implemented. |
| Glacial Spear | 12 | Idea | Agent draft | Longer ice-spear concept; requires more useful line payoff, not only a grander name. | Proposed larger piercing projectile | Release direction; aim open | Large piercing ice silhouette and contacts. |
| Blizzard | 8 | Idea | Agent draft | Persistent storm of repeated ice hits and area control; coverage and duration justify commitment. | Undecided; see concept | Undecided | Readable circulating snow/shards without opaque fog. |

## Lightning and storm

| Spell | Letters | Status | Source | Intended effect / typing payoff | Hit geometry | Targeting / origin | Visual identity |
|---|---:|---|---|---|---|---|---|
| Lightning | 9 | Rework | User decision | Direct focused strike; no travelling projectile or base chain. | Direct strike; impact footprint open | Acquired target | One vertical strike and contact branches. |
| Lightning Arc | 12 | Legacy current name | Current game | Old chaining spell/data identity to migrate to Lightning. Not an extra approved fourth lightning spell. | Undecided; see concept | Undecided | Legacy behavior is not the target art contract. |
| Lightning Bolt | 13 | New bonus design | User decision | Bolt + Lightning: travelling projectile bounces among enemies. Originals stay owned. | Bouncing projectile | First target then eligible bounce targets | Visible travel and successive bounce legs. |
| Thunder | 7 | Naming alternative | User concept | Possible call-down name discussed; retain Lightning as the settled direct-strike name unless explicitly changed. | Undecided; see concept | Undecided | Direct strike if selected as the replacement name. |
| Thunderwave | 11 | Idea | User concept | Electric/shock knockback wave; possible Wave combination. Define an electrical control advantage beyond ordinary Wave. | Proposed shock front; cone vs arc open | Direction/placement open | Readable travelling shock front and real knockback. |
| Lightning Rain | 13 | Idea | User concept | Repeated direct strikes across an area; longer spell promises multiple meaningful hits. | Proposed multiple strike footprints | Area selection open | Separate overhead strikes, not bouncing projectiles. |
| Chain Lightning | 14 | Idea | Agent draft | Historical chaining concept overlaps Lightning Bolt. Preserve the reference; avoid a duplicate unless instant-chain versus projectile-bounce is intentionally distinct. | Undecided; see concept | Undecided | Connected real strike sequence if retained. |
| Thunder Spear | 12 | Idea | Agent draft | Storm spear concept; distinguish from spears and direct Lightning. | Undecided; see concept | Undecided | Directional spear and truthful electrical impact. |
| Static Field | 11 | Idea | Agent draft | Potential persistent electrical zone; choose a control role beyond Cinder Field recolor. | Undecided; see concept | Undecided | Sparse electrical ground connections. |
| Tempest | 7 | Idea | Agent draft | Storm concept; its 7-letter name cannot automatically claim ultimate-tier output. | Undecided; see concept | Undecided | Coherent storm pattern after behavior design. |

## Earth and runes

| Spell | Letters | Status | Source | Intended effect / typing payoff | Hit geometry | Targeting / origin | Visual identity |
|---|---:|---|---|---|---|---|---|
| Earth Shield | 11 | Rework direction | User concept | Keep the existing shield identity and explore damageable, decaying protection around the caster. Compare with separately placed Earth Wall before deciding whether this is terrain, attached protection or another shape. | Undecided protective geometry | Caster-focused; placement open | Ground rises into visible segments which erode and crack. |
| Rune Trap | 8 | Current / rework | User decision | Prepared persistent ground trap until triggered; count/replacement policy remains proposed. | Trigger region + separate burst area | Ground placement policy open | Inscription, armed rune and clear trigger. |
| Earth Bolt | 9 | Idea | User concept | Potential physical earth projectile; proposed stagger or impact weight to distinguish from ordinary Bolt. | Proposed projectile contact/impact | Release direction; aim open | Travelling stone and impact fragments. |
| Earthquake | 10 | Idea | User concept | Broad ground disruption with repeated useful crowd impact. Select stagger/displacement behavior before tuning. | Proposed repeated ground regions | Origin/shape open | Ground pulses and enemy reactions that match real control. |
| Stone | 5 | Idea | New proposal | Short heavy single projectile; modest impact control, limited reach or speed. | Proposed projectile contact | Release direction; aim open | One thrown stone and compact hit. |
| Earth Wall | 9 | Idea | User concept | Separately placed damageable earth terrain for blocking routes; potentially entirely different from caster-focused Earth Shield. Decay, shape and pass-through rules remain open. | Proposed placed barrier | Ground placement; aiming open | A placed rising barrier with readable cracks and erosion. |
| Earth Walls | 10 | Naming / variant idea | User concept | Plural formation alternative for Earth Wall; multiple segments could justify a distinct effect, but no automatic second spell or alias. | Proposed multiple barrier segments | Placement pattern open | Multiple clearly placed barrier segments if selected. |
| Stonewall | 9 | Naming alternative | Earlier assistant proposal | Compare this name with Earth Wall; do not silently add duplicate barrier spells. | Alternative barrier concept | See Earth Wall; undecided | Same placed-wall concept unless deliberately differentiated. |

## Moon, sun and blades

| Spell | Letters | Status | Source | Intended effect / typing payoff | Hit geometry | Targeting / origin | Visual identity |
|---|---:|---|---|---|---|---|---|
| Cross Blade | 10 | Rework proposal | User concept | Blade flies out, lingers, returns; positional useful damage should substantially exceed Bolt per cast. | Moving outbound/linger/return shape | Release direction; return to caster | Outbound path, linger, return and catch. |
| Returning Blade | 14 | Legacy current name | Current game | Existing name for the Cross Blade candidate, not an additional planned attack. | Legacy returning projectile | See Cross Blade proposal | Existing return attack needs the proposed linger. |
| Boomerang | 9 | Naming alternative | User concept | Shorter alternative name discussed for returning weapon. Do not expose all names as cost-free aliases. | Alternative returning projectile | Name/behavior selection open | Outward and return silhouette. |
| Slash | 5 | Idea / deferred starter | User concept | Short directional cut toward nearest enemy; possible future character starter. | Proposed short cutting arc | Toward nearest target | One clear cutting arc. |
| Whip | 4 | Idea / deferred starter | User concept | Short close-range sweep; possible future floating weapon/character. | Proposed sweep | Origin/aim open | A visible lash rather than a generic circular flash. |
| Crescent | 8 | Idea | User naming concept; behavior proposed | A small travelling crescent with limited piercing; needs distinction from Cross Blade. | Proposed travelling cutting shape | Direction/aim open | One moon-shaped travelling cut. |
| Moonfall | 8 | Idea | User concept | Moon area damages enemies and heals the wizard less effectively than pure Regeneration. | Proposed mixed heal/damage area | Ground placement; footprint open | Moon arrival and separately readable healing/damage. |
| Moon Slash | 9 | Idea | User concept | Moon-themed cut proposal; potentially the same design as Crescent Slash. Do not implement both without distinct patterns. | Proposed slash geometry; count open | Direction pattern open | Purple lunar slash geometry. |
| Crescent Slash | 13 | Idea | User concept | Multiple purple directional slashes with useful fan coverage; longer phrase pays more than Slash. | Proposed multiple directional cuts | Fan/direction pattern open | Several individually visible cutting arcs. |
| Sunbeam | 7 | Idea | New sun proposal | Focused radiant beam with a distinct charge/release pattern; compare with Focus Ray before retaining both. | Proposed finite-width beam | Direction/targeting open | Bright narrow beam without blinding full-screen flash. |
| Daybreak | 8 | Idea | New sun proposal | Expanding radiant burst clears close pressure; differentiated reach/timing needed versus Ice Blast. | Proposed expanding radial area | Caster-centered proposed | A brief sun disc and expanding rays. |
| Solar Flare | 10 | Idea | New sun proposal | Large directional flare damages a fan of enemies; pays for longer typing through broad useful coverage. | Proposed directional fan/cone | Aim policy open | Readable fan-shaped flare, hazards remain visible. |
| Divine Aura | 10 | Inactive data | Old data | Draft sustained holy aura; damage/healing role undecided. | Undecided; see concept | Undecided | Restrained persistent aura tied to actual ticks. |

## Relationships still to design

- Life → Regeneration is a commitment/power comparison, not automatically an evolution or recipe. Both can be distinct learned actives.
- Seeker → Seeking Spirit → Reaping Spirit is a proposed naming/fantasy relationship, not an approved mandatory upgrade chain. The existing Reaping Spirit recipe must be revisited if its ingredient changes to Seeker.
- Life Bolt is **Bolt + Life**, planting a collectable healing seed at impact. The user explicitly rejected automatic life-steal. Keep Soul Bloom tied to Regeneration unless separately revised.
- Firewalk, Fire Trail and Ember Trail are competing names for one current movement-fire role. Choose Firewalk provisionally; no alias should allow different typing commitments for identical output.
- Earth Shield and Earth Wall are separate design candidates, not interchangeable names. Shield should focus on protecting the caster; walls should shape routes. Their exact behaviors remain proposed.
- Grasping Hand and earth protection/terrain need exact control/collision contracts before effects or code. Earth Shield must not accidentally trap its caster; pass-through rules and openings remain explicit design questions.
- Yggdrasil stays in the library. Tune its landmark role, unlock route and commitment deliberately. “Tree of Life” is an alternative name; longer ritual/map versions are possible later, not a requirement imposed now.
- Similar ideas (Homing Bolt/Magic Missile, Gravity Well/Maelstrom, Moon Slash/Crescent Slash) remain visible until deliberately combined or differentiated. Do not inflate the promised playable count with synonyms.

## Saved modifier and alternate-name ideas

These are individually recorded examples, not approved arbitrary phrase casting, extra playable spells or interchangeable aliases. The source distinguishes user ideas from older assistant suggestions.

| Idea / phrase | Source | Status | Intended direction / unresolved detail |
|---|---|---|---|
| Mega Bolt | User modifier example | Deferred | Stronger Bolt through an authored modifier; scaling and valid syntax undecided. |
| Mega Lightning Bolt | User modifier example | Deferred | Stronger bouncing spell; no recursive/free modifier system approved. |
| Giant Bolt | User modifier example | Deferred | Larger projectile concept; visual size versus actual hit geometry must be specified. |
| Giant Lightning Bolt | User modifier example | Deferred | Larger bouncing projectile concept; exact effect undecided. |
| Super Extreme Meteor Shower Deluxe | User power-fantasy example | Saved example, not selected name | An unusually long commitment should earn a spectacular, potentially board-clearing payoff. |
| Wide Bolt | Earlier assistant example | Deferred | Coverage modifier; distinguish width from projectile count and fan angle. |
| Piercing Bolt | Earlier assistant example | Deferred | Reach targets behind the first; penetration and repeat-hit rules undecided. |
| Rain of Lightning | User wording | Naming alternative | Same family of concept as Lightning Rain; choose name/behavior rather than silently accepting different-cost aliases. |
| Plague Nut | User informal name reference | Naming alternative, not a selected spell | Preserved as a naming reference for the plant-themed plague concept; not an additional approved mechanic. |

## Other saved ideas — separate from the spell roster

Full explanations remain in [casting fantasy notes](CASTING_FANTASY_NOTES.md) and the [roadmap](../ROGUELITE_ROADMAP.md). This table makes them visible without representing them as spells or current implementation work.

| Idea | Source | Status | Saved intent |
|---|---|---|---|
| Alternate Slash / Whip starters and characters | User | Deferred | Distinct starting weapons/characters and potentially floating weapon focuses. |
| More Whip variations | User | Unnamed concepts | Preserve room for variants; no specific names or effects were settled. |
| Discoverable map reward locations | User and friends | Future concept | Reach a location, perform a specific typed challenge and unlock a reward. |
| Timed difficult-word sequence / leylines | Friends, saved by user | Future concept | Roughly five difficult words under a time limit; proposed leyline creation. |
| Long challenge words | Friends, saved by user | Examples | Incomprehensible, photosynthesis, circumstantial, electromagnetism, misinterpretation and antidisestablishmentarianism; not ordinary unlocked combat spells. |
| XP risk for map challenges | Friends, saved by user | Undecided alternatives | Delayed XP or XP loss; amount and triggering condition unresolved. |
| Mouse final boss | Friends, saved by user | Future concept | Freely moving mouse boss with two attack types; does not override current 20-minute immediate win. |
| Keyboard skill versus mouse speed | Friends, saved by user | Lore idea | Preserve the proposed skill/speed contrast without changing current movement controls. |
| Keyboard-key-count spell Easter egg | Friends, saved by user | Future concept | A library related to keyboard key count; layout/count undecided, no slot-cap change. |
| Typed menu navigation and level-up selection | User | Deferred | Type to choose; existing navigation remains for now. |
| Map-found slot overflow | User | Future concept | Potentially exceed normal build limits through map finds; currently six active/six passive families. |
| Wizard body-part animation | User | Later | Preserve layered assets for future animation. |
| Shaders | User | Explicitly deferred | Visual polish after gameplay/readability baseline. |
| Audio pass | User | Deferred | Later sound work, not part of the current design pass. |
| Siege / tower-defense version | User | Saved alternative; no pivot | Explore the typing-pressure loop through defense if revisited later. |
| Wizard defending a gate | Earlier assistant suggestion | Saved alternative; no pivot | Compact defense experiment with approaching threats. |
| Alchemist defending a tower | User | Saved alternative; no pivot | Roughly ten ingredients, four or five per potion; preparation time versus potency. |
| Authored language / spell composition | User direction, assistant examples | Deferred | Potential phrase vocabulary; ownership, syntax and valid combinations require separate design. |

The school tables preserve the named spell concepts; this section preserves modifiers and broader ideas. A status of idea, alternative or deferred does not mean selected for implementation. Unnamed variants are recorded as unnamed rather than invented and attributed to the user.
