# SpellCast Survivors Console Commands Reference

## Opening the Console
- **Key**: Press `~` (tilde) to toggle the console open/closed
- **Access**: Hidden developer console with extensive debugging and testing capabilities

---

## Basic Commands

### `help [command]`
- **Description**: Show all available commands or detailed help for a specific command
- **Usage**: `help` or `help invincibility`
- **Examples**: 
  - `help` - Shows all commands
  - `help god_mode` - Shows details for god_mode command

### `clear`
- **Description**: Clear console output
- **Usage**: `clear`

---

## Player Cheats & Debug

### `invincibility [on/off/toggle]`
- **Description**: Toggle player invincibility
- **Usage**: `invincibility on` / `invincibility off` / `invincibility toggle`
- **Effect**: Player takes no damage when enabled
- **Visual**: Player sprite gets golden tint when invincible

### `god_mode [on/off/toggle]`
- **Description**: Enable god mode (invincibility + infinite mana)
- **Usage**: `god_mode on` / `god_mode off` / `god_mode toggle`
- **Effect**: Combines invincibility with enhanced abilities

### `heal [amount]`
- **Description**: Heal player to full health or by specific amount
- **Usage**: `heal` / `heal 50`
- **Examples**:
  - `heal` - Full heal
  - `heal 25` - Heal by 25 HP

### `set_health <amount>`
- **Description**: Set player health to specific value
- **Usage**: `set_health 150`

### `speed <multiplier>`
- **Description**: Set player movement speed multiplier
- **Usage**: `speed 1.5` 
- **Examples**:
  - `speed 2.0` - Double movement speed
  - `speed 0.5` - Half movement speed

### `damage <multiplier>`
- **Description**: Set player damage multiplier
- **Usage**: `damage 2.0`
- **Effect**: Multiplies all spell damage by the specified amount

### `teleport`
- **Description**: Teleport player to mouse position
- **Usage**: `teleport`

### `noclip [on/off/toggle]`
- **Description**: Toggle player collision (walk through walls)
- **Usage**: `noclip on` / `noclip off` / `noclip toggle`

---

## Spell & Magic System

### `unlock_spells`
- **Description**: Unlock all spells immediately
- **Usage**: `unlock_spells`
- **Effect**: Sets all spell unlock levels to 1, making them immediately available

### `freeform [on/off/toggle]`
- **Description**: Toggle free-form spell casting mode
- **Usage**: `freeform on` / `freeform off` / `freeform toggle`
- **Effect**: 
  - **Normal Mode**: Press 1-6 to queue spells, then type their names
  - **Freeform Mode**: Start typing any spell name directly (no number keys needed)

### `spell_list`
- **Description**: Show all available spells in freeform mode
- **Usage**: `spell_list`
- **Output**: Lists all basic spells and test spells with character counts

---

## Experience & Leveling

### `add_xp <amount>`
- **Description**: Add experience points
- **Usage**: `add_xp 500`
- **Effect**: Grants XP and can trigger multiple level-ups if amount is large enough

### `level_up`
- **Description**: Trigger level up screen
- **Usage**: `level_up`
- **Effect**: Forces the level-up screen to appear with upgrade choices

---

## Enemy Management

### `spawn_enemy <type> [count]`
- **Description**: Spawn a specific enemy type
- **Usage**: `spawn_enemy goblin 5`
- **Types**: goblin, orc, etc. (depends on available enemy types)

### `kill_all`
- **Description**: Kill all enemies on screen
- **Usage**: `kill_all`

### `difficulty <level/+time>`
- **Description**: Jump to difficulty level or add time
- **Usage**: `difficulty 5` / `difficulty +120`
- **Examples**:
  - `difficulty 10` - Jump to difficulty level 10
  - `difficulty +60` - Add 60 seconds to current time

### `freeze [duration]`
- **Description**: Freeze all enemies in place
- **Usage**: `freeze` / `freeze 5`
- **Default**: 3 seconds if no duration specified

### `explode [damage] [radius]`
- **Description**: Make all enemies explode
- **Usage**: `explode` / `explode 100 200`

### `army <enemy_type> <count>`
- **Description**: Spawn army of specific enemy type
- **Usage**: `army goblin 20`

---

## World & Environment

### `time_scale <multiplier>`
- **Description**: Change game time scale
- **Usage**: `time_scale 0.5`
- **Examples**:
  - `time_scale 2.0` - Double speed
  - `time_scale 0.25` - Quarter speed (slow motion)

### `spawn_chest`
- **Description**: Spawn treasure chest at mouse position
- **Usage**: `spawn_chest`

### `earthquake [intensity] [duration]`
- **Description**: Shake the screen violently
- **Usage**: `earthquake` / `earthquake 5 3`

### `rain <spell_type> [count] [duration]`
- **Description**: Make it rain spell projectiles
- **Usage**: `rain bolt 50 10`

---

## Visual Effects & Fun

### `bighead [on/off/toggle]`
- **Description**: Make all enemies have big heads
- **Usage**: `bighead on` / `bighead off` / `bighead toggle`

### `disco [on/off/toggle]`
- **Description**: Enable disco mode (rainbow effects)
- **Usage**: `disco on` / `disco off` / `disco toggle`

### `matrix [on/off/toggle]`
- **Description**: Enable matrix mode (green tint + effects)
- **Usage**: `matrix on` / `matrix off` / `matrix toggle`

### `giant [scale] [duration]`
- **Description**: Make player giant sized
- **Usage**: `giant` / `giant 3.0 10`
- **Default**: 2x scale for 5 seconds

### `tiny [scale] [duration]`
- **Description**: Make player tiny sized
- **Usage**: `tiny` / `tiny 0.3 10`
- **Default**: 0.5x scale for 5 seconds

