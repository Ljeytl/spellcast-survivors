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
const PLAYER_TRANSPARENCY_TYPING = 1.0
const METEOR_DELAY_INTERVAL = 0.5
const METEOR_SPREAD_RANGE = 300.0
const AOE_RADIUS_METEOR = 100.0
const SLOW_EFFECT_STRENGTH = 0.5
const SLOW_EFFECT_DURATION = 3.0
const SPELL_CAST_COOLDOWN = 0.1  # Minimum time between spell casts

var spell_projectile_scene = preload("res://scenes/SpellProjectile.tscn")

const Synergies = preload("res://scripts/SynergyCatalog.gd")
@export_range(0.1, 30.0, 0.1) var typing_slowdown_capacity: float = 3.0
@export_range(0.1, 60.0, 0.1) var typing_slowdown_refill_seconds: float = 10.0
var typing_slowdown_remaining: float = 3.0
var _scale_change_frame: int = -1
var _scale_before_change: float = 1.0
var space_casting = false
var last_cast_failure: String = ""

const MAX_EQUIPPED_SPELLS = 6
const BASE_SPELL_IDS = ["bolt", "life", "regeneration", "ice_blast", "earth_shield", "lightning_arc", "meteor_shower", "ember_lance", "plague_seed", "cinder_field", "arcane_orbit", "focus_ray", "rune_trap", "seeking_spirit", "ember_trail", "returning_blade"]
var spell_catalog: Dictionary = {}
var evolved_ingredients: Dictionary = {}
var bonus_spells: Dictionary = {}
var acquired_spells: Dictionary = {"bolt": true}

var spell_queue: Array = []
var current_typing_text: String = ""
var is_typing: bool = false
var target_spell: String = ""
var casting_clock: float = 0.0
var last_spell_cast_time: float = -1.0

# Freeform casting system
var freeform_mode: bool = false

# Data-driven spell definitions loaded from DataManager
var spells = {}

# Freeform spell library loaded from DataManager
var freeform_spells: Dictionary = {}

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
	typing_slowdown_remaining = typing_slowdown_capacity
	# Clear any existing queue
	spell_queue.clear()
	
	# Load spell data from DataManager
	load_spells_from_data()
	rebuild_freeform_library()
	
	# Find player sprite for transparency effect
	if player:
		player_sprite = player.get_node("Sprite2D")
	
	# Connect to typing signals for player transparency
	typing_started.connect(_on_typing_started)
	typing_ended.connect(_on_typing_ended)

# Load spells from DataManager
func load_spells_from_data():
	spells.clear()
	bonus_spells.clear()
	acquired_spells = {"bolt": true}
	evolved_ingredients.clear()
	spell_catalog.clear()
	var data = DataManager.get_all_spells()
	for id in BASE_SPELL_IDS:
		if not data.has(id):
			continue
		var info = data[id].duplicate(true)
		info.id = id
		info.display_name = info.get("incantation", id.replace("_", " "))
		info.chars = info.display_name.length()
		info.level = 1
		info.damage = info.get("damage", 0)
		spell_catalog[id] = info
	spells[1] = spell_catalog.bolt.duplicate(true)

func _process(delta):
	var frame_scale = _scale_before_change if _scale_change_frame == Engine.get_process_frames() else Engine.time_scale
	var unscaled_delta = delta / maxf(frame_scale, 0.01)
	casting_clock += unscaled_delta
	advance_typing_slowdown(unscaled_delta)
	# Handle auto-attack mana bolt
	handle_auto_attack(delta)
	
	# Process healing over time effects
	process_healing_effects(delta)

func _input(event):
	if event is InputEventKey and event.pressed:
		if is_typing and event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
		handle_key_input(event)

func handle_key_input(event: InputEventKey):
	if event.echo and event.keycode != KEY_BACKSPACE:
		return
	if space_casting:
		handle_freeform_typing_input(event)
		return
	if event.keycode == KEY_SPACE and not is_typing and not event.echo:
		if casting_clock - last_spell_cast_time >= SPELL_CAST_COOLDOWN:
			space_casting = true
			start_freeform_typing()
		return
	# Handle freeform mode input
	if freeform_mode:
		handle_freeform_input(event)
		return
	
	# Handle normal slot-based input
	var key_code = event.keycode
	
	if key_code >= KEY_1 and key_code <= KEY_6:
		activate_spell_slot(key_code - KEY_0)
		return

	if is_typing:
		handle_typing_input(event)

