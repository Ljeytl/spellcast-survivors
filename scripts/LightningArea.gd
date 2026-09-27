extends Node2D

var radius = 160.0
var duration = 0.2
var age = 0.0
var damage = 80.0
var caster: WeakRef
var hit_ids: Dictionary = {}

func configure(center: Vector2, data: Dictionary, amount: float, player: Node2D):
	global_position = center
	radius = float(data.get("radius", 160.0))
	duration = float(data.get("active_duration", 0.2))
	damage = amount
	caster = weakref(player)

func _ready():
	add_to_group("lightning_areas")
	z_index = 3
	strike()

func strike():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.get("dying") or float(enemy.get("current_health")) <= 0 or hit_ids.has(enemy.get_instance_id()):
			continue
		if global_position.distance_to(enemy.global_position) <= radius:
			hit_ids[enemy.get_instance_id()] = true
			enemy.take_damage(damage, global_position)

func _physics_process(delta):
	advance(delta)

func advance(delta: float):
	var player = caster.get_ref() if caster else null
	if not is_instance_valid(player) or player.is_queued_for_deletion() or age >= duration:
		queue_free()
		return
	age += maxf(0, delta)
	if age < duration:
		strike()
	else:
		queue_free()
	queue_redraw()

func _draw():
	preload("res://scripts/AreaArt.gd").circle(self, Vector2.ZERO, radius, Color("65b9ff"))
	for index in range(7):
		var point = Vector2.from_angle(index * TAU / 7 + age * 4) * radius * 0.75
		var vertices = PackedVector2Array([point + Vector2(-8, -56), point + Vector2(6, -28), point + Vector2(-6, -18), point])
		draw_polyline(vertices, Color("d4efff"), 5)
