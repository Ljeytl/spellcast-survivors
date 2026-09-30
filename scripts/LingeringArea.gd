extends Node2D

func _init():
	DamageSource.stamp(self)

var radius = 80.0
var damage = 0.0
var duration = 0.2
var age = 0.0
var tint = Color("9bdcff")
var kind = "area"
var hit_ids: Dictionary = {}
var slow_factor = 1.0
var slow_time = 0.0
var tick_interval = 0.0
var next_hits: Dictionary = {}

func configure(center: Vector2, area_radius: float, amount: float, active_time: float, color: Color, visual_kind: String = "area", excluded: Dictionary = {}, slow: float = 1.0, slow_duration: float = 0.0):
	position = center
	radius = area_radius
	damage = amount
	duration = maxf(0.001, active_time)
	tint = color
	kind = visual_kind
	hit_ids = excluded.duplicate()
	slow_factor = slow
	slow_time = slow_duration

func _ready():
	add_to_group("lingering_spell_areas")
	z_index = 2
	strike()

func strike():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not preload("res://scripts/SpellTargeting.gd").alive(enemy) or hit_ids.has(enemy.get_instance_id()) or age < float(next_hits.get(enemy.get_instance_id(), -INF)):
			continue
		if global_position.distance_to(enemy.global_position) > radius:
			continue
		if tick_interval > 0.0:
			next_hits[enemy.get_instance_id()] = age + tick_interval
		else:
			hit_ids[enemy.get_instance_id()] = true
		enemy.take_damage(damage, global_position, DamageSource.of(self))
		if is_instance_valid(enemy) and slow_factor < 1.0 and enemy.has_method("apply_slow"):
			enemy.apply_slow(slow_factor, slow_time)

func _physics_process(delta):
	advance(delta)

func advance(delta: float):
	age += maxf(0.0, delta)
	if age >= duration:
		queue_free()
		return
	strike()
	queue_redraw()

func _draw():
	var progress = clampf(age / duration, 0, 1)
	var art = preload("res://scripts/AreaArt.gd")
	art.circle(self, Vector2.ZERO, radius, tint, 1.0 - progress * 0.5)
	if kind == "blade":
		preload("res://scripts/EffectArt.gd").stamp(self, "blade", Vector2.ZERO, Vector2.ONE * radius * 2, Color(1, 1, 1, 0.7), age * 12)
	elif kind == "meteor":
		art.meteor_impact(self, radius, progress)
	elif kind == "lightning":
		for index in range(4):
			var end = Vector2.from_angle(index * TAU / 4.0 + 0.4) * radius * 0.8
			preload("res://scripts/EffectArt.gd").lightning(self, Vector2.ZERO, end, 4, 1.0 - progress * 0.5)
