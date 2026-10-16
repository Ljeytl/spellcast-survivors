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
	DirAccess.make_dir_recursive_absolute("res://builds/hybrid-spirit/game-motion")
	await setup()
	var stage := SubViewport.new()
	stage.size = Vector2i(1280, 850)
	stage.disable_3d = true
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var manager = game.spell_manager
	assert(manager.learn_spell("seeker"))
	assert(manager.cast_spell_by_type(manager.find_spell_slot("seeker")))
	for id in ["infestation", "regeneration", "soul_bloom"]:
		assert(manager.learn_spell(id))
	var victim = get_nodes_in_group("enemies")[0]
	victim.current_health = 1.0
	assert(manager.cast_spell_by_type(manager.find_spell_slot("soul_bloom")))
	var saw_seeker := false
	var saw_soul := false
	for frame in range(150):
		await physics_frame
		await process_frame
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		for visual in get_nodes_in_group("spirit_visuals"):
			saw_seeker = saw_seeker or not visual.soul
			saw_soul = saw_soul or visual.soul
		await RenderingServer.frame_post_draw
		if frame % 2 == 0:
			stage.get_texture().get_image().save_png("res://builds/hybrid-spirit/game-motion/%04d.png" % (frame / 2))
		if frame in [10, 30, 60, 90, 120]:
			stage.get_texture().get_image().save_png("res://builds/hybrid-spirit/game-%03d.png" % frame)
	print("GAME_HOSTS seeker=", saw_seeker, " soul=", saw_soul)
	stage.queue_free()
	await teardown()
	quit(0 if saw_seeker and saw_soul else 1)