func activate_spell_slot(slot: int) -> bool:
	if not game_manager or game_manager.current_state != game_manager.GameState.PLAYING or is_typing:
		return false
	if not is_spell_unlocked(slot):
		game_manager.show_gameplay_feedback("Empty slot · Learn a spell when you level up")
		return false
	if casting_clock - last_spell_cast_time < SPELL_CAST_COOLDOWN:
		game_manager.show_gameplay_feedback("Spell recovering · Try again in a moment")
		return false
	spell_queue.clear()
	queue_spell(slot)
	start_typing()
	return is_typing

func queue_spell(slot: int):
	if not is_spell_unlocked(slot):
		return
	var info = get_spell_info(slot)
	if not is_spell_unlocked(slot):
		spell_locked_error.emit(info.name, 0, player.level)
		return
	spell_queue.append({"slot": slot, "name": info.name, "display_name": info.display_name})
	spell_queued.emit(info.name, slot)

func start_typing():
	if spell_queue.size() == 0:
		return
	
	# Prevent starting typing if already typing
	if is_typing:
		return
	
	is_typing = true
	typing_slowdown_remaining = typing_slowdown_capacity
	current_typing_text = ""
	target_spell = spell_queue[0].get("display_name", spell_queue[0]["name"].to_lower())
	
	_apply_typing_slowdown()

	typing_started.emit()
	update_typing_display()

func advance_typing_slowdown(unscaled_delta: float):
	if is_typing:
		typing_slowdown_remaining = maxf(0.0, typing_slowdown_remaining - maxf(unscaled_delta, 0.0))
		_apply_typing_slowdown()

func _set_typing_time_scale(value: float):
	var frame = Engine.get_process_frames()
	if _scale_change_frame != frame:
		_scale_change_frame = frame
		_scale_before_change = Engine.time_scale
	Engine.time_scale = value

func _apply_typing_slowdown():
	if typing_slowdown_remaining <= 0.0:
		_set_typing_time_scale(1.0)
	else:
		_set_typing_time_scale(TIME_SCALE_DURING_TYPING)
	if game_manager and game_manager.has_method("update_typing_slowdown"):
		game_manager.update_typing_slowdown(typing_slowdown_remaining, typing_slowdown_capacity)

func handle_typing_input(event: InputEventKey):
	if event.echo and event.keycode != KEY_BACKSPACE:
		return
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
		if cast_spell() and AudioManager:
			AudioManager.on_typing_complete()
	else:
		var feedback = "Keep typing" if target_spell.begins_with(current_typing_text) else "Mismatch"
		game_manager.update_typing_display(target_spell + " › " + current_typing_text + " · " + feedback)
		# Play error sound for mistyped spell
		if AudioManager:
			AudioManager.on_typing_error()

func cast_spell() -> bool:
	last_cast_failure = ""
	if spell_queue.is_empty():
		return false
	var spell_data = spell_queue[0]
	var spell_name = spell_data["name"]
	if not cast_spell_by_type(spell_data["slot"]):
		if not last_cast_failure.is_empty() and game_manager:
			game_manager.update_typing_display(current_typing_text + " · " + last_cast_failure)
		return false
	spell_queue.pop_front()
	last_spell_cast_time = casting_clock
	if AudioManager:
		AudioManager.play_spell_sound(spell_name)
	spell_cast.emit(spell_name)
	if game_manager and game_manager.has_method("increment_spells_cast"):
		game_manager.increment_spells_cast()
	end_typing()
	return true

func cancel_typing():
	spell_queue.clear()
	end_typing()

