extends Node

signal spell_queued(spell_name: String, slot: int)
signal spell_cast(spell_name: String)
signal typing_started
signal typing_ended
signal spell_locked_error(spell_name: String, required_level: int, current_level: int)

# Constants for spell system
const TIME_SCALE_DURING_TYPING = 0.2
const SPELL_DAMAGE_MULTIPLIER = 0.15
const MANA_BOLT_COOLDOWN = 1.5
const CHAIN_LIGHTNING_RANGE = 200.0
const CHAIN_DAMAGE_REDUCTION = 0.8
const PLAYER_TRANSPARENCY_TYPING = 0.3
const METEOR_DELAY_INTERVAL = 0.5
const METEOR_SPREAD_RANGE = 300.0
const AOE_RADIUS_METEOR = 100.0
const SLOW_EFFECT_STRENGTH = 0.5
const SLOW_EFFECT_DURATION = 3.0
const SPELL_CAST_COOLDOWN = 0.1  # Minimum time between spell casts

var spell_projectile_scene = preload("res://scenes/SpellProjectile.tscn")

var spell_queue: Array = []
var current_typing_text: String = ""
var is_typing: bool = false
var target_spell: String = ""
var last_spell_cast_time: float = 0.0

# Freeform casting system
var freeform_mode: bool = false

# Spell definitions with their names and character counts
var spells = {
	1: {"name": "bolt", "chars": 4, "damage": 20, "level": 1, "type": "projectile", "unlock_level": 1},
	2: {"name": "life", "chars": 4, "damage": 0, "level": 1, "type": "heal", "heal_amount": 8, "duration": 5, "unlock_level": 3},
	3: {"name": "ice blast", "chars": 9, "damage": 18, "level": 1, "type": "aoe", "radius": 400, "unlock_level": 5},
	4: {"name": "earth shield", "chars": 12, "damage": 0, "level": 1, "type": "shield", "shield_hp": 60, "unlock_level": 7},
	5: {"name": "lightning arc", "chars": 13, "damage": 30, "level": 1, "type": "chain", "chain_count": 3, "unlock_level": 10},
	6: {"name": "meteor shower", "chars": 13, "damage": 35, "level": 1, "type": "multi_aoe", "meteor_count": 3, "unlock_level": 15}
}

# Expanded spell library for freeform mode
var freeform_spells = {
	# Current basic spells (from existing system)
	"bolt": {"chars": 4, "damage": 20, "level": 1, "type": "projectile"},
	"life": {"chars": 4, "damage": 0, "level": 1, "type": "heal", "heal_amount": 8, "duration": 5},
	"ice blast": {"chars": 9, "damage": 18, "level": 1, "type": "aoe", "radius": 400},
	"earth shield": {"chars": 12, "damage": 0, "level": 1, "type": "shield", "shield_hp": 60},
	"lightning arc": {"chars": 13, "damage": 30, "level": 1, "type": "chain", "chain_count": 3},
	"meteor shower": {"chars": 13, "damage": 35, "level": 1, "type": "multi_aoe", "meteor_count": 3},
	"magic missile": {"chars": 13, "damage": 15, "level": 1, "type": "projectile"}, # Basic auto-attack spell
	
	# New test spells for expanded gameplay
	"fireball": {"chars": 8, "damage": 25, "level": 1, "type": "projectile"},
	"heal": {"chars": 4, "damage": 0, "level": 1, "type": "instant_heal", "heal_amount": 25},
	"lightning": {"chars": 9, "damage": 35, "level": 1, "type": "projectile"},
	"explosion": {"chars": 9, "damage": 40, "level": 1, "type": "aoe", "radius": 350},
	"barrier": {"chars": 7, "damage": 0, "level": 1, "type": "shield", "shield_hp": 40},
	"teleport": {"chars": 8, "damage": 0, "level": 1, "type": "utility"},
	"slow": {"chars": 4, "damage": 0, "level": 1, "type": "debuff"},
	"haste": {"chars": 5, "damage": 0, "level": 1, "type": "buff"}
}

# Mana bolt is the auto-attack spell
var mana_bolt_damage = 15.0
var mana_bolt_level = 1
var mana_bolt_cooldown = MANA_BOLT_COOLDOWN
var mana_bolt_timer = 0.0

# Player states
var active_healing_effects = []

# Visual effects
var spell_effects_scene = preload("res://scenes/SpellProjectile.tscn")
var aoe_effect_scene = preload("res://scenes/SpellProjectile.tscn")

@onready var game_manager = get_parent()
@onready var player = get_parent().get_node("Player")
@onready var player_sprite: Sprite2D = null

# Signals
signal healing_applied(amount: float)

func _ready():
	# Clear any existing queue
	spell_queue.clear()
	
	# Find player sprite for transparency effect
	if player:
		player_sprite = player.get_node("Sprite2D")
	
	# Connect to typing signals for player transparency
	typing_started.connect(_on_typing_started)
	typing_ended.connect(_on_typing_ended)

func _process(delta):
	# Handle auto-attack mana bolt
	handle_auto_attack(delta)
	
	# Process healing over time effects
	process_healing_effects(delta)

func _input(event):
	if event is InputEventKey and event.pressed:
		handle_key_input(event)

func handle_key_input(event: InputEventKey):
	# Handle freeform mode input
	if freeform_mode:
		handle_freeform_input(event)
		return
	
	# Handle normal slot-based input
	var key_code = event.keycode
	
	# Check for 'Y' key to unlock all spells
	if key_code == KEY_Y:
		unlock_all_spells()
		return
	
	if key_code >= KEY_1 and key_code <= KEY_6:
		var slot = key_code - KEY_0
		if slot in spells:
			# Don't allow new spell queuing while already typing
			if is_typing:
				return
			
			# Check spell cast cooldown to prevent rapid casting
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - last_spell_cast_time < SPELL_CAST_COOLDOWN:
				return
			
			# Clear queue and immediately start typing this spell
			spell_queue.clear()
			queue_spell(slot)
			start_typing()
		return
	
	if is_typing:
		handle_typing_input(event)

