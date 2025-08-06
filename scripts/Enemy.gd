# Enemy system supporting multiple types and elite variants
# Health and speed scale over time to increase difficulty
extends CharacterBody2D

# Signals sent when enemy takes damage or dies
signal enemy_died(enemy: CharacterBody2D)              # Tells EnemyManager to remove from tracking
signal enemy_damaged(damage: float, position: Vector2) # Triggers floating damage number

# Enemy type enumeration
enum EnemyType {
	CHASER,      # Basic enemy that follows player directly
	SWARM,       # Fast, weak enemies that move in groups
	TANK,        # Slow, high health enemies that are hard to kill
	SHOOTER,     # Ranged enemies that fire projectiles
	ELITE        # Enhanced versions of any type with special abilities
}

# Elite type enumeration for enhanced variants
enum EliteType {
	NONE,           # Not an elite
	ARMORED,        # Takes reduced damage from all sources
	REGENERATOR,    # Slowly heals over time
	SPLITTER,       # Splits into smaller enemies on death
	FROST,          # Slows player on hit, immune to ice effects
	EXPLOSIVE       # Explodes on death, dealing AoE damage
}

# Preload the XP orb scene for dropping on death
var xp_orb_scene = preload("res://scenes/XPOrb.tscn")

# Enemy type and elite status
var enemy_type: EnemyType = EnemyType.CHASER
var elite_type: EliteType = EliteType.NONE
var is_elite: bool = false