func end_typing():
	space_casting = false
	is_typing = false
	current_typing_text = ""
	target_spell = ""
	
	# Force time scale back to normal - this is critical
	_set_typing_time_scale(1.0)
	
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
			display_text = target_spell + "  ›  " + (current_typing_text if not current_typing_text.is_empty() else "Start typing…")
			if not target_spell.begins_with(current_typing_text):
				display_text += " · Mismatch"
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
	
	# Create mana bolt visual effect (simple flash)
	create_simple_spell_flash(player.global_position, Color.CYAN)
	
	# Fire multiple mana bolts with slight timing offset
	for i in range(projectile_count):
		var delay = i * 0.05  # 50ms delay between each mana bolt for smoother effect
		var target = targets[i % targets.size()]  # Cycle through available targets
		
		if delay > 0:
			scene_tree.create_timer(delay).timeout.connect(
				_delayed_mana_bolt.bind(weakref(target), damage, i)
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
	projectile.speed = speed_variation * player.projectile_speed_multiplier
	
	# Strong homing for mana bolts
	projectile.homing_strength = 6.0
	
	projectile.setup_homing(player.global_position, target, damage, projectile_color, "mana_bolt")
	var parent = get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		projectile.queue_free()  # Clean up if we can't add it

# Main spell casting dispatcher
func cast_spell_by_type(slot: int) -> bool:
	last_cast_failure = ""
	if not player or not is_spell_unlocked(slot):
		return false
	
	var spell_info = get_spell_info(slot)
	var spell_type = spell_info["type"]
	
	match spell_type:
		"life_bolt":
			cast_life_bolt(slot)
		"piercing", "plague", "field", "orbit", "beam", "trap", "spirit", "trail", "returning":
			return cast_build_spell(slot)
		"projectile":
			cast_enhanced_bolt_spell(slot)
		"heal":
			player.heal(float(spell_info.heal_amount) * (1.0 + 0.15 * (spell_info.level - 1)))
		"heal_over_time":
			cast_life_spell(slot)
		"aoe":
			cast_ice_blast_spell(slot)
		"shield":
			cast_earthshield_spell(slot)
		"chain", "direct_strike":
			cast_lightning_arc_spell(slot)
		"bouncing_projectile":
			cast_bouncing_bolt(slot)
		"multi_aoe":
			cast_meteor_shower_spell(slot)
	return true

# Individual spell implementations
func cast_bolt_spell(slot: int):
	if not player or not is_instance_valid(player):
		return
		
	var spell_info = get_spell_info(slot)
	if spell_info.is_empty():
		return
		
	var damage = calculate_spell_damage(spell_info)
	
	var closest_enemy = get_closest_enemy()
	if not closest_enemy or not is_instance_valid(closest_enemy):
		return
	
	# Create bolt visual effect (lightning flash)
	create_simple_spell_flash(player.global_position, Color.YELLOW)
	
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
	projectile.speed = 600.0 * player.projectile_speed_multiplier  # Faster than normal
	
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
		
	var spell_info = get_spell_info(slot)
	if spell_info.is_empty():
		return
		
	var damage = calculate_spell_damage(spell_info)
	var spell_level = spell_info["level"]
	
	# Higher level bolt spells fire multiple projectiles with spread + homing
	var projectile_count = 1 + (spell_level - 1)  # Level 1 = 1 bolt, Level 2 = 2 bolts, etc.
	projectile_count = min(projectile_count, 5)  # Cap at 5 projectiles
	
	# Get enemies for targeting (but allow spread even if no specific targets)
	var enemies = get_multiple_enemies(projectile_count * 2)  # Get more enemies than bolts for variety
	
	# Create bolt visual effect (lightning flash)
	create_simple_spell_flash(player.global_position, Color.YELLOW)
	
	# Get scene tree for timer functionality
	var scene_tree = get_tree()
	if not scene_tree:
		return
	
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
				_delayed_spread_bolt.bind(base_direction, spread_angle, weakref(target) if target else null, damage, i)
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
	projectile.speed = speed_variation * player.projectile_speed_multiplier
	
	# Set very subtle homing strength for spread bolts (allows many misses but provides minimal guidance)
	projectile.homing_strength = 1.5  # Very subtle homing to maintain spread pattern and allow many misses
	
	# Add to scene first, then setup (this ensures _ready() runs before setup)
	var parent = get_parent()
	if parent:
		parent.add_child(projectile)
		
		projectile.setup(player.global_position, initial_direction, damage, projectile_color, "bolt")
		projectile.is_homing = false
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
		if not _live_spell_target(enemy):
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
	var spell_info = get_spell_info(slot)
	var level_multiplier = 1.0 + 0.15 * (spell_info["level"] - 1)
	var heal_per_second = spell_info["heal_amount"] * level_multiplier
	var duration = spell_info["duration"]
	
	# Add healing over time effect
	var healing_effect = {
		"heal_per_second": heal_per_second,
		"remaining_time": duration
	}
	active_healing_effects.append(healing_effect)
	

func cast_ice_blast_spell(slot: int):
	print("🧊 cast_ice_blast_spell called!")
	var spell_info = get_spell_info(slot)
	var damage = calculate_spell_damage(spell_info)
	var radius = spell_info.get("radius", 400) + (spell_info["level"] - 1) * 25  # Radius grows with level
	var knockback = spell_info.get("knockback", 400) + (spell_info["level"] - 1) * 50  # Knockback grows with level
	var slow_duration = spell_info.get("slow_duration", 2.0)
	var slow_strength = spell_info.get("slow_effect", 0.3)
	
	print("🧊 Ice blast: radius=", radius, " damage=", damage, " player_pos=", player.global_position)
	create_ice_explosion(player.global_position, radius, damage, knockback, slow_duration, slow_strength)

func cast_earthshield_spell(slot: int):
	var spell_info = get_spell_info(slot)
	var level_multiplier = 1.0 + 0.15 * (spell_info["level"] - 1)
	var overheal_amount = spell_info["shield_hp"] * level_multiplier
	
	# Add overheal to player instead of shield
	if player and player.has_method("add_overheal"):
		player.add_overheal(overheal_amount)
	
	# Create shield visual effect
	create_shield_effect()

func cast_lightning_arc_spell(slot: int):
	var target = get_closest_enemy()
	if not _live_spell_target(target):
		return
	var damage = calculate_spell_damage(get_spell_info(slot))
	create_lightning_arc_visual(player.global_position, target.global_position, target)
	target.take_damage(damage, player.global_position)

func cast_bouncing_bolt(slot: int):
	var info = get_spell_info(slot)
	var target = get_closest_enemy()
	if not _live_spell_target(target):
		return
	var projectile = spell_projectile_scene.instantiate()
	projectile.speed = 550.0 * player.projectile_speed_multiplier
	projectile.set_meta("bounce_count", int(info.get("bounce_count", 2)))
	projectile.set_meta("bounce_range", float(info.get("bounce_range", 240.0)))
	get_parent().add_child(projectile)
	projectile.setup_homing(player.global_position, target, calculate_spell_damage(info), Color("d8eaff"), "lightning_bolt")

func cast_meteor_shower_spell(slot: int):
	var spell_info = get_spell_info(slot)
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
			create_meteor_warning(target_pos, delay, 180.0)
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
		if not _live_spell_target(enemy):
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
	
	return damage * float(spell_info.get("damage_multiplier", 1.0))

func process_healing_effects(delta):
	for i in range(active_healing_effects.size() - 1, -1, -1):
		var effect = active_healing_effects[i]
		var elapsed = min(delta, max(0.0, effect["remaining_time"]))
		effect["remaining_time"] -= elapsed
		if player:
			var previous_health = player.health
			player.heal(effect["heal_per_second"] * elapsed)
			healing_applied.emit(player.health - previous_health)
		if effect["remaining_time"] <= 0:
			active_healing_effects.remove_at(i)

# Visual effect functions
func create_simple_spell_flash(pos: Vector2, color: Color):
	# Create a simple visual flash effect without circles
	var flash = spell_projectile_scene.instantiate()
	if flash:
		flash.setup_effect(pos, color, "flash", 0.3)
		flash.scale = Vector2(0.5, 0.5)  # Make it smaller than AoE effects
		get_parent().add_child(flash)

func create_shield_effect():
	var particles = get_parent().get("particle_manager")
	if is_instance_valid(particles) and particles.has_method("create_persistent_shield_circle"):
		particles.create_persistent_shield_circle(player, player.overheal_duration)

func create_aoe_explosion(pos: Vector2, radius: float, damage: float, color: Color, effect_type: String):
	# Create satisfying area effect explosion
	var effect = spell_projectile_scene.instantiate()
	effect.setup_aoe_effect(pos, radius, color, effect_type)
	get_parent().add_child(effect)
	
	# Deal damage to enemies in range
	var scene_tree = get_tree()
	if not scene_tree:
		return
	var enemies = scene_tree.get_nodes_in_group("enemies")
	for enemy in enemies:
		var distance = pos.distance_to(enemy.global_position)
		if distance <= radius:
			enemy.take_damage(damage)
			# Apply slow effect for ice blast
			if effect_type == "ice" and enemy.has_method("apply_slow"):
				enemy.apply_slow(0.5, 3.0)  # 50% slow for 3 seconds

func create_meteor_strike(pos: Vector2, damage: float):
	# Larger radius and higher damage for meteors with big explosion
	create_aoe_explosion(pos, 180, damage, Color.RED, "meteor")

func create_meteor_warning(pos: Vector2, delay: float, radius: float = 180.0):
	# Create a warning indicator at the target position showing the impact radius
	var warning = spell_projectile_scene.instantiate()
	warning.setup_aoe_effect(pos, radius, Color.ORANGE_RED, "warning")
	warning.lifetime = delay
	get_parent().add_child(warning)

func create_ice_explosion(pos: Vector2, radius: float, damage: float, knockback_base: float = 200, slow_duration: float = 2.0, slow_strength: float = 0.6):
	var target = get_closest_enemy()
	var direction = pos.direction_to(target.global_position) if target else Vector2.RIGHT
	var half_angle = deg_to_rad(45.0)
	var particles = get_parent().get("particle_manager")
	if is_instance_valid(particles) and particles.has_method("create_directional_effect"):
		particles.create_directional_effect(pos, direction, "ice", radius, half_angle)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not _live_spell_target(enemy):
			continue
		var offset: Vector2 = enemy.global_position - pos
		var distance = offset.length()
		if distance > radius or (distance > 0.001 and direction.dot(offset.normalized()) < cos(half_angle)):
			continue
		enemy.take_damage(damage)
		if enemy.has_method("apply_knockback"):
			var strength = knockback_base * (1.2 + (1.0 - distance / radius) * 0.8)
			enemy.apply_knockback(offset.normalized(), strength)
		if enemy.has_method("apply_slow"):
			enemy.apply_slow(slow_strength, slow_duration)

func chain_lightning(target, damage: float, remaining_chains: int, hit_enemies: Array):
	if not _live_spell_target(target) or remaining_chains <= 0:
		return
	
	# Damage current target
	target.take_damage(damage)
	hit_enemies.append(target.get_instance_id())
	
	# Find next target
	var scene_tree = get_tree()
	if not scene_tree:
		return
	var enemies = scene_tree.get_nodes_in_group("enemies")
	var next_target = null
	var closest_distance = INF
	
	for enemy in enemies:
		if not _live_spell_target(enemy) or enemy.get_instance_id() in hit_enemies:
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
				_delayed_chain.bind(weakref(next_target), damage * CHAIN_DAMAGE_REDUCTION, remaining_chains - 1, hit_enemies.duplicate())
			)

