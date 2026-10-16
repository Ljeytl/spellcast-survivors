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
	await create_timer(1.0).timeout
	var stage := SubViewport.new()
	stage.size = Vector2i(1280, 850)
	stage.disable_3d = true
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	game.camera_shake.follow_offset = game.camera.global_position - game.player.global_position
	game.camera_shake.set_process(true)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	assert(game.spell_manager.learn_spell("lightning"))
	assert(game.spell_manager.cast_spell_by_type(game.spell_manager.find_spell_slot("lightning")))
	var cast = game.spell_manager.last_generic_cast
	var saw_strike := false
	var camera_origin: Vector2 = game.camera.global_position
	var max_follow_drift := 0.0
	var max_shake_offset := 0.0
	var samples: Array = []
	print("LIGHTNING_PLAN ", JSON.stringify(cast.plan))
	print("LIGHTNING_TYPING ", game.spell_manager.current_typing_text)
	for frame in range(150):
		await physics_frame
		await process_frame
		max_follow_drift = maxf(max_follow_drift, game.camera.global_position.distance_to(camera_origin))
		max_shake_offset = maxf(max_shake_offset, game.camera.offset.length())
		samples.append({"frame": frame, "position": [game.camera.global_position.x, game.camera.global_position.y], "offset": [game.camera.offset.x, game.camera.offset.y], "shake_left": game.camera_shake.shake_timer})
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		if is_instance_valid(cast):
			for part in cast.parts:
				saw_strike = saw_strike or part.part_name == "strike"
		await RenderingServer.frame_post_draw
		if frame % 2 == 0:
			stage.get_texture().get_image().save_png("res://builds/lightning-feel/%04d.png" % (frame / 2))
	var evidence = FileAccess.open("res://builds/lightning-feel/camera.json", FileAccess.WRITE)
	evidence.store_string(JSON.stringify({"max_follow_drift": max_follow_drift, "max_shake_offset": max_shake_offset, "final_offset": game.camera.offset.length(), "samples": samples}))
	print("LIGHTNING_CAPTURE struck=", saw_strike, " drift=", max_follow_drift, " max_shake=", max_shake_offset, " final_offset=", game.camera.offset.length())
	assert(max_follow_drift < 0.01)
	assert(game.camera.offset.length() < 0.01)
	stage.queue_free()
	await teardown()
	quit(0 if saw_strike else 1)