# Tiered enemy progression - stronger variants over time
var enemy_tiers = {
	EnemyType.CHASER: {
		"tier_1": {  # 0-8 minutes
			"health": 50.0,
			"speed": 100.0,
			"damage": 10.0,
			"xp": 10.0,
			"size_scale": 1.0,
			"name": "Weak",
			"sprites": [
				"res://Dungeon Crawl Stone Soup Full/monster/goblin_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/kobold_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/big_kobold_new.png"
			]
		},
		"tier_2": {  # 8-16 minutes
			"health": 75.0,
			"speed": 105.0,
			"damage": 12.0,
			"xp": 15.0,
			"size_scale": 1.1,
			"name": "Regular",
			"sprites": [
				"res://Dungeon Crawl Stone Soup Full/monster/orc_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/hobgoblin_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/gnoll_new.png"
			]
		},
		"tier_3": {  # 16+ minutes
			"health": 100.0,
			"speed": 110.0,
			"damage": 15.0,
			"xp": 22.0,
			"size_scale": 1.2,
			"name": "Elite",
			"sprites": [
				"res://Dungeon Crawl Stone Soup Full/monster/orc_warrior_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/gnoll_sergeant.png",
				"res://Dungeon Crawl Stone Soup Full/monster/centaur-melee.png"
			]
		}
	},
	EnemyType.SWARM: {
		"tier_1": {  # 0-8 minutes - Small bugs
			"health": 25.0,
			"speed": 115.0,
			"damage": 8.0,
			"xp": 8.0,
			"size_scale": 0.7,
			"name": "Bug",
			"sprites": [
				"res://Dungeon Crawl Stone Soup Full/monster/animals/giant_mite.png",
				"res://Dungeon Crawl Stone Soup Full/monster/animals/giant_cockroach_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/animals/bat.png"
			]
		},
		"tier_2": {  # 8-16 minutes - Bigger insects
			"health": 35.0,
			"speed": 115.0,
			"damage": 10.0,
			"xp": 12.0,
			"size_scale": 0.8,
			"name": "Swarm",
			"sprites": [
				"res://Dungeon Crawl Stone Soup Full/monster/animals/giant_ant.png",
				"res://Dungeon Crawl Stone Soup Full/monster/animals/giant_beetle.png",
				"res://Dungeon Crawl Stone Soup Full/monster/animals/bumblebee.png"
			]
		},
		"tier_3": {  # 16+ minutes - Dangerous creatures
			"health": 50.0,
			"speed": 115.0,
			"damage": 12.0,
			"xp": 18.0,
			"size_scale": 0.9,
			"name": "Predator",
			"sprites": [
				"res://Dungeon Crawl Stone Soup Full/monster/animals/giant_blowfly.png",
				"res://Dungeon Crawl Stone Soup Full/monster/animals/giant_mosquito.png",
				"res://Dungeon Crawl Stone Soup Full/monster/animals/emperor_scorpion.png"
			]
		}
	},
	EnemyType.TANK: {
		"tier_1": {  # 0-8 minutes - Big but slow
			"health": 120.0,
			"speed": 60.0,
			"damage": 20.0,
			"xp": 25.0,
			"size_scale": 1.4,
			"name": "Brute",
			"sprites": [
				"res://Dungeon Crawl Stone Soup Full/monster/ogre_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/hill_giant_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/cyclops_new.png"
			]
		},
		"tier_2": {  # 8-16 minutes - Armored warriors
			"health": 180.0,
			"speed": 65.0,
			"damage": 25.0,
			"xp": 35.0,
			"size_scale": 1.5,
			"name": "Warrior",
			"sprites": [
				"res://Dungeon Crawl Stone Soup Full/monster/troll.png",
				"res://Dungeon Crawl Stone Soup Full/monster/stone_giant_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/minotaur.png"
			]
		},
		"tier_3": {  # 16+ minutes - Massive threats
			"health": 250.0,
			"speed": 70.0,
			"damage": 30.0,
			"xp": 50.0,
			"size_scale": 1.6,
			"name": "Titan",
			"sprites": [
				"res://Dungeon Crawl Stone Soup Full/monster/ettin_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/titan_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/two_headed_ogre_new.png"
			]
		}
	},
	EnemyType.SHOOTER: {
		"tier_1": {  # 0-8 minutes - Basic ranged
			"health": 40.0,
			"speed": 80.0,
			"damage": 12.0,
			"xp": 15.0,
			"size_scale": 1.1,
			"name": "Archer",
			"sprites": [
				"res://Dungeon Crawl Stone Soup Full/monster/orc_wizard_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/deep_elf_conjurer.png",
				"res://Dungeon Crawl Stone Soup Full/monster/kobold_demonologist.png"
			]
		},
		"tier_2": {  # 8-16 minutes - Skilled marksmen
			"health": 60.0,
			"speed": 85.0,
			"damage": 15.0,
			"xp": 22.0,
			"size_scale": 1.2,
			"name": "Marksman",
			"sprites": [
				"res://Dungeon Crawl Stone Soup Full/monster/centaur.png",
				"res://Dungeon Crawl Stone Soup Full/monster/deep_elf_master_archer.png",
				"res://Dungeon Crawl Stone Soup Full/monster/naga_sharpshooter.png"
			]
		},
		"tier_3": {  # 16+ minutes - Elite snipers
			"health": 80.0,
			"speed": 90.0,
			"damage": 18.0,
			"xp": 32.0,
			"size_scale": 1.3,
			"name": "Sniper",
			"sprites": [
				"res://Dungeon Crawl Stone Soup Full/monster/yaktaur_new.png",
				"res://Dungeon Crawl Stone Soup Full/monster/centaur_warrior.png",
				"res://Dungeon Crawl Stone Soup Full/monster/yaktaur_captain_new.png"
			]
		}
	}
}

