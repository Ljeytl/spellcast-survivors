extends Node2D
class_name ParticleManager

# Create built-in particle effects using GPUParticles2D

# Object pooling for particles
var particle_pool: Dictionary = {}
var max_pool_size: int = 50

func _ready():
	# Initialize particle pools
	create_pools()

func create_pools():
	# Initialize object pools for different particle types
	particle_pool["spell_cast"] = []
	particle_pool["enemy_death"] = []
	particle_pool["xp_collect"] = []
	particle_pool["spell_impact"] = []
	particle_pool["heal"] = []
	
	# Spell-specific particle pools
	particle_pool["mana_bolt"] = []
	particle_pool["bolt"] = []
	particle_pool["life"] = []
	particle_pool["ice_blast"] = []
	particle_pool["earthshield"] = []
	particle_pool["lightning_arc"] = []
	particle_pool["meteor_shower"] = []

func get_pooled_particle(type: String) -> GPUParticles2D:
	# Get a particle from the pool or create a new one
	if not particle_pool.has(type):
		return null
	
	var pool = particle_pool[type]
	for particle in pool:
		if not particle.emitting:
			return particle
	
	# If no available particle in pool, create a new one
	if pool.size() < max_pool_size:
		var new_particle = create_particle_by_type(type)
		if new_particle:
			pool.append(new_particle)
			add_child(new_particle)
			return new_particle
	
	return null

func create_particle_by_type(type: String) -> GPUParticles2D:
	# Create a specific type of particle effect
	var particle = GPUParticles2D.new()
	
	match type:
		"spell_cast":
			setup_spell_cast_particle(particle)
		"enemy_death":
			setup_enemy_death_particle(particle)
		"xp_collect":
			setup_xp_collect_particle(particle)
		"spell_impact":
			setup_spell_impact_particle(particle)
		"heal":
			setup_heal_particle(particle)
		# Spell-specific particles
		"mana_bolt":
			setup_mana_bolt_particle(particle)
		"bolt":
			setup_bolt_particle(particle)
		"life":
			setup_life_particle(particle)
		"ice_blast":
			setup_ice_blast_particle(particle)
		"earthshield":
			setup_earthshield_particle(particle)
		"lightning_arc":
			setup_lightning_arc_particle(particle)
		"meteor_shower":
			setup_meteor_shower_particle(particle)
	
	return particle

func setup_spell_cast_particle(particle: GPUParticles2D):
	# Setup spell casting particle effect
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.initial_velocity_min = 50.0
	particle_material.initial_velocity_max = 100.0
	particle_material.angular_velocity_min = -180.0
	particle_material.angular_velocity_max = 180.0
	particle_material.orbit_velocity_min = -0.5
	particle_material.orbit_velocity_max = 0.5
	particle_material.gravity = Vector3(0, -98, 0)
	particle_material.scale_min = 0.5
	particle_material.scale_max = 1.0
	particle_material.color = Color.CYAN
	
	particle.process_material = particle_material
	particle.texture = preload("res://sprites/effects/magic_bolt_1.png")
	particle.amount = 8  # Reduced from 20
	particle.lifetime = 0.5  # Reduced from 1.0
	particle.emitting = false

func setup_enemy_death_particle(particle: GPUParticles2D):
	# Setup enemy death explosion particle effect
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 45.0
	particle_material.initial_velocity_min = 100.0
	particle_material.initial_velocity_max = 200.0
	particle_material.angular_velocity_min = -360.0
	particle_material.angular_velocity_max = 360.0
	particle_material.gravity = Vector3(0, 98, 0)
	particle_material.scale_min = 0.8
	particle_material.scale_max = 1.5
	particle_material.color = Color.RED
	
	particle.process_material = particle_material
	particle.texture = preload("res://sprites/effects/magic_bolt_1.png")
	particle.amount = 12  # Reduced from 30
	particle.lifetime = 0.6  # Reduced from 0.8
	particle.emitting = false

