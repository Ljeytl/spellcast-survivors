extends Node2D
var caster: Node2D
var remaining := 0.35
var duration := 0.35
var ember_ring: CPUParticles2D
var tint := Color("ffe49b")
var sparks: CPUParticles2D
func _ready():
	sparks = CPUParticles2D.new()
	var reduced = caster.get_parent().particle_manager.reduced_effects
	duration = float(preload("res://scripts/KeywordRules.gd").DEFINITIONS.mega.charge_seconds)
	remaining = duration
	sparks.amount = 10 if reduced else 48
	sparks.lifetime = duration
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 44.0
	sparks.direction = Vector2.UP
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 0.0
	sparks.initial_velocity_max = 0.0
	sparks.radial_accel_min = -900.0
	sparks.radial_accel_max = -700.0
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 4.0
	sparks.color = tint
	add_child(sparks)
	sparks.emitting = true
	# A slower orbiting halo so the charge reads at a glance.
	ember_ring = CPUParticles2D.new()
	ember_ring.amount = 6 if reduced else 24
	ember_ring.lifetime = duration
	ember_ring.one_shot = true
	ember_ring.explosiveness = 0.6
	ember_ring.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	ember_ring.emission_sphere_radius = 30.0
	ember_ring.gravity = Vector2.ZERO
	ember_ring.orbit_velocity_min = 0.8
	ember_ring.orbit_velocity_max = 1.2
	ember_ring.scale_amount_min = 1.5
	ember_ring.scale_amount_max = 3.0
	ember_ring.color = tint.lightened(0.3)
	add_child(ember_ring)
	ember_ring.emitting = true
	AudioManager.play_sound(AudioManager.SoundType.MEGA_CHARGE, -1.0, 0.8)
	_process(0)
func _process(_delta):
	if not is_instance_valid(caster):
		queue_free()
		return
	var staff = caster.get_node_or_null("OrbitingStaff")
	global_position = staff.staff.to_global(Vector2(0, -staff.staff.texture.get_height() * 0.32)) if staff and staff.staff else caster.global_position + Vector2(24,-24)
	queue_redraw()
func _draw():
	var fraction = clampf(remaining / duration, 0, 1)
	draw_arc(Vector2.ZERO, 10 + fraction * 34, 0, TAU, 32, tint, 2.5)
	draw_arc(Vector2.ZERO, 6 + fraction * 18, 0, TAU, 24, tint.lightened(0.3), 1.5)
	draw_circle(Vector2.ZERO, 4 + (1-fraction)*12, tint)
func release_burst():
	var ring = preload("res://scripts/KeywordRelease.gd").new()
	ring.tint = tint
	get_parent().add_child(ring)
	ring.global_position = global_position
	var burst = CPUParticles2D.new()
	burst.amount = 14 if caster.get_parent().particle_manager.reduced_effects else 64
	burst.lifetime = 0.32
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.direction = Vector2.RIGHT
	burst.spread = 180.0
	burst.gravity = Vector2.ZERO
	burst.initial_velocity_min = 120
	burst.initial_velocity_max = 320
	burst.damping_min = 300
	burst.damping_max = 500
	burst.scale_amount_min = 2
	burst.scale_amount_max = 5
	burst.color = tint
	get_parent().add_child(burst)
	burst.global_position = global_position
	burst.finished.connect(burst.queue_free)
	burst.emitting = true
	AudioManager.play_sound(AudioManager.SoundType.MEGA_RELEASE, -1.0, 0.85)
