# SpellCast Survivors
## Game Design Document

### Core Concept
A vampire survivors-style game where the player casts powerful spells by typing their names while fighting waves of enemies. Combines the strategic positioning of vampire survivors with the skill ceiling of typing speed and accuracy under pressure.

**Unique Selling Point**: Type spell names to cast them - longer/more complex spells are more powerful but leave you vulnerable while typing.

---

## Core Mechanics

### Movement & Basic Combat
- **Movement**: WASD keys for 8-directional movement
- **Auto-Attack**: Mana Bolt automatically fires at nearest enemy
- **Spell Casting**: Number keys (1-6) queue spells, then type spell name to cast
- **Time Dilation**: Time slows to 20% while typing spell names

### Control Scheme
```
WASD - Movement
1-6 - Queue spell slots
Type spell name - Cast queued spell
ESC - Cancel current spell
```

---

## Spell System

### Spell Progression Formula (8 Levels Max)

**Damage Scaling (Universal)**:
```
damage = base_damage * (1 + 0.15 * (level - 1))
```

**Cast Delay/Cooldown (Asymptotic)**:
```
delay = min_delay + (max_delay - min_delay) * (0.7 ^ (level - 1))
```

**Count/Area (Discrete Breakpoints)**:
```
count = base_count + floor((level - 1) / 3)
area_multiplier = 1 + 0.2 * floor((level - 1) / 2)
```

### Mana Bolt (Auto-Attack)
**Trigger**: Automatic, no input required
**Behavior**: Homing projectiles that target nearest enemy
**Base Stats**: 25 damage, 1.5s delay, 1 missile
**Progression**: Damage scales +15%/level, delay approaches 0.3s, missiles +1 every 3 levels

### Bolt
**Type**: "bolt" (4 characters - FAST)
**Behavior**: Generic magic projectile - single target, moderate damage
**Base Stats**: 50 damage, medium range, instant cast
**Progression**: Damage +15%/level, projectile count +1 every 3 levels, range +20% every 2 levels
**Balance**: Safe, reliable single-target damage with quick typing

### Life
**Type**: "life" (4 characters - FAST)
**Behavior**: Heal over time effect - gradual health restoration
**Base Stats**: 8 HP/second for 5 seconds (40 total), 6s cooldown
**Progression**: HP/sec +15%/level, duration approaches 8s, cooldown approaches 2s
**Balance**: Sustained healing, good for extended fights

### Ice Blast
**Type**: "ice blast" (8 characters - MEDIUM)
**Behavior**: Large AoE frost explosion, damages and slows enemies
**Base Stats**: 55 damage, large area, 2s slow
**Progression**: Damage +15%/level, area +20% every 2 levels, slow duration +0.5s every 2 levels
**Balance**: Good crowd control with moderate typing commitment

### Earthshield
**Type**: "earthshield" (11 characters - SLOW)
**Behavior**: Temporary damage-absorbing shield
**Base Stats**: 80 shield HP, 6s duration, 10s cooldown
**Progression**: Shield HP +15%/level, duration approaches 10s, cooldown approaches 4s
**Balance**: Strong protection but risky to cast under pressure

### Lightning Arc
**Type**: "lightning arc" (12 characters - VERY SLOW)
**Behavior**: Arcs between enemies, starting from nearest
**Base Stats**: 100 damage, 2 targets, medium chain range
**Progression**: Damage +15%/level, targets +1 every 2 levels, chain range +1 every 3 levels
**Balance**: Excellent multi-target damage but very vulnerable while typing

### Meteor Shower
**Type**: "meteor shower" (13 characters - MAXIMUM RISK)
**Behavior**: Multiple delayed AoE strikes across the battlefield
**Base Stats**: 80 damage per meteor, 3 meteors, large area, 2s delay
**Progression**: Damage +15%/level, meteor count +1 every 2 levels, area +20% every 3 levels
**Balance**: Highest total damage potential but longest typing exposure

---

## Progression System

### Experience & Leveling
- **XP Sources**: Enemies drop XP orbs on death
- **XP Collection**: Walk over orbs to collect automatically
- **XP Scaling**: Level N requires `100 + (N * 25)` XP to reach Level N+1
  - Level 1→2: 125 XP
  - Level 2→3: 150 XP  
  - Level 3→4: 175 XP
  - Level 10→11: 350 XP
- **Level Up**: Fill XP bar to get upgrade choice

### Time-Based Difficulty Scaling
**Enemy Health Scaling** (independent of player level):
```
enemy_hp = base_hp * (1 + 0.1 * floor(time_survived / 30))
```
- Every 30 seconds: +10% enemy health
- Creates urgency - players must level up to keep pace
- Allows skilled players to get ahead of the curve
- Punishes slow/defensive play

**Player Power vs Enemy Health**:
- **Optimal pace**: Level up every ~45 seconds to stay even
- **Ahead**: Leveling faster makes enemies easier
- **Behind**: Falling behind makes enemies tankier
- **Catch-up**: Can farm weaker enemies if far behind

### Upgrade Types

**Generic Upgrades** (affect all spells/stats):
- Spell Damage +25%
- Cast Speed +20%
- Movement Speed +15%
- Max Health +20
- XP Pickup Range +50%

**Spell-Specific Upgrades**:
- "Upgrade Mana Bolt" - advances to next level
- "Upgrade Fire" - advances to next level
- "Upgrade Lightning" - advances to next level
- "Upgrade Meteor" - advances to next level
- "Upgrade Life" - advances to next level
- "Upgrade Earth" - advances to next level
- "Upgrade Ice" - advances to next level

