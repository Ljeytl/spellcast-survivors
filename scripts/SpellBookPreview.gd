extends Control

var spell_id = "bolt"

func _draw():
	var center = Vector2(40, 40)
	var color = Color("bc8fff")
	if spell_id in ["life", "regeneration", "life_bolt", "plague_seed", "soul_bloom"]:
		color = Color("91de83")
	elif spell_id in ["ice_blast", "frost_sigil", "steam_field"]:
		color = Color("8ce6ee")
	elif spell_id in ["ember_lance", "cinder_field", "meteor_shower", "meteor_lance", "ember_trail"]:
		color = Color("ffa66b")
	elif spell_id in ["lightning_arc", "lightning_bolt"]:
		color = Color("f4ed96")
	draw_circle(center, 36, Color("202e40"))
	match spell_id:
		"life", "regeneration":
			draw_line(center - Vector2(17, 0), center + Vector2(17, 0), color, 8, true)
			draw_line(center - Vector2(0, 17), center + Vector2(0, 17), color, 8, true)
		"ice_blast":
			draw_colored_polygon(PackedVector2Array([Vector2(16, 40), Vector2(64, 14), Vector2(64, 66)]), Color(color, 0.65))
		"lightning_arc", "lightning_bolt":
			draw_polyline(PackedVector2Array([Vector2(20, 60), Vector2(36, 32), Vector2(49, 48), Vector2(62, 18)]), color, 5, true)
		"cinder_field", "steam_field", "rune_trap", "frost_sigil", "earth_shield", "arcane_orbit":
			draw_arc(center, 23, 0, TAU, 40, color, 4, true)
			draw_circle(center, 11, Color(color, 0.5))
		"focus_ray", "prism_ray", "ember_lance", "meteor_lance":
			draw_line(Vector2(12, 62), Vector2(66, 18), Color(color, 0.3), 14, true)
			draw_line(Vector2(12, 62), Vector2(66, 18), color, 4, true)
		"meteor_shower", "ember_trail":
			for point in [Vector2(23, 28), Vector2(52, 45), Vector2(29, 60)]:
				draw_line(point - Vector2(10, 15), point, color, 3, true)
				draw_circle(point, 6, color)
		"returning_blade":
			draw_arc(center, 23, -PI, PI / 2, 32, color, 5, true)
		_:
			draw_line(Vector2(16, 60), Vector2(48, 32), Color(color, 0.5), 7, true)
			draw_circle(Vector2(49, 30), 12, color)
