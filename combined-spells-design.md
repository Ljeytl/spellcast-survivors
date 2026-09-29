# Combined Spells System Design

## Overview
Combined spells are powerful abilities unlocked when specific conditions are met, similar to weapon evolutions in Vampire Survivors. Players must have certain base spells at specific levels and meet additional requirements to unlock these devastating combinations.

## Base Spells (Reference)
1. **Bolt** (4 chars) - Basic projectile
2. **Ice Blast** (8 chars) - Freezing AoE
3. **Fire Wall** (8 chars) - Damage over time barrier
4. **Lightning** (9 chars) - Chain lightning
5. **Heal** (4 chars) - Self healing
6. **Meteor Shower** (13 chars) - Massive AoE damage

## Combined Spell Categories

### Elemental Fusions
These require two elemental spells at level 5+ and typing both names in sequence.

**Frost Lightning** (13 chars total)
- Requirements: Ice Blast (Level 5+) + Lightning (Level 5+)
- Activation: Type "frostlightning" 
- Effect: Chain lightning that freezes enemies and spreads ice damage
- Damage: 200% of combined base spell damage
- Special: Each chain creates ice explosions

**Meteor Fire Wall** (14 chars total)  
- Requirements: Meteor Shower (Level 5+) + Fire Wall (Level 6+)
- Activation: Type "meteorfirewall"
- Effect: Meteors create persistent fire barriers where they land
- Duration: Fire walls last 15 seconds
- Special: Meteors have 50% larger AoE

**Plasma Storm** (11 chars)
- Requirements: Lightning (Level 6+) + Fire Wall (Level 6+) 
- Activation: Type "plasmastorm"
- Effect: Continuous lightning strikes create burning plasma fields
- Duration: 20 seconds of storms
- Special: Plasma fields deal % max health damage

### Support Combinations
Mixing offensive spells with Heal creates defensive/utility combinations.

**Life Bolt** (8 chars)
- Requirements: Bolt (Level 4+) + Heal (Level 3+)
- Activation: Type "lifebolt" 
- Effect: Projectiles that heal player when they hit enemies
- Healing: 25% of damage dealt returned as health
- Special: Pierces through enemies

**Frozen Sanctuary** (15 chars)
- Requirements: Ice Blast (Level 6+) + Heal (Level 5+)
- Activation: Type "frozensanctuary"
- Effect: Creates healing ice dome around player
- Duration: 10 seconds of healing + freezing nearby enemies
- Special: Player gains 50% damage reduction inside

### Spell Evolution Tiers
Enhanced versions of base spells with different adjectives indicating power level and style.

#### Bolt Evolutions
**Major Bolt** (9 chars)
- Requirements: Bolt (Level 5) + 250 Bolt casts
- Effect: 200% damage, pierces 3 enemies
- Type: Straightforward power increase

**Seeking Bolt** (11 chars) 
- Requirements: Bolt (Level 6) + Lightning (Level 3)
- Effect: Auto-targets nearest enemy, moderate homing
- Type: Utility upgrade

**Ultimate Magic Missile** (16 chars)
- Requirements: Bolt (Level 8) + 1000 Bolt casts
- Effect: Massive projectile that splits into 8 seeking bolts on hit
- Type: Maximum power evolution

#### Meteor Evolutions
**Heavy Meteor** (11 chars)
- Requirements: Meteor Shower (Level 5) + 500 kills
- Effect: Fewer but much larger meteors with bigger AoE
- Type: Raw damage focus

**Meteor Rain** (10 chars)
- Requirements: Meteor Shower (Level 7) + Ice Blast (Level 5+)
- Effect: Continuous screen-wide meteor fall for 15 seconds
- Type: Duration/coverage upgrade

**Ancient Meteor Storm** (18 chars)
- Requirements: Meteor Shower (Level 8) + survive 30+ minutes
- Effect: Meteors leave permanent craters that deal DoT
- Type: Environmental modification

#### Heal Evolutions
**Greater Heal** (11 chars)
- Requirements: Heal (Level 4) + take 5000+ damage
- Effect: 300% healing + removes debuffs
- Type: Enhanced restoration

**Divine Tree** (10 chars)
- Requirements: Heal (Level 6) + Fire Wall (Level 4)
- Effect: Stationary healing tree with defensive barriers
- Type: Area control