# Elite sprite sets - visually distinct sprites for each elite type
var elite_sprite_sets = {
	EliteType.ARMORED: [
		"res://Dungeon Crawl Stone Soup Full/monster/deep_dwarf_berserker.png",
		"res://Dungeon Crawl Stone Soup Full/monster/iron_troll.png",
		"res://Dungeon Crawl Stone Soup Full/monster/hell_knight_new.png",
		"res://Dungeon Crawl Stone Soup Full/monster/nonliving/iron_golem.png"
	],
	EliteType.REGENERATOR: [
		"res://Dungeon Crawl Stone Soup Full/monster/deep_troll_shaman.png",
		"res://Dungeon Crawl Stone Soup Full/monster/necromancer_new.png",
		"res://Dungeon Crawl Stone Soup Full/monster/deep_elf_death_mage.png",
		"res://Dungeon Crawl Stone Soup Full/monster/fungi_plants/thorn_hunter.png"
	],
	EliteType.SPLITTER: [
		"res://Dungeon Crawl Stone Soup Full/monster/demons/chaos_spawn.png",
		"res://Dungeon Crawl Stone Soup Full/monster/mutant_beast.png",
		"res://Dungeon Crawl Stone Soup Full/monster/glowing_shapeshifter.png",
		"res://Dungeon Crawl Stone Soup Full/monster/amorphous/jelly.png"
	],
	EliteType.FROST: [
		"res://Dungeon Crawl Stone Soup Full/monster/frost_giant_new.png",
		"res://Dungeon Crawl Stone Soup Full/monster/ice_beast.png",
		"res://Dungeon Crawl Stone Soup Full/monster/demons/ice_devil.png",
		"res://Dungeon Crawl Stone Soup Full/monster/dragons/ice_dragon_new.png"
	],
	EliteType.EXPLOSIVE: [
		"res://Dungeon Crawl Stone Soup Full/monster/fire_giant_new.png",
		"res://Dungeon Crawl Stone Soup Full/monster/demons/balrug_new.png",
		"res://Dungeon Crawl Stone Soup Full/monster/nonliving/orb_of_fire_new.png",
		"res://Dungeon Crawl Stone Soup Full/monster/killer_klown_red.png"
	]
}

# Starting stats before any difficulty scaling (set by enemy type)
var base_health: float = 50.0   # Base hit points
var base_speed: float = 100.0   # Base movement speed in pixels/second
var base_damage: float = 10.0   # Base damage dealt to player on contact

# Current stats after difficulty scaling is applied
var max_health: float     # Maximum health (scaled by time)
var current_health: float # Current remaining health
var speed: float          # Current movement speed (scaled by time)
var damage: float         # Damage dealt to player (uses base_damage)

# Node references set up during initialization
var player: CharacterBody2D    # The player character to chase
var health_bar_fill: ColorRect # Visual health bar above enemy

# Experience points dropped when enemy dies (scaled by difficulty)
var xp_value: float = 10.0

# Status effects
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 0.9  # How quickly knockback fades
var slow_multiplier: float = 1.0  # Speed multiplier (1.0 = normal, 0.5 = half speed)
var slow_timer: float = 0.0

# Elite-specific variables
var regeneration_rate: float = 0.0  # Health per second for regenerators
var damage_reduction: float = 0.0  # Damage reduction percentage for armored
var split_count: int = 2  # Number of enemies to split into (splitters)
var frost_aura_range: float = 80.0  # Range of frost aura effect
var explosion_damage: float = 0.0  # Damage dealt on explosive death
var explosion_range: float = 120.0  # Range of explosion

# Shooter-specific variables
var shoot_timer: float = 0.0
var shoot_interval: float = 3.0  # Time between shots
var projectile_speed: float = 200.0
var projectile_scene = preload("res://scenes/SpellProjectile.tscn")  # Reuse spell projectile

# Initialize enemy with specific type and elite status
func initialize_enemy(type: EnemyType, elite: EliteType = EliteType.NONE, game_time: float = 0.0):
	enemy_type = type
	elite_type = elite
	is_elite = (elite != EliteType.NONE)
	
	# Determine tier based on game time
	var tier_name = determine_tier_by_time(game_time)
	
	# Set base stats from enemy tier
	if type in enemy_tiers and tier_name in enemy_tiers[type]:
		var tier_stats = enemy_tiers[type][tier_name]
		base_health = tier_stats["health"]
		base_speed = tier_stats["speed"]
		base_damage = tier_stats["damage"]
		xp_value = tier_stats["xp"]
		
		# Apply visual changes
		scale = Vector2.ONE * tier_stats["size_scale"]
		
		# Load appropriate sprite based on elite status and tier
		load_appropriate_sprite(tier_stats)
	
	# Apply elite modifications
	apply_elite_modifications()

