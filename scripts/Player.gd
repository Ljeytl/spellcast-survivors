# Player character controller - handles movement, health, XP, leveling, and damage
# The player moves with WASD keys and casts spells by typing their names
extends CharacterBody2D

# Core gameplay constants that define player capabilities
const BASE_SPEED = 300.0              # Base movement speed in pixels per second
const BASE_MAX_HEALTH = 100.0         # Starting maximum health points
const BASE_XP_REQUIREMENT = 25.0
const XP_LEVEL_INCREMENT = 15.0
const DAMAGE_FLASH_DURATION = 0.1     # How long the red damage flash lasts
const DEBUG_XP_AMOUNT = 50.0          # XP for debug mode

# Core player stats - these change during gameplay
const StatBlock = preload("res://scripts/engine/stats/StatBlock.gd")
## Every changeable number of the wizard: base values plus modifiers with sources (doc 19 §5.3).
## The fields below read and write it, so existing code keeps using player.spell_damage_multiplier etc.
var stats = StatBlock.new({
	"max_health": BASE_MAX_HEALTH, "spell_damage_multiplier": 1.0, "cast_speed_multiplier": 1.0,
	"spell_size_multiplier": 1.0, "spell_duration_multiplier": 1.0, "projectile_speed_multiplier": 1.0,
	"typing_duration_bonus": 0.0, "movement_speed_multiplier": 1.0, "xp_range_multiplier": 1.0,
})

var health: float = BASE_MAX_HEALTH          # Current health points
var max_health: float:  # Maximum health (can be upgraded)
	get: return stats.value("max_health")
	set(v): stats.set_value("max_health", v)
var overheal: float = 0.0                    # Temporary health above max (from earth shield)
var overheal_timer: float = 0.0              # Time remaining for overheal effect
var overheal_duration: float = 16.0           # How long earth shield overheal lasts (seconds)
var earth_shield: Node2D
var xp: float = 0.0                          # Current experience points
var level: int = 1                           # Current player level
var xp_to_next_level: float = BASE_XP_REQUIREMENT  # XP needed for next level

# Upgrade multipliers - these improve through level-up choices
var spell_damage_multiplier: float:
	get: return stats.value("spell_damage_multiplier")
	set(v): stats.set_value("spell_damage_multiplier", v)
var cast_speed_multiplier: float:
	get: return stats.value("cast_speed_multiplier")
	set(v): stats.set_value("cast_speed_multiplier", v)
var spell_size_multiplier: float:
	get: return stats.value("spell_size_multiplier")
	set(v): stats.set_value("spell_size_multiplier", v)
var spell_duration_multiplier: float:
	get: return stats.value("spell_duration_multiplier")
	set(v): stats.set_value("spell_duration_multiplier", v)
var projectile_speed_multiplier: float:
	get: return stats.value("projectile_speed_multiplier")
	set(v): stats.set_value("projectile_speed_multiplier", v)
var typing_duration_bonus: float:
	get: return stats.value("typing_duration_bonus")
	set(v): stats.set_value("typing_duration_bonus", v)
var next_heal_feedback_msec: int = 0
const MAX_PASSIVE_FAMILIES = 6
const SUPPORTED_PASSIVES = ["spell_area", "spell_duration", "spell_damage", "movement_speed", "max_health", "xp_range", "projectile_speed", "slowdown_duration", "mana_bolt_mastery"]
var passive_ranks: Dictionary = {}
var movement_speed_multiplier: float:
	get: return stats.value("movement_speed_multiplier")
	set(v): stats.set_value("movement_speed_multiplier", v)
var xp_range_multiplier: float:
	get: return stats.value("xp_range_multiplier")
	set(v): stats.set_value("xp_range_multiplier", v)

## Level-up passive → the stat it adds to. Each pick is one modifier with source "passive:<type>".
const PASSIVE_STATS = {
	"spell_damage": "spell_damage_multiplier", "cast_speed": "cast_speed_multiplier",
	"spell_area": "spell_size_multiplier", "spell_duration": "spell_duration_multiplier",
	"projectile_speed": "projectile_speed_multiplier", "slowdown_duration": "typing_duration_bonus",
	"movement_speed": "movement_speed_multiplier", "max_health": "max_health", "xp_range": "xp_range_multiplier",
}

# Signals sent to other systems when player state changes
signal health_changed(new_health: float, max_health: float, overheal_amount: float)  # Update health bar UI
signal xp_changed(new_xp: float, xp_needed: float)          # Update XP bar UI
signal player_died                                          # Trigger game over screen
signal level_up(new_level: int, player_stats: Dictionary)   # Show level up screen
signal style_health_damaged(health_loss: float)
signal player_damaged                                       # Trigger screen shake and effects

