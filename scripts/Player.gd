# Player character controller - handles movement, health, XP, leveling, and damage
# The player moves with WASD keys and casts spells by typing their names
extends CharacterBody2D

# Core gameplay constants that define player capabilities
const BASE_SPEED = 300.0              # Base movement speed in pixels per second
const BASE_MAX_HEALTH = 100.0         # Starting maximum health points
const BASE_XP_REQUIREMENT = 100.0     # XP needed to reach level 2
const XP_LEVEL_INCREMENT = 25.0       # Additional XP needed per level (level 3 needs 125, level 4 needs 150, etc.)
const DAMAGE_FLASH_DURATION = 0.1     # How long the red damage flash lasts
const DEBUG_XP_AMOUNT = 50.0          # XP gained when pressing X in debug mode

# Core player stats - these change during gameplay
var health: float = BASE_MAX_HEALTH          # Current health points
var max_health: float = BASE_MAX_HEALTH      # Maximum health (can be upgraded)
var overheal: float = 0.0                    # Temporary health above max (from earth shield)
var overheal_timer: float = 0.0              # Time remaining for overheal effect
var overheal_duration: float = 5.0           # How long earth shield overheal lasts (seconds)
var xp: float = 0.0                          # Current experience points
var level: int = 1                           # Current player level
var xp_to_next_level: float = BASE_XP_REQUIREMENT  # XP needed for next level

# Upgrade multipliers - these improve through level-up choices
var spell_damage_multiplier: float = 1.0     # Increases damage of all spells
var cast_speed_multiplier: float = 1.0       # Reduces spell casting time
var movement_speed_multiplier: float = 1.0   # Increases walking speed
var xp_range_multiplier: float = 1.0         # Increases XP orb pickup range

# Signals sent to other systems when player state changes
signal health_changed(new_health: float, max_health: float, overheal_amount: float)  # Update health bar UI
signal xp_changed(new_xp: float, xp_needed: float)          # Update XP bar UI
signal player_died                                          # Trigger game over screen
signal level_up(new_level: int, player_stats: Dictionary)   # Show level up screen
signal player_damaged                                       # Trigger screen shake and effects

# Visual feedback system for damage
var is_flashing: bool = false              # True when sprite should be red from damage
var flash_timer: float = 0.0               # Countdown timer for damage flash
var flash_duration: float = DAMAGE_FLASH_DURATION  # How long damage flash lasts
@onready var sprite: Sprite2D = $Sprite2D  # Player sprite for visual effects

# Debug mode helpers - only work in debug builds
var debug_x_pressed: bool = false  # Prevents X key spam in debug mode

# Invincibility cheat system
var is_invincible: bool = false     # When true, player takes no damage

# Called when player scene is first loaded
func _ready():
	# Register with player group so other systems can find us
	add_to_group("player")
	
	# Debug: Confirm HitBox signal connection
	print("DEBUG: Player _ready() - HitBox collision detection initialized")
	
	# Send initial UI updates with starting values
	health_changed.emit(health, max_health, overheal)
	xp_changed.emit(xp, xp_to_next_level)

# Called when the player node is about to be removed from the scene
func _exit_tree():
	print("DEBUG: Player _exit_tree() - cleaning up")
	# Clear the touching enemies array to prevent stale references
	touching_enemies.clear()
	damage_timer = 0.0

# Called every physics frame (60 FPS) for movement and visual effects
func _physics_process(delta):
	# Process WASD movement input and apply velocity
	handle_movement()
	# Actually move the player using Godot's built-in physics
	move_and_slide()
	
	# Handle overheal expiration
	handle_overheal_expiration(delta)
	
	# Process continuous damage from touching enemies
	process_enemy_contact_damage(delta)
	
	# Update the red damage flash effect
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			# Flash is over, return sprite to normal color
			is_flashing = false
			if sprite:
				sprite.modulate = Color.WHITE
	
	# Debug feature: press X to gain XP instantly (only in debug builds)
	if OS.is_debug_build():
		if Input.is_physical_key_pressed(KEY_X) and not debug_x_pressed:
			debug_x_pressed = true  # Prevent key repeat spam
			add_xp(DEBUG_XP_AMOUNT)
		elif not Input.is_physical_key_pressed(KEY_X):
			debug_x_pressed = false  # Allow X key to be pressed again

