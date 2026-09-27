# Spell projectile that can be fired in straight lines or home toward enemies
# Supports multiple spell types with different visuals and behaviors
extends Area2D

const Targeting = preload("res://scripts/SpellTargeting.gd")
var reservation_remaining = 0.0
var retarget_range = 600.0

var healing_owner: WeakRef
var heal_on_hit = 0.0
var hit_ids: Dictionary = {}

var despawning: bool = false

# Movement and damage properties
var speed: float = 400.0              # Movement speed in pixels per second
var damage: float = 10.0              # Damage dealt to enemies on hit
var direction: Vector2 = Vector2.RIGHT # Direction vector for straight-line projectiles
var target: Node2D = null             # Target enemy for homing projectiles
var is_homing: bool = false            # Whether this projectile homes toward target
var projectile_type: String = "basic" # Type determines visual and behavior
var effect_color: Color = Color.WHITE # Color tint for the projectile sprite
var effect_radius: float = 0.0        # Radius for area-of-effect spells
var lifetime: float = 3.0             # How long projectile exists before despawning
var homing_strength: float = 5.0      # How quickly homing projectiles turn toward target

# Object pooling support to improve performance
signal pool_return_requested          # Emitted when projectile should return to pool
var lifetime_timer: float = 0.0       # Countdown timer for projectile lifetime
var is_pooled: bool = false            # Whether this projectile came from object pool

func _ready():
	add_to_group("spell_projectiles")
	
	# Set up collision detection - Area2D can only detect other Area2D nodes
	area_entered.connect(_on_area_entered)
	
	# Set up lifetime timer
	lifetime_timer = lifetime
	
	# Update visual based on type
	call_deferred("update_visual")

func _process(delta):
	if despawning:
		return
	reservation_remaining -= delta
	if is_homing and not Targeting.alive(target):
		assign_target(Targeting.select(get_tree(), global_position, retarget_range, hit_ids, self))
	if not is_homing and Targeting.alive(target):
		var offset = target.global_position - global_position
		if offset.dot(direction) < -24 or absf(offset.cross(direction)) > 60:
			reservation_remaining = 0.0
	queue_redraw()
	# Handle lifetime
	lifetime_timer -= delta
	if lifetime_timer <= 0:
		despawn()
		return
	
	if is_homing and is_instance_valid(target):
		# Homing behavior
		var target_direction = (target.global_position - global_position).normalized()
		direction = direction.lerp(target_direction, homing_strength * delta).normalized()
		# Rotate visual to match direction
		rotation = direction.angle()
	
	global_position += direction * speed * delta
	


func setup(start_pos: Vector2, target_dir: Vector2, spell_damage: float, color: Color = Color.WHITE, type: String = "basic"):
	# Ensure we have valid parameters
	if target_dir == Vector2.ZERO:
		print("⚠️  Warning: setup() called with zero direction, using Vector2.RIGHT")
		direction = Vector2.RIGHT
	else:
		direction = target_dir.normalized()
	
	global_position = start_pos
	damage = spell_damage
	effect_color = color
	projectile_type = type
	is_homing = false
	assign_target(null)
	
	# Rotate visual to match direction
	rotation = direction.angle()
	
	# Update visual after a brief delay to ensure _ready() has completed
	call_deferred("update_visual")

func setup_homing(start_pos: Vector2, homing_target: Node2D, spell_damage: float, color: Color = Color.WHITE, type: String = "homing"):
	global_position = start_pos
	target = homing_target
	damage = spell_damage
	effect_color = color
	projectile_type = type
	is_homing = true
	assign_target(homing_target)
	
	# Initial direction towards target
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle()
	
	call_deferred("update_visual")

func setup_effect(pos: Vector2, color: Color, type: String, duration: float):
	monitoring = false
	global_position = pos
	effect_color = color
	projectile_type = type
	lifetime = duration
	lifetime_timer = duration
	speed = 0.0  # Stationary effect
	
	call_deferred("update_visual")

