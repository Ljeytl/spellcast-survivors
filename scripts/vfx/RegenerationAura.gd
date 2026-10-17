extends Node2D

var part_ref: WeakRef
var age := 0.0
var visual_size := 1.0
var fading := false
var fade := 1.0

func _ready():
	add_to_group("healing_visuals")
	z_index = 2

func _process(delta):
	visible = get_parent()._active and get_parent().presenter.enabled
	age += delta
	var part = part_ref.get_ref() if part_ref else null
	if not is_instance_valid(part) or part.done or not is_instance_valid(part.cast.caster) or part.cast.caster.health <= 0:
		fading = true
	if fading:
		fade -= delta * 4.0
		if fade <= 0.0:
			queue_free()
			return
	else:
		global_position = part.cast.caster.global_position
	queue_redraw()

func _draw():
	var breath := 0.5 + 0.5 * sin(age * 2.5)
	for i in 4:
		var angle := age * 0.35 + float(i) * TAU / 4.0
		var radius := (22.0 + breath * 3.0) * visual_size
		var pos := Vector2(cos(angle) * radius, sin(angle) * radius * 0.45 - 3.0)
		var axis := Vector2.from_angle(angle + 0.9)
		var side := axis.orthogonal()
		var leaf := PackedVector2Array([pos + axis * 5.0, pos + side * 2.0, pos - axis * 4.0, pos - side * 1.5])
		draw_colored_polygon(leaf, Color(0.43, 0.83, 0.50, (0.30 + breath * 0.15) * fade * minf(1.0, age * 5.0)))
		draw_line(pos - axis * 3.0, pos + axis * 3.0, Color(0.78, 0.98, 0.66, 0.45 * fade), 1.0, true)
