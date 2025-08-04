# SpellCast Survivors - Godot Editor Step-by-Step Guide

This guide walks you through every step of working with the SpellCast Survivors project in Godot 4.x Editor. Whether you're new to Godot or just want to understand this specific project, this guide will make you confident working in the editor.

## 🚀 Part 1: Opening and First Look

### Step 1: Launch Godot and Open Project

1. **Open Godot Engine 4.x**
2. **Click "Import"** in the project manager
3. **Navigate to** `/Users/ljeytl/spellcast-survivors/`
4. **Select** `project.godot` file
5. **Click "Import & Edit"**

**What You'll See**: The Godot Editor opens with multiple panels (Scene, FileSystem, Inspector, etc.)

**Why This Matters**: The `project.godot` file contains all project settings, input mappings, and autoload configurations that make the game work properly.

### Step 2: Understanding the Editor Layout

**Key Panels to Know:**
- **Scene Panel** (top-left): Shows the node hierarchy of your current scene
- **FileSystem** (bottom-left): Shows all project files and folders
- **Inspector** (right): Shows properties of the selected node
- **Main Viewport** (center): Where you see and edit your scenes
- **Output/Debugger** (bottom): Shows print statements and errors

**Pro Tip**: You can rearrange these panels by dragging their tabs. The layout saves automatically.

## 🎮 Part 2: Testing the Current Game

### Step 3: Open the Main Game Scene

1. **In FileSystem panel**, navigate to `scenes/`
2. **Double-click** `Game.tscn`

**What You'll See**: 
- Scene panel shows a complex node tree with Game, Player, Camera2D, UI, etc.
- Main viewport shows a blue rectangle (player) in the center
- Various UI elements around the edges

**Why This Scene**: `Game.tscn` contains all the core gameplay - player, camera, UI, spell system, and enemy manager.

### Step 4: Run the Game Scene

1. **Press F6** OR **click the "Play Scene" button** (looks like a play triangle with a film strip)
2. **If prompted**, choose "Select Current" to make this the current scene

**What Should Happen**:
- Game window opens showing the blue player rectangle
- Health bar (green) and XP bar (blue) visible in top-left
- Spell slot buttons (1-6) visible
- Camera follows as you move

### Step 5: Test Core Functionality

**Movement Test**:
- **Press WASD or Arrow Keys** to move the blue rectangle
- **Notice**: Camera smoothly follows the player
- **Why it works**: `Player.gd` handles input and `Game.gd` updates camera position

**Spell System Test**:
1. **Press number key 1**: Should see "Queued spell: bolt" in console
2. **Start typing "bolt"**: Time should slow down dramatically
3. **Finish typing "bolt"**: Should see "Cast spell: bolt"
4. **Try ESC while typing**: Cancels the spell

**Console Output** (bottom panel):
```
Queued spell: bolt
Cast spell: bolt
```

