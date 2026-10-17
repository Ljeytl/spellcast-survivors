extends Node2D

var age := 0.0
var gentle := false
var visual_size := 1.0
var life := 0.68
var phase := 0.0

func _ready():
	add_to_group("healing_visuals")
	z_index = 7
	phase = randf() * TAU

func _process(delta):
	visible = get_parent()._active and get_parent().presenter.enabled
	age += delta
	if age >= life:
		queue_free()
	else:
		queue_redraw()

func _draw():
	var gather := clampf(age / 0.24, 0.0, 1.0)
	var release := clampf((age - 0.18) / (life - 0.18), 0.0, 1.0)
	var center := Vector2(0, 4)
	var power := 0.58 if gentle else 1.0
	var radius := lerpf(25.0 if gentle else 39.0, 4.0, 1.0 - pow(1.0 - gather, 2.0)) * visual_size
	var alpha := sin(gather * PI) * power
	for i in (3 if gentle else 6):
		var angle := phase + float(i) * TAU / (3.0 if gentle else 6.0)
		var tangent := Vector2.from_angle(angle + PI * 0.5)
		var direction := Vector2.from_angle(angle)
		var pos := center + direction * radius * Vector2(1, 0.65)
		var length := (7.0 if gentle else 11.0) * visual_size
		var leaf := PackedVector2Array([pos + direction * length, pos + tangent * length * 0.35, pos - direction * length * 0.6, pos - tangent * length * 0.35])
		draw_colored_polygon(leaf, Color(0.52, 0.93, 0.58, alpha * 0.9))
		draw_line(pos - direction * length * 0.4, pos + direction * length * 0.65, Color(0.90, 1.0, 0.71, alpha), 1.8, true)
	var beat := sin(release * PI) * (1.0 - release)
	if release > 0.0:
		for i in 3:
			draw_circle(center, (13.0 - i * 3.0) * visual_size, Color(0.63, 1.0, 0.65, beat * power * (0.09 + i * 0.04)))
		for i in (3 if gentle else 6):
			var x := sin(i * 2.4 + phase) * (8.0 + release * 9.0) * visual_size
			var pos := center + Vector2(x, -release * (23.0 + float(i % 3) * 8.0))
			draw_line(pos, pos + Vector2(0, 3.5), Color(0.91, 1.0, 0.73, beat * power), 1.5, true)
