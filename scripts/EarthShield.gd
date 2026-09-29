extends Node2D

const Eruption = preload("res://scripts/EarthShieldEruption.gd")
var charges: Array[Dictionary] = []
var age: float = 0.0

func _ready():
	z_index = 12
	add_to_group("earth_shields")

func add_charge(info: Dictionary):
	charges.append(info.duplicate(true))
	queue_redraw()

func advance(delta: float):
	age += delta
	for charge in charges:
		charge.remaining -= delta
	charges = charges.filter(func(charge): return charge.remaining > 0)
	queue_redraw()

func _physics_process(delta: float):
	advance(delta)

func block(source: Dictionary) -> bool:
	if charges.is_empty():
		return false
	var earliest = 0
	for index in range(1, charges.size()):
		if charges[index].remaining < charges[earliest].remaining:
			earliest = index
	var charge = charges[earliest]
	charges.remove_at(earliest)
	var point: Vector2 = source.get("source_position", global_position)
	var attacker = source.get("attacker")
	if attacker is WeakRef:
		var enemy = attacker.get_ref()
		if is_instance_valid(enemy):
			point = enemy.global_position
	var aim = global_position.direction_to(point)
	if aim.is_zero_approx():
		aim = source.get("incoming_direction", Vector2.LEFT) * -1.0
	if aim.is_zero_approx():
		aim = Vector2.RIGHT
	release_eruption.call_deferred(charge, global_position, aim.normalized())
	queue_redraw()
	return true

func release_eruption(charge: Dictionary, origin: Vector2, aim: Vector2):
	var eruption = Eruption.new()
	eruption.position = origin
	eruption.direction = aim
	eruption.damage = charge.damage
	eruption.reach = charge.reach
	eruption.half_angle = charge.half_angle
	eruption.knockback = charge.knockback
	eruption.travel_time = charge.travel_time
	get_parent().get_parent().add_child(eruption)

func _draw():
	var count = mini(charges.size(), 12)
	for index in range(count):
		var angle = -PI * 0.5 + index * TAU / maxf(1, count) + sin(age * 0.8) * 0.12
		var point = Vector2.from_angle(angle) * (35 + 3 * sin(age * 2 + index))
		var fade = clampf(float(charges[index].remaining), 0.25, 1.0)
		var shape = PackedVector2Array([point + Vector2(-8,-10), point + Vector2(6,-12), point + Vector2(11,1), point + Vector2(3,10), point + Vector2(-9,6)])
		draw_colored_polygon(shape, Color(0.46,0.36,0.22,fade))
		shape.append(shape[0])
		draw_polyline(shape, Color(0.88,0.75,0.45,fade), 2)
		draw_line(point + Vector2(-3,-5), point + Vector2(4,4), Color(1,0.87,0.6,fade), 2)
