extends RefCounted

const PARTICLE_STAMPS = preload("res://assets/effects/particle-stamps.png")
const SPELL_MOTIFS = preload("res://assets/effects/spell-motifs.png")
const STAMP_REGIONS = {"impact": Rect2(132, 148, 400, 408), "smoke": Rect2(784, 120, 360, 440), "ember": Rect2(208, 768, 272, 352), "shard": Rect2(792, 744, 328, 392)}
const MOTIF_CELLS = {"mana": 0, "bolt": 1, "lance": 2, "ice": 3, "plague": 4, "spirit": 5, "orbit": 6, "blade": 7, "flame": 8, "steam": 9, "meteor": 10, "stone": 11, "heal": 12, "shard": 13, "ember": 14, "prism": 15}
const MOTIF_BOUNDS = [Rect2(67, 108, 223, 146), Rect2(383, 114, 229, 132), Rect2(650, 122, 285, 131), Rect2(994, 108, 218, 145), Rect2(79, 366, 147, 209), Rect2(367, 375, 212, 200), Rect2(673, 364, 228, 228), Rect2(986, 355, 243, 238), Rect2(88, 658, 153, 239), Rect2(371, 689, 216, 194), Rect2(686, 676, 209, 228), Rect2(996, 696, 208, 193), Rect2(68, 1001, 191, 173), Rect2(377, 1006, 187, 175), Rect2(711, 1034, 167, 122), Rect2(1038, 973, 127, 208)]
const MOTIF_BODIES = {"mana": Rect2(67, 108, 150, 146), "bolt": Rect2(383, 114, 144, 132), "spirit": Rect2(420, 375, 158, 169)}

const INK = Color("202334")
const PALETTE = {"mana": Color("69c5ce"), "bolt": Color("f5d779"), "lance": Color("e88d52"), "ice": Color("a3e1e4"), "lightning": Color("b5a3df"), "heal": Color("a9ca79"), "stone": Color("a8a18b"), "spirit": Color("b3c7df"), "flame": Color("e88d52"), "impact": Color("f1dfaf"), "xp": Color("83cbd0"), "smoke": Color("898a94"), "plague": Color("83a35d"), "blade": Color("d6d4eb"), "rune": Color("d2b57a"), "hostile": Color("f27367")}

static func pixel(canvas: CanvasItem, rect: Rect2, color: Color):
	canvas.draw_rect(rect.grow(1), INK)
	canvas.draw_rect(rect, color)

static func stamp(canvas: CanvasItem, kind: String, center: Vector2, size: Vector2, tint: Color = Color.WHITE, angle: float = 0.0):
	if MOTIF_CELLS.has(kind):
		canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var facing = -1.0 if kind in ["mana", "bolt"] else 1.0
		canvas.draw_set_transform(center.round(), angle, Vector2(size.x * facing, size.y) / 24.0)
		canvas.draw_texture_rect_region(SPELL_MOTIFS, Rect2(-12, -12, 24, 24), motif_region(kind), tint)
		canvas.draw_set_transform(Vector2.ZERO)
		return
	canvas.draw_set_transform(center.round(), angle, size / 24.0)
	var color: Color = PALETTE.get(kind, PALETTE.impact) * tint
	match kind:
		"impact", "smoke":
			canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var region: Rect2 = STAMP_REGIONS[kind]
			var ratio = PARTICLE_STAMPS.get_width() / 1280.0
			canvas.draw_texture_rect_region(PARTICLE_STAMPS, Rect2(-12, -12, 24, 24), Rect2(region.position * ratio, region.size * ratio), tint)
		"lightning":
			var points = PackedVector2Array([Vector2(-8, -10), Vector2(5, -10), Vector2(0, -2), Vector2(8, -2), Vector2(-5, 11), Vector2(-1, 2), Vector2(-8, 2)])
			canvas.draw_colored_polygon(points, color)
			points.append(points[0])
			canvas.draw_polyline(points, INK, 1.5)
		"rune":
			canvas.draw_rect(Rect2(-9, -9, 18, 18), INK, false, 4)
			canvas.draw_rect(Rect2(-9, -9, 18, 18), color, false, 2)
			pixel(canvas, Rect2(-1, -5, 2, 10), color)
		"hostile":
			pixel(canvas, Rect2(-5, -5, 10, 10), color)
		_:
			pixel(canvas, Rect2(-4, -4, 8, 8), color)
	canvas.draw_set_transform(Vector2.ZERO)