func create_lightning_arc_visual(from_pos: Vector2, to_pos: Vector2, target_enemy: Node2D = null, from_target: Node2D = null):
	# Validate positions to prevent top-left corner bugs
	if from_pos.length() < 5.0 or to_pos.length() < 5.0:
		print("Warning: Invalid lightning arc positions - from:", from_pos, " to:", to_pos)
		return
	
	# Create lightning arc visual effect
	var lightning = spell_projectile_scene.instantiate()
	lightning.setup_lightning_arc(from_pos, to_pos, Color.YELLOW)
	get_parent().add_child(lightning)

# Player transparency effects
func _on_typing_started():
	if player_sprite:
		player_sprite.modulate.a = PLAYER_TRANSPARENCY_TYPING

func _on_typing_ended():
	if player_sprite:
		player_sprite.modulate.a = 1.0  # Full opacity


# Function to upgrade spells
func upgrade_spell(spell_name: String):
	if spell_name == "mana_bolt":
		mana_bolt_level += 1
		return
	var slot = find_spell_slot(spell_name)
	if is_spell_unlocked(slot):
		get_spell_info(slot).level += 1

func get_mana_bolt_damage() -> float:
	var level_multiplier = 1.0 + SPELL_DAMAGE_MULTIPLIER * (mana_bolt_level - 1)
	var damage = mana_bolt_damage * level_multiplier
	
	# Apply player's spell damage multiplier
	if player:
		damage *= player.spell_damage_multiplier
	
	return damage