func queue_spell(slot: int):
	if slot in spells:
		var spell_info = spells[slot]
		var spell_name = spell_info["name"]
		var unlock_level = spell_info.get("unlock_level", 1)
		
		# Check if player has reached required level
		if player and player.level < unlock_level:
			var error_msg = "🔒 {0} requires level {1}! (You're level {2})".format([spell_name.capitalize(), unlock_level, player.level])
			print(error_msg)
			spell_locked_error.emit(spell_name, unlock_level, player.level)
			return
		
		spell_queue.append({"slot": slot, "name": spell_name})
		spell_queued.emit(spell_name, slot)

func start_typing():
	if spell_queue.size() == 0:
		return
	
	# Prevent starting typing if already typing
	if is_typing:
		return
	
	is_typing = true
	current_typing_text = ""
	target_spell = spell_queue[0]["name"]
	
	# Apply cast speed - higher cast speed = less time dilation (faster typing)
	# cast_speed_multiplier 1.0 = normal, 1.1 = 10% faster casting
	var cast_speed_bonus = player.cast_speed_multiplier if player else 1.0
	var adjusted_time_scale = TIME_SCALE_DURING_TYPING + (cast_speed_bonus - 1.0) * 0.5
	# Clamp between 0.2 (normal) and 0.8 (very fast)
	adjusted_time_scale = clamp(adjusted_time_scale, TIME_SCALE_DURING_TYPING, 0.8)
	
	Engine.time_scale = adjusted_time_scale
	
	typing_started.emit()
	update_typing_display()

func handle_typing_input(event: InputEventKey):
	if not is_typing:
		return
	
	if event.keycode == KEY_BACKSPACE:
		if current_typing_text.length() > 0:
			current_typing_text = current_typing_text.substr(0, current_typing_text.length() - 1)
			update_typing_display()
			# Play backspace sound
			if AudioManager:
				AudioManager.play_sound(AudioManager.SoundType.TYPING_BACKSPACE)
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		attempt_cast()
	elif event.keycode == KEY_ESCAPE:
		cancel_typing()
		# Play error sound for cancellation
		if AudioManager:
			AudioManager.on_typing_error()
	else:
		# Add character to typing text
		var char = char(event.unicode)
		if char.length() > 0 and char.is_valid_identifier() or char == " ":
			current_typing_text += char.to_lower()
			update_typing_display()
			
			# Play typing sound for each character
			if AudioManager:
				AudioManager.play_typing_sound(char)
			
			# Auto-cast if we typed the complete spell name
			if current_typing_text == target_spell:
				attempt_cast()

func attempt_cast():
	if current_typing_text == target_spell:
		cast_spell()
		# Play successful cast completion sound
		if AudioManager:
			AudioManager.on_typing_complete()
	else:
		cancel_typing()
		# Play error sound for mistyped spell
		if AudioManager:
			AudioManager.on_typing_error()

func cast_spell():
	if spell_queue.size() == 0:
		return
	
	var spell_data = spell_queue.pop_front()
	var spell_name = spell_data["name"]
	var slot = spell_data["slot"]
	
	# Update last cast time
	last_spell_cast_time = Time.get_ticks_msec() / 1000.0
	
	# Play spell casting sound
	if AudioManager:
		AudioManager.play_spell_sound(spell_name)
	
	spell_cast.emit(spell_name)
	
	# Notify game manager about spell cast
	if game_manager and game_manager.has_method("increment_spells_cast"):
		game_manager.increment_spells_cast()
	
	# Cast the appropriate spell type
	cast_spell_by_type(slot)
	
	end_typing()

func cancel_typing():
	end_typing()

func end_typing():
	is_typing = false
	current_typing_text = ""
	target_spell = ""
	
	# Force time scale back to normal - this is critical
	Engine.time_scale = 1.0
	
	# Also try the time dilation system
	var scene_tree = get_tree()
	if scene_tree:
		var game_node = scene_tree.get_first_node_in_group("game")
		if game_node and game_node.has_method("end_time_dilation"):
			game_node.end_time_dilation()
	
	typing_ended.emit()
	update_typing_display()

func update_typing_display():
	if game_manager and game_manager.has_method("update_typing_display"):
		var display_text = ""
		if is_typing:
			display_text = "Casting: " + target_spell + "\nTyped: " + current_typing_text
		game_manager.update_typing_display(display_text)

# Auto-attack system
func handle_auto_attack(delta):
	mana_bolt_timer -= delta
	if mana_bolt_timer <= 0.0:
		fire_mana_bolt()
		# Apply cast speed to mana bolt cooldown (faster auto-attacks)
		var cast_speed_bonus = player.cast_speed_multiplier if player else 1.0
		var adjusted_cooldown = mana_bolt_cooldown / cast_speed_bonus
		mana_bolt_timer = adjusted_cooldown

func fire_mana_bolt():
	var scene_tree = get_tree()
	if not scene_tree:
		return
	var enemies = scene_tree.get_nodes_in_group("enemies")
	if enemies.size() == 0 or not player:
		return
	
	# Calculate damage
	var level_multiplier = 1.0 + SPELL_DAMAGE_MULTIPLIER * (mana_bolt_level - 1)
	var damage = mana_bolt_damage * level_multiplier * player.spell_damage_multiplier
	
	# Determine number of projectiles based on mana bolt level
	var projectile_count = 1
	if mana_bolt_level >= 3:
		projectile_count = 2  # Level 3+: 2 mana bolts
	if mana_bolt_level >= 6:
		projectile_count = 3  # Level 6+: 3 mana bolts
	if mana_bolt_level >= 10:
		projectile_count = 4  # Level 10+: 4 mana bolts
	
	# Get multiple targets for higher levels
	var targets = get_multiple_enemies(projectile_count)
	if targets.size() == 0:
		return
	
	# Play mana bolt sound
	if AudioManager:
		AudioManager.play_spell_sound("mana_bolt")
	
	# Create mana bolt particle effect
	var game_node = scene_tree.get_first_node_in_group("game")
	if game_node and game_node.particle_manager:
		game_node.particle_manager.create_mana_bolt_effect(player.global_position)
	
	# Fire multiple mana bolts with slight timing offset
	for i in range(projectile_count):
		var delay = i * 0.05  # 50ms delay between each mana bolt for smoother effect
		var target = targets[i % targets.size()]  # Cycle through available targets
		
		if delay > 0:
			scene_tree.create_timer(delay).timeout.connect(
				func(): create_mana_bolt_projectile(target, damage, i)
			)
		else:
			create_mana_bolt_projectile(target, damage, i)