# Called when enemy is spawned - sets up stats and references
func _ready():
	# Find the player character to chase
	var scene_tree = get_tree()
	if scene_tree:
		player = scene_tree.get_first_node_in_group("player")
	
	# Get reference to health bar visual element
	health_bar_fill = $HealthBar/Fill
	
	# Apply difficulty scaling based on current game time
	var enemy_manager = null
	if scene_tree:
		enemy_manager = scene_tree.get_first_node_in_group("enemy_manager")
	if enemy_manager:
		# Get scaling multipliers from EnemyManager (based on game time)
		var health_mult = enemy_manager.get_health_multiplier()
		var speed_mult = enemy_manager.get_speed_multiplier()
		var damage_mult = enemy_manager.get_damage_multiplier()
		var xp_mult = enemy_manager.get_xp_multiplier()
		
		# Apply scaling to base stats
		max_health = base_health * health_mult
		speed = base_speed * speed_mult
		damage = base_damage * damage_mult
		xp_value = xp_value * xp_mult
	else:
		# Fallback if EnemyManager not found - use base stats
		max_health = base_health
		speed = base_speed
		damage = base_damage
	
	# Start at full health
	current_health = max_health
	update_health_bar()
	
	# Register with enemies group for targeting by spells
	add_to_group("enemies")

# Called every physics frame - handles movement toward player
func _physics_process(delta):
	if not player:
		return
	
	# Process status effects and elite abilities
	process_status_effects(delta)
	process_elite_abilities(delta)
	
	# Handle enemy-type specific behavior
	match enemy_type:
		EnemyType.CHASER:
			handle_chaser_movement(delta)
		EnemyType.SWARM:
			handle_swarm_movement(delta)
		EnemyType.TANK:
			handle_tank_movement(delta)
		EnemyType.SHOOTER:
			handle_shooter_behavior(delta)
		_:
			handle_chaser_movement(delta)  # Default behavior
	
	# Apply knockback if present
	velocity += knockback_velocity
	move_and_slide()
	
	# Decay knockback over time
	knockback_velocity *= knockback_decay

# Basic chaser movement - directly toward player
func handle_chaser_movement(delta: float):
	var direction = (player.global_position - global_position).normalized()
	var final_speed = speed * slow_multiplier
	velocity = direction * final_speed

# Swarm movement - slight random variation and grouping behavior
func handle_swarm_movement(delta: float):
	var direction = (player.global_position - global_position).normalized()
	
	# Add some randomness to create swarm effect
	var random_offset = Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
	direction = (direction + random_offset).normalized()
	
	var final_speed = speed * slow_multiplier
	velocity = direction * final_speed

# Tank movement - slower but more deliberate
func handle_tank_movement(delta: float):
	var direction = (player.global_position - global_position).normalized()
	var final_speed = speed * slow_multiplier
	velocity = direction * final_speed

# Shooter behavior - keep distance and shoot projectiles
func handle_shooter_behavior(delta: float):
	var distance_to_player = global_position.distance_to(player.global_position)
	var direction = (player.global_position - global_position).normalized()
	
	# Maintain optimal shooting distance (300-400 pixels)
	var optimal_distance = 350.0
	var final_speed = speed * slow_multiplier
	
	if distance_to_player < optimal_distance - 50:
		# Too close - move away
		velocity = -direction * final_speed * 0.7
	elif distance_to_player > optimal_distance + 100:
		# Too far - move closer
		velocity = direction * final_speed * 0.5
	else:
		# Good distance - strafe around player
		var strafe_direction = Vector2(-direction.y, direction.x)
		velocity = strafe_direction * final_speed * 0.3
	
	# Handle shooting
	shoot_timer -= delta
	if shoot_timer <= 0 and distance_to_player < 500:
		shoot_at_player()
		shoot_timer = shoot_interval

# Called when enemy takes damage from spells or other sources
func take_damage(damage_amount: float):
	# Apply armor reduction for armored elites
	var final_damage = damage_amount
	if is_elite and elite_type == EliteType.ARMORED:
		final_damage = damage_amount * (1.0 - damage_reduction)
	
	# Reduce health, don't go below 0
	current_health -= final_damage
	current_health = max(0, current_health)
	
	# Show floating damage number
	enemy_damaged.emit(damage_amount, global_position)
	
	# Update visual health bar
	update_health_bar()
	
	# Flash red visual feedback when hit
	flash_damage()
	
	# Check if enemy should die
	if current_health <= 0:
		die()

# Update the visual health bar above the enemy
func update_health_bar():
	if health_bar_fill:
		var health_percent = current_health / max_health
		# Scale the health bar fill horizontally
		health_bar_fill.scale.x = health_percent

