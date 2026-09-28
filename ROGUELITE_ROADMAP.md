## Further endless encounters — deferred

Increase boss pressure at higher difficulties, including additional or concurrent bosses inspired by Risk of Rain. Design cadence and crowd composition separately; no boss-schedule change in the infection/collision fix.

## Twenty-minute choice — 0.1.26

At 20:00 pause for Extract (bank victory) or Continue (endless survival with increasing difficulty). Continuing keeps the run active and does not bank a victory. This supersedes the previous immediate 20-minute win; boss-cadence changes remain deferred.

## Post-0.1.25 feedback to address

See [F41–F43 in the feedback tracker](docs/PLAYER_FEEDBACK.md#post-0125-playtest-feedback--2026-09-28): Firewalk obscuring the wizard; remove bottom instructional messages while retaining spell names/numbers/durations; upgraded Bolt strength deferred for later. F41–F42 implemented in the ground-effect/HUD pass; F43 remains deferred.

## Lasting spell recasts — 0.1.25

Maintained spells use `recast_behavior: extend`; independent effects use `stack`. Arcane Orbit preserves its orbit and damage cadence; Firewalk extends emission only, never patch lifetime; Regeneration keeps one healing stream; Earth Shield retains its additive protection and extends expiration. Timed effects expose real remaining state to the bottom casting reference; traps show arming/armed rather than a fake countdown. Duration banking cap remains undecided and is not implemented.

## Playtester follow-up ideas — 2026-09-28 (deferred)

- Consider boss encounters at minutes 5, 8, 11, 14, 17, 20 instead of the current five-minute cadence. Resolve the minute-20 encounter versus immediate victory before implementation. Timing and difficulty remain unchanged for now.
- Recurring suggestion: add spell cooldowns. Evaluate alongside typing commitment before deciding implementation.
- Style/combo meter: reward quick accurate casting and spell variety; damage could reset rank; high ranks could trigger bonus spells (for example a screen-clearing S-rank reward). Idea only; protect slower typists from compounding disadvantage.
- Preserve preference for Cross Blade’s original single large blade and positive feedback that the game is fun. Summoned flying knives are a separate spell idea.
- Investigate Space versus selected-spell completion behavior, Enter sounding like damage, a reported zero-HP survival case, and difficulty typing two-word spells. Reports are unverified, not fixes.

## Approved playtest follow-up — 2026-09-28

See [bounded scope and deferred feedback](docs/PLAYER_FEEDBACK.md#approved-playtest-follow-up--2026-09-28). Deliver recovery pickups, tree ordering, XP tiers, casting/combination fixes and compact HUD clarity before the browser playtest. Leave rocks, Swarmers and difficulty curves untouched. Preserve movement/landmark/map/relic ideas for later.

## Ritual incantations — 2026-09-28

- [Multi-stage casting / Explosion](docs/CASTING_FANTASY_NOTES.md#multi-stage-ritual-casting--2026-09-28-idea): preserve the long chant → final word → screen-wide payoff concept. Explore one logical cast with finite slowdown and either continuous or checkpointed commitment; no implementation yet.

## Mystical names and relic abilities — 2026-09-28

- [Naming and relic proposal](docs/expedition-design/03-spells.md#mystical-vocabulary-and-relic-granted-abilities--follow-up): Boots of Hermes could unlock quick Dash; Yggdrasil exemplifies the desired ultimate-spell fantasy; Meteor Shower may receive a more evocative name later. Names may draw on mythology/familiar media; short reactive commands remain an exception. Design only.

## Naming and boss idea — 2026-09-28

- Use magical player-facing names; the root-wave spell’s intended mystical name is retained as a naming requirement; Shillelagh is confirmed. Trace names to earlier folklore/mythology sources where available; popular fantasy is also acceptable inspiration.
- Preserve [The Disruptor](docs/expedition-design/06-levels.md#deferred-boss-idea--the-disruptor-2026-09-28), a boss that corrupts incantations without changing their length. Frequency and exact scrambling rules remain undecided; idea only.
- Prioritize local playable updates; routine shareable packaging is optional.

## New ideas captured — 2026-09-28

- [Storm aura, root wave, Dash, Swiftness and accumulated mana](docs/expedition-design/03-spells.md#storm-aura-roots-and-wizard-movement--2026-09-28-ideas): design exploration, with explicit geometry, timing, names, categories and unresolved decisions. Tracked as I13–I17 in player feedback. No implementation authorized by recording these ideas.

## Current balance implementation — 2026-09-28

[Current balance details and verification limits](docs/PLAYER_FEEDBACK.md#current-balance-pass--2026-09-28): lower Regeneration/trap damage, explicit boss budgets, faster second-boss dash, radial Cross Blade progression and mixed Meteor Shower count/area ranks. The older proposals below are retained history; this section is current.

- Cross Blade progresses triangle → X → size/range → pentagon → range → hexagon across eight ranks, with weaker individual blades.
- Meteor Shower progresses from two to eight meteors with separate area ranks and weighted on-screen targeting.
- Spawn pressure rises gently through minute10, ramps after13, and reaches light0.9s / medium0.6s / heavy0.3s by17. Next human pass: boss difficulty, post-boss recovery, maximum blade overlap, and late-game crowding/performance at the160-enemy cap.

Current playtest tuning (2026-09-28): ambient spawns repeat the approved two-minute light/medium/heavy rhythm. Future batch-size thresholds can increase rolls per tick; scheduled horde waves remain separate.

# Current slate — difficulty scaling first

See [Player feedback](docs/PLAYER_FEEDBACK.md) for open, deferred and verified items. Preserve current roguelike progression; validate opening and minutes 3–8 pressure while protecting the liked 9–11 minute escalation. Random health-potion drops, forest paths and rocks are later ideas. Keyword composition and the tower/expedition package remain future experiments.

> Current direction: **Should Have Joined a Party**, a wizard action game using language to express complex magic. Evolve the existing playable game through keywords, preparation and persistent discoveries. Readable inscriptions replace keycap branding. See the [current design and development roadmap](docs/expedition-design/README.md). Older prototype descriptions, plans and marketing language below are historical, not the current target specification.

- Use [Development order](docs/expedition-design/15-development-order.md) for concrete playable milestones, separate from campaign unlock timing. That future sequence does not replace the current difficulty-first slate.

## Next balance review — latest playtest (2026-09-28)

- [Rune Trap and boss targets](docs/PLAYER_FEEDBACK.md#rune-trap-and-boss-target-refinement--2026-09-28): review trap pre-placement strength; proposed final boss HP 1,200 / 1,800 with a faster second boss. Exact speed and trap tuning remain open.

- [F36–F39: Regeneration, Meteor Shower, Cross Blade and boss HP](docs/PLAYER_FEEDBACK.md#latest-balance-playtest--2026-09-28) capture the latest observations and source audit.
- Set lower/slower rank-one healing; choose two or three starting meteors with count or damage growth per rank and better visible-enemy coverage; investigate Cross Blade utility; give bosses deliberate health budgets rather than inheriting ordinary-enemy disparities.
- These are recorded tuning directions, not implemented changes or approved exact numbers. Cross Blade's return-damage candidate remains deferred below.

## Deferred — Cross Blade return-hit identity (2026-09-28)

- Alternative proposed in follow-up: four smaller, weaker spinning blades launched in a cross and returning to the caster. Budget total damage and large-enemy overlap before selecting values; orientation and linger remain undecided. See [follow-up details](docs/PLAYER_FEEDBACK.md#follow-up-proposals-and-boss-damage-context).
- Intent: make the returning blade the payoff, rewarding positioning to catch enemies on its way back and giving Cross Blade a distinct reason to use.
- Tentative options from playtesting: double damage on return; alternatively reduce overall/base damage by 25% and increase return damage by 50%. These are alternatives to test, not approved balance values.
- Open: whether the 50% return increase is relative to the reduced base or the current return damage. Resolve that reference before tuning; compare outbound-only hits, both passes and total damage per cast.
- Status: explicitly deferred by the player. Keep current gameplay unchanged until a later balance pass. Tracked as [I12](docs/PLAYER_FEEDBACK.md#future-design-and-art-ideas).

## Idea — elemental vocabulary tiers

- Explore base forms such as Wall combined with increasingly elaborate elemental words. See section 13 of [the spell-system reference](docs/expedition-design/14-spell-system-reference.md#13-idea-base-forms-with-elemental-word-tiers). Idea only; compare against paired incantation tiers before choosing a system.

## Spell component reference — September 28, 2026 (design only)

- [Reusable components, properties, keyword bindings and spell recipes](docs/expedition-design/14-spell-system-reference.md) now define the proposed data-driven spell foundation.
- Review Big's per-recipe meaning, unsupported modifier pairings, expanding-front versus projectile cones, and infection lifecycle before implementation. Future spell data should generate reference tables and workshop controls from the same schema.

## Expedition direction — September 27, 2026 (design proposal)

- Separate design package: [Expedition design](docs/expedition-design/README.md). This proposes permanent spell and keyword discovery, prepared spell order, mana activation, authored/procedural realm routes and optional guardians.
- Review its decision register before implementation. The current playable prototype and historical roadmap below remain unchanged in behavior.
- First candidate: tutorial plus Verdant Ruins, with a separate composition test profile for later words and Meteor Shower. Expand the remaining realms only after observed player evidence supports the loop.
- Preserve later ideas: elaborate mastery words, typed menus, numeric delay syntax, alternate characters, slime/wizard animation, shaders and eventual asset replacement. These are not silently included in the first slice.

## Encounter pressure — September 27, 2026

- Implemented: camera-aware regular spawns, distant normal enemies reentering from a different offscreen angle with health/status intact, and eight timed staggered melee rushes. Rush enemies chase normally and recycle like other normal enemies; these are not passing formations. Bosses never recycle.
- Next: tune rush size/spacing and recycled pressure through human playtests; distinct passing hordes remain a later design option.

## Integrated baseline — September 26, 2026

- Implemented: per-cast focus, six active/six passive slots, additive bonus spells, Life/Regeneration separation, healing-seed Life Bolt, simple readable effects, cone Ice Blast, personal Earth Shield, clustered forest and reduced-effects preference.
- Seven passive families currently work. Area, Multicast, XP gain, Luck, critical stats and enemy population remain design work; they are not offered as nonfunctional upgrades.
- Next human pass: long-incantation payoff, boss pressure, and crowded effect readability. Do not equate bot survival or assertion counts with fun.

## Current pass — ordinary build inspection

- Expose owned spells, slot-free bonuses, passive ranks and discoveries in the pause spellbook. Larger existing key art improves readability without an art-production expansion.
- Typed menu navigation, elaborate art, shaders and audio redesign remain deferred.
## Forest groves and XP readability — 2026-09-26

- Implemented: irregular deterministic tree/bush groves, occasional lone trees, and empty ground instead of one tree per evenly spaced cell. The starting clearing and connected routes remain open; only tree trunks block movement, with their collision radius reduced from 22 to 11 pixels while canopy art keeps its size.
- Implemented: mana crystals render at 1.5× their previous size, including their pulse, with unchanged pickup and XP mechanics.
- Later: human-test crowded combat around groves and canopy readability at the chosen camera scale. Additional terrain types and environmental gameplay remain separate design work.
## Casting foundations — 2026-09-27

- Implemented foundation: fresh per-cast slowdown, six primary slots, six distinct passive families, independently ranked bonus ownership and current-run casting gates.
- Supported offers: spell power, movement, health, pickup range, projectile speed, Focus duration and bundled Mana Mastery. Other catalog families remain unavailable until their effects are implemented.
- Integration pending: bouncing Lightning Bolt, collectable Life Bolt healing seeds, effect-side projectile speed, bonus access in the player spellbook and complete geometry/feedback review.
- Working acquisition policy: bonus choices begin at rank 1; ingredients retain their slots/ranks. Innate automatic Mana Bolt is free; its first mastery upgrade occupies a passive family.

## 2026-09-26 — Simple art matched to supplied assets (documentation only)

- Record the user's direction to follow the friend's supplied art style closely, reuse existing assets and keep additions simple placeholders.
- Limit art work to the repaired current roster and selected additions. Treat effect lifecycles as readability requirements, not demands for elaborate bespoke animation. Shaders and audio remain deferred.

## 2026-09-26 — Table coverage audit (documentation only)

- Move remaining modifier phrases and broader saved concepts into explicit status/source tables in the [spell library](docs/SPELL_LIBRARY.md); preserve the full discussion notes as supporting detail.
- Record alternate-name references and unnamed Whip variants without counting them as implemented spells. Correct the historical notes' stale equipped-slot reference to the superseding six-slot rule.

## 2026-09-26 — Spell direction accepted

- Frost Nova is an endorsed future selection candidate: circular coverage distinct from directional Ice Blast. Repair the current roster first; select additions deliberately. Detailed tuning and remaining system design still need resolution.

## Later — shaders

- Shader development and shader-based visual polish are deferred by user decision. Revisit after the current gameplay, spell readability, art and UX baseline is settled. No shader implementation is included in the current pass.

## 2026-09-26 — Spell geometry contracts (documentation only)

- Correct Ice Blast to the user-confirmed directional cone and retain radial Frost Nova as a distinct idea.
- Add geometry and targeting to the full library, plus detailed origin, dimensions, timing, collision and upgrade requirements for current spell families.
- Require ordinary VFX to communicate the real affected shape; reserve exact hitbox overlays for opt-in debug. Keep unapproved shape and aim choices explicitly proposed.

## 2026-09-26 — Preserve the baseline and separate debug from play (documentation only)

- Keep and repair the implemented roster; select library expansions separately instead of silently replacing existing spells.
- Define normal play, ordinary spellbook and opt-in debug as distinct information surfaces. Keep technical overlays and test controls out of normal runs.
- Record Earth Wall/Earth Walls separately from Earth Shield, retain Thunderwave as a user concept, and leave protective versus terrain behavior explicit for design selection.

## 2026-09-26 — Complete spell library and naming feedback (documentation only)

- Add the [full spell library](docs/SPELL_LIBRARY.md) with individual status, source, letter count, fantasy and visual identity rows. Preserve user concepts, inactive drafts and name alternatives; add clearly labelled water, sun, earth and arcane suggestions. Rows are not a promised playable spell count.
- Separate quick Life (about 4 HP) from stronger Regeneration, specify straight non-homing Bolt, document Seeker versus stronger Seeking Spirit, recommend Firewalk as a working trail name, and revise Earth Shield toward damageable terrain which decays.
- Reopen affected recipes explicitly rather than silently mapping Life Bolt or Reaping Spirit to new ingredients. Keep implementation, generated art and merges paused for design review.

## 2026-09-26 — Design reconciliation before implementation

- Consolidate playtest feedback into [core design v0.4](docs/CORE_GAME_DESIGN.md), the [spell/passive catalog](docs/SPELL_AND_UPGRADE_CATALOG.md), [art and feedback matrix](docs/ART_AND_FEEDBACK_PLAN.md), and [agent delivery plan](docs/PLAYTEST_REWORK_PLAN.md).
- Record six active/six passive slots, additional slot-free combinations, distinct Bolt/Lightning/Lightning Bolt, per-cast slowdown, useful long-incantation payoff, readable effects and revised opening pressure. These are intended rules, not completed runtime changes.
- Preserve frozen implementation branches and distinguish canonical build, remote UI changes and candidate evidence. Resume implementation only after design approval.
- Keep Moonfall, Tree of Life, Grasping Hand, modifier words, alternate starters, map challenges, typed menus and audio separately scoped or deferred; do not silently add them to this pass.

## Minimal player information implemented — 2026-09-26

- Normal play shows essential state; boss arrival timing is hidden until the boss arrives.
- Upgrade cards use a name and one concrete sentence, with exact effect values and concise evolution trade-offs. No categories, current-stat paragraphs or slot commentary in normal choices.
- Diagnostics remain available: F3 toggles detailed HUD/cards/endings; open the console with backtick and run `ui_debug on`, `ui_debug off` or `ui_details` for full mechanics and run data.
- Next: human-test first-run clarity and compact choices; retain current mouse and keyboard selection until typing-based navigation is designed.

## Stone-letter menus implemented — 2026-09-26

- Menu actions, headings, upgrade names, and discovered recipe titles use the generated letter keys; descriptions retain normal typography.
- Existing click and keyboard navigation remains active. Typing to select choices is still a later feature.

## XP pickup art — 2026-09-26

- Implemented: cyan mana crystals replace square XP placeholders.
- Later: consider larger-value crystal clusters or rare star-shaped pickups with explicit gameplay meaning; do not imply value tiers through random colors.

## Casting presentation implemented — 2026-09-26

- Combat typing places animated stone letter keys with impact sounds; backspace shatters and fades the removed key. Successful casts briefly flash their completed word. A–Z, 0–9, and standard punctuation share the 32×32 key size; punctuation assets do not expand current spell input rules.
- The supplied staff floats on a capped-speed orbit around the wizard, indicating the nearest visible living threat with visible-boss priority. Existing attack targeting is unchanged.
- Later: human-test impact volume and animation pace, animate separate wizard body parts, and decide whether any future spell incantations need punctuation.

## Saved future concepts from friends — 2026-09-26

Documentation only; see [the full concept notes](docs/CASTING_FANTASY_NOTES.md#saved-friend-concepts--september-26-2026).

- Discoverable map locations offering a timed sequence of difficult words, potentially creating leylines or unlocking a reward. XP delay/loss is an undecided risk proposal.
- A computer-mouse final boss: unrestricted movement directions and two attacks versus keyboard movement and a broad spell kit; possible skill-versus-speed lore.
- A spell-catalog Easter egg tied to the number of keys on a keyboard, with the exact count and interpretation left open.
- Preserve current run rules, diagonal movement, and equipped-spell limits until an implementation is explicitly designed and approved.

## Later: type-to-navigate menus — 2026-09-26

- Deferred: type words to navigate menus or select level-up rewards and spells. Keep existing mouse and keyboard navigation for now.
- This is separate from displaying typed combat-incantation letters on the supplied keycap art; deferring menu navigation does not defer that casting presentation.
- Before implementation, settle selection words and input handling so keystrokes from combat cannot accidentally select a newly opened upgrade or menu action.

## Authored interface art — 2026-09-26

- Keycap textures now serve menu/action buttons and spell shortcuts; menu scenery uses the supplied grass and resting slime. Both tree and king-slime variants are in use.
- Remaining logo-letter and key variants are preserved as alternatives. A matching 32×32 casting alphabet, digits, and punctuation are implemented; layered character animation remains future work.

## Art integration — 2026-09-26

- Integrate the supplied Typecast pixel art: assembled wizard, melee slimes, king bosses, ranged wisps, grass variants, tree obstacles, bushes, keyboard logo, and health frame. Keep spell effects without supplied replacements as placeholders.
- Preserve separate wizard hat, face, robes, and staff assets for a later layered animation pass; no animation rig is implied by this static swap.
- Follow up with authored walk/cast animation and obstacle-aware bot behavior after playtesting sparse forest traversal.

## Current agreed next mechanics — September 26, 2026

Keep the survivors premise; do not pivot to siege or alchemy now. See [Core Game Design](docs/CORE_GAME_DESIGN.md#4-typing-is-a-core-combat-system) for the authoritative per-cast slowdown decision and [supporting upgrades / Multicast](docs/CORE_GAME_DESIGN.md#supporting-upgrade-categories--agreed-design) for the agreed stat categories.

- Pending: replace the shared slowdown reserve/refill with a fresh finite window on every cast; fixed strength, upgradeable duration, configurable negligible inter-cast delay.
- Pending: spell-appropriate Multicast, adding one bolt, meteor, jump, healing pulse, or other defined output after one typed cast rather than duplicating the entire spell.
- Pending: expand supporting stats and bundle Mana Bolt damage/rate/count. Keep secondary-slot limits, luck outcomes, and global-stat interactions with Mana Bolt explicitly unresolved.
- Long learned incantations must justify their commitment with major payoff, while quick basic spells remain useful.

Older milestone entries below are historical. Mentions of shared slowdown/refill describe the shipped prototype, not the newly agreed target. This documentation update does not implement these mechanics.

# SpellCast Survivors: Roguelite Transformation Roadmap

## Current gameplay priority — September 2026

The fifteen-spell, five-slot progression loop and seven hidden evolutions are implemented. The latest content adds a focused beam, proximity trap, seeking spirit, movement trail, and returning blade. The focused readability pass is complete. The gameplay interaction pass addresses casting recovery, clickable spell selection, keyboard choices, and defeat explanations. Evaluate ordinary runs for: acquisition clarity, typing feedback, slowdown recharge, combat contrast, and informative run results. UI sizing must remain independent of world-camera scale. Then playtest naturally earned builds, bosses, and a full 20-minute victory before tuning difficulty or commissioning a full art overhaul.

Evolutions now carry explicit tactical costs, and ordinary offers preserve a non-evolution alternative. Life Bolt uses its existing single-projectile cost instead of a blanket damage nerf. Compare equal-investment base-heavy and evolved runs for survival, crowd control, sustain, and boss damage before changing these initial tradeoff values.

Next content evaluation: measure ordinary acquisition and discovery frequency with the larger catalog; distinguish missed ingredients from broken recipes. Evaluate movement trails, trap preparation, sustained tracking, and returning attacks in real builds before changing offer odds or damage numbers.

Future visual work: cohesive enemy silhouettes and animation, spell-effect identity under crowded combat, optional interface scaling, and reduced-motion preferences. These should follow evidence from the gameplay pass rather than adding more content to mask pacing issues.

## Project Vision
Transform SpellCast Survivors from a simple vampire survivors clone into a comprehensive roguelite experience with persistent progression, character classes, exploration, and deep customization while maintaining the unique typing-based spell casting mechanic.

## Core Pillars
1. **Typing-Based Combat**: Preserve the core spell casting mechanic that differentiates us
2. **Meta-Progression**: Long-term progression that persists between runs
3. **Character Diversity**: Multiple classes with unique playstyles and progression paths
4. **Exploration**: Large, handcrafted maps with secrets and rewards to discover
5. **Build Variety**: Deep customization through active spells + passive modifiers

---

## Phase 1: Character Classes & Starting Variations

### Character Selection System
- **Main Menu Integration**: Add character selection before starting new game
- **Character Profiles**: Visual design, lore, and mechanical identity for each class
- **Preview System**: Show starting spells, stats, and unlocked content per character

### Initial Character Classes
1. **Arcane Scholar** (Default/Tutorial Class)
   - Starting Spells: Mana Bolt, Bolt
   - Trait: +15% spell damage, spells unlock 1 level earlier
   - Playstyle: Balanced spellcaster, good for learning

2. **Battle Mage** 
   - Starting Spells: Mana Bolt, Ice Blast
   - Trait: +25% max health, +10% movement speed
   - Playstyle: Aggressive close-range caster

3. **Life Weaver**
   - Starting Spells: Mana Bolt, Life
   - Trait: +50% healing effectiveness, Life spell also grants movement speed
   - Playstyle: Sustain-focused survival specialist

4. **Storm Caller** (Unlocked via meta-progression)
   - Starting Spells: Mana Bolt, Lightning Arc
   - Trait: +20% cast speed, chain spells hit +1 additional target
   - Playstyle: Chain reaction specialist

5. **Meteor Summoner** (Unlocked via meta-progression)
   - Starting Spells: Mana Bolt, Meteor Shower
   - Trait: Area spells deal +25% damage, +15% area of effect
   - Playstyle: High-risk, high-reward AoE focused

### Character Progression Features
- **Mastery Levels**: Each character gains experience independently
- **Class-Specific Unlocks**: New starting spells, passive bonuses, cosmetics
- **Mastery Rewards**: Permanent upgrades that carry across all runs with that character

---

## Phase 2: Meta-Progression System

### Account-Wide Progression
- **Total XP Tracking**: Cumulative XP earned across all runs and characters
- **Account Levels**: Long-term progression (Level 1-100+) that unlocks content
- **Milestone Rewards**: Major unlocks at specific account levels (new characters, spells, etc.)

### Progression Categories
1. **Character Unlocks**: New classes, starting spell variations
2. **Spell Library**: Discover and unlock new spells for the global pool
3. **Passive Item Pool**: Unlock new passive modifiers
4. **Map Access**: Unlock new biomes and areas to explore
5. **Quality of Life**: Larger starting resources (rerolls, locks, etc.)

### Save System Architecture
```json
{
  "account": {
    "total_xp": 15420,
    "account_level": 23,
    "unlocked_characters": ["scholar", "battle_mage", "life_weaver"],
    "unlocked_spells": ["bolt", "life", "ice_blast", "earth_shield", "lightning_arc"],
    "unlocked_passives": ["spell_power", "cast_speed", "health_boost", "xp_magnet"]
  },
  "characters": {
    "scholar": {"mastery_xp": 5200, "mastery_level": 8, "games_played": 12},
    "battle_mage": {"mastery_xp": 3100, "mastery_level": 5, "games_played": 7}
  },
  "statistics": {
    "total_games": 19,
    "best_time": 1247,
    "highest_level": 28,
    "total_enemies_killed": 8934
  }
}
```

### Progression Rewards Examples
- **Account Level 5**: Unlock Battle Mage class
- **Account Level 10**: Start runs with 1 additional reroll
- **Account Level 15**: Unlock Storm Caller class  
- **Account Level 20**: Unlock Cave biome
- **Account Level 25**: Start runs with 1 additional passive slot
- **Scholar Mastery 5**: Can start with Bolt + Life unlocked
- **Battle Mage Mastery 8**: Ice Blast starts at level 2

---

## Phase 3: Active/Passive Item System

### Active Spell Slots (6 Maximum)
- **Current System Enhancement**: Existing spells become "active items"
- **Spell Discovery**: Find new spells during runs through exploration
- **Spell Synergies**: Combinations that modify behavior (e.g., Ice + Lightning = Frozen Lightning)

### Passive Modifier System (6 Slots)
Transform the current generic upgrades into a robust passive item system:

#### Damage Passives
- **Spell Power I/II/III**: +10%/20%/35% spell damage
- **Critical Strikes**: 15% chance for 2x damage
- **Elemental Mastery**: +25% damage to specific element, spells of that element gain bonus effects
- **Spell Echo**: 10% chance for spells to cast twice
- **Overcharge**: Spells cost more to cast but deal significantly more damage

#### Utility Passives  
- **Arcane Intellect**: +2 spell queue slots, +15% cast speed
- **Time Dilation**: Spell casting time dilation increased to 15% (from 20% speed)
- **Mana Efficiency**: Shorter spell names required, typing errors forgiven
- **Spell Steal**: Killing enemies has chance to grant temporary spell upgrades
- **Metamagic**: Can modify spell effects by typing variations (boltfast, icebig, etc.)

#### Defense Passives
- **Barrier**: Regenerate overheal over time
- **Spell Armor**: Taking damage reduces all cooldowns
- **Blink**: Perfect dodging through enemies when casting spells
- **Life Tap**: Convert health to spell power (risk/reward)
- **Guardian Spirit**: Death triggers powerful area spell and revival (once per run)

#### Mobility Passives
- **Swift Cast**: Movement speed increases while casting
- **Teleport Mastery**: Short-range teleport on spell completion
- **Hover**: Brief flight after casting area spells
- **Phase Walk**: Walk through enemies briefly after taking damage
- **Sprint Casting**: Can move at full speed while typing

### Passive Item Rarity & Power
- **Common** (White): Simple stat boosts, always available
- **Rare** (Blue): Unique mechanics, moderate power, unlocked through progression  
- **Epic** (Purple): Game-changing effects, high power, rare drops
- **Legendary** (Gold): Run-defining items, extreme rarity, major meta unlocks

### Synergy System
Certain passive combinations create powerful effects:
- **Spell Power III + Critical Strikes** = Crits deal 3x damage instead of 2x
- **Time Dilation + Swift Cast** = Gain speed boost after each spell for 3 seconds
- **Barrier + Life Tap** = Life Tap generates overheal instead of consuming health

---

## Phase 4: Large Explorable Maps

### Map Design Philosophy
Move away from infinite procedural arenas to handcrafted, interconnected areas that reward exploration while maintaining the survival gameplay loop.

### Biome System
1. **Mystic Forest** (Starting Area)
   - Open clearings connected by paths
   - 15-20 minutes to fully explore
   - Enemies: Basic types, introduction to mechanics
   - Secrets: Hidden spell shrines, XP caches

2. **Ancient Ruins** 
   - Multi-level stone structures with verticality
   - Narrow corridors and large chambers
   - Enemies: Armored types, spell-resistant foes
   - Secrets: Lore tablets, powerful passive items

3. **Crystal Caves**
   - Labyrinthine underground network
   - Environmental hazards (falling crystals, unstable ground)
   - Enemies: Swarm types, crystal-based creatures
   - Secrets: Rare spell variants, mastery XP bonuses

4. **Elemental Plane** (End-game)
   - Shifting magical landscape with multiple sub-areas
   - Each section themed around different elements
   - Enemies: Elite elemental beings, boss encounters
   - Secrets: Legendary items, character unlocks

### Navigation & Flow
- **Minimap System**: Shows explored areas, points of interest, and objectives
- **Waypoint System**: Fast travel between discovered checkpoints
- **Objective Markers**: Guide players toward major encounters and secrets
- **Backtracking Rewards**: Previously cleared areas respawn with different loot

### Environmental Interactions
- **Destructible Objects**: Walls, crystals, furniture that may hide secrets
- **Spell-Activated Doors**: Barriers that require specific spells to pass
- **Pressure Plates**: Timed challenges that require positioning and spell timing
- **Elemental Puzzles**: Use appropriate spells to unlock secret areas

---

## Phase 5: Treasure & Loot Systems

### Treasure Chest Types
1. **Wooden Chests** (Common)
   - 1-2 passive items (common rarity)
   - Small XP bonus
   - Basic consumables

2. **Crystal Chests** (Rare)  
   - 2-3 passive items (rare+ rarity guaranteed)
   - Significant XP bonus
   - Spell upgrade materials

3. **Ancient Coffers** (Epic)
   - 3-4 items (epic+ rarity guaranteed)
   - Major XP bonus
   - Guaranteed spell unlock or upgrade

4. **Legendary Vaults** (1 per biome)
   - 4-5 items (legendary guaranteed)
   - Massive XP bonus
   - Character mastery XP
   - Unique unlocks

### Loot Distribution Strategy
- **Guaranteed Progression**: Each run should provide meaningful advancement
- **Exploration Rewards**: Hidden chests contain better loot than obvious ones
- **Risk/Reward**: Dangerous areas have proportionally better rewards
- **Diminishing Returns**: Later chests in same run have slightly reduced rewards

### Interactive Loot Objects
- **Spell Shrines**: Upgrade a specific spell by 1 level
- **XP Crystals**: Large chunks of experience points
- **Ancient Tomes**: Unlock new spell variations or passive items
- **Mastery Stones**: Grant character-specific mastery experience
- **Enchanted Fountains**: Temporary powerful buffs for remainder of run

### Loot Feedback Systems
- **Visual Telegraphing**: Chest rarity clearly indicated by appearance and glow
- **Audio Cues**: Distinct sound effects for different treasure types
- **Particle Effects**: Magical sparkles and auras that scale with value
- **Discovery Notifications**: Clear UI feedback when finding rare items

---

## Phase 6: Expanded Spell Pool

### Spell Categories & Examples

#### Offensive Spells
**Current:** Bolt, Ice Blast, Lightning Arc, Meteor Shower, Mana Bolt
**New Additions:**
- **Fire Ball** (8 letters): Single-target high damage with burning DoT
- **Chain Lightning** (14 letters): Bounces between enemies, damage increases per bounce  
- **Arcane Missiles** (15 letters): Rapid-fire homing projectiles
- **Void Blast** (9 letters): Pierces through all enemies in line
- **Earthquake** (10 letters): Ground-based AoE that travels outward
- **Solar Flare** (10 letters): Delayed massive damage in large area

#### Defensive Spells  
**Current:** Life, Earth Shield
**New Additions:**
- **Barrier** (7 letters): Temporary damage immunity shield
- **Teleport** (8 letters): Instant movement to cursor position
- **Time Stop** (8 letters): Freeze all enemies briefly
- **Mirror Image** (11 letters): Create decoys that confuse enemies
- **Sanctuary** (9 letters): Create safe zone that damages enemies entering

#### Utility Spells
- **Haste** (5 letters): Temporary massive movement speed boost
- **Invisibility** (12 letters): Become undetectable for short duration
- **Magnetism** (9 letters): Pull all XP and items to player
- **Phase Shift** (10 letters): Walk through enemies and walls briefly
- **Amplify** (7 letters): Next spell cast deals double damage

### Spell Discovery System
- **Run Rewards**: Complete specific objectives to unlock spells temporarily
- **Exploration**: Find spell tomes hidden throughout maps
- **Meta Progression**: Permanent unlocks through account levels
- **Character Mastery**: Class-specific spell unlocks through mastery progression
- **Achievement Rewards**: Complete challenges to discover unique spell variants

### Spell Mastery & Variants
- **Individual Spell Levels**: Each spell can reach level 8 independently
- **Mastery Unlocks**: High-level usage unlocks variant versions
- **Spell Mutations**: Rare variants with altered properties
  - **Bolt** → **Thunder Bolt**: Adds chain lightning effect
  - **Ice Blast** → **Frost Nova**: Adds slowing field
  - **Life** → **Greater Heal**: Also affects nearby allies (if multiplayer added)

### Build Diversity Goals
- **Elemental Specialist**: Focus on one damage type with synergistic passives
- **Utility Mage**: Emphasize mobility and battlefield control
- **Glass Cannon**: Maximum damage output with defensive spell reliance  
- **Sustain Tank**: Health, shields, and healing for extended survival
- **Hybrid Builds**: Balanced approaches with flexibility

---

## Implementation Timeline & Priorities

### Phase 1: Foundation (4-6 weeks)
1. **Character Selection System**: UI, data structures, basic class differences
2. **Save System**: Meta-progression data persistence
3. **Character Classes**: Implement 3 initial classes with unique traits

### Phase 2: Core Systems (6-8 weeks)  
1. **Passive Item Framework**: Slot system, item effects, UI integration
2. **Meta-Progression**: Account levels, unlock system, progression rewards
3. **Expanded Spell Pool**: Add 8-10 new spells with discovery mechanics

### Phase 3: Content Expansion (8-10 weeks)
1. **Map System**: Replace infinite arena with interconnected areas
2. **Treasure System**: Implement various chest types and loot distribution
3. **Advanced Passives**: Complex passive items with synergies

### Phase 4: Polish & Balance (4-6 weeks)
1. **Biome Completion**: Multiple themed areas with unique content
2. **Balance Pass**: Tune progression curves, item power levels
3. **UI/UX Refinement**: Improve all interfaces based on expanded systems

### Phase 5: Advanced Features (6-8 weeks)
1. **Achievement System**: Challenges that drive engagement and unlocks
2. **Statistics Tracking**: Detailed analytics for progression and balance
3. **Endgame Content**: High-level challenges for veteran players

---

## Technical Considerations

### Save System Requirements
- **Cross-Platform Compatibility**: JSON format for easy portability
- **Backup System**: Prevent save corruption and data loss
- **Migration Support**: Handle save format changes across updates
- **Security**: Basic tamper resistance for competitive integrity

### Performance Targets
- **Large Maps**: Efficient culling and LOD systems for complex areas
- **Many Items**: Object pooling for passive effects and visual feedback
- **Smooth Gameplay**: Maintain 60fps even with many simultaneous effects

### Scalability Planning
- **Modular Architecture**: Easy addition of new spells, items, and mechanics
- **Data-Driven Design**: JSON configs for easy balance adjustments
- **Plugin System**: Framework for potential community content

---

## Success Metrics

### Player Engagement
- **Session Length**: Target 30-45 minute average run times
- **Retention**: 70%+ players return within 1 week
- **Progression Feel**: Clear advancement every 2-3 runs

### Content Depth
- **Build Variety**: 15+ viable endgame builds across all characters
- **Replayability**: 50+ hours of content before repetition sets in
- **Discovery**: Secrets and unlocks that reward thorough exploration

### Core Mechanic Preservation
- **Typing Emphasis**: Spell casting remains central to all builds
- **Skill Expression**: Better typists have clear mechanical advantages
- **Learning Curve**: Accessible to newcomers while rewarding mastery

This roadmap transforms SpellCast Survivors into a comprehensive roguelite while preserving its unique typing-based identity and ensuring long-term player engagement through meaningful progression and discovery systems.
## September 2026 encounter milestone

Implemented the forgiving opening, regeneration repair, twelve enemy variants, timed ranged introductions and three boss milestones and immediate victory at 20:00. Next: introduce spell acquisition and combinations, then broader balance, art direction and release qualification. Spell choices should reward behavior and playstyle without requiring elemental counters. See `docs/ENCOUNTER_DESIGN.md` for the current roster and remaining decisions.

Design review: [Core Game Design v0.2](docs/CORE_GAME_DESIGN.md) reconciles the agent proposal with the agreed direction. Its final section lists remaining choices; proposed systems and numerical experiments require review before implementation.

### Spell-acquisition milestone

Run-local acquisition now offers ten base manual spells, five equipped slots, and four authored evolutions. Bolt starts equipped and automatic Mana Bolt remains separate. Level-ups offer learning, owned-spell ranks and passives; at capacity, only eligible evolutions can change spells. Reroll/banish/lock resources remain unchanged. Arbitrary replacement and branching specializations remain future work.

Casting usability: keep the player visible and separate Escape cancellation from pausing. Next playtest must verify held movement, XP collection and an ordinary full run; the short stationary UI test does not qualify balance.

### Scripted baseline player

Developer bot tooling now supports repeatable movement/casting/upgrade runs and isolated progression profiles. Use it for mechanical regressions and multi-seed observations, not as proof of human difficulty or UI quality. Space casting, named hidden-recipe synergies and their persistent discovery menu remain next milestones. See `docs/BASELINE_BOT.md`.

### First hidden synergy playable

Space/Enter casting, movement lock while typing, Life Bolt acquisition and a persistent Spell Collection are implemented. Recipes are authored; arbitrary pairs do not combine. Discovery persists per save slot, while ownership resets each run. Evolutions replace their primary ingredient in its numbered slot and retain rank; catalysts remain equipped. Four authored recipes are implemented, and discoveries remain hidden until selected. Next: verify more recipe behaviors and tune with human play plus multi-seed bot reports; leave encounter difficulty unchanged for now.

### 2026-09-26 UI containment follow-up

- Completed: wrapping/content-sized upgrade cards, scrollable offers, bounded casting text, help markup.
- Next UI pass: make text physically readable at narrow window sizes; current canvas scaling makes menus small even though content is contained.
- Completed: shared three-second typing slowdown budget, ten-second refill outside typing, in-box countdown, and normal-speed casting after exhaustion.
- Mana Tempo (formerly Quick Cast) improves automatic Mana Bolt attack rate without weakening the three-second typing slowdown. Duration/refill upgrades remain a future experiment; current enemy difficulty is unchanged.

### Gameplay build expansion — September 26, 2026

Implemented Ember Lance, Plague Seed, Cinder Field and Arcane Orbit, plus Life Bolt, Meteor Lance, Soul Bloom and Steam Field evolutions. Five manual slots create build commitments. Next: full-run human play alongside multiple bot seeds, then tune spell value, discovery frequency and boss pressure from evidence. Graphics remain deferred. Consider explicit replacement choices and additional recipes only after this pool produces satisfying runs.

### Playtest hypotheses — September 26

- Measure boss health remaining and target access before tuning first-boss durability; automatic nearest-target behavior and random bot casts can obscure the cause.
- Compare uncollected XP against level timing before changing XP rewards.
- Compare damage while typing with total contact/projectile/blast damage; preserve a forgiving opening and basic-spell viability.

### Core fantasy exploration — September 26

See [typed magic discussion notes](docs/CASTING_FANTASY_NOTES.md) for the movement-versus-casting panic, possible gate-defense/tower-defense alternatives, and authored spell-language ideas. These are saved hypotheses, not committed features or an approved pivot. A proposed small-kit playtest should examine whether finishing a dangerous incantation feels worth giving up movement.

### Alchemist concept — September 26

Preserve the creator’s alternative of defending a tower by assembling and throwing potions: approximately ten ingredients available, up to four or five per potion, with greater preparation time buying greater potency. The desired emotional swing is from being overwhelmed to clearing the horde through a strong combination. Input method, recipe rules, resources, movement and progression remain open; see [the expanded concept notes](docs/CASTING_FANTASY_NOTES.md#alchemist-defending-a-tower). No pivot or prototype implementation has been approved.

- Casting foundation follow-up: cone geometry, direct Lightning, additive recipe tests and per-cast timing gates are implemented. Area, multicast, XP, luck, critical stats and population still need supported gameplay contracts before entering the passive offer pool.
### Opening pressure validation — September 26, 2026

The opening now uses a short pressure wave followed by recovery and later brief surges. Evaluate idle, movement-only, stationary casting and active play separately. Preserve active agency before demanding an exact death time for a kiting player. Next: repeat these behavioral comparisons after terrain, spell naming, projectile-speed upgrades and VFX integration; the changed draft pool can alter outcomes for the same seeds. Human play and longer active runs remain necessary before declaring production balance complete.

- Opening pressure follow-up: phase timer transitions and requested bot mode validation are covered; rerun provisional pressure values against the integrated per-cast slowdown and spell build before final tuning.

### Visual sandbox and spellbook follow-up — September 27, 2026

- Keep the native spell/particle comparison gallery as the reference for readable sizes, with a wizard beside every effect. Extend sampled playback to smooth looping animations or GIF/video exports that show complete casts, including meteor descent and impact.
- Proposed developer-only browser sandbox: wizard, enemy-variant, tree/bush, projectile and particle size sliders; camera zoom; reset-to-current-game defaults; side-by-side comparisons. Prefer native-rendered captures for faithful effects. A browser simulation is a separate approximation unless backed by the actual game renderer. Preview changes locally and require an explicit apply/export action before changing game values. This is an idea, not implemented or an approved scope expansion.
- Future slime animation: generate a small set of keyframes in the existing artist's simple pixel style, then test in-betweens/interpolation with nearest-neighbor rendering. Preserve crisp silhouettes and review each variant before expanding to all slimes; avoid blurred pixel transitions.
- Spellbook proposal: show spells discovered during the current run. A separate comprehensive Necronomicon contains the full catalog. Decide spoiler visibility and persistent-discovery presentation before implementation.
- Spell-art direction: simple, readable pixel art matching the supplied wizard/slime/environment assets; modest handmade detail is welcome. Prioritize distinct shapes, visible projectiles and clear damage/healing cues over polish. Steam Field's preview currently reads as healing to the player; audit its cue before any art overhaul.

### Visual workshop delivery — September 27, 2026

The approved pass implements the run-only Spellbook/full implemented Necronomicon split, focused readable spell art and a generated impact/smoke/ember/ice stamp sheet. The workshop uses the actual renderer and exports preview settings without applying changes to game files. Complete native clips and GIFs replace sparse gallery playback.

Remaining: after choosing baseline sizes, vary in-game tree and bush sizes by approximately 10–15%; keep preview reference sizes exact. Slime keyframe animation, persistent per-variant sizing presets, optional boss comparisons and shaders remain later work. Interpolation must preserve crisp pixels before adoption.

- Tabled: regenerating enemy archetype. Keep ongoing regeneration leaves separate from actual health-gain feedback when revisiting.
- Later: individual spell artwork polish after the current readability and playtest pass.

### Later interface polish
- Keep typed-menu navigation deferred; retain ordinary keyboard/pointer navigation for this release.
- Add accessibility preferences for independently scaling interface text and remapping shortcuts after the current readability baseline.
- Revisit spellbook layout/art alongside the spell-specific artwork pass; keep combat HUD minimal.

## Tower hub concept — 28 September 2026

Recorded the [rotary tower chamber and preparation book](docs/expedition-design/09-ui-accessibility.md#wizard-tower-rotary-destination-chamber): rotating room with roughly twelve stained-glass positions, top portal, tower-exit position, deck-like spell preparation and automatic deadline recall. Twenty minutes is the default; per-level curves/durations, book placement and possible 3D blockout are future exploration.
