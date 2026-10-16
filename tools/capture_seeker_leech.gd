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
	DirAccess.make_dir_recursive_absolute("res://builds/seeker-leech")
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
	var saw_return := false
	var healed := false
	var full_spirit = null
	var result := {"burst": false}
	var initial_health: float = game.player.health
	for frame in range(240):
		if frame == 120:
			game.player.health = game.player.max_health
			assert(manager.cast_spell_by_type(manager.find_spell_slot("seeker")))
			full_spirit = manager.last_generic_cast.parts[0]
			full_spirit.tree_exiting.connect(func(): result.burst = full_spirit.done and full_spirit.hit_count > 0 and not full_spirit.returning_life)
		await physics_frame
		await process_frame
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		for spirit in get_nodes_in_group("engine_spirits"):
			saw_return = saw_return or spirit.returning_life
		if frame < 120:
			healed = healed or game.player.health > initial_health
		await RenderingServer.frame_post_draw
		if frame % 2 == 0:
			stage.get_texture().get_image().save_png("res://builds/seeker-leech/%04d.png" % (frame / 2))
	print("SEEKER_CAPTURE return=", saw_return, " healed=", healed, " full_burst=", result.burst, " health=", game.player.health)
	stage.queue_free()
	await teardown()
	quit(0 if saw_return and healed and result.burst else 1)