# Get list of available spells for current player level
func get_available_spells() -> Array:
	var available: Array = []
	for slot in get_all_spells():
		if is_spell_unlocked(slot):
			available.append({"slot": slot, "name": get_spell_info(slot).name, "unlock_level": 1})
	return available

func get_unlocked_spell_names() -> Array:
	var owned: Array = ["mana_bolt"]
	for id in acquired_spells:
		owned.append(id)
	return owned

func is_spell_unlocked(slot: int) -> bool:
	var info = get_spell_info(slot)
	return not info.is_empty() and acquired_spells.has(info.id)

func unlock_all_spells():
	for id in BASE_SPELL_IDS:
		if spells.size() >= MAX_EQUIPPED_SPELLS:
			break
		learn_spell(id)
	game_manager.update_spell_slot_lock_status()


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
	
	# Start typing on any alphabetic key
	if not is_typing:
		# Check if it's a letter key
		if (key_code >= KEY_A and key_code <= KEY_Z) or key_code == KEY_SPACE:
			# Check spell cast cooldown to prevent rapid casting
			var current_time = casting_clock
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
	typing_slowdown_remaining = typing_slowdown_capacity
	current_typing_text = ""
	target_spell = ""  # No target in freeform mode, we'll match dynamically
	
	_apply_typing_slowdown()

	typing_started.emit()
	update_freeform_typing_display()

