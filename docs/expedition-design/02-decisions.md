# Decision register and feedback coverage

**28 September alignment:** preserve the existing fun game and introduce keyword composition first. Working title: **Should Have Joined a Party**. Language controls complex wizardry; use readable inscriptions rather than keycap/typing-game branding. Detailed timing, animation, numeric tuning and the proposal defaults below remain unapproved unless explicitly confirmed. Local XP/mana and spell-identity working notes need reconciliation before their dependent implementation.

## Confirmed direction

| ID | Requirement | Specification |
|---|---|---|
| C01 | Elaborate wizard incantations are the fantasy; basic spells remain useful | Game design; balance commitments |
| C02 | Permanent spell and keyword knowledge | Progression, save contract |
| C03 | Prepare spells before a level; mana activates them in order | Progression table |
| C04 | Replace passive upgrade system with keywords | No passive inventory in new mode |
| C05 | Four ley lines, 20-minute extraction, optional guardian after all four | Level and extraction states |
| C06 | Authored landmarks/routes plus procedural variation | Level generator contracts |
| C07 | Shared spell properties, explicit unsupported combinations allowed | Composition capability matrix |
| C08 | Duplicate and Repeat differ; Delay is free movement with slight boost; Charge roots for much more power | Keyword table and clocks |
| C09 | Effects and collision correspond; shard contact causes Ice Blast damage | Geometry and VFX contracts |
| C10 | Per-cast finite slowdown, not shared meter | Casting state machine |
| C11 | Document all ideas before selecting implementation | Full catalog and reserved appendix |
| C12 | Research levels, impact, visual language and art alternatives | Research; levels; art guide |
| C13 | Document first; leave playable build alone | Delivery scope |

## Decisions to review first

All entries below have a complete proposed default so a future implementation can be estimated. They still need product review before that implementation starts.

| ID | Question | Recommended v0.1 default | Why / alternative |
|---|---|---|---|
| D01 | Prepared capacity? | Six manual pages, first page Bolt fixed in first realm; later any learned starter-eligible spell | Familiar capacity limits burden; eight gives freedom but more menu work. Six is a new proposal, not inherited approval. |
| D02 | Keyword preparation? | All learned keywords available; max four distinct keywords per expression | Real growing vocabulary; prepared keyword slots risk recreating passives. |
| D03 | Death retention? | Discoveries bank immediately at ritual completion, including on later death | Encourages experimentation. Extraction-only banking increases stakes but risks grind. |
| D04 | Automatic attack? | Open comparison: retain current automatic Mana Bolt for keyword introduction; test manual-only combat later before choosing | Automatic attack changes require their own playtest; do not bundle removal into composition. |
| D05 | Combination acquisition? | Once both ingredients are permanently known, discover the recipe; bonus becomes usable when both ingredients activate in-run; no slot | Preserves originals and slot-free bonuses. No arbitrary free casting of unprepared library spells. |
| D06 | 20:00 during boss? | Extraction at 20:00 even during boss; warning at 19:00 and confirmation before late summon | Preserves user’s definite deadline. No hidden grace period. |
| D07 | Repeated discoveries? | Fixed site bundles; repeated sites grant mana, mastery stamps and replay score only | No passive-stat grinding or mandatory currencies. |
| D08 | Keyword vs base spell names? | Canonical suffix identifies base spell; elemental keyword identities use explicit forms such as Fiery, Icy, Venomous | Fire Bolt remains a distinct discovery; Fire is a reserved shorthand experiment, not an ambiguous alias. |
| D09 | Casting resource? | Mana is cumulative progression only; casting uses time plus spell recovery | Avoid silently turning collected progression into ammunition. |
| D10 | In-run spell ranks / XP? | Open: retain current upgrades during keyword introduction; reconcile XP, mana activation and possible spell/wizard upgrades before replacing progression | Keywords replace passive-item expression in the target design; this does not settle every progression role. |
| D11 | Map infinity? | Finite objective graph in a procedurally generated surrounding landscape; soft boundary returns player to graph | Keeps route time and 20-minute goal testable. Infinite exploration remains an alternative. |
| D12 | Realm count/art direction? | Tutorial + four realms; restrained luminous ruins art | Campaign and art recommendation, not a locked user decision. |
| D13 | Slowdown re-entry exploit? | New successful manual cast resets eligibility; cancel/invalid submit preserve the same attempt’s remaining budget; 0.15 s transition debounce; after 3 real seconds continuously outside typing, eligibility refreshes without a successful cast | Prevents empty-open spam without adding a shared energy meter. Failure recovery detailed in combat spec. |
| D14 | Top-tier words? | Powerful ships first; Mega/Super/Omega are reserved mastery tiers until expressive benefit is proven | Keep aspiration visible without four synonymous mandatory damage prefixes. |

