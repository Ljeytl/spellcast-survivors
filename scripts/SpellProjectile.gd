# Spell projectile that can be fired in straight lines or home toward enemies
# Supports multiple spell types with different visuals and behaviors
extends Area2D

var healing_owner: WeakRef
var heal_on_hit = 0.0

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
	print("🎯 SpellProjectile setup_aoe_effect: type=", type, " radius=", radius, " pos=", pos)
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
	print("🎨 update_visual called: type=", projectile_type, " color=", effect_color, " radius=", effect_radius)
	
	# Stop any running animations that might interfere
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and projectile_type in ["ice", "meteor", "warning", "heal", "shield", "flash"]:
		anim_player.stop()
		print("🛑 Stopped AnimationPlayer for effect type: ", projectile_type)
	
	var sprite = get_node_or_null("ProjectileSprite")
	if not sprite:
		print("❌ ProjectileSprite node not found in SpellProjectile")
		return
	print("✅ Found ProjectileSprite node")
	
	# Set the color modulation
	sprite.modulate = effect_color
	print("🎨 Set sprite color to ", effect_color)
	
	# Scale based on type
	match projectile_type:
		"mana_bolt":
			# Enhanced mana bolt with energy trail
			sprite.scale = Vector2(0.8, 0.8)
			z_index = 10
			sprite.modulate = Color(0.4, 0.8, 1.0)  # Bright blue energy
			
			# Pulsing energy effect
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(sprite, "modulate", Color(0.8, 1.0, 1.0), 0.3)
			tween.tween_property(sprite, "modulate", Color(0.4, 0.8, 1.0), 0.3)
			
		"bolt", "life_bolt":
			# Enhanced bolt with crackling energy
			sprite.scale = Vector2(1.0, 1.0)
			z_index = 10
			sprite.modulate = effect_color * 1.2
			
			# Crackling animation
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.1)
			tween.tween_property(sprite, "scale", Vector2(0.9, 0.9), 0.1)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)
			tween.tween_property(sprite, "modulate", effect_color * 1.2, 0.15)
			
		"heal":
			# Radiant healing with golden glow
			sprite.scale = Vector2(2.0, 2.0)
			z_index = 15
			sprite.modulate = Color(1.0, 0.9, 0.3, 0.8)  # Golden glow
			
			# Gentle radial pulsing with sparkle effect
			var tween = create_tween()
			tween.set_parallel(true)
			tween.set_loops()
			
			# Scale pulsing
			tween.tween_property(sprite, "scale", Vector2(2.4, 2.4), 1.0)
			tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 1.0)
			
			# Color intensity pulsing
			tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 0.6, 0.9), 0.5)
			tween.tween_property(sprite, "modulate", Color(1.0, 0.9, 0.3, 0.7), 0.5)
			
		"shield":
			# Protective energy barrier with hexagonal shimmer
			sprite.scale = Vector2(2.5, 2.5)
			z_index = 20
			sprite.modulate = Color(0.3, 0.6, 1.0, 0.7)  # Blue energy shield
			
			# Barrier fluctuation animation
			var tween = create_tween()
			tween.set_parallel(true)
			tween.set_loops()
			
			# Defensive pulsing
			tween.tween_property(sprite, "scale", Vector2(2.8, 2.8), 0.4)
			tween.tween_property(sprite, "scale", Vector2(2.2, 2.2), 0.6)
			
			# Shield energy fluctuation
			tween.tween_property(sprite, "modulate", Color(0.5, 0.8, 1.0, 0.8), 0.3)
			tween.tween_property(sprite, "modulate", Color(0.3, 0.6, 1.0, 0.6), 0.7)
		"ice", "meteor":
			print("🧊 Processing ice/meteor visual with radius ", effect_radius)
			if effect_radius > 0:
				sprite.visible = false  # Hide the projectile sprite
				z_index = 50  # Very high to ensure visibility
				
				# Store enhanced circle info for custom drawing
				set_meta("circle_radius", effect_radius)
				set_meta("circle_color", effect_color)
				set_meta("effect_type", projectile_type)
				set_meta("animation_time", 0.0)
				
				print("🔄 Created enhanced circle with radius ", effect_radius)
				print("✨ Set z_index=", z_index)
				
				# Fast 2-phase animation
				var tween = create_tween()
				tween.set_parallel(true)
				
				# Phase 1: Explosive expansion (0.15s)
				tween.tween_method(
					func(progress): 
						set_meta("animation_time", progress * 0.15)
						queue_redraw(),
					0.0, 1.0, 0.15
				)
				
				# Phase 2: Quick fade out (0.25s)
				tween.tween_method(
					func(progress): 
						set_meta("animation_time", 0.15 + (progress * 0.25))
						modulate.a = 1.0 - progress
						queue_redraw(),
					0.0, 1.0, 0.25
				).set_delay(0.15)
				
				print("🎬 Started enhanced 3-phase animation")
			else:
				print("❌ effect_radius is 0 or negative: ", effect_radius)
		"warning":
			# Warning indicator for incoming attacks - scale to show actual radius
			if effect_radius > 0:
				var radius_scale = effect_radius / 100.0
				sprite.scale = Vector2(radius_scale, radius_scale)
			else:
				sprite.scale = Vector2(2.0, 2.0)  # Default size
			
			z_index = -5  # Behind player but visible
			sprite.modulate.a = 0.5  # Semi-transparent
			
			# Pulsing warning animation
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(sprite, "modulate:a", 0.8, 0.3)
			tween.tween_property(sprite, "modulate:a", 0.3, 0.3)
		"lightning":
			# Epic purple lightning arc with multiple bolts
			sprite.visible = false
			z_index = 25  # Above almost everything
			
			# Store enhanced lightning data
			set_meta("lightning_intensity", 1.5)
			set_meta("branch_count", 1 + randi() % 2)  # 1-2 bolts only
			set_meta("flicker_time", 0.0)
			
			# Lightning flicker animation
			var tween = create_tween()
			tween.set_loops()
			tween.tween_method(
				func(flicker):
					set_meta("flicker_time", flicker)
					queue_redraw(),
				0.0, 1.0, 0.05
			)
		"flash":
			# Explosive flash effect with impact burst
			sprite.scale = Vector2(0.5, 0.5)
			z_index = 30  # Above almost everything
			sprite.modulate = Color.WHITE * 1.5  # Bright flash
			
			# Multi-stage flash animation
			var tween = create_tween()
			tween.set_parallel(true)
			
			# Explosive expansion
			tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.15)
			tween.tween_property(sprite, "modulate", Color(1.2, 1.2, 0.8, 0.8), 0.1)
			
			# Quick fade with color shift
			tween.tween_property(sprite, "modulate:a", 0.0, 0.25).set_delay(0.1)
			tween.tween_callback(func(): queue_free()).set_delay(0.35)