func handle_freeform_typing_input(event: InputEventKey):
	if event.echo and event.keycode != KEY_BACKSPACE:
		return
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
			if not space_casting and current_typing_text in freeform_spells:
				attempt_freeform_cast()

func attempt_freeform_cast():
	var spell_name = current_typing_text.strip_edges().to_lower()
	if cast_freeform_spell(spell_name):
		if AudioManager:
			AudioManager.on_typing_complete()
	elif is_typing:
		game_manager.update_typing_display(current_typing_text + " · " + (last_cast_failure if not last_cast_failure.is_empty() else "Spell unavailable in this run"))

func cast_freeform_spell(spell_name: String) -> bool:
	last_cast_failure = ""
	var slot = find_cast_spell_slot(spell_name)
	if not is_spell_unlocked(slot):
		if slot in spells:
			spell_locked_error.emit(get_spell_info(slot).name, 0, player.level)
		return false
	spell_queue.clear()
	queue_spell(slot)
	return cast_spell()

func cast_life_bolt(slot: int):
	var projectile = spell_projectile_scene.instantiate()
	projectile.speed *= player.projectile_speed_multiplier
	projectile.set_meta("healing_seed_amount", 6.0)
	projectile.set_meta("healing_seed_duration", 2.0)
	projectile.set_meta("healing_seed_lifetime", 10.0)
	projectile.set_meta("healing_seed_cap", 6)
	projectile.set_meta("healing_seed_owner", weakref(player))
	get_parent().add_child(projectile)
	var target = get_closest_enemy()
	var direction = player.global_position.direction_to(target.global_position) if _live_spell_target(target) else Vector2.RIGHT
	projectile.setup(player.global_position, direction, calculate_spell_damage(get_spell_info(slot)), Color.GREEN, "life_bolt")

func add_healing_effect(amount: float, duration: float):
	if amount <= 0.0 or duration <= 0.0 or not is_instance_valid(player):
		return
	active_healing_effects.append({"heal_per_second": amount / duration, "remaining_time": duration})

func get_owned_incantations() -> Array:
	var names: Array = []
	for slot in get_all_spells():
		if is_spell_unlocked(slot):
			names.append(get_spell_info(slot).display_name)
	return names

func cast_freeform_spell_by_type(spell_name: String, _spell_data: Dictionary):
	var slot = find_spell_slot(spell_name)
	if is_spell_unlocked(slot):
		cast_spell_by_type(slot)

