extends Node2D
## Ground telegraph for a stampede (scripts/Stampede.gd): the lane's edges, a translucent band and
## chevrons running the way the herd will come. Pulses while warning, fades once the herd is through.

var direction := Vector2.RIGHT
var length := 1000.0
var width := 260.0
var warning := 2.5
var age := 0.0
var fade := -1.0      # >0: fading out over this many seconds
var fade_total := 1.0

func setup(p_origin: Vector2, p_direction: Vector2, p_length: float, p_width: float, p_warning: float) -> void:
	global_position = p_origin
	direction = p_direction
	rotation = p_direction.angle()
	length = p_length
	width = p_width
	warning = p_warning
	z_index = -1

func _ready():
	add_to_group("stampede_lanes")

func release(seconds: float) -> void:
	fade = maxf(0.05, seconds)
	fade_total = fade

func _process(delta):
	age += delta
	if fade > 0.0:
		fade -= delta
		if fade <= 0.0:
			queue_free()
	queue_redraw()

func _draw():
	var alpha := 1.0
	if fade > 0.0:
		alpha = clampf(fade / fade_total, 0.0, 1.0)
	var pulse = 0.5 + 0.5 * sin(age * TAU * 2.0) if age < warning else 0.6
	var half = width * 0.5
	draw_rect(Rect2(0, -half, length, width), Color(0.55, 0.32, 0.12, 0.16 * alpha * (0.6 + 0.4 * pulse)))
	for side in [-1.0, 1.0]:
		draw_line(Vector2(0, side * half), Vector2(length, side * half), Color(0.08, 0.04, 0.0, 0.5 * alpha), 5.0)
		draw_line(Vector2(0, side * half), Vector2(length, side * half), Color(1.0, 0.72, 0.3, 0.75 * alpha * (0.5 + 0.5 * pulse)), 2.5)
	var spacing = 120.0
	var shift = fmod(age * 260.0, spacing)
	var x = shift
	while x < length:
		var c = Color(1.0, 0.8, 0.35, 0.5 * alpha * (0.5 + 0.5 * pulse))
		draw_polyline(PackedVector2Array([Vector2(x - 26, -38), Vector2(x, 0), Vector2(x - 26, 38)]), c, 5.0)
		x += spacing