# Helper function to create individual mana bolt projectiles
func create_mana_bolt_projectile(target: Node2D, damage: float, projectile_index: int):
	if not target or not is_instance_valid(target):
		return
	
	var scene_tree = get_tree()
	if not scene_tree:
		return
	
	var game_node = scene_tree.get_first_node_in_group("game")
	var projectile = null
	
	# Try to get from object pool first
	if game_node and game_node.has_method("get_pooled_object"):
		projectile = game_node.get_pooled_object("SpellProjectile")
	
	if not projectile:
		projectile = spell_projectile_scene.instantiate()
	
	if not projectile or not is_instance_valid(projectile):
		return
	
	# Vary color slightly for multiple mana bolts
	var base_color = Color.CYAN
	var hue_shift = fmod(projectile_index * 0.1, 1.0)
	var color_variation = Color.from_hsv(0.5 + hue_shift * 0.15, 0.8, 1.0)  # Cyan to blue range
	var projectile_color = base_color.lerp(color_variation, 0.3)
	
	# Slightly vary speed
	var speed_variation = 450.0 + (projectile_index * 25.0)
	projectile.speed = speed_variation
	
	# Strong homing for mana bolts
	projectile.homing_strength = 6.0
	
	projectile.setup_homing(player.global_position, target, damage, projectile_color, "mana_bolt")
	var parent = get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		projectile.queue_free()  # Clean up if we can't add it

# Main spell casting dispatcher
func cast_spell_by_type(slot: int):
	if not player or slot not in spells:
		return
	
	var spell_info = spells[slot]
	var spell_type = spell_info["type"]
	
	match spell_type:
		"projectile":
			cast_enhanced_bolt_spell(slot)
		"heal":
			cast_life_spell(slot)
		"aoe":
			cast_ice_blast_spell(slot)
		"shield":
			cast_earthshield_spell(slot)
		"chain":
			cast_lightning_arc_spell(slot)
		"multi_aoe":
			cast_meteor_shower_spell(slot)

