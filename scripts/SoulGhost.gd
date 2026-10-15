extends Node2D
## Soul Bloom's ghost (doc 21 §5.6): leaves an infected enemy that died. If the caster is hurt it flies
## to them and heals `amount`; otherwise it hunts the nearest enemy and deals `amount` as plague.
## At most three at once per caster; each fades after a few seconds.

const SPEED = 320.0
const LIFE = 4.0
const CAP = 3

var cast_ref: WeakRef
var player_ref: WeakRef
var amount := 6.0
var source: Dictionary = {}
var age := 0.0
var healing := false
var heading := Vector2.RIGHT
var trail: Array[Vector2] = []

func _ready():
	add_to_group("soul_ghosts")
	z_index = 5
	var mine = get_tree().get_nodes_in_group("soul_ghosts").filter(func(g): return g != self and not g.is_queued_for_deletion() and g.player_ref and g.player_ref.get_ref() == player_ref.get_ref())
	while mine.size() >= CAP:
		mine.pop_front().queue_free()

func _physics_process(delta):
	age += delta
	var player = player_ref.get_ref() if player_ref else null
	if age >= LIFE or not is_instance_valid(player):
		queue_free()
		return
	var hurt = player.get("health") != null and float(player.health) < float(player.max_health)
	healing = hurt
	var target = player if hurt else _nearest_enemy()
	if target == null:
		if not trail.is_empty():
			trail.pop_back()
		queue_redraw()
		return
	heading = global_position.direction_to(target.global_position)
	trail.push_front(global_position)
	if trail.size() > 9:
		trail.pop_back()
	global_position = global_position.move_toward(target.global_position, SPEED * delta)
	if global_position.distance_to(target.global_position) <= 24.0:
		if hurt:
			if player.has_method("heal"):
				player.heal(amount)
		else:
			preload("res://scripts/engine/Effects.gd").apply(target, {"type": "damage", "entries": [{"amount": amount, "damage_type": "plague"}], "element": "plague"}, source, global_position)
		_arrival(target.global_position)
		queue_free()
		return
	queue_redraw()

func _nearest_enemy():
	var best = null
	var best_d = INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dying")):
			continue
		var d = global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _arrival(at: Vector2) -> void:
	var vfx = get_node_or_null("/root/Vfx")
	if vfx == null:
		return
	var point := at / (1280.0 / 192.0)
	var colors := [Color("#fff5ce"), Color("#a5f5d2"), Color("#4a98a8")] if healing else [Color("#e0f3a3"), Color("#9d80c9"), Color("#51416d")]
	vfx.ring(point.x, point.y, 4.2, 0.24, colors)
	vfx.star(point.x, point.y, 2.0, 0.14, 4 if healing else 6, colors[0])

func _draw():
	var fade := clampf(1.0 - age / LIFE, 0.3, 1.0)
	var body := Color("#8be0c9") if healing else Color("#9d80c9")
	var edge := Color("#357e99") if healing else Color("#4c356f")
	var core := Color("#fff5ce") if healing else Color("#ddf5a0")
	var normal := heading.orthogonal()
	for ribbon in [-1.0, 1.0]:
		var previous := Vector2.ZERO
		for i in trail.size():
			var k := float(i + 1) / float(trail.size() + 1)
			var wave := sin(age * 10.0 - k * 5.0 + ribbon) * (3.0 + k * 9.0)
			var point: Vector2 = to_local(trail[i]) + normal * (wave + ribbon * 3.0) * k
			draw_line(previous, point, Color(edge, (1.0 - k) * fade * 0.35), (1.0 - k) * 9.0 + 1.0)
			draw_line(previous, point, Color(body, (1.0 - k) * fade * 0.8), (1.0 - k) * 3.0 + 1.0)
			previous = point
	var shape := PackedVector2Array([Vector2(15, 0), Vector2(7, -7), Vector2(-2, -8), Vector2(-10, -5), Vector2(-25, -8), Vector2(-18, 0), Vector2(-29, 7), Vector2(-10, 4), Vector2(-3, 9), Vector2(7, 7)])
	for i in shape.size():
		var point := shape[i]
		if point.x < 0:
			point.y += sin(age * 11.0 + point.x * 0.15) * absf(point.x) * 0.14
		shape[i] = heading * point.x + normal * point.y
	draw_colored_polygon(shape, Color(body, fade * 0.86))
	var outline := shape.duplicate()
	outline.append(shape[0])
	draw_polyline(outline, Color(edge, fade), 2.0)
	var heart := PackedVector2Array([heading * 11.0, heading * 2.0 - normal * 3.0, -heading * 10.0, heading * 2.0 + normal * 3.0])
	draw_colored_polygon(heart, Color(core, fade))