**Sacred Yggdrasil** (15 chars)
- Requirements: Heal (Level 8) + all other spells Level 5+
- Effect: Massive world tree with multiple auras and attacks
- Type: Ultimate defensive structure

#### Ice Evolutions
**Frozen Blast** (11 chars)
- Requirements: Ice Blast (Level 5) + freeze 1000+ enemies
- Effect: Larger AoE, longer freeze duration
- Type: Crowd control focus

**Glacial Storm** (12 chars)
- Requirements: Ice Blast (Level 7) + Lightning (Level 6)
- Effect: Moving blizzard that follows player
- Type: Mobile area denial

#### Fire Evolutions
**Infernal Wall** (12 chars)
- Requirements: Fire Wall (Level 6) + burn 2000+ enemies
- Effect: Taller walls, spreads to nearby enemies
- Type: Enhanced barrier

**Eternal Flame** (12 chars)
- Requirements: Fire Wall (Level 8) + Heal (Level 6)
- Effect: Permanent fire zones that heal allies, burn enemies
- Type: Persistent battlefield control

#### Lightning Evolutions
**Forked Lightning** (14 chars)
- Requirements: Lightning (Level 5) + chain 500+ enemies
- Effect: Each chain splits into 2 more chains
- Type: Exponential spread

**Storm Lord** (9 chars)
- Requirements: Lightning (Level 8) + all elemental spells Level 6+
- Effect: Player becomes lightning conduit, continuous AoE strikes
- Type: Transformation ultimate

### Ultimate Combinations
Require 3+ spells at high levels and have extremely long typing requirements.

**Apocalypse** (10 chars)
- Requirements: Meteor Shower (Level 7+) + Lightning (Level 7+) + Fire Wall (Level 7+)
- Activation: Type "apocalypse"
- Effect: Screen-wide devastation combining all three elements
- Sequence: Lightning strikes → Meteors fall → Fire walls spread
- Cooldown: 60 seconds after casting

**Divine Intervention** (17 chars)
- Requirements: All 6 base spells at Level 6+
- Activation: Type "divineintervention" 
- Effect: Time stops, all enemies take massive damage, player fully heals
- Duration: 5 seconds of stopped time
- Special: One-time use per game session

## Unlock Mechanics

### Discovery System
- Combined spells are not revealed until unlocked
- Players must experiment with having required spells and levels
- Visual hints appear when requirements are nearly met
- Spell book UI shows "???" slots for undiscovered combinations

### Typing Requirements
- Combined spells require perfect typing (no errors allowed)
- Time dilation is reduced to 10% (vs 20% for normal spells)
- Longer typing sequences = more powerful effects
- Failed typing attempts have 10-second cooldown

### Level Requirements
- Base spells must be leveled through normal XP gains
- Combined spell levels are separate and gained through successful casts
- Each combined spell cast grants XP toward that combination
- Max combined spell level: 5 (vs 8 for base spells)

## Balance Considerations

### Power Scaling
- Combined spells are 2-3x more powerful than base spells
- Longer typing requirements offset increased power
- Higher risk/reward due to reduced time dilation
- Limited uses prevent spamming (cooldowns or resource costs)

### Progression Gates
- Early game: Focus on base spell mastery
- Mid game: First combinations unlock (Levels 4-5 requirement)
- Late game: Ultimate combinations (Levels 6-7+ requirement)
- Endgame: Perfect all combinations for maximum power

### Resource Management
- Combined spells could cost mana/energy in addition to typing
- Some combinations have limited uses per level
- Cooldowns prevent constant use of most powerful combinations
- Risk/reward of longer typing times in dangerous situations

## UI Integration

### Spell Queue Display
- Show available combinations when requirements are met
- Visual indicators for "ready to combine" states
- Progress bars for spell levels needed
- Hotkey assignments (Ctrl+1-6 for combinations?)

### Typing Interface
- Different visual styling for combined spell typing
- Progress indicators for long typing sequences
- Error highlighting more prominent due to no-retry policy
- Success celebrations for difficult combinations

## Implementation Priority

1. **Phase 1**: Implement 2-3 basic elemental fusions
2. **Phase 2**: Add support combinations with Heal
3. **Phase 3**: Create ultimate 3+ spell combinations
4. **Phase 4**: Polish discovery system and UI
5. **Phase 5**: Balance testing and difficulty tuning

This system adds significant depth while maintaining the core typing mechanic that differentiates the game from other Vampire Survivors clones.