# Individual spell implementations
func cast_bolt_spell(slot: int):
	if not player or not is_instance_valid(player):
		return
		
	var spell_info = spells.get(slot, {})
	if spell_info.is_empty():
		return
		
	var damage = calculate_spell_damage(spell_info)
	
	var closest_enemy = get_closest_enemy()
	if not closest_enemy or not is_instance_valid(closest_enemy):
		return
	
	# Create bolt spell particle effect
	var scene_tree = get_tree()
	if scene_tree:
		var game_node = scene_tree.get_first_node_in_group("game")
		if game_node and game_node.particle_manager:
			game_node.particle_manager.create_bolt_effect(player.global_position)
	
	# Create projectile
	if not spell_projectile_scene:
		return
	
	var projectile = spell_projectile_scene.instantiate()
	if not projectile or not is_instance_valid(projectile):
		return
	
	var direction = (closest_enemy.global_position - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	
	
	# Set projectile properties before calling setup
	projectile.speed = 600.0  # Faster than normal
	
	# Add to scene first, then setup (this ensures _ready() runs before setup)
	var parent = get_parent()
	if parent:
		parent.add_child(projectile)
		
		# Setup projectile after it's been added to the scene
		projectile.setup(player.global_position, direction, damage, Color.YELLOW, "bolt")
	else:
		projectile.queue_free()  # Clean up if we can't add it

# Enhanced bolt spell with spread firing + homing behavior for higher levels
func cast_enhanced_bolt_spell(slot: int):
	if not player or not is_instance_valid(player):
		return
		
	var spell_info = spells.get(slot, {})
	if spell_info.is_empty():
		return
		
	var damage = calculate_spell_damage(spell_info)
	var spell_level = spell_info["level"]
	
	# Higher level bolt spells fire multiple projectiles with spread + homing
	var projectile_count = 1 + (spell_level - 1)  # Level 1 = 1 bolt, Level 2 = 2 bolts, etc.
	projectile_count = min(projectile_count, 5)  # Cap at 5 projectiles
	
	# Get enemies for targeting (but allow spread even if no specific targets)
	var enemies = get_multiple_enemies(projectile_count * 2)  # Get more enemies than bolts for variety
	
	# Create bolt spell particle effect
	var scene_tree = get_tree()
	if scene_tree:
		var game_node = scene_tree.get_first_node_in_group("game")
		if game_node and game_node.particle_manager:
			game_node.particle_manager.create_bolt_effect(player.global_position)
	
	# Calculate base direction (toward closest enemy or player facing direction)
	var base_direction = Vector2.RIGHT  # Default direction
	if enemies.size() > 0:
		base_direction = (enemies[0].global_position - player.global_position).normalized()
	
	# Fire multiple spread + homing projectiles with timing delays
	for i in range(projectile_count):
		var delay = i * 0.12  # 120ms delay between each projectile for better visibility
		var spread_angle = 0.0
		
		# Add directional spread for multiple projectiles
		if projectile_count > 1:
			# Spread projectiles in an arc (±30 degrees total spread)
			var max_spread = PI / 6.0  # 30 degrees in radians
			var spread_step = max_spread * 2 / (projectile_count - 1)
			spread_angle = -max_spread + (i * spread_step)
		
		# Assign target (prefer different enemies, fallback to closest)
		var target = null
		if enemies.size() > 0:
			target = enemies[i % enemies.size()]  # Cycle through available enemies
		
		# Create spread + homing projectile with delay
		if delay > 0:
			scene_tree.create_timer(delay).timeout.connect(
				func(): create_spread_homing_bolt_projectile(base_direction, spread_angle, target, damage, i)
			)
		else:
			create_spread_homing_bolt_projectile(base_direction, spread_angle, target, damage, i)

# Helper function to create individual spread + homing bolt projectiles
func create_spread_homing_bolt_projectile(base_direction: Vector2, spread_angle: float, target: Node2D, damage: float, projectile_index: int):
	if not spell_projectile_scene:
		return
	
	var projectile = null
	
	# Try to get from object pool first
	var scene_tree = get_tree()
	if scene_tree:
		var game_node = scene_tree.get_first_node_in_group("game")
		if game_node and game_node.has_method("get_pooled_object"):
			projectile = game_node.get_pooled_object("SpellProjectile")
	
	# Fallback to creating new instance
	if not projectile:
		projectile = spell_projectile_scene.instantiate()
	
	if not projectile or not is_instance_valid(projectile):
		return
	
	# Apply spread angle to base direction for initial firing direction
	var initial_direction = base_direction.rotated(spread_angle)
	
	# Vary the color slightly for visual distinction between projectiles
	var base_color = Color.YELLOW
	var hue_shift = fmod(projectile_index * 0.15, 1.0)  # Cycle through hues
	var color_variation = Color.from_hsv(0.15 + hue_shift * 0.3, 0.9, 1.0)  # Yellow to orange range
	var projectile_color = base_color.lerp(color_variation, 0.5)
	
	# Slightly vary speed for additional visual distinction
	var speed_variation = 500.0 + (projectile_index * 30.0)  # Each bolt slightly faster
	projectile.speed = speed_variation
	
	# Set very subtle homing strength for spread bolts (allows many misses but provides minimal guidance)
	projectile.homing_strength = 1.5  # Very subtle homing to maintain spread pattern and allow many misses
	
	# Add to scene first, then setup (this ensures _ready() runs before setup)
	var parent = get_parent()
	if parent:
		parent.add_child(projectile)
		
		# Setup spread + homing projectile
		if target and is_instance_valid(target):
			# Has target: start with spread direction but gradually home to target
			projectile.setup_homing(player.global_position, target, damage, projectile_color, "bolt")
			# Override initial direction to use spread
			projectile.direction = initial_direction
		else:
			# No target: just fire in spread direction (will look for targets as it travels)
			projectile.setup(player.global_position, initial_direction, damage, projectile_color, "bolt")
			# Enable homing anyway in case enemies appear
			projectile.is_homing = true
			projectile.homing_strength = 2.5  # Light homing when no initial target
	else:
		projectile.queue_free()  # Clean up if we can't add it

# Helper function to get multiple enemy targets for multi-projectile spells
func get_multiple_enemies(count: int) -> Array:
	var scene_tree = get_tree()
	if not scene_tree:
		return []
	
	var enemies = scene_tree.get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return []
	
	# Sort enemies by distance from player
	var sorted_enemies = []
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance = player.global_position.distance_to(enemy.global_position)
		sorted_enemies.append({"enemy": enemy, "distance": distance})
	
	# Sort by distance (closest first)
	sorted_enemies.sort_custom(func(a, b): return a.distance < b.distance)
	
	# Return up to 'count' closest enemies
	var targets = []
	for i in range(min(count, sorted_enemies.size())):
		targets.append(sorted_enemies[i].enemy)
	
	return targets

func cast_life_spell(slot: int):
	var spell_info = spells[slot]
	var level_multiplier = 1.0 + 0.15 * (spell_info["level"] - 1)
	var heal_per_second = spell_info["heal_amount"] * level_multiplier
	var duration = spell_info["duration"]
	
	# Add healing over time effect
	var healing_effect = {
		"heal_per_second": heal_per_second,
		"remaining_time": duration
	}
	active_healing_effects.append(healing_effect)
	
	# Create persistent healing circle that follows player
	var scene_tree = get_tree()
	if scene_tree:
		var game_node = scene_tree.get_first_node_in_group("game")
		if game_node and game_node.particle_manager:
			game_node.particle_manager.create_persistent_life_circle(player, duration)

func cast_ice_blast_spell(slot: int):
	var spell_info = spells[slot]
	var damage = calculate_spell_damage(spell_info)
	var radius = spell_info["radius"] + (spell_info["level"] - 1) * 25  # Radius grows with level
	
	# Create player-centered ice explosion with knockback
	create_ice_explosion(player.global_position, radius, damage)

func cast_earthshield_spell(slot: int):
	var spell_info = spells[slot]
	var level_multiplier = 1.0 + 0.15 * (spell_info["level"] - 1)
	var overheal_amount = spell_info["shield_hp"] * level_multiplier
	
	# Add overheal to player instead of shield
	if player and player.has_method("add_overheal"):
		player.add_overheal(overheal_amount)
	
	# Create persistent shield circle that follows player
	# Duration based on how much overheal was provided (more overheal = longer visual)
	var visual_duration = 8.0 + (spell_info["level"] - 1) * 2.0  # 8-22 seconds based on level
	var scene_tree = get_tree()
	if scene_tree:
		var game_node = scene_tree.get_first_node_in_group("game")
		if game_node and game_node.particle_manager:
			game_node.particle_manager.create_persistent_shield_circle(player, visual_duration)

func cast_lightning_arc_spell(slot: int):
	var spell_info = spells[slot]
	var damage = calculate_spell_damage(spell_info)
	var chain_count = spell_info["chain_count"]
	
	var closest_enemy = get_closest_enemy()
	if not closest_enemy:
		return
	
	# Create initial lightning arc visual from player to first target
	create_lightning_arc_visual(player.global_position, closest_enemy.global_position, closest_enemy)
	
	# Start chain lightning
	chain_lightning(closest_enemy, damage, chain_count, [])

func cast_meteor_shower_spell(slot: int):
	var spell_info = spells[slot]
	var damage = calculate_spell_damage(spell_info)
	var meteor_count = spell_info["meteor_count"] + spell_info["level"] - 1  # More meteors at higher levels
	
	# Create multiple delayed meteors targeting enemy-dense areas
	for i in meteor_count:
		var delay = i * 0.3  # Faster intervals for more impact
		var target_pos: Vector2
		
		# Try to target areas with enemies, fallback to random positions around player
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.size() > 0:
			var random_enemy = enemies[randi() % enemies.size()]
			# Target near random enemy with some spread
			target_pos = random_enemy.global_position + Vector2(randf_range(-150, 150), randf_range(-150, 150))
		else:
			# No enemies, target around player
			target_pos = player.global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))
		
		# Create delayed meteor with larger radius and warning indicator
		var tree = get_tree()
		if tree:
			# Show warning indicator first
			create_meteor_warning(target_pos, delay)
			tree.create_timer(delay).timeout.connect(func(): create_meteor_strike(target_pos, damage * 0.8))

