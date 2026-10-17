extends "res://tools/capture_spell_gallery.gd"

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	root.position = Vector2i(10000, 10000)
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var args = OS.get_cmdline_user_args()
	var events: Array = []
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"type": "audio", "movie_frame": Engine.get_frames_drawn(), "event": event}))
	var label = args[0] if args.size() else "after"
	var rank = int(args[1]) if args.size() > 1 else 1
	await setup()
	await create_timer(1.0).timeout
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000, 10000)
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	root.get_node("Vfx").clear()
	root.get_node("Vfx").reduced_effects = args.has("reduced")
	if args.has("narrow"):
		root.size = Vector2i(620, 850)
		root.content_scale_size = root.size
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position
	game.camera.force_update_scroll()
	assert(game.spell_manager.learn_spell("firewalk"))
	var slot = game.spell_manager.find_spell_slot("firewalk")
	game.spell_manager.get_spell_info(slot).level = rank
	if args.has("fast"):
		game.player.projectile_speed_multiplier = 2.0
	var foes = get_nodes_in_group("enemies")
	for i in foes.size():
		foes[i].global_position = game.player.global_position + Vector2.from_angle(float(i) / foes.size() * TAU) * (400.0 if args.has("empty") else (100.0 if i < 3 else 0.0))
	if args.has("contact"):
		for i in foes.size():
			foes[i].global_position = game.player.global_position + Vector2.from_angle(float(i + 1) / foes.size() * TAU) * 130.0
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var folder = "res://builds/firewalk/" + label + "-" + str(rank)
	DirAccess.make_dir_recursive_absolute(folder)
	var origin = game.player.position
	for frame in 900:
		if frame == 12 or (frame == 180 and args.has("recast")) or (frame == 420 and args.has("resume")):
			assert(game.spell_manager.cast_spell_by_type(slot, 1.7 if args.has("large") else 1.0))
		if args.has("moving"):
			if frame < 270:
				game.player.position = origin + Vector2(cos(float(frame) / 270.0 * TAU), sin(float(frame) / 270.0 * TAU)) * 130.0
			elif frame < 360 or (frame >= 420 and frame < 570 and args.has("resume")):
				game.player.position += Vector2(1.5, 0.0)
		if args.has("narrow") and frame >= 360:
			game.camera.position = origin + Vector2(maxf(0.0, game.player.position.x - origin.x - 150.0), 0.0)
			game.camera.reset_smoothing()
			game.camera.force_update_scroll()
		await physics_frame
		await process_frame
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if frame == 0:
			print("FIRST_PNG_MOVIE_FRAME=", Engine.get_frames_drawn())
		if frame % 30 == 0:
			var bodies: Array = []
			for cast in game.spell_manager.ported_casts("firewalk"):
				for part in cast.parts:
					if not is_instance_valid(part):
						continue
					bodies.append({"x": part.global_position.x, "y": part.global_position.y, "radius": part.geo("radius"), "remaining": part.remaining_life()})
			events.append({"type": "lifecycle", "frame": frame, "bodies": bodies})
		if frame % 2 == 0:
			assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) == OK)
	for i in foes.size():
		print("FIREWALK_ENEMY index=", i, " health=", foes[i].current_health)
	FileAccess.open(folder + "/events.json", FileAccess.WRITE).store_string(JSON.stringify(events, "\t"))
	print("FIREWALK_CAPTURE rank=", rank, " args=", args)
	stage.queue_free()
	await teardown()
	quit()
