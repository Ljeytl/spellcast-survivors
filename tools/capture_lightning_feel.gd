extends "res://tools/capture_spell_gallery.gd"

func _initialize() -> void:
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	root.hide()
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280, 850)
	root.content_scale_size = Vector2i(1280, 850)
	root.get_node("AudioManager").quitting = true
	DirAccess.make_dir_recursive_absolute("res://builds/lightning-feel")
	await setup()
	var stage := SubViewport.new()
	stage.size = Vector2i(1280, 850)
	stage.disable_3d = true
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	game.camera_shake.set_process(true)
	assert(game.spell_manager.learn_spell("lightning"))
	assert(game.spell_manager.cast_spell_by_type(game.spell_manager.find_spell_slot("lightning")))
	var cast = game.spell_manager.last_generic_cast
	var saw_strike := false
	for frame in range(150):
		await physics_frame
		await process_frame
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		for visual in get_nodes_in_group("lightning_visuals"):
			saw_strike = saw_strike or visual.struck
		await RenderingServer.frame_post_draw
		if frame % 2 == 0:
			stage.get_texture().get_image().save_png("res://builds/lightning-feel/%04d.png" % (frame / 2))
	print("LIGHTNING_CAPTURE struck=", saw_strike)
	stage.queue_free()
	await teardown()
	quit(0 if saw_strike else 1)
