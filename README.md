# SpellCast Survivors

A vampire survivors-style game with a unique twist: **typing-based spell casting mechanics**. Built in Godot 4.x.

## 🎮 Game Overview

SpellCast Survivors combines the intense action of vampire survivors games with strategic typing mechanics. Players fight waves of enemies while casting powerful spells by typing their names under pressure.

### Core Mechanics
- **WASD Movement** - Navigate through enemy hordes
- **Auto-Attack** - Continuous mana bolt projectiles
- **Spell Queuing** - Press number keys (1-6) to queue spells
- **Typing System** - Type spell names to cast them
- **Time Dilation** - Time slows to 20% while typing for strategic gameplay

### Spell System
6 unique spells with balanced character counts:
- **Bolt** (4 chars) - Quick damage projectile
- **Ice Blast** (9 chars) - Freezing area attack  
- **Life** (4 chars) - Healing spell
- **Earth Shield** (11 chars) - Defensive barrier
- **Lightning Arc** (12 chars) - Chain lightning
- **Meteor Shower** (13 chars) - Devastating area spell

## 🚀 How to Play

### From Executable Files
1. **Windows**: Double-click `SpellCast Survivors.exe`
2. **macOS**: Double-click `SpellCast Survivors.dmg`, then drag to Applications

### From Source (Godot Required)
1. Open `project.godot` in Godot Engine 4.x
2. Press **F5** or click the Play button
3. Select the main scene when prompted

### Controls
- **WASD** - Move player
- **1-6** - Queue spells
- **Type spell names** - Cast queued spells
- **ESC** - Pause game

## 🎯 Game Features

### Progressive Difficulty
- Enemy health scales every 30 seconds
- Spawn rates increase every 45 seconds  
- Enemy speed increases every 60 seconds
- XP rewards scale with enemy strength

### Leveling System
- Gain XP by defeating enemies
- Level up to choose spell upgrades
- 8 upgrade levels per spell with 15% damage scaling per level
- Level N requires `100 + (N * 25)` XP

### Audio System
- Dynamic background music
- Contextual sound effects for all actions
- Typing feedback sounds
- Spell-specific audio cues

### Visual Polish
- Particle effects for all spells
- Damage numbers with floating animation
- Screen shake on impacts
- Smooth camera following

## 🛠️ Technical Details

### Built With
- **Godot 4.x** - Game engine
- **GDScript** - Programming language
- **Custom audio system** - Dynamic music and SFX management
- **Object pooling** - Optimized performance for projectiles and effects

### Architecture
- **Modular systems** - Separate managers for spells, enemies, audio, etc.
- **Scene-based structure** - Clean separation of game elements
- **State management** - Proper game state handling (playing, paused, level-up, game over)

### Performance Optimizations
- Object pooling for frequently spawned objects
- Efficient collision detection
- Optimized particle systems
- Smart memory management

## 📁 Project Structure

```
spellcast-survivors/
├── scenes/           # Godot scene files
├── scripts/          # GDScript source code  
├── sprites/          # Game artwork and animations
├── audio/            # Music and sound effects
├── project.godot     # Godot project file
└── export_presets.cfg # Build configuration
```

## 🎨 Design Philosophy

The typing mechanic creates a unique tension: players must balance positioning, spell selection, and typing accuracy under pressure. The time dilation during typing provides strategic depth while maintaining the frantic pace of the vampire survivors genre.

Spell character counts are carefully balanced - shorter spells (4 chars) are quick utility, while longer spells (13 chars) deliver devastating power at the cost of typing time and vulnerability.

## 🏆 Key Differentiators

1. **Novel Input Mechanic** - Typing system adds skill ceiling beyond traditional survivors games
2. **Time Dilation Strategy** - Creates micro-moments of tactical decision making
3. **Balanced Spell Design** - Character count directly correlates with power level
4. **Audio-Visual Polish** - Complete game feel with professional presentation
5. **Scalable Architecture** - Clean codebase ready for expansion

---

*Built as a demonstration of game development skills, combining innovative mechanics with solid technical execution.*