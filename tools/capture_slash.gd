extends "res://tools/capture_spell_gallery.gd"

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000, 10000)
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	if not root.is_node_ready():
		await root.ready
	var args = OS.get_cmdline_user_args()
	var folder = args[0]
	var events: Array = []
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"audio": event, "movie_frame": Engine.get_frames_drawn()}))
	await setup()
	root.get_node("AudioManager").quitting = false
	await create_timer(1.0).timeout
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000, 10000)
	root.size = Vector2i(620, 850) if args.has("narrow") else Vector2i(1280, 850)
	root.content_scale_size = root.size
	var vfx = root.get_node("Vfx")
	vfx.clear()
	vfx.reduced_effects = args.has("reduced")
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position
	game.camera.force_update_scroll()
	var foes = get_nodes_in_group("enemies")
	var offsets = [Vector2(80, 0), Vector2.from_angle(deg_to_rad(65)) * 110.0, Vector2(175, 0), Vector2(-100, 0)]
	for i in foes.size():
		foes[i].global_position = game.player.global_position + offsets[i] * (3.0 if args.has("empty") else 1.0)
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	DirAccess.make_dir_recursive_absolute(folder)
	for frame in 150:
		if frame in [12, 72]:
			game.spell_manager.last_spell_cast_time = -1e9
			var phrase = ("large " if args.has("large") else "") + ("fiery " if args.has("fiery") else "") + "slash"
			assert(game.spell_manager.cast_keyword_spell(phrase))
			events.append({"cast_frame": frame, "movie_frame": Engine.get_frames_drawn(), "immediate_hp": foes.map(func(e): return e.current_health)})
		await physics_frame
		await process_frame
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if frame == 0:
			print("FIRST_PNG_MOVIE_FRAME=", Engine.get_frames_drawn())
		events.append({"frame": frame, "movie_frame": Engine.get_frames_drawn(), "hp": foes.map(func(e): return e.current_health), "slashes": vfx.elements.slashes.size()})
		assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % frame) == OK)
	FileAccess.open(folder + "/events.json", FileAccess.WRITE).store_string(JSON.stringify(events, "\t"))
	print("SLASH_CAPTURE args=", args, " health=", foes.map(func(e): return e.current_health))
	quit()
