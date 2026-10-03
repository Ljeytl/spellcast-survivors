extends Node2D
## One ley-line site in the world. LeyLines owns the logic; this node stores the
## site's progress and draws it.

enum State { DORMANT, SIEGE, GUARDIAN, ATTUNED }

## Big enough to move and fight inside while typing words.
const RADIUS = 340.0
const COLORS = {
	State.DORMANT: Color("b48cff"),
	State.SIEGE: Color("e2d0ff"),
	State.GUARDIAN: Color("ff8175"),
	State.ATTUNED: Color("f7d87a"),
}

var state: int = State.DORMANT
var words: Array[String] = []
var bound: Array[String] = []
var wave_timer := 0.0
## Waves earned (wake + bound words) but not yet sent.
var pending_waves := 0
## Monsters from this site's latest wave; the next word waits until they are (mostly) down.
var wave_members: Array = []
var guardian: Node = null
var dwell := 0.0
var spin := 0.0

func _ready():
	add_to_group("ley_sites")
	# An attuned circle holds the combo like a channelled spell: no decay inside it.
	add_to_group("style_holds")
	z_index = -1

func contains(point: Vector2) -> bool:
	return global_position.distance_to(point) <= RADIUS

func is_style_channel_active() -> bool:
	return state == State.ATTUNED and player_inside()

func player_inside() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	return is_instance_valid(player) and contains(player.global_position)

## Rune circle: five counter-rotating layers drawn additively (a glyph ring, a tick
## ring, a hexagram, crossed squares, a pulsing core). Geometry is authored at an
## outer radius of 560 and scaled to RADIUS. Spin and glow rise with `charge`.
const RUNE_SIZE = 560.0
## [bright, deep] per state.
const THEMES = {
	State.DORMANT: [Color("8fe9ff"), Color("b98cff")],
	State.SIEGE: [Color("8fe9ff"), Color("b98cff")],
	State.GUARDIAN: [Color("ffd27a"), Color("ff5a1f")],
	State.ATTUNED: [Color("fff2b8"), Color("f7b54a")],
}
const STROKES = [[0, -1, 1, -0.4], [0, -1, -1, -0.4], [0, 0, 1, 0.5], [0, 0, -1, 0.5], [0, 1, 1, 0.4], [0, -0.3, 0.8, -0.9], [-0.7, -0.2, 0.7, -0.2], [0, 0.2, -0.8, 1], [0, -1, 0.6, -1]]

var time := 0.0
var charge := 0.0
var flash := 0.0
var glyphs: Array = []
var rune: Node2D
var layers: Array = []
var core: Node2D

func _enter_tree():
	if rune:
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	for i in 24:
		var picks: Array = []
		while picks.size() < 1 + rng.randi() % 3:
			var k = rng.randi() % STROKES.size()
			if k not in picks:
				picks.append(k)
		glyphs.append(picks.map(func(k): return STROKES[k]))
	rune = Node2D.new()
	rune.name = "Rune"
	rune.scale = Vector2.ONE * RADIUS / RUNE_SIZE
	var additive = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	rune.material = additive
	add_child(rune)
	for draw_fn in [draw_glyph_ring, draw_tick_ring, draw_hexagram, draw_squares, draw_core]:
		var layer = Node2D.new()
		layer.use_parent_material = true
		layer.draw.connect(draw_fn.bind(layer))
		rune.add_child(layer)
		layers.append(layer)
	core = layers[4]

## A word was bound or the site changed state: brief bright flash.
func pulse_flash():
	flash = 1.0

func target_charge() -> float:
	match state:
		State.SIEGE:
			return 0.25 + 0.75 * float(bound.size()) / maxf(1.0, float(words.size()))
		State.GUARDIAN:
			return 1.0
		State.ATTUNED:
			return 0.1
	return 0.0

func _process(delta):
	time += delta
	charge = move_toward(charge, target_charge(), delta * 0.8)
	flash = maxf(0.0, flash - delta * 1.8)
	var spin = 1.0 + charge * 6.0
	layers[0].rotation += delta * 0.08 * spin
	layers[1].rotation -= delta * 0.25 * spin
	layers[2].rotation += delta * 0.15 * spin
	layers[3].rotation -= delta * 0.4 * spin
	layers[4].rotation += delta * 0.6 * spin
	var p = 1.0 + 0.06 * sin(time * 3.0) + charge * 0.3
	core.scale = Vector2(p, p)
	rune.scale = Vector2.ONE * RADIUS / RUNE_SIZE * (1.0 + charge * 0.06)
	var dim = 0.55 if state == State.DORMANT else 1.0
	rune.modulate = Color(dim, dim, dim, 1.0) * (1.0 + flash * 0.8)
	if state != _drawn_state:
		_drawn_state = state
		for layer in layers:
			layer.queue_redraw()
	queue_redraw()

