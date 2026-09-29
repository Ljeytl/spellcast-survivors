# SpellCast Survivors

**Style scoring — 0.1.27:** [specification](docs/style-scoring/README.md). F–SSS combo, banked run score, casting bonuses, colored rune HUD, local high scores and S-rank Atomic are implemented for playtesting. Rank cadence and finisher balance still need human feedback.

> **Current development slate:** keep the playable roguelike alpha. Difficulty scaling is next; keyword and expedition work are deferred. Track observations, open work and verified fixes in the [player feedback tracker](docs/PLAYER_FEEDBACK.md). Future milestones below are not the immediate implementation queue.

> Current direction: **Should Have Joined a Party**, a wizard action game using language to express complex magic. Evolve the existing playable game through keywords, preparation and persistent discoveries. Readable inscriptions replace keycap branding. See the [current design and development roadmap](docs/expedition-design/README.md). Older prototype descriptions, plans and marketing language below are historical, not the current target specification.

A vampire survivors-style game with a unique twist: **typing-based spell casting mechanics**. Built in Godot 4.x.

## 🎮 Game Overview

SpellCast Survivors combines the intense action of vampire survivors games with strategic typing mechanics. Players fight waves of enemies while casting powerful spells by typing their names under pressure.

### Core Mechanics
- **WASD Movement** - Navigate through enemy hordes
- **Auto-Attack** - Continuous Magic Missile projectiles
- **Spell Queuing** - Press number keys (1-5) to queue equipped spells
- **Typing System** - Type spell names to cast them
- **Time Dilation** - Typing has a shared three-second slowdown budget, refilling over ten seconds outside typing

### Spell System
Choose five manual spells from fifteen base spells. Automatic Magic Missile is separate.

- **Bolt** — Focused projectiles
- **Regeneration** — Healing over time
- **Ice Blast** — Area damage, knockback and slow
- **Earth Shield** — Temporary overheal
- **Lightning Arc** — Chaining damage
- **Meteor Shower** — Delayed area strikes
- **Ember Lance** — Straight piercing damage
- **Plague Seed** — Spreading damage over time
- **Cinder Field** — Stationary area damage
- **Arcane Orbit** — Moving close-range sparks
- **Focus Ray** — Sustained tracking beam against a nearby target
- **Rune Trap** — Delayed proximity trap with a single area burst
- **Seeking Spirit** — Pursuing spirit with repeated contact strikes
- **Ember Trail** — Leave temporary damage patches while moving
- **Returning Blade** — Outbound and returning sweep, one hit per enemy on each leg

Seven hidden authored evolutions can appear when their ingredients are equipped. Choosing one replaces its primary spell, retaining the slot and rank while preserving its catalyst. Discoveries persist in the Spell Collection; equipped spells reset each run. Evolutions show a gain and a cost: crowd coverage, healing, or control can trade away direct damage, duration, preparation time, or ranked projectiles. Keeping and ranking a basic spell remains a valid choice. Ordinary offers retain a non-evolution alternative unless all three choices were explicitly locked.

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
- **1-5** - Queue an equipped spell
- **Type spell names** - Cast queued spells
- **Space** - Type any owned spell; **Enter** casts
- **ESC** - Cancel typing, or pause outside typing

## 🎯 Game Features

### Progressive Difficulty
- Survive twenty minutes for immediate victory.
- Bosses arrive at five, ten and fifteen minutes.
- Time advances encounter tiers regardless of boss survival; ranged enemies enter later.

### Leveling System
- Gain XP by defeating enemies.
- Choose new spells, equipped-spell ranks, passives, or eligible evolutions.
- At five equipped spells, new base-spell offers stop; evolutions and upgrades remain available.
- Damage ranks add 15% of base damage, with spell-specific bonuses on existing spells.
- Mana Tempo increases automatic Magic Missile attack rate by 10% per pick. It does not weaken or extend the shared typing slowdown.

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
### Browser playtest build

From a clean committed checkout with matching Godot export templates installed:

```sh
python3 tools/export_web.py
python3 tools/serve_previews.py --directory builds/web-TIMESTAMP/web --port 8765
```

Open `http://127.0.0.1:8765/`. The export prints its actual output directory and writes a revision manifest plus `Shoulda-Joined-a-Party-Web.zip`. The ZIP contains `index.html` at its root for an itch.io HTML project. Select the upload as playable in-browser. On itch, open Edit game → Embed options → Click to launch in fullscreen, then save and relaunch the game. Alternatively, choose Embed in page and enable Fullscreen Button for a bottom-right fullscreen control. This is a desktop keyboard game. Verify typing, audio, menu transitions and saved settings in the browser before sharing. Re-run after each approved gameplay/balance merge; exported files are ignored by Git. Export success alone does not certify browser gameplay.
