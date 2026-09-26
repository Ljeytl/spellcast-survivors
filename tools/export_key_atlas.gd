extends SceneTree

func _initialize():
	export_atlas("stone-key-atlas.png", "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 4, false)
	export_atlas("stone-symbol-atlas.png", "0123456789-_/\\+=[]{}',?.:;!~`$#@%^&*()<>|\"", 6, true)
	quit()

func export_atlas(filename: String, glyphs: String, rows: int, numeric_names: bool):
	var source = Image.load_from_file("res://art_sources/" + filename)
	var bounds = source.get_used_rect()
	for index in range(glyphs.length()):
		var x0 = bounds.position.x + roundi(bounds.size.x * (index % 8) / 8.0)
		var x1 = bounds.position.x + roundi(bounds.size.x * ((index % 8) + 1) / 8.0)
		var y0 = bounds.position.y + roundi(bounds.size.y * (index / 8) / float(rows))
		var y1 = bounds.position.y + roundi(bounds.size.y * ((index / 8) + 1) / float(rows))
		var key = source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
		key.resize(32, 32, Image.INTERPOLATE_NEAREST)
		var name = "u%04x" % glyphs.unicode_at(index) if numeric_names else glyphs[index]
		key.save_png("res://assets/typecast/Keys/%s.png" % name)
