# SpellCast Survivors: Roguelite Transformation Roadmap

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