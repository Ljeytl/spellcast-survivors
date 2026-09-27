extends RefCounted

static func circle(canvas: CanvasItem, center: Vector2, radius: float, color: Color, opacity: float = 1.0, fill: float = 1.0):
	canvas.draw_circle(center, radius * clampf(fill, 0, 1), Color(color.darkened(0.4), 0.32 * opacity))
	canvas.draw_arc(center, radius, 0, TAU, 64, Color(color.lightened(0.25), opacity), 4.0)
	if fill < 1.0:
		canvas.draw_arc(center, maxf(2, radius * fill), 0, TAU, 64, Color(color, opacity), 3.0)

static func fire_circle(canvas: CanvasItem, center: Vector2, radius: float, age: float, opacity: float = 1.0):
	circle(canvas, center, radius, Color("ed7048"), opacity)
	for index in range(12):
		var angle = index * 2.39996
		var point = center + Vector2.from_angle(angle) * radius * sqrt((index + 0.5) / 12.0) * 0.85
		var flicker = 0.65 + 0.2 * sin(age * 9 + index)
		canvas.draw_rect(Rect2(point - Vector2(6, 3), Vector2(12, 6)), Color("ffc76a", opacity * flicker))

static func fire_segment(canvas: CanvasItem, start: Vector2, end: Vector2, radius: float, age: float, opacity: float = 1.0):
	var normal = (end - start).normalized().orthogonal() * radius
	canvas.draw_line(start, end, Color("a93e32", 0.32 * opacity), radius * 2)
	canvas.draw_line(start + normal, end + normal, Color("f59d61", opacity), 4)
	canvas.draw_line(start - normal, end - normal, Color("f59d61", opacity), 4)
	for index in range(maxi(1, int(start.distance_to(end) / 24))):
		var point = start.lerp(end, (index + 0.5) / maxi(1, int(start.distance_to(end) / 24)))
		canvas.draw_rect(Rect2(point - Vector2(6, 3), Vector2(12, 6)), Color("ffc76a", opacity * (0.65 + 0.2 * sin(age * 9 + index))))
