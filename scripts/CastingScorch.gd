extends Node2D
## The sealed rune rings left burned into the ground where a spell was cast; fades in about 1.4s.
## Real-time fade, since typing slows Engine.time_scale.

var radii: Array = []
var color = Color.WHITE
var life = 1.0
var duration = 1.4
var spin = 0.0
var last_ticks = 0

func _ready():
	z_as_relative = false
	z_index = -2
	process_mode = Node.PROCESS_MODE_ALWAYS
	var additive = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	last_ticks = Time.get_ticks_usec()

func _process(_delta):
	var now = Time.get_ticks_usec()
	var dt = clampf((now - last_ticks) / 1000000.0, 0.0, 0.1)
	last_ticks = now
	life -= dt / duration
	spin += dt * 0.4
	if life <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw():
	var a = clampf(life, 0.0, 1.0)
	for i in radii.size():
		var r = float(radii[i])
		draw_arc(Vector2.ZERO, r, 0, TAU, 72, Color(color.r, color.g, color.b, 0.45 * a), 1.5, true)
		var start = spin * (-1.0 if i % 2 == 1 else 1.0)
		for t in 12:
			var ang = start + t * TAU / 12.0
			draw_line(Vector2.from_angle(ang) * (r - 3.0), Vector2.from_angle(ang) * (r + 3.0), Color(color.r, color.g, color.b, 0.35 * a), 1.0, true)