func setup_xp_collect_particle(particle: GPUParticles2D):
	# Setup XP orb collection sparkle effect
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 30.0
	particle_material.initial_velocity_min = 30.0
	particle_material.initial_velocity_max = 80.0
	particle_material.angular_velocity_min = -90.0
	particle_material.angular_velocity_max = 90.0
	particle_material.gravity = Vector3(0, -50, 0)
	particle_material.scale_min = 0.3
	particle_material.scale_max = 0.8
	particle_material.color = Color.GOLD
	
	particle.process_material = particle_material
	particle.texture = preload("res://sprites/effects/magic_bolt_1.png")
	particle.amount = 6  # Reduced from 15
	particle.lifetime = 0.4  # Reduced from 0.6
	particle.emitting = false

func setup_spell_impact_particle(particle: GPUParticles2D):
	# Setup spell impact particle effect
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 60.0
	particle_material.initial_velocity_min = 80.0
	particle_material.initial_velocity_max = 150.0
	particle_material.angular_velocity_min = -180.0
	particle_material.angular_velocity_max = 180.0
	particle_material.gravity = Vector3(0, 100, 0)
	particle_material.scale_min = 0.4
	particle_material.scale_max = 1.2
	particle_material.color = Color.ORANGE
	
	particle.process_material = particle_material
	particle.texture = preload("res://sprites/effects/magic_bolt_1.png")
	particle.amount = 10  # Reduced from 25
	particle.lifetime = 0.4  # Reduced from 0.7
	particle.emitting = false

func setup_heal_particle(particle: GPUParticles2D):
	# Setup healing particle effect
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 20.0
	particle_material.initial_velocity_min = 20.0
	particle_material.initial_velocity_max = 60.0
	particle_material.angular_velocity_min = -45.0
	particle_material.angular_velocity_max = 45.0
	particle_material.gravity = Vector3(0, -80, 0)
	particle_material.scale_min = 0.6
	particle_material.scale_max = 1.0
	particle_material.color = Color.GREEN
	
	particle.process_material = particle_material
	particle.texture = preload("res://sprites/effects/magic_bolt_1.png")
	particle.amount = 5  # Reduced from 12
	particle.lifetime = 0.8  # Reduced from 1.2
	particle.emitting = false

func auto_cleanup_particle(particle: GPUParticles2D, delay: float):
	# Automatically stop particle emission after delay
	await get_tree().create_timer(delay).timeout
	if particle and is_instance_valid(particle):
		particle.emitting = false

# Public methods to create particles
func create_spell_cast_effect(pos: Vector2):
	# Create spell casting particle effect at position
	var particle = get_pooled_particle("spell_cast")
	if particle:
		particle.global_position = pos
		particle.restart()
		# Auto-cleanup after lifetime + buffer
		auto_cleanup_particle(particle, 1.0)

func create_enemy_death_effect(pos: Vector2):
	# Create enemy death explosion effect at position
	var particle = get_pooled_particle("enemy_death")
	if particle:
		particle.global_position = pos
		particle.restart()
		# Auto-cleanup after lifetime + buffer
		auto_cleanup_particle(particle, 1.2)

func create_xp_collect_effect(pos: Vector2):
	# Create XP collection sparkle effect at position
	var particle = get_pooled_particle("xp_collect")
	if particle:
		particle.global_position = pos
		particle.restart()
		# Auto-cleanup after lifetime + buffer
		auto_cleanup_particle(particle, 0.8)

func create_spell_impact_effect(pos: Vector2):
	# Create spell impact effect at position
	var particle = get_pooled_particle("spell_impact")
	if particle:
		particle.global_position = pos
		particle.restart()
		# Auto-cleanup after lifetime + buffer
		auto_cleanup_particle(particle, 0.8)

func create_heal_effect(pos: Vector2):
	# Create healing effect at position
	var particle = get_pooled_particle("heal")
	if particle:
		particle.global_position = pos
		particle.restart()
		# Auto-cleanup after lifetime + buffer
		auto_cleanup_particle(particle, 1.2)

