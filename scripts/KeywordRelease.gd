extends Node2D
var tint := Color("ffe49b")
var age := 0.0
func _process(delta):
	age += delta
	if age >= 0.3:
		queue_free()
	queue_redraw()
func _draw():
	var color = tint
	color.a = maxf(0, 1-age/0.3)
	draw_arc(Vector2.ZERO, 12+age/0.3*72, 0, TAU, 40, color, 3.5)
	draw_arc(Vector2.ZERO, 8+age/0.3*44, 0, TAU, 32, color, 2.0)