### `rainbow [on/off/toggle]`
- **Description**: Give player rainbow trail effect
- **Usage**: `rainbow on` / `rainbow off` / `rainbow toggle`

### `magnet [on/off/toggle]`
- **Description**: Attract all enemies to player
- **Usage**: `magnet on` / `magnet off` / `magnet toggle`

---

## Advanced Effects

### `missile [count] [damage]`
- **Description**: Launch homing missiles at all enemies
- **Usage**: `missile` / `missile 10 50`

### `blackhole [duration] [strength]`
- **Description**: Create black hole that sucks in enemies
- **Usage**: `blackhole` / `blackhole 5 2.0`

### `laser [on/off/toggle] [damage]`
- **Description**: Player shoots continuous laser beam
- **Usage**: `laser on` / `laser on 100`

---

## Level-Up System

### `rerolls <amount>`
- **Description**: Set reroll resource count
- **Usage**: `rerolls 10`
- **Effect**: Sets available rerolls for level-up screen

### `banishes <amount>`
- **Description**: Set banish resource count
- **Usage**: `banishes 10`
- **Effect**: Sets available banishes for level-up screen

### `locks <amount>`
- **Description**: Set lock resource count
- **Usage**: `locks 10`
- **Effect**: Sets available locks for level-up screen

---

## Character Progression (Roguelite System)

### `persistent_xp [amount]`
- **Description**: Set or show persistent XP for character progression
- **Usage**: `persistent_xp` / `persistent_xp 1000`
- **Examples**:
  - `persistent_xp` - Show current persistent XP
  - `persistent_xp 5000` - Set persistent XP to 5000

### `character [character_name]`
- **Description**: Show or select character
- **Usage**: `character` / `character wizard`
- **Examples**:
  - `character` - Show current character and available characters
  - `character battlemage` - Switch to Battle Mage character

### `unlock_character <character_name>`
- **Description**: Unlock a specific character
- **Usage**: `unlock_character stormcaller`
- **Effect**: Makes the character available for selection

### `progression`
- **Description**: Show current progression stats
- **Usage**: `progression`
- **Output**: Displays persistent XP, games played, survival records, unlocked content

### `reset_progression`
- **Description**: Reset all character progression data
- **Usage**: `reset_progression`
- **Warning**: Requires confirmation with `reset_progression_confirm`
- **Effect**: Resets all persistent progression, unlocks, and statistics

---

## Save Slot Management

### `save_slots`
- **Description**: Show information about all save slots
- **Usage**: `save_slots`
- **Output**: Displays all 3 save slots with character data, XP, games played, and best times

### `switch_slot <1-3>`
- **Description**: Switch to a different save slot
- **Usage**: `switch_slot 2`
- **Effect**: Changes active save slot (1, 2, or 3)
- **Note**: Each slot maintains separate character progression

### `delete_slot <1-3>`
- **Description**: Delete a save slot
- **Usage**: `delete_slot 3`
- **Safety**: Cannot delete currently active save slot
- **Effect**: Permanently removes all progression data from specified slot

---

## Easter Eggs & Fun Commands

### `thanos`
- **Description**: Snap fingers - remove half of all enemies
- **Usage**: `thanos`
- **Effect**: Perfectly balanced, as all things should be

### `konami`
- **Description**: Activate legendary cheat mode
- **Usage**: `konami`
- **Effect**: Secret enhanced abilities

### `party`
- **Description**: Throw a party! 🎉
- **Usage**: `party`
- **Effect**: Celebration mode with special effects

### `rickroll`
- **Description**: Never gonna give you up...
- **Usage**: `rickroll`
- **Effect**: Classic internet meme experience

### `cake`
- **Description**: The cake is a lie
- **Usage**: `cake`
- **Effect**: Portal reference

### `42`
- **Description**: Answer to life, universe, and everything
- **Usage**: `42`
- **Effect**: Hitchhiker's Guide reference

---

## Freeform Spell List

When `freeform on` is active, you can type any of these spell names directly:

### Basic Spells (Current System)
- **bolt** (4) - Lightning projectile
- **life** (4) - Heal over time  
- **ice blast** (9) - Freezing explosion
- **earth shield** (12) - Protective barrier
- **lightning arc** (13) - Chain lightning
- **meteor shower** (13) - Multiple meteor strikes
- **magic missile** (13) - Basic auto-attack spell

### Test Spells (Experimental)
- **fireball** (8) - Fire projectile
- **heal** (4) - Instant healing
- **lightning** (9) - Single lightning strike
- **explosion** (9) - Area blast
- **barrier** (7) - Shield effect
- **teleport** (8) - Move to cursor
- **slow** (4) - Slow all enemies
- **haste** (5) - Speed boost

---

## Tips & Notes

### Console Usage
- Commands are case-insensitive
- Use `help <command>` for detailed information about any command
- Many commands have optional parameters with sensible defaults
- Commands with `[on/off/toggle]` parameters default to toggle if no parameter given

### Freeform Spell Casting
- No need to press number keys in freeform mode
- Start typing any spell name to begin casting
- Partial matches are shown in real-time
- Press Enter to force cast or Escape to cancel
- Auto-casts when you complete a spell name

### Safety Features
- Destructive commands like `reset_progression` require confirmation
- Most visual effects can be toggled off
- Time scale and speed changes can be reset with normal values
- Console can be closed anytime with `~` key

### Development & Testing
- These commands are designed for testing and debugging
- Most effects are temporary and reset between game sessions
- Perfect for experimenting with game balance and mechanics
- Great for content creators and streamers for entertaining effects