func update_freeform_typing_display():
	if game_manager and game_manager.has_method("update_typing_display"):
		var display_text = ""
		if is_typing:
			var potential_matches = []
			for info in get_all_spells().values():
				var normalized = current_typing_text.strip_edges().to_lower().replace("_", " ")
				for alias in [info.name, info.display_name]:
					if str(alias).to_lower().replace("_", " ").begins_with(normalized) and not normalized.is_empty():
						potential_matches.append(info.display_name)
						break
			
			display_text = current_typing_text if not current_typing_text.is_empty() else "Type an equipped spell…"
			if not current_typing_text.is_empty() and potential_matches.is_empty():
				display_text += " · No matching spell"
			if potential_matches.size() > 0:
				display_text += " · Ready to cast" if find_cast_spell_slot(current_typing_text) != 0 else " · Matches: " + potential_matches[0]
				if potential_matches.size() > 1 and find_cast_spell_slot(current_typing_text) == 0:
					display_text += " (+%d)" % (potential_matches.size() - 1)
		game_manager.update_typing_display(display_text)

func get_all_spells() -> Dictionary:
	var all = spells.duplicate()
	all.merge(bonus_spells)
	return all

func get_spell_info(slot: int) -> Dictionary:
	return spells.get(slot, bonus_spells.get(slot, {}))

func find_spell_slot(spell_name: String) -> int:
	var normalized = spell_name.strip_edges().to_lower().replace("_", " ")
	for slot in get_all_spells():
		var info = get_spell_info(slot)
		for alias in [info.id, info.name, info.display_name]:
			if str(alias).to_lower().replace("_", " ") == normalized:
				return slot
	return 0

func find_cast_spell_slot(spell_name: String) -> int:
	var normalized = spell_name.strip_edges().to_lower()
	for slot in get_all_spells():
		var info = get_spell_info(slot)
		if normalized == info.display_name or normalized == str(info.name).to_lower():
			return slot
	return 0

func learn_spell(spell_id: String) -> bool:
	if acquired_spells.has(spell_id):
		return false
	if spell_id in Synergies.RECIPES:
		if not synergy_eligible(spell_id):
			return false
		var recipe = Synergies.RECIPES[spell_id]
		var ingredient = spell_catalog.get(recipe.ingredients[0], {})
		if ingredient.is_empty():
			return false
		var bonus = ingredient.duplicate(true)
		bonus.merge(recipe.overrides, true)
		bonus.id = spell_id
		bonus.name = recipe.name
		bonus.display_name = recipe.incantation
		bonus.chars = recipe.incantation.length()
		bonus.level = 1
		bonus_spells[MAX_EQUIPPED_SPELLS + bonus_spells.size() + 1] = bonus
		acquired_spells[spell_id] = true
		CharacterManager.discover_synergy(spell_id)
	else:
		if not spell_catalog.has(spell_id) or spells.size() >= MAX_EQUIPPED_SPELLS:
			return false
		spells[spells.size() + 1] = spell_catalog[spell_id].duplicate(true)
		acquired_spells[spell_id] = true
	rebuild_freeform_library()
	return true

func get_spell_rank(spell_id: String) -> int:
	if spell_id == "mana_bolt":
		return mana_bolt_level
	var slot = find_spell_slot(spell_id)
	return int(get_spell_info(slot).level) if is_spell_unlocked(slot) else 0

func rebuild_freeform_library():
	freeform_spells.clear()
	for info in get_all_spells().values():
		for alias in [str(info.name).to_lower(), info.display_name]:
			freeform_spells[alias] = info

func get_learnable_spell_cards() -> Array:
	var cards: Array = []
	if spells.size() < MAX_EQUIPPED_SPELLS:
		for id in spell_catalog:
			if acquired_spells.has(id):
				continue
			var info = spell_catalog[id]
			cards.append({"key": "learn:" + id, "name": "Learn " + info.name,
				"description": info.get("role", "Learn a new spell.") + "\nSlot %d of 6 · Type: %s" % [spells.size() + 1, info.display_name],
				"icon": "+", "effect": {"type": "learn_spell", "spell": id}})
	for id in Synergies.RECIPES:
		if acquired_spells.has(id) or not synergy_eligible(id):
			continue
		var recipe = Synergies.RECIPES[id]
		cards.append({"key": "learn:" + id, "name": "Learn " + recipe.name,
			"description": recipe.card_description + "\nBonus spell; keeps both ingredients, takes no active slot and starts at rank 1.",
			"icon": "+", "effect": {"type": "learn_spell", "spell": id}})
	return cards