# Spell-specific particle setup functions
func setup_mana_bolt_particle(particle: GPUParticles2D):
	# Small cyan homing projectiles with subtle trail
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 15.0
	particle_material.initial_velocity_min = 30.0
	particle_material.initial_velocity_max = 60.0
	particle_material.angular_velocity_min = -90.0
	particle_material.angular_velocity_max = 90.0
	particle_material.gravity = Vector3(0, 0, 0)  # No gravity for homing effect
	particle_material.scale_min = 0.3
	particle_material.scale_max = 0.6
	particle_material.color = Color.CYAN
	
	particle.process_material = particle_material
	particle.texture = preload("res://sprites/effects/magic_bolt_1.png")
	particle.amount = 5  # Small subtle trail
	particle.lifetime = 0.3
	particle.emitting = false

func setup_bolt_particle(particle: GPUParticles2D):
	# Fast yellow projectiles with electric sparks
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 25.0
	particle_material.initial_velocity_min = 80.0
	particle_material.initial_velocity_max = 120.0
	particle_material.angular_velocity_min = -180.0
	particle_material.angular_velocity_max = 180.0
	particle_material.gravity = Vector3(0, 20, 0)
	particle_material.scale_min = 0.4
	particle_material.scale_max = 0.8
	particle_material.color = Color.YELLOW
	
	particle.process_material = particle_material
	particle.texture = preload("res://sprites/effects/magic_bolt_1.png")
	particle.amount = 8  # Electric sparks
	particle.lifetime = 0.4
	particle.emitting = false

func setup_life_particle(particle: GPUParticles2D):
	# Green healing particles that pulse around the player
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 360.0  # Full circle around player
	particle_material.initial_velocity_min = 20.0
	particle_material.initial_velocity_max = 40.0
	particle_material.angular_velocity_min = -45.0
	particle_material.angular_velocity_max = 45.0
	particle_material.gravity = Vector3(0, -30, 0)  # Float upward
	particle_material.scale_min = 0.5
	particle_material.scale_max = 1.0
	particle_material.color = Color.LIME_GREEN
	
	particle.process_material = particle_material
	particle.texture = preload("res://sprites/effects/magic_bolt_1.png")
	particle.amount = 10  # Pulsing effect
	particle.lifetime = 0.8
	particle.emitting = false

func setup_ice_blast_particle(particle: GPUParticles2D):
	# Blue frost explosion with ice crystals
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 60.0
	particle_material.initial_velocity_min = 100.0
	particle_material.initial_velocity_max = 180.0
	particle_material.angular_velocity_min = -120.0
	particle_material.angular_velocity_max = 120.0
	particle_material.gravity = Vector3(0, 80, 0)
	particle_material.scale_min = 1.0  # Increased from 0.6
	particle_material.scale_max = 2.0  # Increased from 1.2
	particle_material.color = Color.CYAN  # Changed to more visible cyan
	
	particle.process_material = particle_material
	particle.texture = preload("res://sprites/effects/magic_bolt_1.png")
	particle.amount = 20  # Increased from 12 for more visibility
	particle.lifetime = 1.0  # Increased from 0.6 for longer duration
	particle.emitting = false

func setup_earthshield_particle(particle: GPUParticles2D):
	# Brown/orange shield particles around player
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 0, 0)
	particle_material.spread = 360.0  # Full circle shield
	particle_material.initial_velocity_min = 5.0
	particle_material.initial_velocity_max = 15.0
	particle_material.angular_velocity_min = -30.0
	particle_material.angular_velocity_max = 30.0
	particle_material.gravity = Vector3(0, 0, 0)  # Orbiting effect
	particle_material.orbit_velocity_min = 0.2
	particle_material.orbit_velocity_max = 0.5
	particle_material.scale_min = 0.7
	particle_material.scale_max = 1.0
	particle_material.color = Color.SANDY_BROWN
	
	particle.process_material = particle_material
	particle.texture = preload("res://sprites/effects/magic_bolt_1.png")
	particle.amount = 15  # Shield barrier effect
	particle.lifetime = 0.8
	particle.emitting = false