# Visual feedback system for damage
var is_flashing: bool = false              # True when sprite should be red from damage
var flash_timer: float = 0.0               # Countdown timer for damage flash
var flash_duration: float = DAMAGE_FLASH_DURATION  # How long damage flash lasts
@onready var sprite: Sprite2D = $Sprite2D  # Player sprite for visual effects

# Debug mode helpers
var debug_x_pressed: bool = false

# Invincibility cheat system
var last_damage_context: Dictionary = {}
var is_invincible: bool = false     # When true, player takes no damage
## Brief invulnerability after Earth Shield blocks a hit, so one crowd contact does not eat every charge.
const SHIELD_BLOCK_GRACE: float = 0.25
var shield_grace_remaining: float = 0.0

# Called when player scene is first loaded
func _ready():
	# Register with player group so other systems can find us
	add_to_group("player")


	# Send initial UI updates with starting values
	health_changed.emit(health, max_health, overheal)
	xp_changed.emit(xp, xp_to_next_level)

# Called when the player node is about to be removed from the scene
func _exit_tree():
	# Clean up player resources
	# Clear the touching enemies array to prevent stale references
	touching_enemies.clear()
	damage_timer = 0.0

# Called every physics frame (60 FPS) for movement and visual effects
func _physics_process(delta):
	shield_grace_remaining = maxf(0.0, shield_grace_remaining - delta)
	# Process WASD movement input and apply velocity
	handle_movement()
	# Actually move the player using Godot's built-in physics
	move_and_slide()

	# Handle overheal expiration
	handle_overheal_expiration(delta)

	# Process continuous damage from touching enemies
	process_enemy_contact_damage(delta)
	process_statuses(delta)

	# Update the red damage flash effect
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			is_flashing = false

# Process WASD movement input and set player velocity
func handle_movement():
	var spells = get_parent().get_node_or_null("SpellManager")
	if spells and spells.is_typing:
		velocity = Vector2.ZERO
		return
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
		var current_speed = BASE_SPEED * movement_speed_multiplier * status_speed_multiplier()

		# Apply slowdown based on touching enemies
		var slowdown_multiplier = calculate_enemy_slowdown()
		current_speed *= slowdown_multiplier

		velocity = input_dir * current_speed
	else:
		# Stop moving when no keys are pressed
		velocity = Vector2.ZERO

# Called when player takes damage from enemies or other sources
func take_damage(damage: float, source: Dictionary = {}):
	var previous_health = health
	var previous_overheal = overheal
	var previous_total = health + overheal
	if health <= 0.0:
		return
	# Check invincibility first
	if is_invincible:
		return

	if damage <= 0:
		return
	if shield_grace_remaining > 0.0:
		return
	if is_instance_valid(earth_shield) and earth_shield.block(source):
		shield_grace_remaining = SHIELD_BLOCK_GRACE
		last_damage_context = source.duplicate(true)
		last_damage_context.merge({"kind": source.get("kind", "unknown"), "damage": 0.0, "health_loss": 0.0, "overheal_loss": 0.0, "blocked": true}, true)
		return

	# Apply damage to overheal first, then health
	if overheal > 0:
		var damage_to_overheal = min(damage, overheal)
		overheal -= damage_to_overheal
		damage -= damage_to_overheal

	# Apply remaining damage to health
	health -= damage
	health = max(0, health)  # Don't let health go below 0
	var actual_damage = maxf(0, previous_total - health - overheal)
	if actual_damage > 0:
		var particles = get_parent().get("particle_manager")
		if is_instance_valid(particles):
			if previous_overheal > overheal and particles.has_method("create_earthshield_effect"):
				particles.create_earthshield_effect(global_position)
			if previous_health > health and particles.has_method("create_hurt_effect"):
				particles.create_hurt_effect(global_position)
		last_damage_context = source.duplicate(true)
		last_damage_context["kind"] = source.get("kind", "unknown")
		last_damage_context["damage"] = actual_damage
		last_damage_context["health_loss"] = maxf(0, previous_health - health)
		last_damage_context["overheal_loss"] = maxf(0, previous_overheal - overheal)
		if previous_health > health:
			style_health_damaged.emit(previous_health - health)

	# Play damage sound effect
	if actual_damage > 0 and is_instance_valid(AudioManager):
		AudioManager.on_damage_taken()

	# Update the health bar UI
	health_changed.emit(health, max_health, overheal)

	# Trigger visual and camera effects
	if previous_health > health:
		flash_damage()
	player_damaged.emit() # Trigger camera shake in Game.gd

	# Check if player has died
	if health <= 0:
		player_died.emit()  # Trigger game over screen

