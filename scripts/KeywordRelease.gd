extends Node2D
var tint := Color("ffe49b")
var age := 0.0
func _process(delta):
	age += delta
	if age >= 0.18:
		queue_free()
	queue_redraw()
func _draw():
	var color = tint
	color.a = maxf(0, 1-age/0.18)
	draw_arc(Vector2.ZERO, 10+age/0.18*32, 0, TAU, 28, color, 2.5)
