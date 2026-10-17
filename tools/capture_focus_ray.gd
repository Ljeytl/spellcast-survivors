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
	var folder = args[0]
	var rank = int(args[1]) if args.size() > 1 else 1
	var events: Array = []
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"type":"audio", "event":event, "movie_frame":Engine.get_frames_drawn()}))
	await setup()
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000, 10000)
	root.size = Vector2i(720, 850) if args.has("narrow") else Vector2i(1280, 850)
	root.content_scale_size = root.size
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position + Vector2(100, 0)
	game.camera.force_update_scroll()
	assert(game.spell_manager.learn_spell("focus_ray"))
	var slot = game.spell_manager.find_spell_slot("focus_ray")
	game.spell_manager.get_spell_info(slot).level = rank
	var foes = get_nodes_in_group("enemies")
	var origin: Vector2 = game.player.position
	var casts: Array = []
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	DirAccess.make_dir_recursive_absolute(folder)
	for frame in 240:
		if frame == 12 or (rank == 8 and frame in [24, 36]):
			assert(game.spell_manager.cast_spell_by_type(slot))
			casts.append(game.spell_manager.last_generic_cast)
		if frame == 48:
			for enemy in foes:
				enemy.global_position = origin + Vector2(800, 0)
		if frame == 72:
			for i in foes.size():
				foes[i].global_position = origin + Vector2(200, 65 * (i - 1))
		if frame == 96:
			foes[0].current_health = 0
		if args.has("moving"):
			game.player.position += Vector2(0.15, sin(frame / 20.0) * 0.15)
		await physics_frame
		await process_frame
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		var beams: Array = []
		for cast in casts:
			if is_instance_valid(cast):
				for part in cast.root_parts():
					beams.append({"end":str(part.beam_end), "hits":part.hit_count, "remaining":part.remaining_life()})
		events.append({"type":"frame", "frame":frame, "movie_frame":Engine.get_frames_drawn(), "beams":beams})
		if frame % 2 == 0:
			assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) == OK)
	FileAccess.open(folder + "/events.json", FileAccess.WRITE).store_string(JSON.stringify(events, "\t"))
	print("FOCUS_CAPTURE rank=", rank, " frames=120")
	stage.queue_free()
	await teardown()
	quit()
