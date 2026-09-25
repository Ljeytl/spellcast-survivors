extends Node

# Animation management system for SpellCast Survivors
# Integrates with DataManager to provide animated visuals for all game elements

signal animation_finished(entity_id: String, animation_name: String)
signal particle_effect_spawned(effect_name: String, position: Vector2)

var active_animations: Dictionary = {}
var active_particles: Array = []
var animation_pools: Dictionary = {}

# Performance settings
var current_quality_level: String = "medium"
var max_active_animations: int = 50
var max_active_particles: int = 100

func _ready():
	# Wait for DataManager to load
	if DataManager.is_loaded:
		initialize_animation_system()
	else:
		DataManager.data_loaded.connect(_on_data_loaded)

func _on_data_loaded():
	initialize_animation_system()

func initialize_animation_system():
	# Load performance settings
	var performance = DataManager.get_performance_settings(current_quality_level)
	max_active_animations = performance.get("max_particles", 100)
	max_active_particles = performance.get("max_particles", 100)
	
	print("AnimationManager: Initialized with quality level: ", current_quality_level)

# ========== SPELL ANIMATION SYSTEM ==========

func play_spell_animation(spell_id: String, animation_type: String, target_node: Node, position: Vector2 = Vector2.ZERO) -> AnimationPlayer:
	var visual_data = DataManager.get_spell_visual_data(spell_id)
	if visual_data.is_empty():
		print("Warning: No visual data found for spell: ", spell_id)
		return null
	
	var animation_data = visual_data.get(animation_type, {})
	if animation_data.is_empty():
		print("Warning: No animation data found for spell ", spell_id, " animation: ", animation_type)
		return null
	
	# Create and configure animation
	var animation_player = DataManager.create_animation_resource({animation_type: animation_data})
	target_node.add_child(animation_player)
	
	# Position the effect
	if position != Vector2.ZERO:
		target_node.position = position
	
	# Connect to cleanup signal
	animation_player.animation_finished.connect(_on_animation_finished.bind(spell_id, animation_type, animation_player))
	
	# Play the animation
	animation_player.play(animation_type)
	
	# Track active animation
	var entity_id = spell_id + "_" + str(target_node.get_instance_id())
	active_animations[entity_id] = {
		"player": animation_player,
		"node": target_node,
		"spell_id": spell_id,
		"type": animation_type
	}
	
	return animation_player

func play_spell_cast_effect(spell_id: String, caster_position: Vector2, target_position: Vector2 = Vector2.ZERO):
	var visual_data = DataManager.get_spell_visual_data(spell_id)
	var cast_effect = visual_data.get("cast_effect", {})
	
	if not cast_effect.is_empty():
		# Create cast effect at caster position
		var effect_node = create_effect_node(cast_effect)
		get_tree().current_scene.add_child(effect_node)
		effect_node.position = caster_position
		
		# Play cast sound if available
		var sound_data = visual_data.get("sound_effects", {})
		var cast_sound = sound_data.get("cast", "")
		if not cast_sound.is_empty() and AudioManager:
			AudioManager.play_sound_at_position(cast_sound, caster_position)

func spawn_spell_particles(spell_id: String, position: Vector2, particle_type: String = ""):
	var visual_data = DataManager.get_spell_visual_data(spell_id)
	var particle_effects = visual_data.get("particle_effects", [])
	
	if particle_effects.is_empty():
		return
	
	# Use specific particle type or pick first one
	var effect_name = particle_type if particle_type in particle_effects else particle_effects[0]
	var particle_data = DataManager.get_particle_system_data(effect_name)
	
	if not particle_data.is_empty():
		spawn_particle_effect(effect_name, position, particle_data)

# ========== CHARACTER ANIMATION SYSTEM ==========

func setup_character_animations(character_id: String, character_node: Node) -> AnimationPlayer:
	var visual_data = DataManager.get_character_visual_data(character_id)
	var animations = visual_data.get("character_animations", {})
	
	if animations.is_empty():
		print("Warning: No animations found for character: ", character_id)
		return null
	
	var animation_player = DataManager.create_animation_resource(animations)
	character_node.add_child(animation_player)
	
	# Setup state machine blending if available
	var blending_data = DataManager.get_animation_blending_data("character_state_machine")
	if not blending_data.is_empty():
		setup_animation_blending(animation_player, blending_data)
	
	return animation_player

func play_character_animation(character_node: Node, animation_name: String, blend_time: float = 0.1):
	var animation_player = character_node.get_node_or_null("AnimationPlayer")
	if not animation_player:
		print("Warning: No AnimationPlayer found on character node")
		return
	
	# Blend to new animation if different from current
	if animation_player.current_animation != animation_name:
		if blend_time > 0:
			var tween = create_tween()
			tween.tween_method(_blend_animation, 1.0, 0.0, blend_time)
			await tween.finished
		
		animation_player.play(animation_name)
		
		if blend_time > 0:
			var tween2 = create_tween()
			tween2.tween_method(_blend_animation, 0.0, 1.0, blend_time)

func _blend_animation(weight: float):
	# Helper function for animation blending
	pass # Implementation depends on specific blending requirements

# ========== ENEMY ANIMATION SYSTEM ==========

func setup_enemy_animations(enemy_class: String, zone_id: String, enemy_node: Node) -> AnimationPlayer:
	var animation_data = DataManager.get_enemy_visual_data(zone_id, enemy_class)
	
	if animation_data.is_empty():
		print("Warning: No animation data found for enemy ", enemy_class, " in zone ", zone_id)
		return null
	
	var animation_player = DataManager.create_animation_resource(animation_data)
	enemy_node.add_child(animation_player)
	
	# Start with idle animation
	animation_player.play("idle")
	
	return animation_player

# ========== UI ANIMATION SYSTEM ==========