static func motif_region(kind: String) -> Rect2:
	return MOTIF_BOUNDS[MOTIF_CELLS[kind]]

static func beam(canvas: CanvasItem, start: Vector2, end: Vector2, width: float, opacity: float = 1.0, prism: bool = false):
	var hue = Color("cbb5fa") if prism else Color("a5eaff")
	var normal = (end - start).normalized().orthogonal() * width * 0.5
	canvas.draw_line(start, end, Color(hue.darkened(0.25), opacity * 0.42), width)
	canvas.draw_line(start + normal, end + normal, Color(hue, opacity * 0.8), 2)
	canvas.draw_line(start - normal, end - normal, Color(hue, opacity * 0.8), 2)
	canvas.draw_line(start, end, Color(hue, opacity * 0.85), maxf(3, width * 0.22))
	canvas.draw_line(start, end, Color("f4f3e9", opacity), maxf(2, width * 0.09))
	if prism:
		var length = start.distance_to(end)
		var direction = (end - start).normalized()
		for index in range(1, int(length / 80.0) + 1):
			stamp(canvas, "prism", start + direction * minf(index * 80.0, length - 12.0), Vector2.ONE * minf(22.0, width * 0.58), Color(1, 1, 1, opacity))

static func wreath(canvas: CanvasItem, kind: String, center: Vector2, radius: float, phase: float, opacity: float = 0.8, count: int = 8, particle_size: float = 14.0):
	for index in range(count):
		var angle = TAU * index / count + phase
		stamp(canvas, kind, center + Vector2.from_angle(angle) * radius, Vector2.ONE * particle_size, Color(1, 1, 1, opacity))

static func burst(canvas: CanvasItem, row: int, center: Vector2, diameter: float, progress: float, opacity: float = 0.8):
	var kind = ["flame", "ice", "heal", "impact"][clampi(row, 0, 3)]
	wreath(canvas, kind, center, diameter * 0.5 * clampf(progress, 0, 1), 0, opacity * (1 - progress), 8)

static func row_for_color(color: Color) -> int:
	if color.g > color.r * 1.3 and color.g > color.b * 1.2:
		return 2
	if color.b > 0.6 and color.g > color.r * 1.2:
		return 1
	return 0 if color.r > color.b * 1.4 else 3

static func lightning(canvas: CanvasItem, start: Vector2, end: Vector2, width: float = 6.0, opacity: float = 1.0):
	var axis = end - start
	var normal = axis.normalized().orthogonal()
	var count = maxi(3, ceili(axis.length() / 22.0))
	var points = PackedVector2Array([start.round()])
	for index in range(1, count):
		points.append((start + axis * float(index) / count + normal * (7 if index % 2 else -7)).round())
	points.append(end.round())
	canvas.draw_polyline(points, Color(INK, opacity), width + 4)
	canvas.draw_polyline(points, Color(PALETTE.lightning, opacity), width)
	canvas.draw_polyline(points, Color("fff1d1", opacity), 2)

static func healing_plus(canvas: CanvasItem, center: Vector2, size: float, opacity: float):
	canvas.draw_set_transform(center.round(), 0, Vector2.ONE * size / 12.0)
	var outline = Color("315a3a", opacity)
	var green = Color("86ed8a", opacity)
	canvas.draw_rect(Rect2(-3, -7, 6, 14), outline)
	canvas.draw_rect(Rect2(-7, -3, 14, 6), outline)
	canvas.draw_rect(Rect2(-2, -6, 4, 12), green)
	canvas.draw_rect(Rect2(-6, -2, 12, 4), green)
	canvas.draw_rect(Rect2(-1, -5, 2, 6), Color("e7ffd0", opacity))
	canvas.draw_set_transform(Vector2.ZERO)

static func electric_tail(canvas: CanvasItem, factor: float):
	var points = PackedVector2Array([Vector2(-12, 0), Vector2(-23, -4), Vector2(-28, 4), Vector2(-39, 0)])
	for index in range(points.size()):
		points[index] *= factor
	canvas.draw_polyline(points, Color("477d96"), 3 * factor)
	canvas.draw_polyline(points, Color("c5f4ff"), 1.5 * factor)
