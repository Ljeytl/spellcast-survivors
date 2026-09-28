extends Control

var game: Node
var arrow_position = Vector2.ZERO
var angle = 0.0
var has_target = false

func _ready():
	name = "BossDirection"
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
	has_target = false
	if game.current_state != game.GameState.PLAYING:
		queue_redraw()
		return
	var rect = Rect2(Vector2.ZERO, game.hud.size)
	var closest = INF
	for boss in get_tree().get_nodes_in_group("bosses"):
		if not is_instance_valid(boss) or boss.dying:
			continue
		var screen = game.hud.get_global_transform_with_canvas().affine_inverse() * (boss.get_global_transform_with_canvas() * Vector2.ZERO)
		if rect.has_point(screen):
			continue
		var distance = screen.distance_squared_to(rect.get_center())
		if distance >= closest:
			continue
		closest = distance
		var direction = screen - rect.get_center()
		var bounds = rect.size / 2 - Vector2(30, 40)
		var factor = minf(bounds.x / maxf(absf(direction.x), 0.01), bounds.y / maxf(absf(direction.y), 0.01))
		arrow_position = rect.get_center() + direction * factor
		angle = direction.angle()
		has_target = true
	queue_redraw()

func _draw():
	if not has_target:
		return
	draw_set_transform(arrow_position, angle)
	var shape = PackedVector2Array([Vector2(13, 0), Vector2(-8, -9), Vector2(-4, 0), Vector2(-8, 9)])
	draw_colored_polygon(shape, Color("ff8175"))
	shape.append(shape[0])
	draw_polyline(shape, Color("17231c"), 3)
	draw_set_transform(Vector2.ZERO)