var _drawn_state := -1

## Faint fill so the circle reads as an area to stand in.
func _draw():
	var deep: Color = THEMES[state][1]
	draw_circle(Vector2.ZERO, RADIUS, Color(deep, 0.07 + 0.05 * charge))
	if flash > 0.0:
		for i in 6:
			draw_circle(Vector2.ZERO, RADIUS * (0.3 + i * 0.14), Color(THEMES[state][0], 0.05 * flash))

## Glowing stroke: a wide faint pass under a thin bright one.
func glow_line(layer: Node2D, a: Vector2, b: Vector2, color: Color, width: float):
	layer.draw_line(a, b, Color(color, 0.18), width * 4.0)
	layer.draw_line(a, b, color, width)

func glow_circle(layer: Node2D, center: Vector2, radius: float, color: Color, width: float):
	layer.draw_arc(center, radius, 0, TAU, 96, Color(color, 0.18), width * 4.0)
	layer.draw_arc(center, radius, 0, TAU, 96, color, width)

func glow_poly(layer: Node2D, sides: int, radius: float, rot: float, color: Color, width: float):
	for i in sides:
		var a = Vector2.from_angle(rot + i * TAU / sides) * radius
		var b = Vector2.from_angle(rot + (i + 1) * TAU / sides) * radius
		glow_line(layer, a, b, color, width)

func draw_glyph_ring(layer: Node2D):
	var bright: Color = THEMES[state][0]
	var deep: Color = THEMES[state][1]
	glow_circle(layer, Vector2.ZERO, 560, deep, 4)
	glow_circle(layer, Vector2.ZERO, 470, deep, 3)
	for i in glyphs.size():
		var angle = i * TAU / glyphs.size()
		var t = Transform2D(angle, Vector2.ZERO) * Transform2D(0, Vector2(0, -515))
		var k = 26.0
		glow_line(layer, t * Vector2(0, -k), t * Vector2(0, k), bright, 5)
		for st in glyphs[i]:
			glow_line(layer, t * Vector2(st[0] * k * 0.6, st[1] * k), t * Vector2(st[2] * k * 0.6, st[3] * k), bright, 5)

func draw_tick_ring(layer: Node2D):
	var bright: Color = THEMES[state][0]
	var deep: Color = THEMES[state][1]
	for i in 72:
		var dir = Vector2.from_angle(i * PI / 36.0 - PI / 2.0)
		layer.draw_line(dir * 445, dir * (430 if i % 6 else 410), bright, 3)
	for i in 8:
		glow_circle(layer, Vector2.from_angle(i * PI / 4.0 - PI / 2.0) * 395, 14, bright, 3)
	glow_circle(layer, Vector2.ZERO, 375, deep, 2)

func draw_hexagram(layer: Node2D):
	var bright: Color = THEMES[state][0]
	var deep: Color = THEMES[state][1]
	glow_poly(layer, 3, 360, -PI / 2.0, deep, 4)
	glow_poly(layer, 3, 360, PI / 2.0, deep, 4)
	glow_circle(layer, Vector2.ZERO, 180, bright, 3)

func draw_squares(layer: Node2D):
	var bright: Color = THEMES[state][0]
	glow_poly(layer, 4, 250, PI / 4.0, bright, 4)
	glow_poly(layer, 4, 250, 0.0, bright, 4)
	for i in 8:
		glow_circle(layer, Vector2.from_angle(i * PI / 4.0) * 250, 10, bright, 4)

func draw_core(layer: Node2D):
	var bright: Color = THEMES[state][0]
	var points = PackedVector2Array()
	for i in 65:
		var a = i * TAU / 64.0
		points.append(Vector2(cos(a) * 110, sin(a) * 55))
	layer.draw_polyline(points, Color(bright, 0.18), 20)
	layer.draw_polyline(points, bright, 5)
	glow_circle(layer, Vector2.ZERO, 38, bright, 5)
	layer.draw_circle(Vector2.ZERO, 12 + charge * 20, bright)
	for seg in [[Vector2(-150, 0), Vector2(-115, 0)], [Vector2(115, 0), Vector2(150, 0)], [Vector2(0, -90), Vector2(0, -60)], [Vector2(0, 60), Vector2(0, 90)]]:
		glow_line(layer, seg[0], seg[1], bright, 5)