# Make the player sprite flash red briefly when taking damage
func flash_damage():
	if sprite:
		is_flashing = true              # Start the flash effect
		flash_timer = flash_duration    # Reset the timer
		preload("res://scripts/DamageFlash.gd").trigger(sprite, flash_duration)

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
	xp_to_next_level = BASE_XP_REQUIREMENT + ((level - 1) * XP_LEVEL_INCREMENT)

	# Play level up sound effect
	if is_instance_valid(AudioManager):
		AudioManager.on_level_up()

	# Send level up event with current player stats for upgrade selection
	var player_stats = {
		"spell_damage_multiplier": spell_damage_multiplier,
		"cast_speed_multiplier": cast_speed_multiplier,
		"spell_size_multiplier": spell_size_multiplier,
		"spell_duration_multiplier": spell_duration_multiplier,
		"projectile_speed_multiplier": projectile_speed_multiplier,
		"passive_ranks": passive_ranks.duplicate(),
		"movement_speed_multiplier": movement_speed_multiplier,
		"max_health": max_health,
		"xp_range_multiplier": xp_range_multiplier
	}
	level_up.emit(level, player_stats)

# Restore health to the player (from Life spell or chest items)
func heal(amount: float, visual_size: float = 1.0, visual_source: String = "heal"):
	if health <= 0.0 or amount <= 0.0:
		return false
	var previous_health = health
	health = min(max_health, health + amount)
	if health > previous_health and Time.get_ticks_msec() >= next_heal_feedback_msec:
		next_heal_feedback_msec = Time.get_ticks_msec() + 350
		var vfx = get_node_or_null("/root/Vfx")
		var particles = get_parent().get("particle_manager")
		if visual_source == "soul_bloom":
			pass
		elif vfx and vfx.prop_burst(visual_source, global_position, visual_size):
			pass   # the VFX layer shows heals (docs/VFX_EVENTS.md)
		elif is_instance_valid(particles) and particles.has_method("create_heal_effect"):
			var effect = particles.create_heal_effect(global_position)
			if is_instance_valid(effect):
				effect.scale = Vector2.ONE * visual_size
	# Update the health bar UI
	health_changed.emit(health, max_health, overheal)
	if visual_source == "soul_bloom" and health > previous_health:
		var vfx = get_node_or_null("/root/Vfx")
		return vfx != null and vfx.prop_burst(visual_source, global_position, visual_size)
	return false

# Toggle invincibility cheat (called from Game.gd)
func toggle_invincibility():
	is_invincible = not is_invincible
	var status = "ON" if is_invincible else "OFF"

	# Visual feedback - make player flash when invincible
	if is_invincible:
		sprite.modulate = Color(1.0, 1.0, 0.5, 0.8)  # Golden tint with transparency
	else:
		sprite.modulate = Color.WHITE  # Back to normal

# Alternative name for add_xp used by chest system
func gain_xp(amount: float):
	add_xp(amount)

## WARDING: a ward absorbs damage before health. It refreshes rather than stacks (doc 21 §4.4).
func add_ward(amount: float, duration: float):
	overheal = maxf(overheal, amount)
	overheal_timer = maxf(overheal_timer, duration)
	health_changed.emit(health, max_health, overheal)

# Add temporary overheal (from earth shield spell)
func add_overheal(amount: float, duration: float = 16.0):
	overheal_duration = maxf(0.0, duration)
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
				if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.get("dying") or float(enemy.get("current_health")) <= 0.0:
					touching_enemies.remove_at(i)

			# Apply damage from all touching enemies
			if touching_enemies.size() > 0:
				var unblocked_damage = 0.0
				var unblocked_enemies: Array = []
				for enemy in touching_enemies.duplicate():
					if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.get("dying"):
						continue
					if is_instance_valid(earth_shield) and not earth_shield.charges.is_empty():
						take_damage(float(enemy.base_damage), {"kind": "contact", "source_position": enemy.global_position, "attacker": weakref(enemy)})
					else:
						unblocked_damage += float(enemy.base_damage)
						unblocked_enemies.append(enemy)
				if unblocked_damage > 0:
					var before = health + overheal
					take_damage(unblocked_damage, {"kind": "contact", "count": unblocked_enemies.size(), "source_position": unblocked_enemies[0].global_position})
					if health + overheal < before:
						for enemy in unblocked_enemies:
							if is_instance_valid(enemy) and enemy.has_method("recoil_from_contact"):
								enemy.recoil_from_contact(global_position)
							if is_instance_valid(enemy) and enemy.has_method("on_dealt_contact"):
								enemy.on_dealt_contact(float(enemy.base_damage))   # LEECHING elites
				damage_timer = DAMAGE_INTERVAL  # Reset timer

# Calculate movement slowdown based on number of touching enemies
func calculate_enemy_slowdown() -> float:
	return 1.0  # No slowdown - player moves at full speed regardless of enemy contact

# Apply upgrades selected from the level-up screen
func can_acquire_passive(family: String) -> bool:
	return family in SUPPORTED_PASSIVES and (passive_ranks.has(family) or passive_ranks.size() < MAX_PASSIVE_FAMILIES)