func setup_lightning_arc_particle(particle: GPUParticles2D):
	# Purple chain lightning with electric effects
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 30.0
	particle_material.initial_velocity_min = 150.0
	particle_material.initial_velocity_max = 250.0
	particle_material.angular_velocity_min = -360.0
	particle_material.angular_velocity_max = 360.0
	particle_material.gravity = Vector3(0, 0, 0)  # Electric energy
	particle_material.scale_min = 0.3
	particle_material.scale_max = 0.7
	particle_material.color = Color.PURPLE
	
	particle.process_material = particle_material
	particle.texture = preload("res://sprites/effects/magic_bolt_1.png")
	particle.amount = 10  # Electric arc effect
	particle.lifetime = 0.5
	particle.emitting = false

func setup_meteor_shower_particle(particle: GPUParticles2D):
	# Red explosion particles with fire effects
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 45.0
	particle_material.initial_velocity_min = 120.0
	particle_material.initial_velocity_max = 200.0
	particle_material.angular_velocity_min = -180.0
	particle_material.angular_velocity_max = 180.0
	particle_material.gravity = Vector3(0, 100, 0)
	particle_material.scale_min = 0.8
	particle_material.scale_max = 1.5
	particle_material.color = Color.ORANGE_RED
	
	particle.process_material = particle_material
	particle.texture = preload("res://sprites/effects/magic_bolt_1.png")
	particle.amount = 15  # Explosive fire effect
	particle.lifetime = 0.7
	particle.emitting = false

# Spell-specific particle creation methods
func create_mana_bolt_effect(pos: Vector2):
	var particle = get_pooled_particle("mana_bolt")
	if particle:
		particle.global_position = pos
		particle.restart()
		auto_cleanup_particle(particle, 0.6)

func create_bolt_effect(pos: Vector2):
	var particle = get_pooled_particle("bolt")
	if particle:
		particle.global_position = pos
		particle.restart()
		auto_cleanup_particle(particle, 0.8)

func create_life_effect(pos: Vector2):
	var particle = get_pooled_particle("life")
	if particle:
		particle.global_position = pos
		particle.restart()
		auto_cleanup_particle(particle, 1.2)

func create_ice_blast_effect(pos: Vector2):
	# Create particle effect
	var particle = get_pooled_particle("ice_blast")
	if particle:
		particle.global_position = pos
		particle.z_index = 50  # Ensure it renders above other elements
		particle.emitting = true  # Explicitly enable emitting
		particle.restart()
		auto_cleanup_particle(particle, 1.5)  # Increased to match longer lifetime
	
	# Create multiple expanding circle effects for ice blast
	create_expanding_circle(pos, 400.0, Color.CYAN, 0.8, true)
	# Add a faster, smaller inner circle
	create_expanding_circle(pos, 300.0, Color.LIGHT_BLUE, 0.6, true)
	# Add a slow outer circle for lingering effect
	create_expanding_circle(pos, 450.0, Color.WHITE, 1.2, true)

func create_earthshield_effect(pos: Vector2):
	var particle = get_pooled_particle("earthshield")
	if particle:
		particle.global_position = pos
		particle.restart()
		auto_cleanup_particle(particle, 1.2)

func create_lightning_arc_effect(pos: Vector2):
	var particle = get_pooled_particle("lightning_arc")
	if particle:
		particle.global_position = pos
		particle.restart()
		auto_cleanup_particle(particle, 1.0)

func create_meteor_shower_effect(pos: Vector2):
	var particle = get_pooled_particle("meteor_shower")
	if particle:
		particle.global_position = pos
		particle.restart()
		auto_cleanup_particle(particle, 1.2)
	
	# Create expanding circle effects for meteor impact
	create_expanding_circle(pos, 180.0, Color.ORANGE_RED, 0.6, true)
	# Add inner fire circle
	create_expanding_circle(pos, 120.0, Color.RED, 0.4, true)
	# Add outer blast wave
	create_expanding_circle(pos, 220.0, Color.YELLOW, 0.8, true)

