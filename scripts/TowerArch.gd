extends Node2D

const ART = preload("res://scripts/TowerArt.gd")
const WIDTH = 170.0
const DEPTH = 26.0
const GROUND_Y = 2.0 / 3.0
const SOURCE = Rect2i(82, 290, 285, 192)
const SOURCE_SCALE = WIDTH / 285.0
const GLASS_POINTS = [Vector2(73,173), Vector2(73,114), Vector2(84,89), Vector2(101,70), Vector2(142,52), Vector2(182,70), Vector2(201,92), Vector2(213,120), Vector2(213,173)]

static var edges: Array[Dictionary] = []
var phase = 0.0
var woodland = false
## Training Grounds doorway: glows violet instead of showing the woodland scene.
var training = false

static func inward(at_phase: float) -> Vector2:
	return Vector2(-sin(at_phase), cos(at_phase))

static func ground(value: Vector2) -> Vector2:
	return value * Vector2(1.0, GROUND_Y)

func project(local: Vector2, depth: float) -> Vector2:
	return ground(Vector2(cos(phase), sin(phase)) * local.x + inward(phase) * depth) + Vector2(0, local.y)

func source_point(value: Vector2) -> Vector2:
	return (value - Vector2(SOURCE.size.x / 2.0, SOURCE.size.y)) * SOURCE_SCALE

func set_phase(value: float):
	phase = value
	queue_redraw()

static func build_edges():
	if not edges.is_empty():
		return
	var outer = [Vector2(2,187), Vector2(2,151), Vector2(13,151), Vector2(13,62), Vector2(36,62), Vector2(36,33), Vector2(73,33), Vector2(102,13), Vector2(142,2), Vector2(183,13), Vector2(213,33), Vector2(249,33), Vector2(249,62), Vector2(274,62), Vector2(274,151), Vector2(284,151), Vector2(284,187)]
	var inner = GLASS_POINTS.duplicate()
	inner.reverse()
	for contour in [outer, inner]:
		for i in contour.size():
			var a: Vector2 = contour[i]
			var b: Vector2 = contour[(i+1) % contour.size()]
			var count = maxi(1, ceili(a.distance_to(b)/29.0))
			for part in count:
				var start = a.lerp(b,float(part)/count)
				var end = a.lerp(b,float(part+1)/count)
				var color = Color("85868b") if absf(a.y-b.y) > absf(a.x-b.x) else Color("b1b0b4")
				if start.y > 155 and end.y > 155:
					color = Color("727b55")
				edges.append({"a":start, "b":end, "color":color})

func face_transform(depth: float) -> Transform2D:
	return Transform2D(Vector2(cos(phase), sin(phase) * GROUND_Y), Vector2.DOWN, ground(inward(phase) * depth))

func draw_face(depth: float, front: bool):
	draw_set_transform_matrix(face_transform(depth))
	if woodland:
		var points = PackedVector2Array()
		var uvs = PackedVector2Array()
		for i in GLASS_POINTS.size():
			points.append(source_point(GLASS_POINTS[i]))
			var normalized = (GLASS_POINTS[i] - Vector2(73,52)) / Vector2(140,121)
			uvs.append((Vector2(147,557) + normalized * Vector2(150,155)) / Vector2(ART.ATLAS.get_size()))
		if front:
			draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, ART.ATLAS)
		else:
			draw_colored_polygon(points, Color("41494d"))
	if training:
		var glow = PackedVector2Array()
		for point in GLASS_POINTS:
			glow.append(source_point(point))
		draw_colored_polygon(glow, Color("7b5cc4") if front else Color("41394d"))
	draw_texture_rect(ART.texture(4), Rect2(source_point(Vector2.ZERO), Vector2(SOURCE.size) * SOURCE_SCALE), false, Color.WHITE if front else Color("b6bdb7"))
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw():
	build_edges()
	var front_visible = cos(phase) >= 0.0
	var near_depth = DEPTH / 2.0 if front_visible else -DEPTH / 2.0
	if absf(cos(phase)) > 0.0001:
		draw_face(-near_depth, not front_visible)
	var sides: Array[Dictionary] = []
	for edge in edges:
		var a = source_point(edge.a)
		var b = source_point(edge.b)
		var polygon = PackedVector2Array([project(a,-DEPTH/2), project(b,-DEPTH/2), project(b,DEPTH/2), project(a,DEPTH/2)])
		var cross = (polygon[1] - polygon[0]).cross(polygon[2] - polygon[0])
		if cross > 0.01:
			sides.append({"points":polygon, "color":edge.color, "order":(a.x + b.x) * sin(phase)})
	sides.sort_custom(func(a,b): return a.order < b.order)
	for side in sides:
		draw_colored_polygon(side.points, side.color)
		draw_line(side.points[0], side.points[3], Color("45464e"), 1.5)
	if absf(cos(phase)) > 0.0001:
		draw_face(near_depth, front_visible)