# Flash the enemy red when taking damage for visual feedback
func flash_damage():
	var visual = $Visual
	if visual:
		# Quick red flash animation
		var tween = create_tween()
		tween.tween_property(visual, "color", Color.WHITE, 0.1)
		tween.tween_property(visual, "color", Color(0.8, 0.2, 0.2, 1), 0.1)

# Called when enemy health reaches 0 - handles death sequence
func die():
	# Handle elite death effects first
	handle_elite_death_effects()
	
	# Play death sound effect
	if AudioManager:
		AudioManager.on_enemy_death()
	
	# Create visual death effect (particles, screen shake, etc.)
	var scene_tree = get_tree()
	if scene_tree:
		var game_node = scene_tree.get_first_node_in_group("game")
		if game_node and game_node.has_method("create_enemy_death_effect"):
			game_node.create_enemy_death_effect(global_position)
	
	# Spawn XP orb for player to collect
	drop_xp_orb()
	
	# Tell EnemyManager to remove this enemy from tracking
	enemy_died.emit(self)
	
	# Remove enemy from the scene
	queue_free()

# Spawn an XP orb at the enemy's death location
func drop_xp_orb():
	var xp_orb = xp_orb_scene.instantiate()
	xp_orb.global_position = global_position
	xp_orb.xp_value = xp_value  # Scaled based on difficulty
	get_parent().add_child(xp_orb)

# Collision handler for enemy's HurtBox area
func _on_hurt_box_area_entered(area):
	# This is primarily handled by SpellProjectile when it hits
	# SpellProjectile calls take_damage() and then destroys itself
	# This function exists as a backup in case something goes wrong
	if area.is_in_group("spell_projectiles"):
		# Damage dealing and projectile cleanup handled by the projectile itself
		pass

# Status effect functions
func apply_knockback(direction: Vector2, strength: float):
	knockback_velocity += direction * strength

func apply_slow(slow_amount: float, duration: float):
	slow_multiplier = slow_amount
	slow_timer = duration

func process_status_effects(delta: float):
	# Handle slow effect timer
	if slow_timer > 0:
		slow_timer -= delta
		if slow_timer <= 0:
			slow_multiplier = 1.0  # Return to normal speed

# Apply elite modifications to stats
func apply_elite_modifications():
	if not is_elite:
		return
	
	match elite_type:
		EliteType.ARMORED:
			damage_reduction = 0.3  # 30% damage reduction
			base_health *= 1.2  # 20% more health
		EliteType.REGENERATOR:
			regeneration_rate = base_health * 0.02  # 2% health per second
			base_health *= 1.5  # 50% more health
		EliteType.SPLITTER:
			base_health *= 0.8  # 20% less health since they split
			split_count = 3  # Split into 3 smaller enemies
		EliteType.FROST:
			base_health *= 1.3  # 30% more health
			base_speed *= 0.8  # 20% slower
		EliteType.EXPLOSIVE:
			explosion_damage = base_damage * 2.5  # High explosion damage
			base_health *= 0.9  # 10% less health since they explode
	
	# All elites get bonus XP
	xp_value *= 2.5
	
	# Visual indication for elites - make them larger and add glow
	scale *= 1.15  # Slightly larger
	
	# Add elite visual effects
	apply_elite_visual_effects()

# Process elite-specific abilities each frame
func process_elite_abilities(delta: float):
	if not is_elite:
		return
	
	match elite_type:
		EliteType.ARMORED:
			# Armor effect is passive - handled in take_damage function
			pass
		EliteType.REGENERATOR:
			# Regenerate health over time
			if current_health < max_health:
				current_health = min(max_health, current_health + regeneration_rate * delta)
				update_health_bar()
		EliteType.FROST:
			# Slow nearby player
			if player:
				var distance = global_position.distance_to(player.global_position)
				if distance < frost_aura_range:
					# Apply frost effect to player (would need player script modification)
					pass

# Handle special death effects for elite enemies
func handle_elite_death_effects():
	if not is_elite:
		return
	
	match elite_type:
		EliteType.SPLITTER:
			spawn_split_enemies()
		EliteType.EXPLOSIVE:
			create_explosion()

