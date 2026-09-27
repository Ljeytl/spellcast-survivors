extends SceneTree

func _initialize():
	run.call_deferred()

func run():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Visual Workshop"):
		quit(2)
		return
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(5000, 5000)
	root.size = Vector2i(960, 600)
	root.content_scale_size = Vector2i(1280, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("AudioManager").quitting = true
	var folder = "res://builds/projectile-readability/"
	DirAccess.make_dir_recursive_absolute(folder)
	var fixture = preload("res://tools/workshop/PreviewFixture.gd").new()
	fixture.settings.scenery = false
	for id in ["bolt", "mana_bolt", "life_bolt", "lightning_bolt", "ember_lance", "meteor_lance"]:
		paused = false
		Engine.time_scale = 1
		await fixture.setup(root, id)
		paused = true
		Engine.time_scale = 0
		for effect in get_nodes_in_group("projectile_visuals"):
			if effect.has_method("advance"):
				effect.advance(0.12)
			elif effect.get("direction") != null:
				effect.position += effect.direction * 84
		for effect in get_nodes_in_group("effect_bursts"):
			effect.age = 0.2
			effect.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder + id + ".png")
	paused = false
	Engine.time_scale = 1
	fixture.game.free()
	quit()
