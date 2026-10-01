extends Control
## Edge-of-screen arrows toward ley sites that are still worth visiting.

var ley: Node
var marks: Array = []

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
	marks.clear()
	var game = ley.game
	if game.current_state == game.GameState.PLAYING and not ley.ritual_active():
		var rect = Rect2(Vector2.ZERO, size)
		for site in ley.sites:
			if not is_instance_valid(site) or site.state == site.State.ATTUNED:
				continue
			var screen = get_global_transform_with_canvas().affine_inverse() * (site.get_global_transform_with_canvas() * Vector2.ZERO)
			if rect.has_point(screen):
				continue
			var direction = screen - rect.get_center()
			var bounds = rect.size / 2 - Vector2(44, 56)
			var factor = minf(bounds.x / maxf(absf(direction.x), 0.01), bounds.y / maxf(absf(direction.y), 0.01))
			marks.append({"at": rect.get_center() + direction * factor, "angle": direction.angle(), "ready": site.state == site.State.DORMANT})
	queue_redraw()

func _draw():
	for mark in marks:
		draw_set_transform(mark.at, mark.angle)
		if mark.ready:
			draw_circle(Vector2.ZERO, 15.0, Color(0.7, 0.55, 1.0, 0.25))
		var shape = PackedVector2Array([Vector2(16, 0), Vector2(-10, -12), Vector2(-4, 0), Vector2(-10, 12)])
		draw_colored_polygon(shape, Color("b48cff") if mark.ready else Color("6f6a80"))
		shape.append(shape[0])
		draw_polyline(shape, Color("17101f"), 2.5)
	draw_set_transform(Vector2.ZERO)
