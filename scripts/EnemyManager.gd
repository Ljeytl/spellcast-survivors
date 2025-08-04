extends Node2D

var enemy_scene = preload("res://scenes/Enemy.tscn")
var spawn_timer: Timer
var difficulty_timer: Timer

var base_spawn_interval: float = 2.0
var current_spawn_interval: float = 2.0
var enemies_spawned: int = 0
var enemies_alive: int = 0
var game_time: float = 0.0

# Performance optimization settings
var max_enemies: int = 100
var cleanup_distance: float = 1200  # Distance from player to remove enemies
var cleanup_timer: float = 0.0
var cleanup_interval: float = 2.0  # Check for cleanup every 2 seconds

@onready var player: CharacterBody2D = get_parent().get_node("Player")

func _ready():
	setup_timers()
	# Add to enemy_manager group so enemies can find us
	add_to_group("enemy_manager")

func _process(delta):
	game_time += delta
	update_difficulty()
	
	# Handle cleanup timer
	cleanup_timer += delta
	if cleanup_timer >= cleanup_interval:
		cleanup_timer = 0.0
		cleanup_distant_enemies()

func setup_timers():
	# Spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = current_spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)
	
	# Difficulty scaling timer (every 45 seconds)
	difficulty_timer = Timer.new()
	difficulty_timer.wait_time = 45.0
	difficulty_timer.timeout.connect(_on_difficulty_timer_timeout)
	difficulty_timer.autostart = true
	add_child(difficulty_timer)

func _on_spawn_timer_timeout():
	# Spawn multiple enemies at once based on game time
	var spawn_count = get_spawn_count()
	for i in spawn_count:
		spawn_enemy()

func _on_difficulty_timer_timeout():
	# Noticeable spawn rate increase to fill screen as player gets stronger
	current_spawn_interval = max(0.5, current_spawn_interval * 0.9)  # More noticeable reduction
	spawn_timer.wait_time = current_spawn_interval
	
	# Increase max enemies to create visual density
	if game_time >= 120:  # After 2 minutes
		max_enemies = min(180, max_enemies + 8)  # More substantial increases
	
	print("Spawn rate increased! New interval: {0:.2f}s | Max enemies: {1}".format([current_spawn_interval, max_enemies]))

func update_difficulty():
	# This will be used for real-time difficulty scaling
	pass

func get_spawn_count() -> int:
	# Spawn multiple enemies per cycle as game progresses
	if game_time < 300:  # 0-5 minutes: 1 enemy
		return 1
	elif game_time < 600:  # 5-10 minutes: 2 enemies
		return 2
	elif game_time < 1200:  # 10-20 minutes: 3 enemies
		return 3
	elif game_time < 1800:  # 20-30 minutes: 4 enemies
		return 4
	else:  # 30+ minutes: 5 enemies per spawn
		return 5

func spawn_enemy():
	if not player:
		return
	
	# Don't spawn if we've hit the max enemy limit
	if enemies_alive >= max_enemies:
		return
	
	# Determine enemy type based on game time and difficulty
	var enemy_type = determine_enemy_type()
	var elite_type = determine_elite_type()
	
	# Create and configure enemy
	var enemy = enemy_scene.instantiate()
	
	# Initialize enemy with type and current game time before adding to scene
	enemy.initialize_enemy(enemy_type, elite_type, game_time)
	
	# Calculate spawn position around player (off-screen)
	var spawn_distance = 600  # Distance from player
	var angle = randf() * 2 * PI
	var spawn_pos = player.global_position + Vector2(
		cos(angle) * spawn_distance,
		sin(angle) * spawn_distance
	)
	
	enemy.global_position = spawn_pos
	
	# Connect enemy signals
	enemy.enemy_died.connect(_on_enemy_died)
	
	# Connect to damage manager if it exists
	var damage_manager = get_parent().get_node_or_null("DamageManager")
	if damage_manager and damage_manager.has_method("_on_enemy_damaged"):
		enemy.enemy_damaged.connect(damage_manager._on_enemy_damaged)
	
	# Add to scene
	get_parent().add_child(enemy)
	
	enemies_spawned += 1
	enemies_alive += 1
	
	var type_name = ["Chaser", "Swarm", "Tank", "Shooter"][enemy_type]
	var elite_name = ["", "Armored", "Regenerator", "Splitter", "Frost", "Explosive"][elite_type]
	var tier = "T1" if game_time < 480 else ("T2" if game_time < 960 else "T3")
	print("Enemy spawned: {0} {1} {2} | Time: {3}s | Total: {4} | Alive: {5}".format([elite_name, tier, type_name, int(game_time), enemies_spawned, enemies_alive]))

func get_health_multiplier() -> float:
	# Health scales every 30 seconds - primary difficulty scaling
	return 1.0 + 0.15 * floor(game_time / 30.0)

