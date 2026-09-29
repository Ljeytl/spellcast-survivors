extends Node2D

var direction: Vector2 = Vector2.RIGHT
var damage: float = 60.0
var reach: float = 160.0
var half_angle: float = deg_to_rad(50.0)
var knockback: float = 500.0
var travel_time: float = 0.22
var age: float = 0.0
var hit_ids: Dictionary = {}
var front: float = 0.0

func _ready():
	z_index = 8
	add_to_group("earth_shield_eruptions")

func _physics_process(delta: float):
	advance(delta)

func advance(delta: float):
	age += delta
	front = reach * clampf(age / maxf(0.01, travel_time), 0, 1)
	if age <= travel_time + delta:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not preload("res://scripts/SpellTargeting.gd").alive(enemy) or hit_ids.has(enemy.get_instance_id()):
				continue
			var offset = enemy.global_position - global_position
			if offset.length() <= front and (offset.is_zero_approx() or absf(direction.angle_to(offset)) <= half_angle):
				hit_ids[enemy.get_instance_id()] = true
				enemy.take_damage(damage, global_position)
				if is_instance_valid(enemy) and enemy.has_method("apply_knockback"):
					enemy.apply_knockback(offset.normalized() if not offset.is_zero_approx() else direction, knockback)
	if age >= travel_time + 0.24:
		queue_free()
	queue_redraw()

func _draw():
	var alpha = clampf(1.0 - maxf(0, age - travel_time) / 0.24, 0, 1)
	var polygon = PackedVector2Array([Vector2.ZERO])
	for index in range(17):
		polygon.append(Vector2.from_angle(direction.angle() - half_angle + index * half_angle * 2 / 16) * front)
	draw_colored_polygon(polygon, Color(0.4,0.29,0.13,0.35 * alpha))
	polygon.append(Vector2.ZERO)
	draw_polyline(polygon, Color(0.95,0.75,0.34,alpha), 3)
	for row in range(1,4):
		var distance = front * row / 3.0
		for index in range(row * 2 + 1):
			var angle = direction.angle() - half_angle * 0.8 + index * half_angle * 1.6 / (row * 2)
			var point = Vector2.from_angle(angle) * distance * 0.88
			var scale = reach / 160.0
			var shard = PackedVector2Array([point + Vector2(-8,6)*scale,point+Vector2(-4,-14)*scale,point+Vector2(4,-20)*scale,point+Vector2(10,6)*scale])
			draw_colored_polygon(shard,Color(0.55,0.41,0.24,alpha))
			draw_line(shard[1],shard[2],Color(1,0.85,0.52,alpha),2)