func _on_area_entered(area):
	if despawning:
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
				var health_before = enemy.current_health
				enemy.take_damage(damage, global_position)
				var dealt = maxf(0.0, health_before - enemy.current_health)
				if heal_on_hit > 0.0 and dealt > 0.0 and healing_owner:
					var owner_player = healing_owner.get_ref()
					if is_instance_valid(owner_player) and owner_player.health > 0:
						owner_player.heal(minf(heal_on_hit, dealt))
				
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

# Custom drawing for special effects like lightning and area effects
func _draw():
	if projectile_type == "lightning":
		var end_pos = get_meta("end_pos", global_position)
		var local_end = to_local(end_pos)
		var intensity = get_meta("lightning_intensity", 1.0)
		var branch_count = get_meta("branch_count", 1)
		var flicker = get_meta("flicker_time", 0.0)
		
		# Epic purple lightning colors
		var primary_color = Color.MAGENTA * (1.2 + sin(flicker * 20.0) * 0.3)
		var secondary_color = Color(0.8, 0.4, 1.0) * intensity
		var core_color = Color.WHITE * (0.8 + sin(flicker * 15.0) * 0.2)
		
		# Draw multiple lightning branches
		for branch in range(branch_count):
			var branch_offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
			var branch_end = local_end + branch_offset
			
			# Main lightning bolt segments
			var segments = 8 + randi() % 4
			var points = [Vector2.ZERO]
			
			# Generate jagged lightning path
			for i in range(1, segments):
				var t = float(i) / segments
				var base_point = Vector2.ZERO.lerp(branch_end, t)
				var chaos = 40.0 * (1.0 - abs(t - 0.5) * 2.0)  # More chaos in middle
				var offset = Vector2(
					randf_range(-chaos, chaos),
					randf_range(-chaos, chaos)
				)
				points.append(base_point + offset)
			
			points.append(branch_end)
			
			# Draw lightning with multiple layers for glow effect
			for layer in range(3):
				var layer_width = [8.0, 4.0, 2.0][layer]
				var layer_color = [secondary_color, primary_color, core_color][layer]
				var layer_alpha = [0.4, 0.7, 1.0][layer] * modulate.a
				
				layer_color.a = layer_alpha
				
				# Draw segments
				for i in range(points.size() - 1):
					draw_line(points[i], points[i + 1], layer_color, layer_width)
			
			# Add crackling sparks
			if branch == 0:  # Only on main branch
				for spark in range(6):
					var spark_t = randf()
					var spark_pos = Vector2.ZERO.lerp(branch_end, spark_t)
					var spark_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
					var spark_end = spark_pos + spark_offset
					
					draw_line(spark_pos, spark_end, core_color * 0.6, 1.5)
		
		# Add electric aura around start and end points
		var aura_radius = 8.0 + sin(flicker * 12.0) * 3.0
		draw_circle(Vector2.ZERO, aura_radius, Color(primary_color.r, primary_color.g, primary_color.b, 0.3))
		draw_circle(local_end, aura_radius * 0.7, Color(primary_color.r, primary_color.g, primary_color.b, 0.2))
	
	elif projectile_type in ["ice", "meteor"]:
		var base_radius = get_meta("circle_radius", 0.0)
		var base_color = get_meta("circle_color", Color.WHITE)
		var effect_type = get_meta("effect_type", "ice")
		var anim_time = get_meta("animation_time", 0.0)
		
		if base_radius > 0:
			print("🎨 Drawing enhanced effect: radius=", base_radius, " time=", anim_time)
			
			# Fast 2-phase animation
			var expansion_factor = 1.0
			var pulse_intensity = 1.0
			var outer_rings = 2
			
			if anim_time <= 0.15:  # Phase 1: Explosive expansion
				var phase_progress = anim_time / 0.15
				var eased_progress = 1.0 - pow(1.0 - phase_progress, 3.0)  # Cubic ease-out
				expansion_factor = lerp(0.2, 1.1, eased_progress)
				pulse_intensity = 1.8 - (phase_progress * 0.4)
				outer_rings = 3
			else:  # Phase 2: Quick fade
				var phase_progress = (anim_time - 0.15) / 0.25
				expansion_factor = lerp(1.1, 1.2, phase_progress)
				pulse_intensity = lerp(1.4, 0.6, phase_progress)
				outer_rings = 2
			
			var current_radius = base_radius * expansion_factor
			
			# Color variations based on effect type
			var primary_color = base_color
			var secondary_color = base_color
			
			if effect_type == "ice":
				primary_color = Color.CYAN * pulse_intensity
				secondary_color = Color(0.4, 0.8, 1.0) * pulse_intensity
			else:  # meteor
				primary_color = Color.ORANGE_RED * pulse_intensity
				secondary_color = Color.YELLOW * pulse_intensity
			
			# Draw multiple concentric circles for depth
			for i in range(outer_rings):
				var ring_radius = current_radius * (1.0 - (i * 0.3))
				var ring_alpha = (1.0 - (i * 0.4)) * modulate.a
				
				# Filled circle with gradient effect
				var fill_alpha = ring_alpha * 0.25
				draw_circle(Vector2.ZERO, ring_radius, Color(primary_color.r, primary_color.g, primary_color.b, fill_alpha))
				
				# Outer ring with stronger color
				var ring_width = 4.0 + (i * 2.0)
				draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 128, Color(secondary_color.r, secondary_color.g, secondary_color.b, ring_alpha), ring_width)
			
			# Add sparkling edge effect (only during expansion)
			if anim_time <= 0.15:
				var sparkle_count = 8
				for j in range(sparkle_count):
					var angle = (TAU / sparkle_count) * j + (anim_time * 6.0)  # Fast rotating sparkles
					var sparkle_pos = Vector2(cos(angle), sin(angle)) * current_radius
					var sparkle_size = 2.0 + sin(anim_time * 12.0 + j) * 1.5
					draw_circle(sparkle_pos, sparkle_size, Color.WHITE * modulate.a * 0.9)
			
			# Center burst effect during expansion
			if anim_time <= 0.15:
				var burst_radius = current_radius * 0.12 * (anim_time / 0.15)
				draw_circle(Vector2.ZERO, burst_radius, Color.WHITE * modulate.a)

# Object pooling methods
func setup_for_pool():
	# Called when object is first created for pooling
	is_pooled = true

func reset_for_pool():
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
	lifetime = 5.0
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
	# Remove projectile from scene (return to pool or queue_free)
	if is_pooled:
		pool_return_requested.emit()
	else:
		queue_free()

func _on_lifetime_timer_timeout():
	# Called by the LifetimeTimer node in the scene
	despawn()
