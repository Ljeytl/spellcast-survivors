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

func _draw():
	var a := clampf(1.0 - age / LIFE, 0.3, 1.0)
	var body := Color("#c8fff0") if healing else Color("#b4d978")
	var edge := Color("#539eaf") if healing else Color("#664d8a")
	for i in range(trail.size() - 1, -1, -1):
		var k := 1.0 - float(i) / float(trail.size())
		var offset := to_local(trail[i]) + heading.orthogonal() * sin(age * 12.0 - i * 0.65) * (1.0 - k) * 8.0
		draw_circle(offset, 2.0 + k * 5.0, Color(edge, k * 0.45 * a))
	var bob := Vector2(0, sin(age * 9.0) * 2.0)
	var shape := PackedVector2Array([Vector2(-9, 4), Vector2(-9, -5), Vector2(-5, -11), Vector2(3, -12), Vector2(9, -6), Vector2(10, 3), Vector2(7, 10), Vector2(3, 6), Vector2(0, 12), Vector2(-4, 7), Vector2(-8, 10)])
	for i in shape.size():
		shape[i] += bob
	draw_colored_polygon(shape, Color(body, a))
	var outline := shape.duplicate()
	outline.append(shape[0])
	draw_polyline(outline, Color(edge, a), 2.0)
	var gaze := heading * 1.5 + bob
	draw_rect(Rect2(Vector2(-4, -5) + gaze, Vector2(2, 4)), Color("#263a46"))
	draw_rect(Rect2(Vector2(3, -5) + gaze, Vector2(2, 4)), Color("#263a46"))
	if healing:
		draw_line(Vector2(-3, 2) + bob, Vector2(3, 2) + bob, Color.WHITE, 2.0)
		draw_line(Vector2(0, -1) + bob, Vector2(0, 5) + bob, Color.WHITE, 2.0)