func apply_upgrade(upgrade_data: Dictionary) -> bool:
	var effect = upgrade_data.get("effect", {})
	var effect_type = effect.get("type", "")
	var value = effect.get("value", 0.0)

	if effect_type in SUPPORTED_PASSIVES:
		if not can_acquire_passive(effect_type):
			return false
		passive_ranks[effect_type] = int(passive_ranks.get(effect_type, 0)) + 1
	elif effect_type not in ["spell_upgrade", "learn_spell", "recovery"]:
		return false
	# Passives are stat modifiers; spell upgrades are handled by SpellManager.
	if effect_type == "recovery":
		heal(float(value))
	elif effect_type == "mana_bolt_mastery":
		stats.add_modifier("cast_speed_multiplier", "add", 0.1, "passive:mana_bolt_mastery")
	elif PASSIVE_STATS.has(effect_type):
		stats.add_modifier(PASSIVE_STATS[effect_type], "add", float(value), "passive:" + effect_type)
		if effect_type == "max_health":
			health += value  # also heal when max health increases
			health_changed.emit(health, max_health, overheal)
	return true

# Track enemies currently touching the player for continuous damage
var touching_enemies: Array = []
var damage_timer: float = 0.0
const DAMAGE_INTERVAL: float = 1.0  # Take damage every 1 second while touching
const ENEMY_SLOWDOWN_FACTOR: float = 0.7  # Player moves 70% speed when touching enemies
const MAX_ENEMY_SLOWDOWN: float = 0.3  # Minimum speed is 30% when surrounded

# Collision detection - called when enemy enters player's HitBox
func _on_hit_box_body_entered(body):
	if body.is_in_group("enemies") and body not in touching_enemies:
		touching_enemies.append(body)

# Collision detection - called when enemy leaves player's HitBox
func _on_hit_box_body_exited(body):
	if body.is_in_group("enemies") and body in touching_enemies:
		touching_enemies.erase(body)

func start_healing_over_time(amount: float, duration: float):
	var game = get_tree().get_first_node_in_group("game")
	if game != null and health > 0.0:
		game.spell_manager.add_healing_effect(amount, duration)

func add_earth_shield_charge(info: Dictionary):
	if not is_instance_valid(earth_shield):
		earth_shield = preload("res://scripts/EarthShield.gd").new()
		add_child(earth_shield)
	earth_shield.add_charge(info)

# --- monster spells and statuses on the player (elites, data/elites.json "player_statuses") -----
## Running statuses: id -> {remaining, tick}. Burn hurts over time; chilled and shocked slow.
var statuses: Dictionary = {}

## Effects from monster spells and elite contact (scripts/engine/Effects.gd routes here).
func apply_effect(effect: Dictionary, source: Dictionary = {}, origin: Vector2 = Vector2.INF) -> float:
	match str(effect.get("type", "")):
		"damage":
			var total := 0.0
			for entry in effect.get("entries", []):
				total += float(entry.get("amount", 0.0))
			total += float(effect.get("amount", 0.0))
			if total > 0.0:
				var before = health + overheal
				take_damage(total, {"kind": "spell", "source_position": origin, "spell": str(source.get("spell", ""))})
				return maxf(0.0, before - health - overheal)
		"status":
			apply_status(str(effect.get("status", "")))
		"heal":
			heal(float(effect.get("amount", 0.0)))
	return 0.0

func apply_status(id: String) -> void:
	var defs: Dictionary = preload("res://scripts/Elites.gd").data().get("player_statuses", {})
	if not defs.has(id):
		return
	statuses[id] = {"remaining": float(defs[id].get("duration", 2.0)), "tick": float(defs[id].get("tick", 0.5))}

func has_status(id: String) -> bool:
	return statuses.has(id)

func status_speed_multiplier() -> float:
	var defs: Dictionary = preload("res://scripts/Elites.gd").data().get("player_statuses", {})
	var mult := 1.0
	for id in statuses:
		mult = minf(mult, 1.0 - float(defs.get(id, {}).get("slow", 0.0)))
	return mult

func process_statuses(delta: float) -> void:
	if statuses.is_empty():
		return
	var defs: Dictionary = preload("res://scripts/Elites.gd").data().get("player_statuses", {})
	for id in statuses.keys():
		var s: Dictionary = statuses[id]
		s.remaining -= delta
		var dps = float(defs.get(id, {}).get("damage_per_second", 0.0))
		if dps > 0.0:
			s.tick -= delta
			if s.tick <= 0.0:
				var interval = float(defs[id].get("tick", 0.5))
				s.tick += interval
				take_damage(dps * interval, {"kind": "status", "status": id})
		if s.remaining <= 0.0:
			statuses.erase(id)
