extends Control

var spell_id = "bolt"

func _draw():
	var center = Vector2(40, 40)
	# Glyph and colour are data (presentation.preview); new spells default by element and shape.
	var preview: Dictionary = preload("res://scripts/engine/SpellCatalog.gd").preview(spell_id)
	var color = Color(str(preview.color))
	draw_circle(center, 36, Color("202e40"))
	match str(preview.glyph):
		"cross":
			draw_line(center - Vector2(17, 0), center + Vector2(17, 0), color, 8, true)
			draw_line(center - Vector2(0, 17), center + Vector2(0, 17), color, 8, true)
		"cone":
			draw_colored_polygon(PackedVector2Array([Vector2(16, 40), Vector2(64, 14), Vector2(64, 66)]), Color(color, 0.65))
		"zigzag":
			draw_polyline(PackedVector2Array([Vector2(20, 60), Vector2(36, 32), Vector2(49, 48), Vector2(62, 18)]), color, 5, true)
		"ring":
			draw_arc(center, 23, 0, TAU, 40, color, 4, true)
			draw_circle(center, 11, Color(color, 0.5))
		"rocks":
			draw_colored_polygon(PackedVector2Array([Vector2(18,24),Vector2(34,18),Vector2(38,43),Vector2(26,52),Vector2(16,40)]), Color("9d8253"))
			draw_colored_polygon(PackedVector2Array([Vector2(38,48),Vector2(66,24),Vector2(68,64)]), Color("d8b979"))
		"beam":
			draw_line(Vector2(12, 62), Vector2(66, 18), Color(color, 0.3), 14, true)
			draw_line(Vector2(12, 62), Vector2(66, 18), color, 4, true)
		"meteors":
			for point in [Vector2(23, 28), Vector2(52, 45), Vector2(29, 60)]:
				draw_line(point - Vector2(10, 15), point, color, 3, true)
				draw_circle(point, 6, color)
		"arc":
			draw_arc(center, 23, -PI, PI / 2, 32, color, 5, true)
		_:
			draw_line(Vector2(16, 60), Vector2(48, 32), Color(color, 0.5), 7, true)
			draw_circle(Vector2(49, 30), 12, color)