func synergy_eligible(id: String) -> bool:
	if id not in Synergies.RECIPES or not Synergies.RECIPES[id].get("enabled", true):
		return false
	for ingredient in Synergies.RECIPES[id].ingredients:
		if not acquired_spells.has(ingredient):
			return false
	return true

func get_rank_upgrade_description(spell_id: String) -> String:
	var rank = get_spell_rank(spell_id)
	var prefix = "Rank %d → %d: " % [rank, rank + 1]
	var damage = "+15% of evolved base damage" if Synergies.RECIPES.has(spell_id) and float(Synergies.RECIPES[spell_id].overrides.get("damage_multiplier", 1.0)) != 1.0 else "+15% of base damage"
	match spell_id:
		"mana_bolt":
			return prefix + damage + (", +1 missile" if rank + 1 in [3, 6, 10] else "")
		"bolt":
			return prefix + damage + (", +1 projectile" if rank < 5 else "")
		"life":
			return prefix + "+15% of base instant healing"
		"regeneration":
			return prefix + "+15% of base healing per second"
		"ice_blast":
			return prefix + damage + ", +25 radius, +50 knockback"
		"earth_shield":
			return prefix + "+15% of base overheal"
		"lightning_arc":
			return prefix + damage
		"meteor_shower":
			return prefix + damage + ", +1 meteor"
	return prefix + damage

func cast_build_spell(slot: int) -> bool:
	var info = get_spell_info(slot).duplicate(true)
	var target = get_visible_plague_host(info) if info.type == "plague" else get_closest_enemy()
	if info.type == "plague" and target == null:
		last_cast_failure = "No target in range"
		return false
	info.projectile_speed_multiplier = player.projectile_speed_multiplier
	var tactical = info.type in ["beam", "trap", "spirit", "trail", "returning"]
	var active = get_tree().get_nodes_in_group("build_spell_effects").filter(func(effect): return (effect.info.type == info.type if tactical else effect.info.id == info.id) and not effect.is_queued_for_deletion())
	if active.size() >= int(info.get("active_limit", 3)):
		active[0].queue_free()
	if tactical:
		target = null
		var distance = INF
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if _live_spell_target(enemy) and player.global_position.distance_squared_to(enemy.global_position) < distance:
				distance = player.global_position.distance_squared_to(enemy.global_position)
				target = enemy
	var effect = preload("res://scripts/TacticalSpellEffect.gd").new() if tactical else preload("res://scripts/BuildSpellEffect.gd").new()
	effect.configure(info, calculate_spell_damage(info), player, target)
	get_parent().add_child(effect)
	return true

func get_visible_plague_host(info: Dictionary):
	var nearest = null
	var nearest_distance = INF
	var maximum_distance = maxf(0.0, float(info.get("cast_range", INF)))
	var viewport = get_viewport().get_visible_rect()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not _live_spell_target(enemy) or not enemy.is_visible_in_tree():
			continue
		if not viewport.has_point(enemy.get_global_transform_with_canvas().origin):
			continue
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance <= maximum_distance and distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest

func _live_spell_target(target) -> bool:
	return is_instance_valid(target) and not target.is_queued_for_deletion() and not target.get("dying") and float(target.get("current_health")) > 0.0

func _delayed_mana_bolt(reference: WeakRef, damage: float, index: int):
	if not is_inside_tree() or not is_instance_valid(player):
		return
	var target = reference.get_ref()
	if _live_spell_target(target):
		create_mana_bolt_projectile(target, damage, index)

func _delayed_spread_bolt(direction: Vector2, angle: float, reference: WeakRef, damage: float, index: int):
	if not is_inside_tree() or not is_instance_valid(player):
		return
	var target = reference.get_ref() if reference else null
	if reference and not _live_spell_target(target):
		return
	create_spread_homing_bolt_projectile(direction, angle, target, damage, index)

func _delayed_chain(reference: WeakRef, damage: float, remaining: int, hit_ids: Array):
	if not is_inside_tree() or not is_instance_valid(player):
		return
	var target = reference.get_ref()
	if _live_spell_target(target):
		chain_lightning(target, damage, remaining, hit_ids)