func setup_aoe_effect(pos: Vector2, radius: float, color: Color, type: String):
	monitoring = false
	print("🎯 SpellProjectile setup_aoe_effect: type=", type, " radius=", radius, " pos=", pos)
	global_position = pos
	effect_color = color
	projectile_type = type
	effect_radius = radius
	speed = 0.0  # Stationary effect
	lifetime = 0.5
	lifetime_timer = lifetime
	
	call_deferred("update_visual")

func setup_lightning_arc(from_pos: Vector2, to_pos: Vector2, color: Color):
	monitoring = false
	global_position = from_pos
	effect_color = color
	projectile_type = "lightning"
	speed = 0.0
	lifetime = 0.3
	lifetime_timer = lifetime
	
	# Store end position for drawing
	set_meta("end_pos", to_pos)
	
	call_deferred("update_visual")

func update_visual():
	var animation = get_node_or_null("AnimationPlayer")
	if animation:
		animation.stop()
	var sprite = get_node_or_null("ProjectileSprite")
	if sprite:
		sprite.visible = false
	var particles = get_node_or_null("TrailParticles")
	if particles:
		particles.emitting = false
	z_index = 10
	queue_redraw()

func _on_area_entered(area):
	if despawning or projectile_type in ["heal", "shield", "ice", "meteor", "warning", "lightning", "flash"]:
		return
	# Handle different projectile types
	if is_in_group("enemy_projectiles"):
		# Enemy projectile hitting player 
		if area.name == "HurtBox" and area.get_parent().is_in_group("player"):
			var player = area.get_parent()
			if player.has_method("take_damage"):
				player.take_damage(damage)
				
				# Create impact effect
				var scene_tree = get_tree()
				if scene_tree:
					var game_node = scene_tree.get_first_node_in_group("game")
					if game_node and game_node.has_method("create_spell_impact_effect"):
						game_node.create_spell_impact_effect(global_position)
				
				despawn()
	else:
		# Player projectile hitting enemy (existing code)
		if area.name == "HurtBox" and area.get_parent().is_in_group("enemies"):
			var enemy = area.get_parent()
			if enemy.has_method("take_damage"):
				if hit_ids.has(enemy.get_instance_id()) or enemy.get("dying") or enemy.current_health <= 0:
					return
				reservation_remaining = 0.0
				hit_ids[enemy.get_instance_id()] = true
				var health_before = enemy.current_health
				enemy.take_damage(damage, global_position)
				var dealt = maxf(0.0, health_before - enemy.current_health)
				if projectile_type == "life_bolt" and dealt > 0:
					spawn_healing_seed()

				# Create particle effect on impact
				var scene_tree = get_tree()
				if scene_tree:
					var game_node = scene_tree.get_first_node_in_group("game")
					if game_node and game_node.has_method("create_spell_impact_effect"):
						game_node.create_spell_impact_effect(global_position)
				
				# Create damage number
				var parent = get_parent()
				if parent and parent.has_method("show_damage_number"):
					parent.show_damage_number(enemy.global_position, damage)
				
				# Remove projectile after hit (unless it's a piercing type)
				if not bounce_from(enemy) and projectile_type != "lightning_arc":
					despawn()

# Custom drawing for special effects like lightning and area effects
func _draw():
	var art = preload("res://scripts/EffectArt.gd")
	match projectile_type:
		"lightning":
			art.beam(self, Vector2.ZERO, to_local(get_meta("end_pos", global_position)), 3)
		"warning":
			draw_arc(Vector2.ZERO, effect_radius, 0, TAU, 48, Color("e88d52"), 2)
		"ice", "meteor":
			art.burst(self, 1 if projectile_type == "ice" else 0, Vector2.ZERO, effect_radius * 2, 1 - lifetime_timer / maxf(lifetime, 0.01))
		"shield":
			art.wreath(self, "stone", Vector2.ZERO, 30, 0)
		"heal":
			art.wreath(self, "heal", Vector2.ZERO, 24, 0)
		"mana_bolt":
			art.stamp(self, "mana", Vector2.ZERO, Vector2(22, 18))
		"bolt", "life_bolt", "lightning_bolt":
			art.stamp(self, "bolt", Vector2.ZERO, Vector2(30, 24), Color("b3d899") if projectile_type == "life_bolt" else Color.WHITE)
		_:
			art.stamp(self, "impact", Vector2.ZERO, Vector2.ONE * 18)

