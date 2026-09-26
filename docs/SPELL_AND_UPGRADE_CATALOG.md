# Spell and upgrade catalog

Status: proposed implementation specification for review; no runtime changes. Read with [core design](CORE_GAME_DESIGN.md) and the matching [art matrix](ART_AND_FEEDBACK_PLAN.md).

The [full spell library](SPELL_LIBRARY.md) is the master list of current identities, user ideas, inactive drafts, naming alternatives and new proposals, with explicit status and typing length. This document specifies current mechanics and migration; it is not the complete imagined roster.

## Inventory and naming

The current acquisition pool has 15 manual base spells, seven replacement recipes, and separate automatic Mana Bolt. The target converts every recipe into an additional slot-free spell and adds the confirmed Bolt + Lightning recipe. Current data identifiers are listed to make migration explicit; retaining an identifier does not approve its old behavior or displayed name.

The earliest compact roster was six manual spells plus automatic Mana Bolt. Historical drafts differ. Do not silently replace today's roster with an imagined original eight-spell list.

Proposed readable incantations below use single spaces and case-insensitive letters. Exact accepted aliases and save migration need review; aliases must never let a short phrase invoke a materially stronger long spell. For comparison, count letters separately from spaces and measure actual entry time and errors. “Yggdrasil” has 9 letters; “Regeneration” has 12. Preserve both distinct fantasies and tune useful payoff/commitment honestly; the letter comparison is not grounds to discard the Tree of Life idea.

## Base spell specification

All identities below require a complete cast/impact/expiration presentation in the art matrix. Existing figures are diagnostic observations, not final tuning. Names marked proposed still need approval.

| Current ID → intended name | Fantasy and targeting | Useful payoff / design requirement |
|---|---|---|
| `mana_bolt` → Mana Bolt, automatic | Small automatic projectile aimed at a valid nearby threat. | Baseline progression and fodder hits; clean forward 2D motion. No typing cost, no manual active slot. Mastery slot decision remains open. |
| `bolt` → Bolt | Quick simple projectile at an acquired living target. | Reliable fast damage; aim once and travel straight, no homing or innate bounce. Homing Bolt is a separate future idea. Starts in slot 1. Remove the misleading current Lightning Bolt label. Rank and Multicast behavior must not erase this identity. |
| `lightning_arc` → Lightning | Direct strike on an acquired living enemy. | Greater focused payoff than Bolt for more typing. Current chaining behavior must change; a rename alone is insufficient. Chaining belongs to Lightning Bolt. |
| `life` → Regeneration | Restore the caster over time. | Dependable specialist healing; proposed benchmark stronger than hybrid healing at comparable commitment. Current base is 40 HP over 5 seconds; inspect full-health/recast behavior before setting targets. Life becomes a genuinely separate quick heal, target about 4 HP; it must not remain a short alias for this stronger spell. Separate IDs and recipe migration are required. |
| New identity → Life | Quick small heal to the caster. | User direction: about 4 HP immediately; distinct from longer, substantially stronger Regeneration. Not implemented as a separate spell yet. |
| `ice_blast` → Ice Blast | Player-centered burst pushing and slowing nearby enemies. | Emergency breathing room, not maximum single-target damage. Clear affected radius and survivor slow state. |
| `earth_shield` → Earth Shield | Caster-focused earth protection, exploring damageable/decaying earth. | Keep and repair this existing spell. Earth Wall is a separate terrain concept, not a rename. Compare their roles before settling attached protection versus nearby terrain, durability, enemy attacks, escape and recast behavior. Current mechanic still grants overheal. |
| `meteor_shower` → Meteor Shower | Several delayed falling impacts around valid targets. | Long-commitment crowd payoff. Reduce wasted random landings; show distinct arrival and impact. Do not promise lingering fire unless it deals damage. |
| `ember_lance` → Ember Lance | Directional fire spear piercing aligned enemies. | Strong line damage; alignment is the tactical requirement. Preserve its successful fantasy as a benchmark. |
| `plague_seed` → Plague Seed | Plant-themed seed infects an initial host, then infection spreads between hosts. | Delayed crowd payoff with visible planting, infected state and actual transfer. Current limits: 8 infected targets, 5-second effect, 0.5-second ticks, 130-world-unit spread distance. These are baseline values to re-evaluate, not approved final ranges. |
| `cinder_field` → Cinder Field | Burning ground placed at an acquired target position. | Rewards holding enemies in an area. Keep distinct from a directional Firewall concept; geometry is a gameplay distinction. |
| `arcane_orbit` → Arcane Orbit | Arcane satellites circle the wizard and hit nearby enemies. | Close-range moving protection; satellites are not autonomous spirit creatures. Count useful contacts, not theoretical full-lifetime damage. |
| `focus_ray` → Focus Ray | Sustained focused beam tracks one valid target. | Reliable concentrated damage over time versus Lightning's immediate strike. Current ceiling 96 damage over 2 seconds; target loss and recasts must be accounted for. |
| `rune_trap` → Rune Trap | Place and arm a ground trap before enemies arrive. | Remains until triggered. Current six-second expiry conflicts with desired preparation fantasy. Proposed cap 3 and oldest-first replacement require approval; apply persistence consistently to Frost Sigil. |
| `seeking_spirit` → Seeker, proposed migration | Short summon of one pursuing hunter. | Latest user suggestion supports a short basic identity. Keep Seeking Spirit as a separately listed stronger multi-hunter idea, not an alias. Exact retention/acquisition of both remains open. |
| `ember_trail` → Firewalk, working name | Leave burning tracks along actual movement. | User suggested Fire Trail/Firewalk alternatives. Recommend Firewalk and tune its useful trail for the shorter typing cost. Ember Trail remains a legacy name, not a separate required spell. Define patch aging, overlap and recast behavior. |
| `returning_blade` → Cross Blade, proposed spelling | Blade flies out, lingers, then returns to the moving player. | Aim for roughly two Bolts of useful output in a suitable encounter. Current 38 outbound + 38 return versus Bolt 40 is only a ceiling; missing the return loses half. Linger and useful return geometry are required. |