# Create persistent spell circles that follow the player
func create_persistent_life_circle(target: Node2D, duration: float):
	var circle = PersistentSpellCircle.new()
	circle.setup_persistent_circle(target, 90.0, Color.LIME_GREEN, duration, 1.5)  # Slow, soothing pulse
	add_child(circle)

func create_persistent_shield_circle(target: Node2D, duration: float):
	var circle = PersistentSpellCircle.new()
	circle.setup_persistent_circle(target, 110.0, Color.SANDY_BROWN, duration, 0.8)  # Slower, protective pulse
	add_child(circle)

# Create persistent lightning arc that originates from player
func create_persistent_lightning_arc(from_target: Node2D, to_pos: Vector2, duration: float = 1.0, to_target: Node2D = null):
	var lightning = PersistentLightningArc.new()
	lightning.setup_lightning_arc(from_target, to_pos, Color.PURPLE, duration, to_target)
	add_child(lightning)

# Visual circle effects for AOE spells
func create_expanding_circle(pos: Vector2, max_radius: float, color: Color, duration: float, fade_out: bool = true):
	# Create a custom drawn circle effect
	var circle_effect = ExpandingCircle.new()
	circle_effect.global_position = pos
	circle_effect.z_index = 60  # Above particles
	circle_effect.setup(max_radius, color, duration, fade_out)
	add_child(circle_effect)