# Helper functions
func get_closest_enemy():
	var scene_tree = get_tree()
	if not scene_tree:
		return null
	var enemies = scene_tree.get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return null
	
	var closest_enemy = null
	var closest_distance = INF
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	
	return closest_enemy

func calculate_spell_damage(spell_info: Dictionary) -> float:
	var base_damage = spell_info["damage"]
	var spell_level = spell_info["level"]
	var level_multiplier = 1.0 + 0.15 * (spell_level - 1)
	var damage = base_damage * level_multiplier
	
	if player:
		damage *= player.spell_damage_multiplier
	
	return damage

func process_healing_effects(delta):
	for i in range(active_healing_effects.size() - 1, -1, -1):
		var effect = active_healing_effects[i]
		effect["remaining_time"] -= delta
		
		# Apply healing
		if player:
			player.heal(effect["heal_per_second"] * delta)
			healing_applied.emit(effect["heal_per_second"] * delta)
		
		# Remove expired effects
		if effect["remaining_time"] <= 0:
			active_healing_effects.remove_at(i)

# Visual effect functions
func create_healing_effect():
	# Create life spell particle effect
	var scene_tree = get_tree()
	if not scene_tree:
		return
	var game_node = scene_tree.get_first_node_in_group("game")
	if game_node and game_node.particle_manager:
		game_node.particle_manager.create_life_effect(player.global_position)
	
	var effect = spell_projectile_scene.instantiate()
	effect.setup_effect(player.global_position, Color.GREEN, "heal", 1.0)
	get_parent().add_child(effect)

func create_shield_effect():
	# Create earthshield particle effect
	var scene_tree = get_tree()
	if not scene_tree:
		return
	var game_node = scene_tree.get_first_node_in_group("game")
	if game_node and game_node.particle_manager:
		game_node.particle_manager.create_earthshield_effect(player.global_position)
	
	var effect = spell_projectile_scene.instantiate()
	effect.setup_effect(player.global_position, Color.ORANGE, "shield", 2.0)
	get_parent().add_child(effect)

func create_aoe_explosion(pos: Vector2, radius: float, damage: float, color: Color, effect_type: String):
	# Create spell-specific particle effect
	var scene_tree = get_tree()
	if not scene_tree:
		return
	var game_node = scene_tree.get_first_node_in_group("game")
	if game_node and game_node.particle_manager:
		if effect_type == "ice":
			game_node.particle_manager.create_ice_blast_effect(pos)
		else:
			game_node.particle_manager.create_spell_impact_effect(pos)
	
	# Create visual effect
	var effect = spell_projectile_scene.instantiate()
	effect.setup_aoe_effect(pos, radius, color, effect_type)
	get_parent().add_child(effect)
	
	# Deal damage to enemies in range
	var enemies = scene_tree.get_nodes_in_group("enemies")
	for enemy in enemies:
		var distance = pos.distance_to(enemy.global_position)
		if distance <= radius:
			enemy.take_damage(damage)
			# Apply slow effect for ice blast
			if effect_type == "ice" and enemy.has_method("apply_slow"):
				enemy.apply_slow(0.5, 3.0)  # 50% slow for 3 seconds

func create_meteor_strike(pos: Vector2, damage: float):
	# Create meteor shower particle effect
	var scene_tree = get_tree()
	if not scene_tree:
		return
	var game_node = scene_tree.get_first_node_in_group("game")
	if game_node and game_node.particle_manager:
		game_node.particle_manager.create_meteor_shower_effect(pos)
	
	# Larger radius and higher damage for meteors
	create_aoe_explosion(pos, 180, damage, Color.RED, "meteor")

func create_meteor_warning(pos: Vector2, delay: float):
	# Create a warning indicator at the target position
	var warning = spell_projectile_scene.instantiate()
	warning.setup_effect(pos, Color.ORANGE_RED, "warning", delay)
	get_parent().add_child(warning)

func create_ice_explosion(pos: Vector2, radius: float, damage: float):
	# Create ice blast particle effect
	var scene_tree = get_tree()
	if not scene_tree:
		return
	var game_node = scene_tree.get_first_node_in_group("game")
	if game_node and game_node.particle_manager:
		game_node.particle_manager.create_ice_blast_effect(pos)
	
	# Create expanding visual effect
	var effect = spell_projectile_scene.instantiate()
	effect.setup_aoe_effect(pos, radius, Color.LIGHT_BLUE, "ice")
	get_parent().add_child(effect)
	
	# Deal damage and apply knockback to enemies in range
	var enemies = scene_tree.get_nodes_in_group("enemies")
	for enemy in enemies:
		var distance = pos.distance_to(enemy.global_position)
		if distance <= radius:
			# Deal damage
			enemy.take_damage(damage)
			
			# Apply knockback - push enemies away from center
			if enemy.has_method("apply_knockback"):
				var knockback_direction = (enemy.global_position - pos).normalized()
				var knockback_strength = 500.0 * (1.0 - distance / radius)  # Stronger closer to center
				enemy.apply_knockback(knockback_direction, knockback_strength)
			
			# Apply slow effect
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(SLOW_EFFECT_STRENGTH, SLOW_EFFECT_DURATION)

