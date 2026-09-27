extends RefCounted

const INK = Color("202334")
const PALETTE = {"mana": Color("69c5ce"), "bolt": Color("f5d779"), "lance": Color("e88d52"), "ice": Color("a3e1e4"), "lightning": Color("b5a3df"), "heal": Color("a9ca79"), "stone": Color("a8a18b"), "spirit": Color("b3c7df"), "flame": Color("e88d52"), "impact": Color("f1dfaf"), "xp": Color("83cbd0"), "smoke": Color("898a94"), "plague": Color("83a35d"), "blade": Color("d6d4eb"), "rune": Color("d2b57a"), "hostile": Color("f27367")}

static func pixel(canvas: CanvasItem, rect: Rect2, color: Color):
	canvas.draw_rect(rect.grow(1), INK)
	canvas.draw_rect(rect, color)

static func stamp(canvas: CanvasItem, kind: String, center: Vector2, size: Vector2, tint: Color = Color.WHITE, angle: float = 0.0):
	canvas.draw_set_transform(center.round(), angle, size / 24.0)
	var color: Color = PALETTE.get(kind, PALETTE.impact) * tint
	match kind:
		"mana", "bolt", "lance", "ice":
			pixel(canvas, Rect2(-9, -2, 14, 4), color)
			pixel(canvas, Rect2(4, -4, 5, 8), color)
			canvas.draw_rect(Rect2(4, -1, 3, 2), Color("fff1d1") * tint)
		"plague":
			pixel(canvas, Rect2(-1, -2, 2, 10), color)
			pixel(canvas, Rect2(-7, -5, 6, 4), color)
			pixel(canvas, Rect2(1, -8, 6, 4), color)
		"stone":
			pixel(canvas, Rect2(-6, -5, 12, 10), color)
			canvas.draw_rect(Rect2(-4, -4, 7, 2), color.lightened(0.25))
		"spirit", "flame":
			pixel(canvas, Rect2(-5, -5, 10, 11), color)
			pixel(canvas, Rect2(-2, -9, 4, 4), color)
			if kind == "spirit":
				canvas.draw_rect(Rect2(-3, -2, 2, 2), INK)
				canvas.draw_rect(Rect2(2, -2, 2, 2), INK)
		"blade":
			pixel(canvas, Rect2(-10, -2, 20, 4), color)
			pixel(canvas, Rect2(-2, -10, 4, 20), color)
		"rune":
			canvas.draw_rect(Rect2(-9, -9, 18, 18), INK, false, 4)
			canvas.draw_rect(Rect2(-9, -9, 18, 18), color, false, 2)
			pixel(canvas, Rect2(-1, -5, 2, 10), color)
		"smoke", "hostile":
			pixel(canvas, Rect2(-5, -5, 10, 10), color)
		_:
			pixel(canvas, Rect2(-7, -1, 14, 2), color)
			pixel(canvas, Rect2(-1, -7, 2, 14), color)
	canvas.draw_set_transform(Vector2.ZERO)

static func beam(canvas: CanvasItem, start: Vector2, end: Vector2, width: float, opacity: float = 1.0):
	canvas.draw_line(start, end, Color(INK, opacity), width + 2)
	canvas.draw_line(start, end, Color(PALETTE.lightning, opacity), width)
	canvas.draw_line(start, end, Color("f0e8eb", opacity), maxf(1, width / 3))

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