## Explicit changes from the prototype

| Old rule | New proposal | Preserved intention |
|---|---|---|
| Random XP level-up choices and six passive families | XP remains useful for in-run spell upgrades and potentially wizard upgrades, without necessarily retaining the old passive-item system; mana activates prepared pages; discovery at ley lines | XP-driven growth throughout a run, meaningful upgrades, choices between runs |
| Every run discovers a fresh randomized build | Permanent library, deliberate preparation | Replay variety through routes, loadouts and vocabulary |
| Boss every five minutes | Realm guardian after four objectives; timed elite patrols, no automatic five-minute boss | Escalation and milestones |
| 20-minute immediate victory | 20-minute extraction success; guardian provides optional stronger completion | Definite run endpoint |
| Mostly elemental theming | Modest realm efficiency modifiers | Thematic builds remain viable, no total resistance wall |
| Current spell ranks/automatic attack upgrades | Target passive-item replacement uses vocabulary; spell ranks and automatic attack remain separate decisions | Keep existing progression playable until its replacement is specified and tested |

## Playtest feedback carried forward

| Feedback | Required response / proof |
|---|---|
| Plague looks broken or does nothing | Visible seed flight, infected marker, spread link, 3 s orphan spore; host-death test |
| Duplicate shots wasted on dead targets | Incoming-damage reservations; reacquire only where guidance permits; no lifetime reset |
| Lightning / Bolt confused | Separate straight Bolt, blue area Lightning, bouncing Lightning Bolt; distinct previews |
| Regen too long for UI | Single-line name region with bounded fit; horizontal incantation viewport, no wrapped inscription stack |
| Circle around every enemy is noise | No decorative permanent circles; effect boundaries only where mechanically meaningful |
| Flames look like candles | Connected burning-ground patches; boundary and tick timing represent damage |
| Orbit, blade, trail weak | Numerical utility/dwell/contact model and role-specific tests, not merely brighter effects |
| Focus Ray useful | Preserve tracking single-target sustained niche; Prism trades intensity for line coverage |
| Tree collision traps player | Trunk-only collision; canopy overlap separate; route clearance checks |
| Slimes indistinct / too small | Role-specific silhouette/scale, not color alone; wizard-relative size board |
| Projectiles huge / invisible | Per-spell readable body; shared visual/collision geometry; workshop at real gameplay zoom |
| Crystals pulse needlessly / lost offscreen | Stable sizes, value tiers, exact XP conservation and consolidation |
| 3–8 minutes too easy, 9/11 worked | Early-middle pressure tests; avoid reusing old exact curve without new manual-cast testing |
| Boss drops nothing | Guardian knowledge reward, visible reward/extraction sequence |
| Damage feedback confusing | Local red flash only on actual damage; no healing motifs on hostile effects |
| Too much UI text | Health, run timer, active pages, pending activation; detailed math in journal/debug |
| Particles fail in workshop | Same runtime effect definitions in preview and game; deterministic scenes for every spell |

## Preserved ideas outside initial scope

- **Alternate formats:** siege/tower defense, wizard defending a gate, alchemist defending a tower with about ten ingredients and four/five per potion. Keep as separate concepts; do not merge their loops into this expedition.
- **Characters:** Slash/sword or Whip starters and floating weapons; several whip variants. Player may someday choose multiple floating weapons. No class roster promised now.
- **Ritual language:** optional five-word sequences: incomprehensible, photosynthesis, circumstantial, electromagnetism, misinterpretation; antidisestablishmentarianism as a novelty. XP-loss stakes were an idea, not an approved default penalty.
- **Mouse final boss:** free-angle movement and two attacks versus keyboard wizard’s movement and broad magic; skill/speed lore; one-spell-per-key Easter egg. Optional later chapter, not current guardian.
- **Presentation:** wizard body-part animation, slime frame generation/interpolation workflow, shaders, typed menus, commissioned release assets/audio, future regenerating enemy.
- **Systems:** world pickups exceeding loadout limit, quick-cast initials with weaker output, numeric delay parameters, Mega/Super/Omega mastery, modifier aliases, endless challenge mode.
- **Names:** Super Extreme Meteor Shower Deluxe, Mega Bolt, Mega Lightning Bolt, Giant Bolt, Giant Lightning Bolt, Wide Bolt, Piercing Bolt and Rain of Lightning. These are recorded phrases, not parser shortcuts or promises of distinct spells.

No idea is discarded simply because it does not fit v0.1. The spell catalog records identity overlaps explicitly; duplicate names do not inflate the shipping count.