func chain_lightning(target, damage: float, remaining_chains: int, hit_enemies: Array):
	if not target or not is_instance_valid(target) or remaining_chains <= 0:
		return
	
	# Damage current target
	target.take_damage(damage)
	hit_enemies.append(target)
	
	# Find next target
	var scene_tree = get_tree()
	if not scene_tree:
		return
	var enemies = scene_tree.get_nodes_in_group("enemies")
	var next_target = null
	var closest_distance = INF
	
	for enemy in enemies:
		if enemy in hit_enemies or not is_instance_valid(enemy):
			continue
		
		var distance = target.global_position.distance_to(enemy.global_position)
		if distance <= CHAIN_LIGHTNING_RANGE and distance < closest_distance:
			closest_distance = distance
			next_target = enemy
	
	# Create lightning visual effect with position validation
	if next_target and is_instance_valid(next_target):
		var from_pos = target.global_position
		var to_pos = next_target.global_position
		
		# Validate positions before creating arc
		if from_pos.length() > 5.0 and to_pos.length() > 5.0:
			create_lightning_arc_visual(from_pos, to_pos, next_target, target)
		else:
			print("Warning: Invalid chain lightning positions - skipping visual")
		
		# Chain to next target with reduced damage (with validation in callback)
		var tree = get_tree()
		if tree:
			tree.create_timer(0.1).timeout.connect(
				func(): 
					if is_instance_valid(next_target):
						chain_lightning(next_target, damage * CHAIN_DAMAGE_REDUCTION, remaining_chains - 1, hit_enemies)
			)

func create_lightning_arc_visual(from_pos: Vector2, to_pos: Vector2, target_enemy: Node2D = null, from_target: Node2D = null):
	# Validate positions to prevent top-left corner bugs
	if from_pos.length() < 5.0 or to_pos.length() < 5.0:
		print("Warning: Invalid lightning arc positions - from:", from_pos, " to:", to_pos)
		return
	
	# Create persistent lightning arc from specified source to target
	var scene_tree = get_tree()
	if not scene_tree:
		return
	var game_node = scene_tree.get_first_node_in_group("game")
	if game_node and game_node.particle_manager:
		# Create single particle effect at the start position only (reduce visual clutter)
		game_node.particle_manager.create_lightning_arc_effect(from_pos)
		
		# Use from_target if provided, otherwise default to player for initial cast
		var source_node = from_target if from_target else player
		
		# Validate source node before creating arc
		if not source_node or not is_instance_valid(source_node):
			print("Warning: Invalid source node for lightning arc, using position fallback")
			# Create a temporary node at the from_pos as fallback
			var temp_node = Node2D.new()
			temp_node.global_position = from_pos
			game_node.add_child(temp_node)
			game_node.particle_manager.create_persistent_lightning_arc(temp_node, to_pos, 0.5, target_enemy)
			# Clean up temp node after lightning duration
			scene_tree.create_timer(0.6).timeout.connect(func(): temp_node.queue_free())
		else:
			# Create persistent lightning arc that lasts 0.5 seconds (shorter for less overlap)
			game_node.particle_manager.create_persistent_lightning_arc(source_node, to_pos, 0.5, target_enemy)

# Player transparency effects
func _on_typing_started():
	if player_sprite:
		player_sprite.modulate.a = PLAYER_TRANSPARENCY_TYPING

func _on_typing_ended():
	if player_sprite:
		player_sprite.modulate.a = 1.0  # Full opacity


# Function to upgrade spells
func upgrade_spell(spell_name: String):
	# Handle mana bolt (auto-attack) separately
	if spell_name == "mana_bolt":
		mana_bolt_level += 1
		print("Mana Bolt upgraded to level ", mana_bolt_level)
		return
	
	# Find and upgrade the spell
	for slot in spells:
		var spell_info = spells[slot]
		if spell_info["name"] == spell_name:
			spell_info["level"] += 1
			print(spell_name.capitalize(), " upgraded to level ", spell_info["level"])
			return
		# Also check variations like "ice blast" vs "ice_blast"
		elif spell_info["name"].replace(" ", "_") == spell_name:
			spell_info["level"] += 1
			print(spell_name.capitalize(), " upgraded to level ", spell_info["level"])
			return

# Function to get mana bolt damage with scaling
func get_mana_bolt_damage() -> float:
	var level_multiplier = 1.0 + SPELL_DAMAGE_MULTIPLIER * (mana_bolt_level - 1)
	var damage = mana_bolt_damage * level_multiplier
	
	# Apply player's spell damage multiplier
	if player:
		damage *= player.spell_damage_multiplier
	
	return damage


# Get list of available spells for current player level
func get_available_spells() -> Array:
	var available = []
	if not player:
		return available
	
	for slot in spells:
		var spell_info = spells[slot]
		var unlock_level = spell_info.get("unlock_level", 1)
		if player.level >= unlock_level:
			available.append({
				"slot": slot,
				"name": spell_info["name"],
				"unlock_level": unlock_level
			})
	
	return available

# Get list of unlocked spell names (efficient version for LevelUpScreen)
func get_unlocked_spell_names() -> Array:
	# Check if we have a CharacterManager for persistent unlocks
	var character_manager = get_node_or_null("/root/CharacterManager")
	if character_manager and character_manager.has_method("get_unlocked_spells"):
		return character_manager.get_unlocked_spells()
	
	# Fallback to level-based unlocks if no CharacterManager
	var unlocked = ["mana_bolt"]  # mana_bolt is always available
	if not player:
		return unlocked
	
	for slot in spells:
		var spell_info = spells[slot]
		var unlock_level = spell_info.get("unlock_level", 1)
		if player.level >= unlock_level:
			unlocked.append(spell_info["name"])
	
	return unlocked