# Process WASD movement input and set player velocity
func handle_movement():
	var input_dir = Vector2.ZERO
	
	# Check each movement key and build direction vector
	if Input.is_action_pressed("move_left"):    # A key
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):   # D key
		input_dir.x += 1
	if Input.is_action_pressed("move_up"):      # W key
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):    # S key
		input_dir.y += 1
	
	# Apply movement if any direction keys are pressed
	if input_dir != Vector2.ZERO:
		# Normalize to prevent faster diagonal movement
		input_dir = input_dir.normalized()
		# Apply speed with upgrades multiplier
		var current_speed = BASE_SPEED * movement_speed_multiplier
		
		# Apply slowdown based on touching enemies
		var slowdown_multiplier = calculate_enemy_slowdown()
		current_speed *= slowdown_multiplier
		
		velocity = input_dir * current_speed
	else:
		# Stop moving when no keys are pressed
		velocity = Vector2.ZERO

# Called when player takes damage from enemies or other sources
func take_damage(damage: float):
	# Check invincibility first
	if is_invincible:
		print("DEBUG: Damage blocked by invincibility: ", damage)
		return
	
	# Apply damage to overheal first, then health
	if overheal > 0:
		var damage_to_overheal = min(damage, overheal)
		overheal -= damage_to_overheal
		damage -= damage_to_overheal
	
	# Apply remaining damage to health
	health -= damage
	health = max(0, health)  # Don't let health go below 0
	
	# Play damage sound effect
	if is_instance_valid(AudioManager):
		print("DEBUG: Playing damage sound")
		AudioManager.on_damage_taken()
	else:
		print("DEBUG: AudioManager not available for damage sound")
	
	# Update the health bar UI
	health_changed.emit(health, max_health, overheal)
	
	# Trigger visual and camera effects
	flash_damage()        # Make player sprite flash red
	player_damaged.emit() # Trigger camera shake in Game.gd
	
	# Check if player has died
	if health <= 0:
		print("DEBUG: Player health reached 0, emitting player_died signal")
		player_died.emit()  # Trigger game over screen

# Make the player sprite flash red briefly when taking damage
func flash_damage():
	if sprite:
		is_flashing = true              # Start the flash effect
		flash_timer = flash_duration    # Reset the timer
		sprite.modulate = Color.RED     # Turn sprite red

# Add experience points to the player, potentially triggering level up
func add_xp(amount: float):
	xp += amount
	
	# Handle multiple level ups if player gained a lot of XP at once
	while xp >= xp_to_next_level:
		do_level_up()
	
	# Update the XP bar UI
	xp_changed.emit(xp, xp_to_next_level)

# Internal function to handle leveling up when XP threshold is reached
func do_level_up():
	# Subtract XP cost for this level and advance to next level
	xp -= xp_to_next_level
	level += 1
	# Calculate XP needed for next level (increases by 25 each level)
	xp_to_next_level = BASE_XP_REQUIREMENT + (level * XP_LEVEL_INCREMENT)
	
	# Play level up sound effect
	if is_instance_valid(AudioManager):
		AudioManager.on_level_up()
	
	# Send level up event with current player stats for upgrade selection
	var player_stats = {
		"spell_damage_multiplier": spell_damage_multiplier,
		"cast_speed_multiplier": cast_speed_multiplier, 
		"movement_speed_multiplier": movement_speed_multiplier,
		"max_health": max_health,
		"xp_range_multiplier": xp_range_multiplier
	}
	level_up.emit(level, player_stats)

# Restore health to the player (from Life spell or chest items)
func heal(amount: float):
	# Don't heal above maximum health
	health = min(max_health, health + amount)
	# Update the health bar UI
	health_changed.emit(health, max_health, overheal)

# Toggle invincibility cheat (called from Game.gd)
func toggle_invincibility():
	is_invincible = not is_invincible
	var status = "ON" if is_invincible else "OFF"
	print("DEBUG: Player invincibility toggled {0}".format([status]))
	
	# Visual feedback - make player flash when invincible
	if is_invincible:
		sprite.modulate = Color(1.0, 1.0, 0.5, 0.8)  # Golden tint with transparency
	else:
		sprite.modulate = Color.WHITE  # Back to normal

# Alternative name for add_xp used by chest system
func gain_xp(amount: float):
	add_xp(amount)

