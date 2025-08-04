extends Node2D

# Monster Manager using mathematical JSON configuration
# Replaces hardcoded enemy types with formula-driven system

var monster_config: Dictionary = {}
var enemy_scene = preload("res://scenes/Enemy.tscn")
var spawn_timer: Timer
var game_time: float = 0.0
var monsters_alive: int = 0
var max_monsters: int = 100

@onready var player: CharacterBody2D = get_parent().get_node("Player")

signal monster_spawned(monster_data: Dictionary)
signal monster_died(monster_data: Dictionary)

func _ready():
	load_monster_config()
	setup_spawn_timer()
	add_to_group("monster_manager")

func _process(delta):
	game_time += delta

func load_monster_config():
	var config_path = "res://monster_config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			monster_config = json.data.monster_configuration
			print("Monster configuration loaded successfully!")
		else:
			print("Error parsing monster config JSON: ", parse_result)
			use_fallback_config()
	else:
		print("Monster config file not found, using fallback")
		use_fallback_config()

func use_fallback_config():
	# Simple fallback if JSON fails to load
	monster_config = {
		"monster_roster": {
			"tier_1_basic": [
				{
					"name": "Goblin",
					"archetype": "normal",
					"base_health": 20,
					"base_speed": 50,
					"base_damage": 5,
					"base_xp": 5,
					"sprite_path": "res://goblin_new.png",
					"unlock_difficulty": 1,
					"rarity": "common"
				}
			]
		}
	}

func setup_spawn_timer():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 2.0
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)

func _on_spawn_timer_timeout():
	if monsters_alive < max_monsters:
		spawn_monster()
		
	# Update spawn rate dynamically
	var new_interval = calculate_spawn_interval()
	spawn_timer.wait_time = new_interval

func spawn_monster():
	if not player:
		return
		
	# Calculate current difficulty level using formula
	var difficulty_level = evaluate_formula("floor(time_seconds / 60) + 1", {"time_seconds": game_time})
	
	# Select monster to spawn
	var monster_data = select_monster(difficulty_level)
	if not monster_data:
		return
		
	# Create enemy instance
	var monster = enemy_scene.instantiate()
	
	# Calculate spawn position (off-screen around player)
	var spawn_distance = 600
	var angle = randf() * 2 * PI
	var spawn_pos = player.global_position + Vector2(
		cos(angle) * spawn_distance,
		sin(angle) * spawn_distance
	)
	monster.global_position = spawn_pos
	
	# Map JSON archetype to Enemy.gd EnemyType enum
	var enemy_type = map_archetype_to_enemy_type(monster_data.archetype)
	var elite_type = 0  # EliteType.NONE for now
	
	# Initialize using existing Enemy.gd system
	monster.initialize_enemy(enemy_type, elite_type, game_time)
	
	# Then apply our mathematical scaling on top
	var scaled_stats = calculate_monster_stats(monster_data, difficulty_level)
	if monster.has_method("set_monster_stats"):
		monster.set_monster_stats(scaled_stats)
	
	# Connect signals
	monster.enemy_died.connect(_on_monster_died)
	
	# Add to scene
	get_parent().add_child(monster)
	monsters_alive += 1
	
	# Emit signal
	monster_spawned.emit(monster_data)
	
	print("Spawned: {0} | Level: {1} | HP: {2} | Speed: {3}".format([
		monster_data.name, 
		difficulty_level, 
		scaled_stats.health, 
		scaled_stats.speed
	]))

func select_monster(difficulty_level: int) -> Dictionary:
	var available_monsters = []
	
	# Collect all available monsters for current difficulty
	for tier_name in monster_config.monster_roster.keys():
		var tier_monsters = monster_config.monster_roster[tier_name]
		for monster in tier_monsters:
			if monster.unlock_difficulty <= difficulty_level:
				available_monsters.append(monster)
	
	if available_monsters.is_empty():
		return {}
		
	# Apply archetype bias and rarity weights
	var weighted_monsters = apply_spawn_weights(available_monsters, difficulty_level)
	
	# Select weighted random monster
	return weighted_random_selection(weighted_monsters)

func apply_spawn_weights(monsters: Array, difficulty_level: int) -> Array:
	var weighted_monsters = []
	
	for monster in monsters:
		var weight = calculate_spawn_weight(monster, difficulty_level)
		if weight > 0:
			weighted_monsters.append({
				"monster": monster,
				"weight": weight
			})
	
	return weighted_monsters

func calculate_spawn_weight(monster: Dictionary, difficulty_level: int) -> float:
	var archetype = monster.archetype
	var rarity = monster.rarity
	
	# Get base archetype weight using bias formulas
	var archetype_weight = 50.0  # Default
	if monster_config.has("spawn_probability_formulas") and monster_config.spawn_probability_formulas.has("archetype_bias"):
		var archetype_formulas = monster_config.spawn_probability_formulas.archetype_bias
		if archetype_formulas.has(archetype):
			var formula = archetype_formulas[archetype]
			archetype_weight = evaluate_formula(formula, {"difficulty_level": difficulty_level})
	
	# Get rarity weight
	var rarity_weight = 50.0  # Default
	if monster_config.has("spawn_probability_formulas") and monster_config.spawn_probability_formulas.has("rarity_weights"):
		var rarity_weights = monster_config.spawn_probability_formulas.rarity_weights
		if rarity_weights.has(rarity):
			rarity_weight = float(rarity_weights[rarity])
	
	return max(0.0, archetype_weight * (rarity_weight / 100.0))

