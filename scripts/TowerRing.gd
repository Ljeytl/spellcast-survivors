extends Node2D

var angle = 0.0

func _draw():
	var outer = PackedVector2Array()
	for i in 97:
		outer.append(Vector2(sin(i * TAU / 96), -cos(i * TAU / 96)) * Vector2(455, 305))
	draw_polyline(outer, Color("30313c"), 28, true)
	draw_polyline(outer, Color("737978"), 20, true)
	for i in 48:
		var phase = i * TAU / 48 + angle
		var direction = Vector2(sin(phase), -cos(phase))
		draw_line(direction * Vector2(443, 293), direction * Vector2(467, 317), Color("34353f"), 3)
