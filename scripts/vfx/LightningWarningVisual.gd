extends Node2D

var mark_ref: WeakRef
var vfx
var radius := 100.0
var duration := 0.32
var charge := 0.0

func setup(part, owner_vfx) -> void:
	vfx = owner_vfx
	mark_ref = weakref(part)
	position = part.global_position
	radius = maxf(10.0, part.geo("radius", 100.0))
	duration = maxf(0.01, part.total_life())

func _ready() -> void:
	add_to_group("lightning_visuals")
	top_level = true
	z_index = -1

func _process(_delta: float) -> void:
	var mark = mark_ref.get_ref()
	if not vfx.presenter.enabled or not is_instance_valid(mark) or mark.done:
		queue_free()
		return
	charge = clampf(float(mark.age) / duration, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var alpha := lerpf(0.5, 1.0, smoothstep(0.0, 0.25, charge))
	draw_circle(Vector2.ZERO, radius, Color(0.12, 0.4, 1.0, 0.06 * alpha))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(0.2, 0.65, 1.0, alpha), 2.0, true)
	draw_arc(Vector2.ZERO, radius * lerpf(1.1, 0.88, charge), -PI * 0.5, -PI * 0.5 + TAU * charge, 80, Color(0.65, 0.92, 1.0, alpha), 1.5, true)
	for i in 8:
		var a := float(i) * TAU / 8.0
		draw_line(Vector2.from_angle(a) * radius * 0.94, Vector2.from_angle(a) * radius, Color(0.7, 0.95, 1.0, alpha), 1.5, true)