func bounce_from(enemy) -> bool:
	if projectile_type != "lightning_bolt":
		return false
	var bounces = int(get_meta("bounce_count", 0))
	if bounces <= 0:
		return false
	var nearest = Targeting.select(get_tree(), global_position, float(get_meta("bounce_range", 240.0)), hit_ids, self)
	if not nearest:
		return false
	set_meta("bounce_count", bounces - 1)
	is_homing = true
	assign_target(nearest)
	direction = global_position.direction_to(nearest.global_position)
	rotation = direction.angle()
	return true

func spawn_healing_seed():
	var owner_reference = get_meta("healing_seed_owner") if has_meta("healing_seed_owner") else healing_owner
	var player = owner_reference.get_ref() if owner_reference else get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	var seed = preload("res://scripts/HealingSeed.gd").new()
	seed.player_ref = weakref(player)
	seed.healing_amount = float(get_meta("healing_seed_amount", 6.0))
	seed.healing_duration = float(get_meta("healing_seed_duration", 2.0))
	seed.remaining = float(get_meta("healing_seed_lifetime", 10.0))
	seed.cap = maxi(1, int(get_meta("healing_seed_cap", 6)))
	seed.position = get_parent().to_local(global_position)
	get_parent().add_child(seed)

# Object pooling methods
func setup_for_pool():
	# Called when object is first created for pooling
	is_pooled = true

func reset_for_pool():
	reservation_remaining = 0.0
	monitoring = true
	hit_ids.clear()
	remove_meta("bounce_count")
	remove_meta("bounce_range")
	for key in ["healing_seed_owner", "healing_seed_amount", "healing_seed_duration", "healing_seed_lifetime", "healing_seed_cap"]:
		remove_meta(key)
	healing_owner = null
	heal_on_hit = 0.0
	despawning = false
	# Reset object state for reuse from pool
	# Reset all properties to defaults
	speed = 400.0
	damage = 10.0
	direction = Vector2.RIGHT
	target = null
	is_homing = false
	projectile_type = "basic"
	effect_color = Color.WHITE
	effect_radius = 0.0
	lifetime = 3.0
	lifetime_timer = lifetime
	homing_strength = 5.0
	
	# Reset visual properties
	global_position = Vector2.ZERO
	rotation = 0.0
	visible = true
	
	# Reset sprite if it exists
	var sprite = get_node_or_null("ProjectileSprite")
	if sprite:
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2.ONE
		sprite.visible = true

func despawn():
	if despawning:
		return
	despawning = true
	reservation_remaining = 0.0
	# Remove projectile from scene (return to pool or queue_free)
	if is_pooled:
		pool_return_requested.emit()
	else:
		queue_free()

func _on_lifetime_timer_timeout():
	# Called by the LifetimeTimer node in the scene
	despawn()

func assign_target(enemy):
	target = enemy
	reservation_remaining = 0.0
	if Targeting.alive(target):
		reservation_remaining = minf(lifetime_timer if lifetime_timer > 0 else lifetime, global_position.distance_to(target.global_position) / maxf(speed, 1.0) + 0.25)

func reserved_damage(enemy) -> float:
	if despawning or is_queued_for_deletion() or not visible or reservation_remaining <= 0 or not Targeting.alive(target):
		return 0.0
	return damage if enemy == target else 0.0