# Check if a specific spell is unlocked
func is_spell_unlocked(slot: int) -> bool:
	if not player or slot not in spells:
		return false
	
	var unlock_level = spells[slot].get("unlock_level", 1)
	return player.level >= unlock_level

# Unlock all spells (cheat command)
func unlock_all_spells():
	
	# Set all spell unlock levels to 1 (already unlocked)
	for slot in spells:
		spells[slot]["unlock_level"] = 1
	
	# Update the UI to reflect unlocked spells
	if game_manager and game_manager.has_method("update_spell_slot_lock_status"):
		game_manager.update_spell_slot_lock_status()
	
	# Print confirmation message
	print("All spells unlocked! You can now use all 6 spells regardless of level.")

# ========== FREEFORM CASTING SYSTEM ==========

func toggle_freeform_mode(action: String):
	match action:
		"on":
			freeform_mode = true
		"off":
			freeform_mode = false
		"toggle", _:
			freeform_mode = not freeform_mode
	
	# Clear any current typing state when switching modes
	if is_typing:
		cancel_typing()
	

func handle_freeform_input(event: InputEventKey):
	var key_code = event.keycode
	
	# Special keys that work in both modes
	if key_code == KEY_Y:
		unlock_all_spells()
		return
	
	# Start typing on any alphabetic key
	if not is_typing:
		# Check if it's a letter key
		if (key_code >= KEY_A and key_code <= KEY_Z) or key_code == KEY_SPACE:
			# Check spell cast cooldown to prevent rapid casting
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - last_spell_cast_time < SPELL_CAST_COOLDOWN:
				return
			
			start_freeform_typing()
			# Process this first character
			handle_freeform_typing_input(event)
		return
	
	# Handle typing input
	if is_typing:
		handle_freeform_typing_input(event)

func start_freeform_typing():
	if is_typing:
		return
	
	is_typing = true
	current_typing_text = ""
	target_spell = ""  # No target in freeform mode, we'll match dynamically
	
	# Apply cast speed - higher cast speed = less time dilation (faster typing)
	var cast_speed_bonus = player.cast_speed_multiplier if player else 1.0
	var adjusted_time_scale = TIME_SCALE_DURING_TYPING + (cast_speed_bonus - 1.0) * 0.5
	# Clamp between 0.2 (normal) and 0.8 (very fast)
	adjusted_time_scale = clamp(adjusted_time_scale, TIME_SCALE_DURING_TYPING, 0.8)
	
	Engine.time_scale = adjusted_time_scale
	
	typing_started.emit()
	update_freeform_typing_display()

func handle_freeform_typing_input(event: InputEventKey):
	if not is_typing:
		return
	
	if event.keycode == KEY_BACKSPACE:
		if current_typing_text.length() > 0:
			current_typing_text = current_typing_text.substr(0, current_typing_text.length() - 1)
			update_freeform_typing_display()
			# Play backspace sound
			if AudioManager:
				AudioManager.play_sound(AudioManager.SoundType.TYPING_BACKSPACE)
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		attempt_freeform_cast()
	elif event.keycode == KEY_ESCAPE:
		cancel_typing()
		# Play error sound for cancellation
		if AudioManager:
			AudioManager.on_typing_error()
	else:
		# Add character to typing text
		var char = char(event.unicode)
		if char.length() > 0 and (char.is_valid_identifier() or char == " "):
			current_typing_text += char.to_lower()
			update_freeform_typing_display()
			
			# Play typing sound for each character
			if AudioManager:
				AudioManager.play_typing_sound(char)
			
			# Check if we have a perfect match with any spell
			if current_typing_text in freeform_spells:
				attempt_freeform_cast()

func attempt_freeform_cast():
	var spell_name = current_typing_text.strip_edges()
	
	if spell_name in freeform_spells:
		cast_freeform_spell(spell_name)
		# Play successful cast completion sound
		if AudioManager:
			AudioManager.on_typing_complete()
	else:
		print("Unknown spell: ", spell_name)
		print("Available spells: ", freeform_spells.keys())
		cancel_typing()
		# Play error sound for unknown spell
		if AudioManager:
			AudioManager.on_typing_error()

func cast_freeform_spell(spell_name: String):
	if not spell_name in freeform_spells:
		return
	
	var spell_data = freeform_spells[spell_name]
	
	# Update last cast time
	last_spell_cast_time = Time.get_ticks_msec() / 1000.0
	
	# Play spell casting sound
	if AudioManager:
		AudioManager.play_spell_sound(spell_name)
	
	spell_cast.emit(spell_name)
	
	# Notify game manager about spell cast
	if game_manager and game_manager.has_method("increment_spells_cast"):
		game_manager.increment_spells_cast()
	
	# Cast the appropriate spell type
	cast_freeform_spell_by_type(spell_name, spell_data)
	
	end_typing()

func cast_freeform_spell_by_type(spell_name: String, spell_data: Dictionary):
	if not player or not is_instance_valid(player):
		return
	
	var spell_type = spell_data["type"]
	var damage = calculate_freeform_spell_damage(spell_data)
	
	
	match spell_type:
		"projectile":
			cast_freeform_projectile_spell(spell_name, spell_data, damage)
		"heal":
			cast_freeform_heal_spell(spell_name, spell_data)
		"instant_heal":
			cast_freeform_instant_heal_spell(spell_name, spell_data)
		"aoe":
			cast_freeform_aoe_spell(spell_name, spell_data, damage)
		"shield":
			cast_freeform_shield_spell(spell_name, spell_data)
		"chain":
			cast_freeform_chain_spell(spell_name, spell_data, damage)
		"multi_aoe":
			cast_freeform_multi_aoe_spell(spell_name, spell_data, damage)
		"utility":
			cast_freeform_utility_spell(spell_name, spell_data)
		"debuff":
			cast_freeform_debuff_spell(spell_name, spell_data)
		"buff":
			cast_freeform_buff_spell(spell_name, spell_data)
		_:
			print("Unknown freeform spell type: ", spell_type)

