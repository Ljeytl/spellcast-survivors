extends RefCounted

static func circle(canvas: CanvasItem, center: Vector2, radius: float, color: Color, opacity: float = 1.0, fill: float = 1.0):
	canvas.draw_circle(center, radius * clampf(fill, 0, 1), Color(color.darkened(0.4), 0.32 * opacity))
	canvas.draw_arc(center, radius, 0, TAU, 64, Color(color.lightened(0.25), opacity), 4.0)
	if fill < 1.0:
		canvas.draw_arc(center, maxf(2, radius * fill), 0, TAU, 64, Color(color, opacity), 3.0)

static func fire_circle(canvas: CanvasItem, center: Vector2, radius: float, age: float, opacity: float = 1.0):
	canvas.draw_circle(center, radius, Color("d44b35", 0.48 * opacity))
	canvas.draw_arc(center, radius, 0, TAU, 64, Color("ffab68", opacity), 4)
	for index in range(12):
		var angle = index * 2.39996
		var point = center + Vector2.from_angle(angle) * radius * sqrt((index + 0.5) / 12.0) * 0.85
		var flicker = 0.65 + 0.2 * sin(age * 9 + index)
		canvas.draw_rect(Rect2(point - Vector2(6, 3), Vector2(12, 6)), Color("ffc76a", opacity * flicker))

static func fire_path(canvas: CanvasItem, points: PackedVector2Array, radius: float, age: float):
	if points.is_empty():
		return
	if points.size() == 1:
		fire_circle(canvas, points[0], radius, age)
		return
	var polygons = Geometry2D.offset_polyline(points, radius, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
	for polygon in polygons:
		canvas.draw_colored_polygon(polygon, Color("d44b35", 0.48))
		var border = polygon.duplicate()
		border.append(polygon[0])
		canvas.draw_polyline(border, Color("ffab68"), 4)
	for index in range(points.size()):
		var point = points[index]
		var offset = Vector2(0, sin(index * 2.4) * radius * 0.5)
		canvas.draw_rect(Rect2(point + offset - Vector2(7, 4), Vector2(14, 8)), Color("ffd079", 0.7 + 0.2 * sin(age * 9 + index)))

static func cone(canvas: CanvasItem, radius: float, angle: float, half_angle: float, color: Color, opacity: float):
	var points = PackedVector2Array([Vector2.ZERO])
	for index in range(25):
		points.append(Vector2.from_angle(angle - half_angle + 2 * half_angle * index / 24) * radius)
	canvas.draw_colored_polygon(points, Color(color.darkened(0.4), opacity * 0.2))
	points.append(Vector2.ZERO)
	canvas.draw_polyline(points, Color(color, opacity), 3)