**Upgrade Selection**: Present 3 random options from available pool

---

## Enemy Design

### Basic Enemy Types
**Chaser**: Moves directly toward player, 30 HP, 15 damage
**Swarm**: Fast, weak enemies, 10 HP, 10 damage
**Tank**: Slow, high HP enemies, 80 HP, 25 damage
**Shooter**: Ranged enemies that fire projectiles, 40 HP, 20 damage

### Spawn Patterns & Scaling
- **0-60s**: Chasers only, spawn every 3s, base stats
- **60-120s**: Add Swarm enemies, spawn every 2s
- **120-180s**: Add Tank enemies, spawn every 5s  
- **180s+**: Add Shooter enemies, all enemy types active
- **240s+**: Elite variants with 2x health and damage

### Time-Based Scaling Formulas
**Enemy Health**: `base_hp * (1 + 0.1 * floor(time / 30))`
**Enemy Speed**: `base_speed * (1 + 0.05 * floor(time / 60))`
**Spawn Rate**: `base_spawn_delay * (0.95 ^ floor(time / 45))`

**XP Rewards Scale with Health**:
```
xp_reward = base_xp * sqrt(enemy_health_multiplier)
```
- Stronger enemies give proportionally more XP
- Prevents XP farming on weak enemies
- Encourages engaging with current difficulty

---

## User Interface

### HUD Elements
- **Health Bar**: Top-left corner
- **XP Bar**: Bottom of screen
- **Active Spell**: Shows currently queued spell and typing progress
- **Spell Cooldowns**: Icons showing available spells
- **Score/Time**: Current survival time
- **Level**: Current player level

### Level Up Screen
- **Pause Game**: Stop enemy movement and spawning
- **3 Upgrade Options**: Random selection from available upgrades
- **Click to Select**: Resume game after selection

---

## Technical Implementation

### Technology Stack
- **Engine**: Godot 4.x
- **Language**: GDScript
- **Backend**: Simple REST API (Flask/FastAPI)
- **Database**: SQLite for local development

### Core Systems

**Game State Manager**:
```gdscript
enum GameState { PLAYING, LEVEL_UP, GAME_OVER, PAUSED }
```

**Spell System**:
```gdscript
class_name Spell
var name: String
var level: int = 1
var stats: Array[Dictionary]
var current_cooldown: float = 0.0
```

**Enemy Manager**:
```gdscript
var spawn_timer: float
var difficulty_scaling: Dictionary
var active_enemies: Array[Enemy]
```

### File Structure
```
game/
├── scenes/
│   ├── Main.tscn
│   ├── Player.tscn
│   ├── Enemy.tscn
│   └── UI.tscn
├── scripts/
│   ├── GameManager.gd
│   ├── Player.gd
│   ├── SpellSystem.gd
│   ├── EnemyManager.gd
│   └── UIManager.gd
└── assets/
    ├── sprites/
    ├── sounds/
    └── fonts/
```

---

## Backend Requirements

### API Endpoints
```
POST /api/scores
GET /api/leaderboard
GET /api/player-stats/{player_id}
```

### Data Schema
```json
{
  "player_id": "string",
  "survival_time": "integer (seconds)",
  "final_level": "integer",
  "enemies_killed": "integer",
  "spells_cast": "integer",
  "timestamp": "datetime"
}
```

---

## Development Timeline (6 Hours)

### Hour 1: Core Framework
- [x] Project setup in Godot
- [x] Player movement (WASD)
- [x] Basic enemy spawning and movement
- [x] Collision detection

### Hour 2: Spell System Foundation
- [x] Spell queuing (number keys 1-6)
- [x] Text input system for spell names
- [x] Time dilation during typing
- [x] Basic spell casting (fire, lightning)

### Hour 3: Combat & Progression
- [x] Mana Bolt auto-attack
- [x] XP system and collection
- [x] Level up UI and upgrade selection
- [x] Enemy health/damage system

### Hour 4: Content & Balance
- [x] All 6 spell types implemented
- [x] Spell upgrade system working
- [x] Enemy variety and spawn patterns
- [x] Basic game balance

### Hour 5: Backend & Polish
- [x] Score tracking API
- [x] Game over screen
- [x] Sound effects and particle effects
- [x] UI polish and feedback

### Hour 6: Documentation & Demo
- [x] README with setup instructions
- [x] Code documentation
- [x] Loom recording (3-5 minutes)
- [x] Final testing and bug fixes

---

## Success Metrics

### Core Functionality
- [ ] Player can move and auto-attack
- [ ] Player can type spell names to cast spells
- [ ] Enemies spawn and chase player
- [ ] XP collection and level progression works
- [ ] Game over when player dies

### Polish Features
- [ ] All 6 spell types functional
- [ ] Spell upgrade system working
- [ ] Score persistence via backend
- [ ] Visual/audio feedback for actions
- [ ] Smooth game feel and responsive controls

### Technical Demonstration
- [ ] Clean, readable code architecture
- [ ] Proper separation of concerns
- [ ] Working backend integration
- [ ] Comprehensive documentation

---

## Risk Mitigation

### High-Risk Features (Cut if needed)
- Complex spell upgrade paths → Use generic upgrades only
- Multiple enemy types → Stick to basic chaser enemies
- Backend integration → Local high score only
- Visual effects → Focus on gameplay first

### MVP Fallback
If behind schedule, minimum viable version:
- 3 spells (fire, lightning, life)
- 1 enemy type (chaser)
- Basic XP/level system
- Local scoring only

**The core typing mechanic is non-negotiable** - this is what makes the game unique.