**Why This is Important**: This proves the unique typing mechanic (the game's core feature) is working correctly.

## 🔍 Part 3: Understanding the Scene Structure

### Step 6: Explore the Node Hierarchy

**In Scene panel, expand the Game node tree:**

```
Game (Node2D)
├── Player (CharacterBody2D)
├── Camera2D
├── SpellManager (Node)
├── EnemyManager (Node2D)
└── UI (CanvasLayer)
	├── HUD (Control)
	│   ├── HealthBar (ProgressBar)
	│   ├── XPBar (ProgressBar)
	│   ├── SpellSlots (HBoxContainer)
	│   │   ├── Button1, Button2, etc.
	│   └── TypingArea (VBoxContainer)
	│       └── TypingLabel (Label)
	└── PauseOverlay (ColorRect)
```

**Click on each node** to see its properties in the Inspector panel.

**Key Concepts**:
- **CharacterBody2D**: Physics-based character with collision
- **CanvasLayer**: UI that stays on screen regardless of camera
- **Node**: Pure logic containers (no visual representation)
- **Control nodes**: UI elements (buttons, labels, progress bars)

### Step 7: Examine Scripts

**Right-click any node with a script icon** → **"Open Script"**

**Key Scripts to Understand**:

1. **Game.gd** (attached to Game node):
   - Manages game states (PLAYING, PAUSED, GAME_OVER)
   - Handles UI updates
   - Connects player signals to UI

2. **Player.gd** (attached to Player node):
   - WASD movement with physics
   - Health and XP management
   - Emits signals when stats change

3. **SpellManager.gd** (attached to SpellManager node):
   - Listens for number key presses (1-6)
   - Handles typing input and validation
   - Controls time dilation during casting

## 🛠 Part 4: Development Workflow

### Step 8: Edit → Test → Debug Cycle

**Making Changes**:
1. **Stop the running game** (close game window or press F8)
2. **Edit code or scene**
3. **Save** (Ctrl/Cmd + S)
4. **Test again** (F6)

**Example Edit**: Let's change player speed
1. **Select Player node** in Scene panel
2. **Click "Open Script"** or press Ctrl/Cmd + Shift + E
3. **Find line 3**: `const SPEED = 300.0`
4. **Change to**: `const SPEED = 500.0`
5. **Save and test** - player should move faster

### Step 9: Using the Console for Debugging

**Where to Look**: Bottom panel → "Output" tab

**Current Debug Messages**:
- `"Queued spell: [spell_name]"` - When you press 1-6
- `"Cast spell: [spell_name]"` - When you finish typing
- `"Enemy spawned! Total: X"` - Every 2 seconds (no visual yet)
- `"Level up! Now level X"` - When XP reaches threshold

**Adding Your Own Debug**: In any script, use `print("Your message")`

### Step 10: Understanding Signals (Godot's Event System)

**What are Signals**: Godot's way for nodes to communicate without direct references.

**Current Signal Connections**:
1. **Player signals** → **Game script**:
   - `health_changed` → updates health bar
   - `xp_changed` → updates XP bar
   - `player_died` → triggers game over

2. **SpellManager signals** → **Game script**:
   - `spell_queued` → future spell slot highlighting
   - `spell_cast` → future spell effect creation

**To See Connections**: Select a node → Inspector → "Node" tab → "Signals" tab

## 🎯 Part 5: Next Development Steps

### Step 11: Create Your First Enemy

**Why Start Here**: Enemies make the game immediately more interactive and testable.

**Steps to Create Enemy Scene**:
1. **Scene menu** → **New Scene**
2. **Add CharacterBody2D** as root (name it "Enemy")
3. **Add child ColorRect** (make it red, 20x20 pixels)
4. **Add child CollisionShape2D** (add RectangleShape2D resource)
5. **Save as** `scenes/Enemy.tscn`

**Create Enemy Script**:
1. **Right-click Enemy node** → **Attach Script**
2. **Save as** `scripts/Enemy.gd`
3. **Basic enemy code**:
```gdscript
extends CharacterBody2D

var speed = 100.0
var health = 50.0
var player: CharacterBody2D

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
```

### Step 12: Connect Enemy to Spawn System

**Modify EnemyManager.gd**:
1. **Open** `scripts/EnemyManager.gd`
2. **Find line 66-69** (the commented enemy spawning code)
3. **Uncomment and modify**:
```gdscript
var enemy = enemy_scene.instantiate()
enemy.global_position = spawn_pos
get_parent().add_child(enemy)
```

**Test**: Run the game - red squares should spawn and chase the player!

### Step 13: Add Player Group for Enemy Targeting

**Modify Player Setup**:
1. **Select Player node** in Game.tscn
2. **Inspector** → **Groups** tab
3. **Add to group**: "player"

**Why This Matters**: Enemies can now find the player using `get_first_node_in_group("player")`

## 🎨 Part 6: Visual Improvements

### Step 14: Improve Player Appearance

1. **Select Player node**
2. **Add child**: **ColorRect**
3. **Set size**: 32x32 pixels
4. **Set color**: Blue (#0080FF)
5. **Set anchors**: Center

**Pro Tip**: You can add a **Sprite2D** instead and import an image for better visuals.

### Step 15: Add Visual Feedback for Spells

**Create Simple Spell Effect**:
1. **New Scene** → **Area2D** (root node named "Bolt")
2. **Add ColorRect** child (yellow, 8x24 pixels)
3. **Add CollisionShape2D** child (CapsuleShape2D)
4. **Save as** `scenes/spells/Bolt.tscn`

**Script for Movement**:
```gdscript
extends Area2D

var speed = 800.0
var direction = Vector2.RIGHT

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(10)
	queue_free()
```

## 🐛 Part 7: Common Issues and Solutions

### Issue: Game Won't Run
**Symptoms**: F6 does nothing or shows errors
**Solutions**:
1. Check **Output** tab for error messages
2. Ensure **main scene** is set (Project → Project Settings → Main Scene)
3. Verify **script syntax** (look for red underlines)

### Issue: Movement Not Working
**Check**:
1. **Project Settings** → **Input Map** → Verify WASD mappings
2. **Player script** is attached to Player node
3. **CharacterBody2D** collision shape exists

### Issue: Spells Not Queuing
**Debug Steps**:
1. Check **console output** when pressing 1-6
2. Verify **SpellManager** is child of Game node
3. Ensure **SpellManager.gd** script is attached

### Issue: UI Not Updating
**Common Causes**:
1. **Signal connections** broken (check Node → Signals tab)
2. **@onready variables** pointing to wrong nodes
3. **UI nodes** don't match script expectations

## 💡 Part 8: Godot-Specific Tips

### Understanding @onready
```gdscript
@onready var health_bar: ProgressBar = $UI/HUD/HealthBar
```
**What this does**: Waits until `_ready()` is called, then finds the node at that path.

### Node Paths
- `$UI/HUD/HealthBar` - Relative to current node
- `get_node("UI/HUD/HealthBar")` - Same thing, explicit
- `get_tree().get_first_node_in_group("enemies")` - Find by group

### Groups vs. References
- **Groups**: Flexible, nodes can join/leave dynamically
- **Direct references**: Faster, but more rigid structure

### Autoload (Singletons)
**SceneManager** is autoloaded (see `project.godot`):
- Available globally as `SceneManager`
- Persists between scene changes
- Good for game state, settings, etc.

## 🎯 Part 9: Performance Monitoring

### Built-in Profiler
1. **Debug menu** → **Profiler**
2. **Start profiling** while game runs
3. **Monitor**:
   - FPS (target: 60)
   - Memory usage
   - Physics time
   - Render time

### Frame Rate Display
**Add to any script**:
```gdscript
func _process(delta):
	print("FPS: ", Engine.get_frames_per_second())
```

## 🚀 Part 10: Advanced Workflow Tips

### Scene Instancing
**Create reusable components**:
1. **Enemy types**: Different scenes inheriting from base Enemy
2. **Spell effects**: Each spell as separate scene
3. **UI panels**: Reusable across different game screens

### Version Control
**Important files to track**:
- `*.tscn` (scenes)
- `*.gd` (scripts)  
- `project.godot` (settings)
- `*.tres` (resources)

**Files to ignore**:
- `.godot/` (generated files)
- `*.tmp` (temporary files)

## 📚 Key Takeaways

### What Makes This Project Special
1. **Typing Mechanics**: Unique real-time typing system with time dilation
2. **Signal Architecture**: Clean communication between systems
3. **Modular Design**: Easy to add new spells, enemies, UI elements
4. **Performance Conscious**: Built with proper node hierarchy

### Your Development Path
1. **Master the basics**: Movement, spawning, simple collision
2. **Add visual polish**: Sprites, particles, screen effects
3. **Expand systems**: More spell types, enemy varieties
4. **Optimize**: Performance profiling and improvements
5. **Polish**: Audio, UI improvements, game balance

### Most Important Godot Concepts for This Project
- **Node hierarchy** and scene structure
- **Signals** for loose coupling
- **CharacterBody2D** for physics-based movement
- **Timer nodes** for game events
- **Groups** for flexible object references
- **Engine.time_scale** for game speed effects

---

## 🎉 You're Ready to Develop!

With this guide, you understand:
- ✅ How to open and test the project
- ✅ The scene structure and why it's organized this way
- ✅ The development workflow (edit → test → debug)
- ✅ How to add new features (enemies, spells, UI)
- ✅ Common issues and how to solve them
- ✅ Godot-specific concepts used in this project

**Next Steps**: Start with creating the Enemy scene (Step 11) to make the game immediately more fun to test!

The foundation is solid - the typing mechanic works beautifully and the architecture is clean. Focus on bringing the world to life with enemies and spell effects. Every addition will make the game more engaging and closer to the unique vampire survivors experience envisioned in the design.

Happy coding! 🚀
