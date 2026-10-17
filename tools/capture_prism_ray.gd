extends "res://tools/capture_spell_gallery.gd"

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var args = OS.get_cmdline_user_args()
	if args.size() < 2 or not args[1].is_valid_int() or int(args[1]) < 1 or int(args[1]) > 8:
		printerr("Usage: capture_prism_ray output_directory rank[1..8] [moving large reduced narrow]")
		quit(2)
		return
	var folder = args[0]
	var rank = int(args[1])
	await setup()
	root.size = Vector2i(720, 850) if args.has("narrow") else Vector2i(1280, 850)
	root.content_scale_size = root.size
	root.get_node("Vfx").reduced_effects = args.has("reduced")
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position + Vector2(150, 0)
	game.camera.force_update_scroll()
	assert(game.spell_manager.learn_spell("focus_ray"))
	assert(game.spell_manager.learn_spell("ember_spear"))
	assert(game.spell_manager.learn_spell("prism_ray"))
	var slot = game.spell_manager.find_spell_slot("prism_ray")
	game.spell_manager.get_spell_info(slot).level = rank
	var hit_count := 0
	var cast
	var max_rays := 0
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	DirAccess.make_dir_recursive_absolute(folder)
	var events: Array = []
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"audio":event,"movie_frame":Engine.get_frames_drawn()}))
	var start = game.player.global_position
	for frame in 210:
		if frame == 12:
			assert(game.spell_manager.cast_spell_by_type(slot, 1.7 if args.has("large") else 1.0))
			cast = game.spell_manager.last_generic_cast
		if args.has("moving") and frame > 40 and frame < 120:
			game.player.global_position = start + Vector2(0, (frame - 40) * 0.6)
		await physics_frame
		await process_frame
		if is_instance_valid(cast):
			hit_count = maxi(hit_count, cast.hits_log.size())
		max_rays = maxi(max_rays, root.get_node("Vfx").presenter._lasers.size())
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if frame % 2 == 0:
			assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) == OK)
			events.append({"png":frame / 2,"movie_frame":Engine.get_frames_drawn()})
	FileAccess.open(folder + "/events.json", FileAccess.WRITE).store_string(JSON.stringify(events,"\t"))
	assert(hit_count > 0)
	assert(max_rays >= 6)
	print("PRISM_CAPTURE checks=2 hits=", hit_count, " max_rays=", max_rays)
	cast = null
	stage.queue_free()
	await teardown()
	quit()
