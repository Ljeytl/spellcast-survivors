extends SceneTree

func _initialize():
	run.call_deferred()

func run():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Visual Workshop"):
		quit(2)
		return
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(5000, 5000)
	root.get_node("AudioManager").quitting = true
	var folder = "res://builds/healing-capture/"
	DirAccess.make_dir_recursive_absolute(folder)
	var fixture = preload("res://tools/workshop/PreviewFixture.gd").new()
	if "--baseline" in OS.get_cmdline_user_args():
		fixture.settings.zoom = 1.5
	for width in [1280, 800]:
		root.size = Vector2i(width, 800 if width == 1280 else 600)
		root.content_scale_size = root.size
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		for id in ["bolt", "regeneration", "regeneration-full", "life"]:
			paused = false
			Engine.time_scale = 1
			await fixture.setup(root, id.trim_suffix("-full"))
			if id == "regeneration-full":
				fixture.game.player.health = fixture.game.player.max_health
			elif id == "regeneration":
				fixture.game.player.next_heal_feedback_msec = 0
				fixture.advance(0.2)
			paused = true
			Engine.time_scale = 0
			for effect in get_nodes_in_group("effect_bursts"):
				effect.age = 0.2
				effect.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder + id + "-" + str(width) + ".png")
		paused = false
		Engine.time_scale = 1
		await fixture.setup(root, "regeneration")
		fixture.game.get_node("UI").show()
		fixture.game.spell_manager.start_freeform_typing()
		fixture.game.spell_manager.current_typing_text = "regeneration"
		fixture.game.spell_manager.update_freeform_typing_display()
		for frame in range(20):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder + "typing-" + str(width) + ".png")
		fixture.game.spell_manager.end_typing()
	paused = false
	Engine.time_scale = 1
	fixture.game.free()
	quit()
