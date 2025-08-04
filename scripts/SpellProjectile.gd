# Spell projectile that can be fired in straight lines or home toward enemies
# Supports multiple spell types with different visuals and behaviors
extends Area2D

# Movement and damage properties
var speed: float = 400.0              # Movement speed in pixels per second
var damage: float = 10.0              # Damage dealt to enemies on hit
var direction: Vector2 = Vector2.RIGHT # Direction vector for straight-line projectiles
var target: Node2D = null             # Target enemy for homing projectiles
var is_homing: bool = false            # Whether this projectile homes toward target
var projectile_type: String = "basic" # Type determines visual and behavior
var effect_color: Color = Color.WHITE # Color tint for the projectile sprite
var effect_radius: float = 0.0        # Radius for area-of-effect spells
var lifetime: float = 5.0             # How long projectile exists before despawning
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
	# Handle lifetime
	lifetime_timer -= delta
	if lifetime_timer <= 0:
		despawn()
		return
	
	if is_homing and target and is_instance_valid(target):
		# Homing behavior
		var target_direction = (target.global_position - global_position).normalized()
		direction = direction.lerp(target_direction, homing_strength * delta).normalized()
		# Rotate visual to match direction
		rotation = direction.angle()
	
	global_position += direction * speed * delta
	
	# Remove if target is destroyed
	if is_homing and target and not is_instance_valid(target):
		despawn()

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
	
	# Initial direction towards target
	if target:
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle()
	
	call_deferred("update_visual")

func setup_effect(pos: Vector2, color: Color, type: String, duration: float):
	global_position = pos
	effect_color = color
	projectile_type = type
	lifetime = duration
	speed = 0.0  # Stationary effect
	
	call_deferred("update_visual")

func setup_aoe_effect(pos: Vector2, radius: float, color: Color, type: String):
	global_position = pos
	effect_color = color
	projectile_type = type
	effect_radius = radius
	speed = 0.0  # Stationary effect
	lifetime = 1.0  # Short visual effect
	
	call_deferred("update_visual")

func setup_lightning_arc(from_pos: Vector2, to_pos: Vector2, color: Color):
	global_position = from_pos
	effect_color = color
	projectile_type = "lightning"
	speed = 0.0
	lifetime = 0.3
	
	# Store end position for drawing
	set_meta("end_pos", to_pos)
	
	call_deferred("update_visual")

func update_visual():
	# Update sprite/visual based on projectile type and color
	var sprite = get_node_or_null("Sprite2D")
	if not sprite:
		print("⚠️  Warning: Sprite2D node not found in SpellProjectile")
		return
	
	# Set the color modulation
	sprite.modulate = effect_color
	
	# Scale based on type
	match projectile_type:
		"mana_bolt":
			sprite.scale = Vector2(0.6, 0.6)
		"bolt":
			sprite.scale = Vector2(0.8, 0.8)
		"heal", "shield":
			sprite.scale = Vector2(1.2, 1.2)
			# Pulsing effect for heal/shield
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.5)
			tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.5)
		"ice", "meteor":
			if effect_radius > 0:
				# Scale based on actual effect radius - assuming base sprite represents ~100 pixel radius
				var radius_scale = effect_radius / 100.0
				sprite.scale = Vector2(radius_scale, radius_scale)
				
				# Make AoE effects render behind player with reduced opacity
				z_index = -10  # Behind player and enemies
				sprite.modulate.a = 0.6  # 60% opacity for better visibility
		"warning":
			# Pulsing warning indicator for meteor strikes
			sprite.scale = Vector2(2.0, 2.0)
			z_index = -5  # Behind player but in front of AoE effects
			sprite.modulate.a = 0.8  # Slightly more visible than AoE effects
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(sprite, "scale", Vector2(2.5, 2.5), 0.2)
			tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.2)
		"lightning":
			# Special handling for lightning arc - could draw a line
			sprite.visible = false

func _on_area_entered(area):
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
				enemy.take_damage(damage)
				
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
				if projectile_type != "lightning_arc":
					despawn()

# Custom drawing for special effects like lightning
func _draw():
	if projectile_type == "lightning":
		var end_pos = get_meta("end_pos", global_position)
		var local_end = to_local(end_pos)
		
		# Draw lightning bolt effect
		draw_line(Vector2.ZERO, local_end, effect_color, 3.0)
		
		# Add some jagged lines for lightning effect
		var segments = 5
		var prev_point = Vector2.ZERO
		for i in range(1, segments):
			var t = float(i) / segments
			var base_point = Vector2.ZERO.lerp(local_end, t)
			var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
			var jagged_point = base_point + offset
			
			draw_line(prev_point, jagged_point, effect_color, 2.0)
			prev_point = jagged_point
		
		# Final segment to end
		draw_line(prev_point, local_end, effect_color, 2.0)

# Object pooling methods
func setup_for_pool():
	# Called when object is first created for pooling
	is_pooled = true

func reset_for_pool():
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
	lifetime = 5.0
	lifetime_timer = lifetime
	homing_strength = 5.0
	
	# Reset visual properties
	global_position = Vector2.ZERO
	rotation = 0.0
	visible = true
	
	# Reset sprite if it exists
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2.ONE
		sprite.visible = true

func despawn():
	# Remove projectile from scene (return to pool or queue_free)
	if is_pooled:
		pool_return_requested.emit()
	else:
		queue_free()

func _on_lifetime_timer_timeout():
	# Called by the LifetimeTimer node in the scene
	despawn()