func weighted_random_selection(weighted_monsters: Array) -> Dictionary:
	if weighted_monsters.is_empty():
		return {}
		
	var total_weight = 0.0
	for item in weighted_monsters:
		total_weight += item.weight
		
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for item in weighted_monsters:
		current_weight += item.weight
		if random_value <= current_weight:
			return item.monster
			
	# Fallback to first monster
	return weighted_monsters[0].monster

func calculate_monster_stats(monster_data: Dictionary, difficulty_level: int) -> Dictionary:
	var archetype = monster_data.archetype
	var base_multiplier = evaluate_formula("1 + (difficulty_level - 1) * 0.3", {"difficulty_level": difficulty_level})
	
	var stats = {}
	
	# Get archetype formulas
	if monster_config.has("monster_archetypes") and monster_config.monster_archetypes.has(archetype):
		var archetype_data = monster_config.monster_archetypes[archetype]
		
		# Calculate each stat using formulas
		var formula_context = {
			"base_health": monster_data.base_health,
			"base_speed": monster_data.base_speed, 
			"base_damage": monster_data.base_damage,
			"base_xp": monster_data.base_xp,
			"base_multiplier": base_multiplier,
			"time_seconds": game_time,
			"difficulty_level": difficulty_level,
			"health_multiplier": 1.0 + 0.1 * floor(game_time / 30.0)
		}
		
		stats.health = evaluate_formula(archetype_data.health_formula, formula_context)
		stats.speed = evaluate_formula(archetype_data.speed_formula, formula_context)
		stats.damage = evaluate_formula(archetype_data.damage_formula, formula_context)
		stats.xp = evaluate_formula(archetype_data.xp_formula, formula_context)
		
		# Special archetype properties
		if archetype == "swarmer" and archetype_data.has("group_size_formula"):
			var group_multiplier = evaluate_formula("1 + difficulty_level * 0.2", {"difficulty_level": difficulty_level})
			stats.group_size = int(evaluate_formula(archetype_data.group_size_formula, {
				"difficulty_level": difficulty_level,
				"swarmer_group_multiplier": group_multiplier
			}))
		
		if archetype == "shooter":
			stats.attack_range = evaluate_formula("150 + difficulty_level * 20", {"difficulty_level": difficulty_level})
			stats.projectile_speed = evaluate_formula("100 + difficulty_level * 10", {"difficulty_level": difficulty_level})
	else:
		# Fallback calculations
		stats.health = monster_data.base_health * base_multiplier
		stats.speed = monster_data.base_speed
		stats.damage = monster_data.base_damage * base_multiplier
		stats.xp = monster_data.base_xp
	
	return stats

func calculate_spawn_interval() -> float:
	# Dynamic spawn rate based on time and difficulty
	var base_interval = 2.0
	var difficulty_level = evaluate_formula("floor(time_seconds / 60) + 1", {"time_seconds": game_time})
	
	# Faster spawning as difficulty increases
	var interval = base_interval / (1.0 + difficulty_level * 0.2)
	return max(0.3, interval)

func initialize_monster(monster: CharacterBody2D, monster_data: Dictionary, stats: Dictionary):
	# Set sprite if it exists
	var sprite_node = monster.get_node_or_null("Sprite2D")
	if sprite_node and monster_data.has("sprite_path"):
		var texture = load(monster_data.sprite_path)
		if texture:
			sprite_node.texture = texture
	
	# Apply stats (assuming Enemy.gd has these properties)
	if monster.has_method("set_monster_stats"):
		monster.set_monster_stats(stats)
	else:
		# Fallback - set properties directly if they exist
		if monster.has_property("base_health"):
			monster.base_health = stats.health
		if monster.has_property("speed"):
			monster.speed = stats.speed
		if monster.has_property("base_damage"):
			monster.base_damage = stats.damage
		if monster.has_property("xp_value"):
			monster.xp_value = stats.xp

func _on_monster_died(monster: CharacterBody2D):
	monsters_alive -= 1
	monster_died.emit({})

# Formula evaluation function
func evaluate_formula(formula: String, context: Dictionary) -> float:
	# Replace variables in formula with values from context
	var processed_formula = formula
	
	for key in context.keys():
		var value = str(context[key])
		processed_formula = processed_formula.replace(key, value)
	
	# Evaluate mathematical expression
	return evaluate_math_expression(processed_formula)

func evaluate_math_expression(expression: String) -> float:
	# Simple expression evaluator for basic math operations
	# This is a simplified version - for production, consider using Godot's Expression class
	
	var expr = Expression.new()
	var error = expr.parse(expression)
	
	if error != OK:
		print("Error parsing expression: ", expression)
		return 0.0
		
	var result = expr.execute()
	
	if expr.has_execute_failed():
		print("Error executing expression: ", expression)
		return 0.0
		
	return float(result)

func map_archetype_to_enemy_type(archetype: String) -> int:
	# Map JSON archetypes to Enemy.gd EnemyType enum
	match archetype:
		"normal":
			return 0  # EnemyType.CHASER
		"swarmer":
			return 1  # EnemyType.SWARM  
		"elite":
			return 2  # EnemyType.TANK
		"shooter":
			return 3  # EnemyType.SHOOTER
		_:
			return 0  # Default to CHASER

# Debug functions
func get_current_difficulty_level() -> int:
	return int(evaluate_formula("floor(time_seconds / 60) + 1", {"time_seconds": game_time}))

func get_monster_count() -> int:
	return monsters_alive

func add_game_time(additional_time: float):
	game_time += additional_time
	print("MonsterManager: Added {0}s to game time. New time: {1}s | Difficulty: {2}".format([
		int(additional_time), 
		int(game_time), 
		get_current_difficulty_level()
	]))