func animate_ui_element(element_node: Node, animation_type: String, ui_element_name: String):
	var ui_animation_data = DataManager.get_ui_animation_data(ui_element_name)
	var animation_info = ui_animation_data.get(animation_type, {})
	
	if animation_info.is_empty():
		return
	
	# Create tween-based animations for UI elements
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Handle different animation types
	match animation_type:
		"card_hover":
			var scale_data = animation_info.get("scale", {})
			if not scale_data.is_empty():
				var from_scale = scale_data.get("from", 1.0)
				var to_scale = scale_data.get("to", 1.05)
				var duration = scale_data.get("duration", 0.15)
				tween.tween_property(element_node, "scale", Vector2.ONE * to_scale, duration)
		
		"level_up_card_select":
			# Flash effect
			var flash_data = animation_info.get("flash", {})
			if not flash_data.is_empty():
				tween.tween_property(element_node, "modulate", Color.WHITE * 1.5, 0.05)
				tween.tween_property(element_node, "modulate", Color.WHITE, 0.1)

# ========== PARTICLE SYSTEM ==========

func spawn_particle_effect(effect_name: String, position: Vector2, particle_data: Dictionary):
	if active_particles.size() >= max_active_particles:
		# Remove oldest particle effect
		cleanup_oldest_particle()
	
	# Create particle system
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.position = position
	
	# Configure particle system from data
	configure_particle_system(particles, particle_data)
	
	# Start emission
	particles.emitting = true
	
	# Track and auto-cleanup
	active_particles.append({
		"particles": particles,
		"lifetime": particle_data.get("lifetime", 2.0),
		"spawn_time": Time.get_time_dict_from_system()
	})
	
	particle_effect_spawned.emit(effect_name, position)

func configure_particle_system(particles: CPUParticles2D, data: Dictionary):
	# Load texture
	var texture_path = DataManager.get_asset_path("particles") + data.get("texture", "default_particle.png")
	if ResourceLoader.exists(texture_path):
		particles.texture = load(texture_path)
	
	# Set emission properties
	particles.emission.rate = data.get("emission_rate", 50)
	particles.lifetime = data.get("lifetime", 2.0)
	
	# Set colors
	var colors = data.get("colors", [[1, 1, 1, 1]])
	if colors.size() >= 1:
		particles.color = Color(colors[0][0], colors[0][1], colors[0][2], colors[0][3])
	if colors.size() >= 2:
		particles.color_ramp = create_gradient_from_colors(colors)
	
	# Set scale
	var scale_curve = data.get("scale_curve", [1.0])
	if scale_curve.size() > 1:
		particles.scale_amount_min = scale_curve[0]
		particles.scale_amount_max = scale_curve[-1]
	
	# Set velocity
	var velocity = data.get("velocity", {"min": 50, "max": 100})
	particles.initial_velocity_min = velocity.get("min", 50)
	particles.initial_velocity_max = velocity.get("max", 100)

func create_gradient_from_colors(colors: Array) -> Gradient:
	var gradient = Gradient.new()
	gradient.clear()
	
	for i in range(colors.size()):
		var color_data = colors[i]
		var color = Color(color_data[0], color_data[1], color_data[2], color_data[3])
		var offset = float(i) / float(colors.size() - 1) if colors.size() > 1 else 0.0
		gradient.add_point(offset, color)
	
	return gradient

# ========== EFFECT UTILITIES ==========

func create_effect_node(effect_data: Dictionary) -> Node2D:
	var effect_node = Node2D.new()
	var sprite = Sprite2D.new()
	effect_node.add_child(sprite)
	
	# Load first frame as texture
	var frames = effect_data.get("frames", [])
	if not frames.is_empty():
		var texture_path = DataManager.get_asset_path("effects") + frames[0]
		if ResourceLoader.exists(texture_path):
			sprite.texture = load(texture_path)
	
	return effect_node

# ========== CLEANUP AND OPTIMIZATION ==========

func _on_animation_finished(spell_id: String, animation_type: String, animation_player: AnimationPlayer):
	# Emit signal
	animation_finished.emit(spell_id, animation_type)
	
	# Remove from active animations
	for entity_id in active_animations:
		var anim_data = active_animations[entity_id]
		if anim_data.player == animation_player:
			active_animations.erase(entity_id)
			break
	
	# Clean up animation player
	if is_instance_valid(animation_player):
		animation_player.queue_free()

func cleanup_oldest_particle():
	if active_particles.is_empty():
		return
	
	var oldest_particle = active_particles[0]
	if is_instance_valid(oldest_particle.particles):
		oldest_particle.particles.queue_free()
	
	active_particles.remove_at(0)

func _process(_delta):
	# Clean up expired particles
	var current_time = Time.get_time_dict_from_system()
	var to_remove = []
	
	for i in range(active_particles.size()):
		var particle_data = active_particles[i]
		var age = current_time.get("unix", 0) - particle_data.spawn_time.get("unix", 0)
		
		if age > particle_data.lifetime:
			if is_instance_valid(particle_data.particles):
				particle_data.particles.queue_free()
			to_remove.append(i)
	
	# Remove expired particles (reverse order to maintain indices)
	for i in range(to_remove.size() - 1, -1, -1):
		active_particles.remove_at(to_remove[i])

func setup_animation_blending(animation_player: AnimationPlayer, blending_data: Dictionary):
	# Set up animation blending based on state machine data
	# This is a placeholder for more complex blending logic
	pass

func set_quality_level(quality: String):
	if quality in ["low", "medium", "high"]:
		current_quality_level = quality
		var performance = DataManager.get_performance_settings(quality)
		max_active_animations = performance.get("max_particles", 100)
		max_active_particles = performance.get("max_particles", 100)
		print("AnimationManager: Quality level set to ", quality)