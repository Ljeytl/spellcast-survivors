extends SceneTree

func _initialize():
	var source = Image.load_from_file("res://art_sources/mana-crystal.png")
	var crystal = source.get_region(source.get_used_rect())
	crystal.resize(16, 24, Image.INTERPOLATE_NEAREST)
	var sprite = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	sprite.blit_rect(crystal, Rect2i(0, 0, 16, 24), Vector2i(4, 0))
	sprite.save_png("res://assets/typecast/Pickups/Mana Crystal.png")
	quit()