func get_speed_multiplier() -> float:
	# Speed stays constant - no scaling with time
	return 1.0

func get_damage_multiplier() -> float:
	# Damage scales very slowly so enemies remain threatening but not overwhelming
	return 1.0 + 0.05 * floor(game_time / 120.0)

func get_xp_multiplier() -> float:
	# XP scales with health since enemies are harder to kill
	var health_mult = get_health_multiplier()
	return sqrt(health_mult)

func _on_enemy_died(enemy: CharacterBody2D):
	enemies_alive -= 1
	
	# Notify game manager about enemy kill
	var game_manager = get_parent()
	if game_manager and game_manager.has_method("increment_enemies_killed"):
		game_manager.increment_enemies_killed()
	
	print("Enemy died! Enemies alive: ", enemies_alive)

func cleanup_distant_enemies():
	# Remove enemies that are too far from the player to improve performance
	if not player:
		return
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var cleaned_up = 0
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
			
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance > cleanup_distance:
			enemy.queue_free()
			enemies_alive -= 1
			cleaned_up += 1
	
	if cleaned_up > 0:
		print("Cleaned up ", cleaned_up, " distant enemies. Alive: ", enemies_alive)

func get_enemy_count() -> int:
	# Get current number of alive enemies
	return enemies_alive

func is_at_enemy_limit() -> bool:
	# Check if we've reached the maximum enemy count
	return enemies_alive >= max_enemies

# Add time to game_time (for difficulty cheat command)
func add_game_time(additional_time: float):
	game_time += additional_time
	print("EnemyManager: Added {0}s to game time. New time: {1}s".format([int(additional_time), int(game_time)]))

# Determine enemy type based on game progression
func determine_enemy_type() -> int:
	# Enemy type introduction schedule (much longer timeline):
	# 0-5min: Only Chasers (learn basic mechanics)
	# 5-10min: Chasers + Swarm (introduce fast enemies)
	# 10-15min: Chasers + Swarm + Tanks (introduce tough enemies) 
	# 15min+: All types including Shooters (full difficulty)
	
	var available_types = [0]  # Always include Chasers (EnemyType.CHASER = 0)
	
	if game_time >= 300:  # 5 minutes
		available_types.append(1)  # Add Swarm (EnemyType.SWARM = 1)
	
	if game_time >= 600:  # 10 minutes
		available_types.append(2)  # Add Tank (EnemyType.TANK = 2)
	
	if game_time >= 900:  # 15 minutes
		available_types.append(3)  # Add Shooter (EnemyType.SHOOTER = 3)
	
	# Weight distribution based on time
	var weights = []
	for type in available_types:
		match type:
			0:  # Chaser - always common
				weights.append(40)
			1:  # Swarm - becomes more common over time
				var swarm_weight = 20 + min(20, floor(game_time / 30))
				weights.append(swarm_weight)
			2:  # Tank - less common but consistent
				weights.append(15)
			3:  # Shooter - rare but dangerous
				weights.append(10)
	
	# Select weighted random type
	return weighted_random_choice(available_types, weights)

# Determine if enemy should be elite and what type
func determine_elite_type() -> int:
	# Elite chance increases over time: 1% at start, up to 12% at 20 minutes
	var elite_chance = 1.0 + min(11.0, game_time / 1200.0 * 11.0)
	
	if randf() * 100.0 > elite_chance:
		return 0  # EliteType.NONE
	
	# If elite, determine type
	var elite_types = [1, 2, 3, 4, 5]  # All elite types except NONE
	var elite_weights = [25, 25, 15, 20, 15]  # Armored, Regenerator, Splitter, Frost, Explosive
	
	return weighted_random_choice(elite_types, elite_weights)

# Utility function for weighted random selection
func weighted_random_choice(choices: Array, weights: Array) -> int:
	var total_weight = 0
	for weight in weights:
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_weight = 0
	
	for i in range(choices.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return choices[i]
	
	# Fallback
	return choices[0] if choices.size() > 0 else 0

# Special spawn function for splitter enemies
func spawn_split_enemy(position: Vector2, enemy_type: int):
	if enemies_alive >= max_enemies:
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.initialize_enemy(enemy_type, 0, game_time)  # No elite type for split enemies
	enemy.global_position = position
	
	# Make split enemies smaller and weaker
	enemy.scale *= 0.6
	enemy.base_health *= 0.4
	enemy.base_damage *= 0.6
	enemy.xp_value *= 0.3
	
	# Connect signals
	enemy.enemy_died.connect(_on_enemy_died)
	var damage_manager = get_parent().get_node_or_null("DamageManager")
	if damage_manager and damage_manager.has_method("_on_enemy_damaged"):
		enemy.enemy_damaged.connect(damage_manager._on_enemy_damaged)
	
	# Add to scene
	get_parent().add_child(enemy)
	enemies_alive += 1
	
	print("Split enemy spawned at ", position)
