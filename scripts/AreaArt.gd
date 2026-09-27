extends RefCounted

static func circle(canvas: CanvasItem, center: Vector2, radius: float, color: Color, opacity: float = 1.0, fill: float = 1.0):
	canvas.draw_circle(center, radius * clampf(fill, 0, 1), Color(color.darkened(0.4), 0.32 * opacity))
	canvas.draw_arc(center, radius, 0, TAU, 64, Color(color.lightened(0.25), opacity), 4.0)
	if fill < 1.0:
		canvas.draw_arc(center, maxf(2, radius * fill), 0, TAU, 64, Color(color, opacity), 3.0)

static func fire_circle(canvas: CanvasItem, center: Vector2, radius: float, age: float, opacity: float = 1.0):
	canvas.draw_circle(center, radius, Color("f15c32", 0.60 * opacity))
	canvas.draw_arc(center, radius, 0, TAU, 64, Color("ffab68", opacity), 4)
	for index in range(12):
		var angle = index * 2.39996
		var point = center + Vector2.from_angle(angle) * radius * sqrt((index + 0.5) / 12.0) * 0.85
		var flicker = 0.65 + 0.2 * sin(age * 9 + index)
		canvas.draw_rect(Rect2(point - Vector2(6, 3), Vector2(12, 6)), Color("ffc76a", opacity * flicker))
		if index % 3 == 0:
			flame(canvas, point, opacity)

static func fire_path(canvas: CanvasItem, points: PackedVector2Array, radius: float, age: float):
	if points.is_empty():
		return
	if points.size() == 1:
		fire_circle(canvas, points[0], radius, age)
		return
	var polygons = Geometry2D.offset_polyline(points, radius, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
	for index in range(points.size()):
		canvas.draw_circle(points[index], radius, Color("f15c32", 0.45))
		if index + 1 < points.size():
			canvas.draw_line(points[index], points[index + 1], Color("f15c32", 0.45), radius * 2)
	for polygon in polygons:
		var border = polygon.duplicate()
		border.append(polygon[0])
		canvas.draw_polyline(border, Color("ffab68"), 4)
	for index in range(points.size()):
		var point = points[index]
		var offset = Vector2(0, sin(index * 2.4) * radius * 0.5)
		canvas.draw_rect(Rect2(point + offset - Vector2(7, 4), Vector2(14, 8)), Color("ffd079", 0.7 + 0.2 * sin(age * 9 + index)))
		if index % maxi(1, ceili(points.size() / 8.0)) == 0:
			flame(canvas, point + offset)

static func cone(canvas: CanvasItem, radius: float, angle: float, half_angle: float, color: Color, opacity: float):
	var points = PackedVector2Array([Vector2.ZERO])
	for index in range(25):
		points.append(Vector2.from_angle(angle - half_angle + 2 * half_angle * index / 24) * radius)
	canvas.draw_colored_polygon(points, Color(color.darkened(0.4), opacity * 0.2))
	points.append(Vector2.ZERO)
	canvas.draw_polyline(points, Color(color, opacity), 3)

static func flame(canvas: CanvasItem, point: Vector2, opacity: float = 1.0):
	var outer = PackedVector2Array([Vector2(-8, 7), Vector2(-9, -2), Vector2(-3, -7), Vector2(0, -18), Vector2(4, -7), Vector2(8, -2), Vector2(7, 7)])
	var inner = PackedVector2Array([Vector2(-4, 7), Vector2(-3, 0), Vector2(1, -9), Vector2(4, 1), Vector2(3, 7)])
	for index in range(outer.size()):
		outer[index] += point
	for index in range(inner.size()):
		inner[index] += point
	canvas.draw_colored_polygon(outer, Color("ff7b38", opacity))
	canvas.draw_colored_polygon(inner, Color("ffde83", opacity))

static func steam_circle(canvas: CanvasItem, center: Vector2, radius: float, age: float):
	var art = preload("res://scripts/EffectArt.gd")
	canvas.draw_circle(center, radius, Color("566577", 0.48))
	canvas.draw_arc(center, radius, 0, TAU, 48, Color("a3e1e4"), 3)
	for index in range(11):
		var point = center + Vector2.from_angle(index * 2.39996) * radius * sqrt((index + 0.5) / 11.0) * 0.82
		var phase = fmod(age * 0.7 + index * 0.37, 1.0)
		art.stamp(canvas, "ember", point, Vector2(20, 18), Color(1, 1, 1, 0.8))
		art.stamp(canvas, "smoke", point + Vector2(0, -phase * 22 - 8), Vector2(34, 38), Color(1, 1, 1, 0.95 - phase * 0.45))
	for index in range(6):
		var point = center + Vector2.from_angle(index * TAU / 6) * radius * 0.92
		var chevron = PackedVector2Array([point + Vector2(-6, -3), point + Vector2(0, 3), point + Vector2(6, -3)])
		canvas.draw_polyline(chevron, Color("a3e1e4"), 3)

static func meteor_warning(canvas: CanvasItem, radius: float, progress: float, projectile_scale: float = 1.0):
	var art = preload("res://scripts/EffectArt.gd")
	circle(canvas, Vector2.ZERO, radius, Color("e88d52"), 1, clampf(progress, 0, 1))
	for index in range(8):
		var direction = Vector2.from_angle(index * TAU / 8)
		canvas.draw_line(direction * (radius - 12), direction * radius, Color("f1dfaf"), 4)
	canvas.draw_circle(Vector2.ZERO, 13 + progress * 10, Color("202334", 0.7))
	if progress < 0.3:
		return
	var descent = clampf((progress - 0.3) / 0.7, 0, 1)
	var point = Vector2(70, -190) * (1 - descent)
	canvas.draw_set_transform(point.round(), 0, Vector2.ONE * projectile_scale)
	for index in range(3, 0, -1):
		art.stamp(canvas, "ember", Vector2(index * 8, -index * 20), Vector2.ONE * (38 - index * 5))
	var rock = PackedVector2Array([Vector2(-16, -8), Vector2(-8, -8), Vector2(-8, -16), Vector2(10, -16), Vector2(10, -8), Vector2(17, -8), Vector2(17, 10), Vector2(9, 10), Vector2(9, 17), Vector2(-10, 17), Vector2(-10, 10), Vector2(-16, 10)])
	canvas.draw_colored_polygon(rock, Color("e88d52"))
	rock.append(rock[0])
	canvas.draw_polyline(rock, art.INK, 3)
	canvas.draw_rect(Rect2(Vector2(-9, -6), Vector2(19, 17)), Color("82705d"))
	canvas.draw_rect(Rect2(Vector2(-9, -6), Vector2(10, 5)), Color("c7ad80"))

	canvas.draw_set_transform(Vector2.ZERO)

static func meteor_impact(canvas: CanvasItem, radius: float, progress: float):
	var art = preload("res://scripts/EffectArt.gd")
	var opacity = clampf((1 - progress) * 2, 0, 1)
	canvas.draw_circle(Vector2.ZERO, radius, Color("e88d52", opacity * 0.25))
	canvas.draw_arc(Vector2.ZERO, maxf(4, radius * progress), 0, TAU, 48, Color("f1dfaf", opacity), 6)
	art.stamp(canvas, "impact", Vector2.ZERO, Vector2.ONE * lerpf(90, 130, progress), Color(1, 1, 1, opacity))
	for index in range(10):
		var point = Vector2.from_angle(index * TAU / 10) * radius * progress * 0.85
		art.stamp(canvas, "ember" if index % 2 else "smoke", point, Vector2.ONE * 34, Color(1, 1, 1, opacity))