# Custom class for drawing expanding circles
class ExpandingCircle extends Node2D:
	var current_radius: float = 0.0
	var max_radius: float = 100.0
	var circle_color: Color = Color.WHITE
	var alpha: float = 1.0
	var tween: Tween
	
	func setup(radius: float, color: Color, duration: float, fade: bool):
		max_radius = radius
		circle_color = color
		
		# Create tween for animation
		tween = create_tween()
		tween.set_parallel(true)
		
		# Animate radius expansion
		tween.tween_method(
			func(r): 
				current_radius = r
				queue_redraw(),
			0.0, max_radius, duration * 0.5
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
		# Animate fade out if requested
		if fade:
			tween.tween_method(
				func(a): 
					alpha = a
					queue_redraw(),
				1.0, 0.0, duration * 0.7
			).set_delay(duration * 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		
		# Clean up after animation
		tween.finished.connect(queue_free)
	
	func _draw():
		if current_radius > 0:
			var draw_color = circle_color
			draw_color.a = alpha * 0.2  # Semi-transparent filled circle
			
			# Draw filled circle background
			draw_circle(Vector2.ZERO, current_radius, draw_color)
			
			# Draw bright outline
			var outline_color = circle_color
			outline_color.a = alpha
			draw_arc(Vector2.ZERO, current_radius, 0, TAU, 64, outline_color, 6.0)
			
			# Draw inner ring for more visibility
			if current_radius > 30:
				var inner_color = outline_color
				inner_color.a *= 0.6
				draw_arc(Vector2.ZERO, current_radius - 15, 0, TAU, 32, inner_color, 3.0)

# Custom class for persistent spell circles that follow the player
class PersistentSpellCircle extends Node2D:
	var target_node: Node2D = null  # Player or other target to follow
	var base_radius: float = 80.0
	var current_radius: float = 80.0
	var circle_color: Color = Color.WHITE
	var alpha: float = 1.0
	var pulse_tween: Tween
	var fade_tween: Tween
	var remaining_duration: float = 5.0
	var pulse_speed: float = 2.0
	var is_active: bool = true
	
	func setup_persistent_circle(follow_target: Node2D, radius: float, color: Color, duration: float, pulse_rate: float = 2.0):
		target_node = follow_target
		base_radius = radius
		current_radius = radius
		circle_color = color
		remaining_duration = duration
		pulse_speed = pulse_rate
		
		z_index = 40  # Below expanding circles but above most other elements
		
		# Start pulsing animation
		start_pulsing()
		
		# Start duration countdown - defer until node is in scene tree
		call_deferred("setup_timer", duration)
	
	func start_pulsing():
		if pulse_tween:
			pulse_tween.kill()
		
		pulse_tween = create_tween()
		pulse_tween.set_loops()  # Loop indefinitely
		
		# Pulse radius between 0.8 and 1.3 of base size
		pulse_tween.tween_method(
			func(scale_factor): 
				current_radius = base_radius * scale_factor
				queue_redraw(),
			0.8, 1.3, 1.0 / pulse_speed
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
		pulse_tween.tween_method(
			func(scale_factor): 
				current_radius = base_radius * scale_factor
				queue_redraw(),
			1.3, 0.8, 1.0 / pulse_speed
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	func fade_and_destroy():
		is_active = false
		if pulse_tween:
			pulse_tween.kill()
		
		fade_tween = create_tween()
		fade_tween.tween_method(
			func(a): 
				alpha = a
				queue_redraw(),
			1.0, 0.0, 0.5
		).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		
		fade_tween.finished.connect(queue_free)
	
	func setup_timer(duration: float):
		var tree = get_tree()
		if tree:
			var duration_timer = tree.create_timer(duration)
			duration_timer.timeout.connect(fade_and_destroy)
		else:
			# Fallback: destroy after a fixed time using a different approach
			var fallback_timer = Timer.new()
			fallback_timer.wait_time = duration
			fallback_timer.one_shot = true
			fallback_timer.timeout.connect(fade_and_destroy)
			add_child(fallback_timer)
			fallback_timer.start()
	
	func _process(_delta):
		# Follow the target
		if target_node and is_instance_valid(target_node) and is_active:
			global_position = target_node.global_position
	
	func _draw():
		if current_radius > 0 and is_active:
			var draw_color = circle_color
			draw_color.a = alpha * 0.15  # Very subtle filled circle
			
			# Draw filled circle background
			draw_circle(Vector2.ZERO, current_radius, draw_color)
			
			# Draw main outline
			var outline_color = circle_color
			outline_color.a = alpha * 0.8
			draw_arc(Vector2.ZERO, current_radius, 0, TAU, 64, outline_color, 3.0)
			
			# Draw inner pulsing ring
			var inner_color = outline_color
			inner_color.a = alpha * 0.4
			var inner_radius = current_radius * 0.7
			draw_arc(Vector2.ZERO, inner_radius, 0, TAU, 32, inner_color, 2.0)

# Custom class for persistent lightning arcs that follow the caster
class PersistentLightningArc extends Node2D:
	var from_target: Node2D = null  # Usually the player
	var to_position: Vector2 = Vector2.ZERO  # Target position (can be static)
	var to_target: Node2D = null  # Target node (can track moving enemies)
	var arc_color: Color = Color.PURPLE
	var alpha: float = 1.0
	var flicker_tween: Tween
	var fade_tween: Tween
	var remaining_duration: float = 1.0
	var max_duration: float = 1.0  # Track original duration
	var is_active: bool = true
	var lightning_segments: Array = []
	var segment_regenerate_timer: float = 0.0
	
	func setup_lightning_arc(from_node: Node2D, target_pos: Vector2, color: Color, duration: float, target_node: Node2D = null):
		# Safety checks
		if not from_node or not is_instance_valid(from_node):
			print("Warning: Invalid from_node in lightning arc setup")
			queue_free()
			return
		
		if duration <= 0.0:
			print("Warning: Invalid duration in lightning arc setup")
			queue_free()
			return
		
		# Validate positions to prevent top-left corner bugs
		var source_pos = from_node.global_position
		if source_pos.length() < 10.0:
			print("Warning: Source position too close to origin, using fallback")
			source_pos = Vector2(100, 100)  # Safe fallback position
		
		if target_pos.length() < 10.0:
			print("Warning: Target position too close to origin, using fallback")
			target_pos = source_pos + Vector2(200, 0)  # Offset from source
		
		from_target = from_node
		to_position = target_pos
		to_target = target_node
		arc_color = color
		remaining_duration = duration
		max_duration = duration
		
		# Position the lightning arc node at the midpoint for better coordinate handling
		var midpoint = (source_pos + target_pos) * 0.5
		global_position = midpoint
		
		z_index = 45  # Above circles but below expanding effects
		
		# Generate initial lightning segments
		regenerate_lightning_segments()
		
		# Start flickering animation for lightning effect (with a small delay)
		call_deferred("start_flickering")
		
		# Start duration countdown (deferred to ensure node is in scene tree)
		call_deferred("setup_timer", duration)
	
	func setup_timer(duration: float):
		var tree = get_tree()
		if tree:
			var duration_timer = tree.create_timer(duration)
			duration_timer.timeout.connect(fade_and_destroy)
		else:
			# Fallback: destroy after a fixed time using a different approach
			var fallback_timer = Timer.new()
			fallback_timer.wait_time = duration
			fallback_timer.one_shot = true
			fallback_timer.timeout.connect(fade_and_destroy)
			add_child(fallback_timer)
			fallback_timer.start()

	func start_flickering():
		if flicker_tween:
			flicker_tween.kill()
		
		flicker_tween = create_tween()
		flicker_tween.set_loops()  # Loop indefinitely
		
		# More stable flicker pattern with longer intervals
		flicker_tween.tween_method(
			func(a): 
				if is_active:  # Safety check
					alpha = a
					queue_redraw(),
			1.0, 0.6, 0.08
		).set_ease(Tween.EASE_IN_OUT)
		
		flicker_tween.tween_method(
			func(a): 
				if is_active:  # Safety check
					alpha = a
					queue_redraw(),
			0.6, 1.0, 0.08
		).set_ease(Tween.EASE_IN_OUT)
		
		# Reduce bright flash frequency for better performance
		flicker_tween.tween_callback(func(): 
			if is_active and randf() < 0.1:  # Reduced from 0.3 to 0.1
				flash_bright()
		).set_delay(0.15)
	
	func flash_bright():
		# Brief bright flash
		var flash_tween = create_tween()
		flash_tween.tween_method(
			func(a): 
				alpha = a
				queue_redraw(),
			alpha, 1.5, 0.02
		)
		flash_tween.tween_method(
			func(a): 
				alpha = a
				queue_redraw(),
			1.5, alpha, 0.08
		)
	
	func regenerate_lightning_segments():
		lightning_segments.clear()
		
		# Get current positions with safety checks and fallbacks
		var from_pos = to_position  # Default fallback to target position instead of ZERO
		var target_pos = to_position
		
		# Get source position with validation
		if from_target and is_instance_valid(from_target):
			from_pos = from_target.global_position
		else:
			# If from_target is invalid, try to get a reasonable fallback position
			# Use the lightning arc's global position as fallback (better than ZERO)
			from_pos = global_position
		
		# Get target position with validation
		if to_target and is_instance_valid(to_target):
			target_pos = to_target.global_position
		else:
			target_pos = to_position
		
		# Validate that we have reasonable positions (not at origin)
		if from_pos.length() < 10.0 and target_pos.length() < 10.0:
			# Both positions are near origin - this is likely an error state
			# Create a minimal safe lightning bolt
			lightning_segments.append(global_position + Vector2(-50, 0))
			lightning_segments.append(global_position + Vector2(50, 0))
			return
		
		# If one position is at origin, use the other as reference
		if from_pos.length() < 10.0:
			from_pos = target_pos + Vector2(-100, 0)  # Offset from target
		elif target_pos.length() < 10.0:
			target_pos = from_pos + Vector2(100, 0)  # Offset from source
		
		# Safety check for valid positions
		var direction = (target_pos - from_pos)
		var distance = direction.length()
		
		# Handle edge cases
		if distance < 5.0:
			# Very short distance - just draw a straight line
			lightning_segments.append(from_pos)
			lightning_segments.append(target_pos)
			return
		
		# Create fewer, more stable segments for better performance
		var segments = max(2, min(8, int(distance / 60.0)))  # Reduced segment count
		var normalized_dir = direction.normalized()
		
		lightning_segments.append(from_pos)
		
		# Create more stable lightning path with consistent offset pattern
		for i in range(1, segments):
			var t = float(i) / segments
			var base_point = from_pos.lerp(target_pos, t)
			
			# Use sine wave for more consistent jagged pattern
			var perp = normalized_dir.rotated(PI/2)
			var wave_offset = sin(t * PI * 4.0) * 20.0  # Sine wave pattern
			var random_offset = randf_range(-15.0, 15.0)  # Small random variation
			var total_offset = (wave_offset + random_offset) * (1.0 - abs(t - 0.5) * 1.5)  # Taper toward ends
			
			lightning_segments.append(base_point + perp * total_offset)
		
		lightning_segments.append(target_pos)
	
	func fade_and_destroy():
		is_active = false
		if flicker_tween:
			flicker_tween.kill()
		
		fade_tween = create_tween()
		fade_tween.tween_method(
			func(a): 
				alpha = a
				queue_redraw(),
			alpha, 0.0, 0.3
		).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		
		fade_tween.finished.connect(queue_free)
	
	func _process(delta):
		if not is_active:
			return
		
		# Manual countdown as backup mechanism
		remaining_duration -= delta
		if remaining_duration <= 0.0:
			fade_and_destroy()
			return
		
		# Regenerate lightning segments periodically for animated effect (slower for stability)
		segment_regenerate_timer -= delta
		if segment_regenerate_timer <= 0.0:
			regenerate_lightning_segments()
			segment_regenerate_timer = 0.15  # Regenerate every 150ms for more stable lightning
			queue_redraw()
	
	func _draw():
		if not is_active or lightning_segments.size() < 2:
			return
		
		var draw_color = arc_color
		draw_color.a = clamp(alpha, 0.0, 1.0)  # Ensure alpha is valid
		
		# Draw main lightning bolt - use global coordinates directly
		for i in range(lightning_segments.size() - 1):
			# Safety check for valid indices
			if i >= lightning_segments.size() - 1:
				break
			
			var from_pos = lightning_segments[i]
			var to_pos = lightning_segments[i + 1]
			
			# Safety check for valid positions
			if not (from_pos is Vector2) or not (to_pos is Vector2):
				continue
			
			# Use global coordinates directly to avoid transformation issues
			var from_local = from_pos - global_position
			var to_local = to_pos - global_position
			
			# Safety check for reasonable segment length
			if from_local.distance_to(to_local) > 1000.0:
				continue  # Skip extremely long segments
			
			# Draw main bolt with thicker line for better visibility
			draw_line(from_local, to_local, draw_color, 6.0)
			
			# Draw inner bright core
			var bright_color = Color.WHITE
			bright_color.a = clamp(alpha * 0.9, 0.0, 1.0)
			draw_line(from_local, to_local, bright_color, 3.0)
			
			# Draw secondary core with original color
			var core_color = arc_color
			core_color.a = clamp(alpha * 0.7, 0.0, 1.0)
			draw_line(from_local, to_local, core_color, 1.5)
			
			# Reduce secondary arcs frequency for better performance and cleaner look
			if randf() < 0.15 and i < lightning_segments.size() - 2:  # Only add for non-final segments
				var mid_point = (from_local + to_local) * 0.5
				var side_offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
				var dim_color = draw_color
				dim_color.a = clamp(alpha * 0.3, 0.0, 1.0)
				draw_line(from_local, mid_point + side_offset, dim_color, 2.0)
				draw_line(mid_point + side_offset, to_local, dim_color, 2.0)

# Convenience methods for different spell types
func create_powerful_spell_effect(pos: Vector2, spell_name: String):
	# Create enhanced particle effects for powerful spells
	match spell_name:
		"meteor shower":
			# Create multiple meteor effects
			for i in range(3):
				var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
				create_meteor_shower_effect(pos + offset)
		"lightning arc":
			# Create electric-looking effect
			create_lightning_arc_effect(pos)
			create_spell_cast_effect(pos)
		_:
			create_spell_impact_effect(pos)