# Spawn smaller enemies when splitter dies
func spawn_split_enemies():
	var scene_tree = get_tree()
	if not scene_tree:
		return
	
	var enemy_manager = scene_tree.get_first_node_in_group("enemy_manager")
	if not enemy_manager or not enemy_manager.has_method("spawn_split_enemy"):
		return
	
	# Spawn smaller enemies around death location
	for i in split_count:
		var angle = (2 * PI * i) / split_count
		var spawn_offset = Vector2(cos(angle), sin(angle)) * 60
		var spawn_pos = global_position + spawn_offset
		
		# Create smaller swarm-type enemies
		enemy_manager.spawn_split_enemy(spawn_pos, EnemyType.SWARM)

# Create explosion damage on death
func create_explosion():
	var scene_tree = get_tree()
	if not scene_tree:
		return
	
	# Damage player if in range
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < explosion_range:
			var damage_to_player = explosion_damage * (1.0 - distance / explosion_range)
			if player.has_method("take_damage"):
				player.take_damage(damage_to_player)
	
	# Create visual explosion effect
	var game_node = scene_tree.get_first_node_in_group("game")
	if game_node and game_node.has_method("create_explosion_effect"):
		game_node.create_explosion_effect(global_position, explosion_range)

# Shooter fires projectile at player
func shoot_at_player():
	if not player or not projectile_scene:
		return
	
	var projectile = projectile_scene.instantiate()
	var direction = (player.global_position - global_position).normalized()
	
	# Add to scene
	var parent = get_parent()
	if parent:
		parent.add_child(projectile)
		
		# Setup enemy projectile (different from player spells)
		projectile.setup(global_position, direction, damage * 0.8, Color.DARK_RED, "enemy_shot")
		projectile.speed = projectile_speed
		projectile.add_to_group("enemy_projectiles")  # Different group from player spells

# Determine enemy tier based on game time
func determine_tier_by_time(game_time: float) -> String:
	if game_time < 480:  # 0-8 minutes
		return "tier_1"
	elif game_time < 960:  # 8-16 minutes
		return "tier_2"
	else:  # 16+ minutes
		return "tier_3"

# Load appropriate sprite based on elite status and enemy tier
func load_appropriate_sprite(tier_stats: Dictionary):
	var sprite_path: String = ""
	
	# Check if this is an elite with special sprites
	if is_elite and elite_type in elite_sprite_sets:
		var elite_sprites = elite_sprite_sets[elite_type]
		sprite_path = elite_sprites[randi() % elite_sprites.size()]
	else:
		# Use normal enemy tier sprites
		if "sprites" in tier_stats and tier_stats["sprites"].size() > 0:
			var sprite_paths = tier_stats["sprites"]
			sprite_path = sprite_paths[randi() % sprite_paths.size()]
	
	# Load the selected sprite
	if sprite_path != "":
		load_enemy_sprite(sprite_path)

# Load sprite texture for the enemy
func load_enemy_sprite(sprite_path: String):
	var visual = $Sprite2D  # Changed from $Visual to $Sprite2D
	if not visual:
		print("ERROR: Could not find Sprite2D node")
		return
	
	# Try to load the texture
	var texture = load(sprite_path)
	if texture:
		visual.texture = texture
		print("Loaded enemy sprite: ", sprite_path)
	else:
		print("Failed to load enemy sprite: ", sprite_path)
		# Keep the default texture if loading fails

