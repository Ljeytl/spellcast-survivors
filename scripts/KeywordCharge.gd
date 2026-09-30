extends Node2D
var caster: Node2D
var remaining := 0.12
var duration := 0.12
var tint := Color("ffe49b")
var sparks: CPUParticles2D
func _ready():
	sparks = CPUParticles2D.new()
	sparks.amount = 5 if caster.get_parent().particle_manager.reduced_effects else 18
	sparks.lifetime = duration
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 26.0
	sparks.direction = Vector2.UP
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 0.0
	sparks.initial_velocity_max = 0.0
	sparks.radial_accel_min = -2200.0
	sparks.radial_accel_max = -1800.0
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 4.0
	sparks.color = tint
	add_child(sparks)
	sparks.emitting = true
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
	draw_arc(Vector2.ZERO, 8 + fraction * 20, 0, TAU, 20, tint, 2.0)
	draw_circle(Vector2.ZERO, 4 + (1-fraction)*8, tint)
func release_burst():
	var ring = preload("res://scripts/KeywordRelease.gd").new()
	ring.tint = tint
	get_parent().add_child(ring)
	ring.global_position = global_position
	var burst = CPUParticles2D.new()
	burst.amount = 5 if caster.get_parent().particle_manager.reduced_effects else 18
	burst.lifetime = 0.18
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.direction = Vector2.RIGHT
	burst.spread = 180.0
	burst.gravity = Vector2.ZERO
	burst.initial_velocity_min = 45
	burst.initial_velocity_max = 115
	burst.scale_amount_min = 2
	burst.scale_amount_max = 4
	burst.color = tint
	get_parent().add_child(burst)
	burst.global_position = global_position
	burst.finished.connect(burst.queue_free)
	burst.emitting = true