### Plague Seed targeting and failure feedback

The current closest-enemy helper checks instance validity but not dying state and has no range bound. Infection itself rejects invalid/dead targets. This creates a plausible dead-target or offscreen-target explanation for the reported empty cast, but is a code-based hypothesis, not a reproduced diagnosis.

Proposed contract: acquire a living visible host within an explicitly authored cast range, show the host/planting event, and show a brief “No target” response if none qualifies. Decide whether an empty cast completes or remains editable before implementation. The initial targeting range and the later spread radius are different quantities and must not be conflated. Show propagation locally; do not add permanent radius circles around every enemy.

## Bonus spell catalog

**Confirmed global rule:** combinations are new spells, retain both ingredients and consume no active slot. Both ingredients must be owned this run. All eight identities below follow that rule, including the seven legacy recipes.

**Proposal:** acquire through a level-up choice, start at rank 1, upgrade independently. Discovery persists in the recipe collection but never grants casting ownership in another run. Current replacement-era penalties below are audit inputs; re-evaluate them with both originals still available.

| Bonus | Ingredients | Distinct tactical role and review requirement |
|---|---|---|
| Life Bolt | Currently Bolt + Regeneration; proposed Bolt + Life after split | Damage projectile earns healing on a real damaging hit. Current healing up to 6 HP; do not imply healing on a miss or automatically inherit the original's ranked volley. Less dependable sustain than Regeneration. |
| Meteor Lance | Ember Lance + Meteor Shower | Piercing impacts produce local explosions. Current direct damage reduced 40%; explosions deal half hit damage within 90 units. Evaluate useful grouped damage versus focused lance damage. |
| Soul Bloom | Plague Seed + Regeneration | Spreading plant infection also heals. Current damage reduced 25%; healing 10% damage capped at 2 HP per tick. Show spreading and earned healing separately. |
| Steam Field | Cinder Field + Ice Blast | Short ground damage plus slowing steam. Current duration 3 rather than 5 seconds and 40% slow. Preserve a control specialty instead of a universal field replacement. |
| Prism Ray | Focus Ray + Ember Lance | Beam pierces several aligned targets. Current up to 3 targets at 60% individual damage. Focus Ray should remain useful against one strong target. |
| Frost Sigil | Rune Trap + Ice Blast | Prepared larger burst slows survivors. Current radius 170 and slower 1.4-second arming versus 0.8. Remove the conflicting expiry under persistent-trap rules; cap and replacement policy need approval. |
| Reaping Spirit | Currently Seeking Spirit + Plague Seed; Seeker migration requires decision | Hunters cause local bursts on their qualifying contact kills. Current contact damage reduced 25%; burst half damage within 100 units, non-chaining. Specify hunter count and burst eligibility under the Seeker/Seeking Spirit split; do not silently keep an obsolete recipe. |
| Lightning Bolt, new | Bolt + Lightning | Visible travelling projectile bounces between enemies in a readable hit order. More useful group output for the longer incantation; Bolt stays quick and Lightning stays immediate. Bounce count, range, repeat-hit rule and expiry need tuning. |