func calculate_freeform_spell_damage(spell_data: Dictionary) -> float:
	var base_damage = spell_data.get("damage", 0)
	var spell_level = spell_data.get("level", 1)
	var level_multiplier = 1.0 + 0.15 * (spell_level - 1)
	var damage = base_damage * level_multiplier
	
	if player:
		damage *= player.spell_damage_multiplier
	
	return damage

func update_freeform_typing_display():
	if game_manager and game_manager.has_method("update_typing_display"):
		var display_text = ""
		if is_typing:
			var potential_matches = []
			for spell in freeform_spells:
				if spell.begins_with(current_typing_text) and current_typing_text.length() > 0:
					potential_matches.append(spell)
			
			display_text = "Freeform Casting\nTyped: " + current_typing_text
			if potential_matches.size() > 0:
				display_text += "\nMatches: " + ", ".join(potential_matches.slice(0, 3))
				if potential_matches.size() > 3:
					display_text += "..."
		game_manager.update_typing_display(display_text)

# Freeform spell implementations (basic versions for testing)
func cast_freeform_projectile_spell(spell_name: String, spell_data: Dictionary, damage: float):
	var closest_enemy = get_closest_enemy()
	if not closest_enemy:
		return
	
	var projectile = spell_projectile_scene.instantiate()
	if not projectile:
		return
	
	# Determine color based on spell name
	var color = Color.CYAN
	match spell_name:
		"bolt", "lightning":
			color = Color.YELLOW
		"fireball":
			color = Color.ORANGE_RED
		"magic missile":
			color = Color.CYAN
	
	projectile.setup_homing(player.global_position, closest_enemy, damage, color, spell_name)
	get_parent().add_child(projectile)

func cast_freeform_heal_spell(spell_name: String, spell_data: Dictionary):
	# Heal over time (like existing life spell)
	var heal_amount = spell_data.get("heal_amount", 8)
	var duration = spell_data.get("duration", 5)
	
	var healing_effect = {
		"heal_per_second": heal_amount,
		"remaining_time": duration
	}
	active_healing_effects.append(healing_effect)
	
	var scene_tree = get_tree()
	if scene_tree:
		var game_node = scene_tree.get_first_node_in_group("game")
		if game_node and game_node.particle_manager:
			game_node.particle_manager.create_persistent_life_circle(player, duration)

func cast_freeform_instant_heal_spell(spell_name: String, spell_data: Dictionary):
	# Instant healing
	var heal_amount = spell_data.get("heal_amount", 25)
	if player:
		player.heal(heal_amount)
		print("Instant heal: +", heal_amount, " health")

func cast_freeform_aoe_spell(spell_name: String, spell_data: Dictionary, damage: float):
	# Area of effect spell centered on player
	var radius = spell_data.get("radius", 350)
	var color = Color.LIGHT_BLUE if spell_name == "ice blast" else Color.RED
	
	create_aoe_explosion(player.global_position, radius, damage, color, spell_name)

func cast_freeform_shield_spell(spell_name: String, spell_data: Dictionary):
	# Shield/barrier spell
	var shield_hp = spell_data.get("shield_hp", 40)
	
	if player and player.has_method("add_overheal"):
		player.add_overheal(shield_hp)
	
	var visual_duration = 8.0
	var scene_tree = get_tree()
	if scene_tree:
		var game_node = scene_tree.get_first_node_in_group("game")
		if game_node and game_node.particle_manager:
			game_node.particle_manager.create_persistent_shield_circle(player, visual_duration)

func cast_freeform_chain_spell(spell_name: String, spell_data: Dictionary, damage: float):
	# Chain lightning spell
	var chain_count = spell_data.get("chain_count", 3)
	
	var closest_enemy = get_closest_enemy()
	if not closest_enemy:
		return
	
	create_lightning_arc_visual(player.global_position, closest_enemy.global_position, closest_enemy)
	chain_lightning(closest_enemy, damage, chain_count, [])

func cast_freeform_multi_aoe_spell(spell_name: String, spell_data: Dictionary, damage: float):
	# Multiple AoE attacks (meteor shower style)
	var meteor_count = spell_data.get("meteor_count", 3)
	
	for i in meteor_count:
		var delay = i * 0.3
		var target_pos: Vector2
		
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.size() > 0:
			var random_enemy = enemies[randi() % enemies.size()]
			target_pos = random_enemy.global_position + Vector2(randf_range(-150, 150), randf_range(-150, 150))
		else:
			target_pos = player.global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))
		
		var tree = get_tree()
		if tree:
			create_meteor_warning(target_pos, delay)
			tree.create_timer(delay).timeout.connect(func(): create_meteor_strike(target_pos, damage * 0.8))

func cast_freeform_utility_spell(spell_name: String, spell_data: Dictionary):
	match spell_name:
		"teleport":
			# Teleport player to mouse position
			var mouse_pos = get_global_mouse_position()
			if player:
				player.global_position = mouse_pos
				print("Teleported to: ", mouse_pos)

func cast_freeform_debuff_spell(spell_name: String, spell_data: Dictionary):
	match spell_name:
		"slow":
			# Slow all enemies
			var enemies = get_tree().get_nodes_in_group("enemies")
			for enemy in enemies:
				if enemy.has_method("apply_slow"):
					enemy.apply_slow(0.5, 5.0)  # 50% slow for 5 seconds
			print("Slowed all enemies")

func cast_freeform_buff_spell(spell_name: String, spell_data: Dictionary):
	match spell_name:
		"haste":
			# Temporary speed boost for player
			if player:
				var original_speed = player.movement_speed_multiplier
				player.movement_speed_multiplier *= 1.5
				print("Haste activated: +50% movement speed for 10 seconds")
				# Restore speed after duration
				var tree = get_tree()
				if tree:
					tree.create_timer(10.0).timeout.connect(
						func(): 
							if player:
								player.movement_speed_multiplier = original_speed
								print("Haste effect ended")
					)