# Add temporary overheal (from earth shield spell)
func add_overheal(amount: float):
	# Add to existing overheal
	overheal += amount
	# Reset or extend the timer
	overheal_timer = overheal_duration
	print("Earthshield activated: +", amount, " overheal for ", overheal_duration, "s | Total overheal: ", overheal, " | Total effective HP: ", health + overheal)
	# Update the health bar UI to show overheal
	health_changed.emit(health, max_health, overheal)

# Handle overheal expiration over time
func handle_overheal_expiration(delta: float):
	if overheal > 0:
		overheal_timer -= delta
		
		# Warn when overheal is about to expire (last 5 seconds)
		if overheal_timer <= 5.0 and overheal_timer > 4.9:
			print("⚠️ Earthshield expiring in 5 seconds!")
		
		if overheal_timer <= 0:
			# Overheal has expired
			print("🛡️ Earthshield expired - overheal removed")
			overheal = 0.0
			overheal_timer = 0.0
			health_changed.emit(health, max_health, overheal)

# Get remaining overheal time for UI display
func get_overheal_time_remaining() -> float:
	return overheal_timer

# Get current health as a percentage (0.0 to 1.0)
func get_health_percent() -> float:
	return health / max_health

# Get current total health including overheal
func get_total_health() -> float:
	return health + overheal

# Process continuous damage from enemies touching the player
func process_enemy_contact_damage(delta: float):
	if touching_enemies.size() > 0:
		damage_timer -= delta
		if damage_timer <= 0.0:
			# Clean up any invalid enemies from the list
			for i in range(touching_enemies.size() - 1, -1, -1):
				var enemy = touching_enemies[i]
				if not is_instance_valid(enemy):
					touching_enemies.remove_at(i)
			
			# Apply damage from all touching enemies
			if touching_enemies.size() > 0:
				var total_damage = 0.0
				for enemy in touching_enemies:
					var damage = enemy.base_damage if enemy.get("base_damage") else 20.0
					total_damage += damage
				
				print("DEBUG: Taking ", total_damage, " damage from ", touching_enemies.size(), " touching enemies")
				take_damage(total_damage)
				damage_timer = DAMAGE_INTERVAL  # Reset timer

# Calculate movement slowdown based on number of touching enemies
func calculate_enemy_slowdown() -> float:
	return 1.0  # No slowdown - player moves at full speed regardless of enemy contact

# Apply upgrades selected from the level-up screen
func apply_upgrade(upgrade_data: Dictionary):
	var effect = upgrade_data.get("effect", {}) 
	var effect_type = effect.get("type", "")
	var value = effect.get("value", 0.0)
	
	# Apply the upgrade based on its type
	match effect_type:
		"spell_damage":
			spell_damage_multiplier += value  # Increase spell damage
		"cast_speed":
			cast_speed_multiplier += value    # Reduce spell casting time
		"movement_speed":
			movement_speed_multiplier += value # Increase walking speed
		"max_health":
			max_health += value               # Increase maximum health
			health += value                   # Also heal when max health increases
			health_changed.emit(health, max_health, overheal)
		"xp_range":
			xp_range_multiplier += value      # Increase XP orb pickup range
		"spell_upgrade":
			# Spell level upgrades are handled by SpellManager
			var spell_name = effect.get("spell", "")
			pass

# Track enemies currently touching the player for continuous damage
var touching_enemies: Array = []
var damage_timer: float = 0.0
const DAMAGE_INTERVAL: float = 1.0  # Take damage every 1 second while touching
const ENEMY_SLOWDOWN_FACTOR: float = 0.7  # Player moves 70% speed when touching enemies
const MAX_ENEMY_SLOWDOWN: float = 0.3  # Minimum speed is 30% when surrounded

# Collision detection - called when enemy enters player's HitBox
func _on_hit_box_body_entered(body):
	print("DEBUG: HitBox collision ENTERED with: ", body.name, " | Is enemy: ", body.is_in_group("enemies"))
	if body.is_in_group("enemies") and body not in touching_enemies:
		touching_enemies.append(body)
		print("DEBUG: Enemy added to touching list. Total touching: ", touching_enemies.size())

# Collision detection - called when enemy leaves player's HitBox
func _on_hit_box_body_exited(body):
	print("DEBUG: HitBox collision EXITED with: ", body.name, " | Is enemy: ", body.is_in_group("enemies"))
	if body.is_in_group("enemies") and body in touching_enemies:
		touching_enemies.erase(body)
		print("DEBUG: Enemy removed from touching list. Total touching: ", touching_enemies.size())