Bonus does not mean universally superior. With originals retained, costs can remain on the bonus spell itself, but never secretly nerf its ingredients. No elemental immunity checks are needed to create these strategic choices.

## Passive families — six slots total

These categories consolidate user requests. Numeric rank values are proposals to author after the spell behavior contracts are approved. No uncited example percentage below is a shipped value.

| Passive family | Effect | Required boundary |
|---|---|---|
| Slowdown duration | More protected typing time per cast. | Fixed strength; no shared reserve, recharge or refill stat. |
| Spell area / size | Larger relevant spell coverage. | Specify hit geometry versus cosmetic size; no fake larger hit art. |
| Spell damage | More damaging output. | Does not silently scale healing, duration or enemy HP. |
| Movement speed | Faster movement outside typing. | Keep collision and escape routes fair. |
| Max health | More maximum HP. | Decide whether gaining a rank also heals; show the actual rule. |
| Multicast | One additional spell-appropriate output unit. | Author each spell's mapping; no unlimited recursive casts or duplicated bonus triggers. |
| XP gain | More experience from collected rewards. | Exact multiplier and rounding; distinguish from enemy population. |
| Mana Bolt mastery | Bundle automatic attack damage, rate and count progression. | One family rather than three separate passive taxes; first-rank slot accounting open. |
| Pickup radius | Collect XP from farther away. | Separate collection reach, magnet onset and visual crystal size. |
| Luck | Improve explicitly named random outcomes. | Must define affected rolls and caps before offering it; vague “better luck” is insufficient. |
| Crit chance | More eligible attacks critically hit. | Define damage-over-time and per-target rolls; no misleading universal claim. |
| Crit damage | Stronger eligible critical hits. | Display actual bonus convention consistently. |
| Enemy population | More enemies, yielding potential faster XP growth. | Explicit risk/reward; technical population caps must not nullify the benefit silently. |
| Projectile speed | Faster relevant projectiles. | Beams, instant strikes and fields need an explicit non-applicable rule; no universal benefit claim. |

Multicast mapping proposal: Bolt/Life Bolt/Lances/Cross Blade → another projectile; Meteor Shower → another meteor; Lightning → another strike; Lightning Bolt → another bounce; Seeker/Seeking Spirit/Reaping Spirit → another hunter; Orbit → another satellite; Life/Regeneration → another healing pulse; ground effects → an explicitly placed additional patch/trap; beams → an authored additional target or beam. **Earth Shield terrain and infection mappings remain open.** Do not multiply spread recursively or create infinite persistent traps. Validate passive interactions in the spell catalog before implementing global multipliers.

## Future concepts, not implementation scope

The individual, status-labelled rows now live in the [full library](SPELL_LIBRARY.md), including water, every named user concept and additional proposals. The groups below are only an index, not a substitute for those rows.

| Concept | Saved fantasy / unresolved decision |
|---|---|
| Moonfall | Moon-themed area damage and healing; weaker healing than Regeneration. Placement, duration and caster positioning are open. |
| Moon Slash / Crescent Slash | Multiple purple slashes; related Slash base and character identity deferred. |
| Yggdrasil / Tree of Life | Powerful restorative living landmark; choose a meaningful incantation and commitment rather than assuming the 9-letter name is harder than Regeneration. |
| Grasping Hand | Area control; clarify hold, root, pull, crush or another intended action before designing animation. |
| Earthquake | Broad ground disruption; distinguish its control and timing from Ice Blast and Meteor Shower. |
| Mana Storm / Firestorm / Lightning Rain | Large spectacle concepts; each needs a distinct pattern and target role, not a larger recolor of an existing field. |
| Fire Bolt / Earth Bolt / Ice Lance / Firewall | Potential themed geometries or combinations. No obligation to build one spell per element. |
| Slash, Whip, new characters | Potential alternate starter weapons and floating focus items; deferred. |
| Mega / giant modifier words | Deferred typed modifiers; no arbitrary phrases bypassing ownership. |

Nine extra JSON entries are inactive drafts, not available spells: Fire Storm, Time Warp, Chain Heal, Frost Nova, Arcane Missiles, Divine Aura, Skeleton Warrior, Arcane Turret and Flame Elemental. Preserve for reference; do not count as completed variety.