# Apply visual effects for elite enemies (subtle since they have unique sprites)
func apply_elite_visual_effects():
	var visual = $Sprite2D
	if not visual:
		return
	
	# MAKE ELITES GLOW AND STAND OUT!
	match elite_type:
		EliteType.ARMORED:
			# BRIGHT metallic silver glow
			visual.modulate = Color(1.3, 1.3, 1.4, 1.0)
			create_elite_outline(Color.SILVER, 8.0)
		EliteType.REGENERATOR:
			# BRIGHT green regeneration glow
			visual.modulate = Color(0.8, 1.4, 0.8, 1.0)  
			create_elite_outline(Color.LIME_GREEN, 6.0)
			create_pulsing_effect(Color.GREEN)
		EliteType.SPLITTER:
			# BRIGHT purple chaotic energy
			visual.modulate = Color(1.3, 0.9, 1.3, 1.0)
			create_elite_outline(Color.MAGENTA, 7.0)
		EliteType.FROST:
			# BRIGHT icy blue glow
			visual.modulate = Color(0.9, 1.1, 1.4, 1.0)
			create_elite_outline(Color.CYAN, 6.0)
		EliteType.EXPLOSIVE:
			# BRIGHT fiery orange glow with flickering
			visual.modulate = Color(1.4, 1.2, 0.8, 1.0)
			create_elite_outline(Color.ORANGE_RED, 8.0)
			create_flickering_effect(Color.RED)
		_:
			# Bright golden glow for unspecified elites
			visual.modulate = Color(1.2, 1.2, 1.0, 1.0)
			create_elite_outline(Color.GOLD, 5.0)

# Method to set monster stats from mathematical system
func set_monster_stats(stats: Dictionary):
	if stats.has("health"):
		base_health = stats.health
		max_health = stats.health
		current_health = stats.health
	
	if stats.has("speed"):
		speed = stats.speed
		base_speed = stats.speed
	
	if stats.has("damage"):
		base_damage = stats.damage
		damage = stats.damage
	
	if stats.has("xp"):
		xp_value = stats.xp
	
	# Handle archetype-specific properties
	if stats.has("group_size"):
		# For swarmer types - could spawn multiple
		pass
		
	if stats.has("attack_range"):
		# For shooter types
		if has_property("attack_range"):
			set("attack_range", stats.attack_range)
	
	if stats.has("projectile_speed"):
		# For shooter types  
		if has_property("projectile_speed"):
			set("projectile_speed", stats.projectile_speed)

# Method to check if property exists (helper for dynamic property setting)
func has_property(property_name: String) -> bool:
	var property_list = get_property_list()
	for property in property_list:
		if property.name == property_name:
			return true
	return false

# Create GLOWING outline effect for elite enemies
func create_elite_outline(color: Color, thickness: float):
	# Create a Line2D node for the outline
	var outline = Line2D.new()
	outline.name = "EliteOutline"
	outline.z_index = -1  # Behind the sprite
	outline.width = thickness
	outline.default_color = color
	outline.antialiased = true
	
	# Create circle points around the enemy
	var radius = 35.0  # Adjust based on enemy size
	var points = []
	for i in range(32):  # 32 points for smooth circle
		var angle = (2 * PI * i) / 32
		var point = Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	points.append(points[0])  # Close the circle
	
	outline.points = PackedVector2Array(points)
	add_child(outline)
	
	# Make it pulse
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(outline, "modulate", Color(color.r, color.g, color.b, 0.7), 0.8)
	tween.tween_property(outline, "modulate", Color(color.r, color.g, color.b, 1.0), 0.8)

# Create pulsing regeneration effect
func create_pulsing_effect(color: Color):
	var tween = create_tween()
	tween.set_loops()
	var sprite = $Sprite2D
	if sprite:
		tween.tween_property(sprite, "modulate", Color(0.8, 1.4, 0.8, 1.0), 1.0)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.2, 1.0, 1.0), 1.0)

# Create flickering explosive effect  
func create_flickering_effect(color: Color):
	var sprite = $Sprite2D
	if sprite:
		var flicker_timer = Timer.new()
		flicker_timer.wait_time = randf_range(0.1, 0.3)
		flicker_timer.timeout.connect(_flicker_explosive)
		add_child(flicker_timer)
		flicker_timer.start()

# Flicker effect callback for explosive enemies
func _flicker_explosive():
	var sprite = $Sprite2D
	if sprite:
		var intensity = randf_range(1.2, 1.6)
		sprite.modulate = Color(intensity, intensity * 0.8, 0.7, 1.0)
		
		# Reset after brief flash
		var reset_timer = Timer.new()
		reset_timer.wait_time = 0.05
		reset_timer.one_shot = true
		reset_timer.timeout.connect(func(): sprite.modulate = Color(1.4, 1.2, 0.8, 1.0))
		add_child(reset_timer)
		reset_timer.start()
