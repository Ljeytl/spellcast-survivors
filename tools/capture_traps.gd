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
	var args = OS.get_cmdline_user_args()
	var folder = args[0]
	var id = args[1]
	var rank = int(args[2])
	var events: Array = []
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"audio": event, "movie_frame": Engine.get_frames_drawn()}))
	await setup()
	await create_timer(1.0).timeout
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000, 10000)
	root.size = Vector2i(620, 850) if args.has("narrow") else Vector2i(1280, 850)
	root.content_scale_size = root.size
	root.get_node("Vfx").clear()
	root.get_node("Vfx").reduced_effects = args.has("reduced")
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position + Vector2(100, 0)
	game.camera.force_update_scroll()
	var foes = get_nodes_in_group("enemies")
	var origin = game.player.global_position
	for i in foes.size():
		foes[i].global_position = origin + Vector2(340 + i * 30, i * 30)
	if id == "frost_sigil":
		game.spell_manager.learn_spell("rune_trap")
		game.spell_manager.learn_spell("ice_blast")
		if rank > 1:
			for ingredient in ["rune_trap", "ice_blast"]:
				game.spell_manager.get_spell_info(game.spell_manager.find_spell_slot(ingredient)).level = 8
	if id != "trap":
		assert(game.spell_manager.learn_spell(id))
		game.spell_manager.get_spell_info(game.spell_manager.find_spell_slot(id)).level = rank
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	DirAccess.make_dir_recursive_absolute(folder)
	var placed = origin + Vector2(160, 0)
	for frame in (660 if args.has("empty") else 420):
		if frame == 12 or (frame == 90 and args.has("recast")):
			if id == "trap":
				assert(game.spell_manager.cast_keyword_spell("mega trap" if args.has("large") else "trap"))
			else:
				assert(game.spell_manager.cast_spell_by_type(game.spell_manager.find_spell_slot(id), 1.7 if args.has("large") else 1.0))
			var roots = game.spell_manager.last_generic_cast.root_parts()
			if not roots.is_empty():
				placed = roots[0].global_position
		if id == "trap" and frame < 150:
			for c in get_nodes_in_group("generic_casts"):
				for p in c.root_parts():
					if p.delivery == "trap":
						placed = p.global_position
						for i in foes.size():
							foes[i].global_position = placed + Vector2(180 + i * 30, i * 24)
		if frame >= 150 and frame < 210 and not args.has("empty"):
			for i in foes.size():
				foes[i].global_position = placed + Vector2(180 - (frame - 150) * 3.0, i * 24)
		if frame == 180 and args.has("overlap"):
			game.spell_manager.learn_spell("ice_blast")
			game.spell_manager.cast_spell_by_type(game.spell_manager.find_spell_slot("ice_blast"))
		await physics_frame
		await process_frame
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if frame == 0:
			print("FIRST_PNG_MOVIE_FRAME=", Engine.get_frames_drawn())
		if frame % 6 == 0:
			var parts: Array = []
			for c in get_nodes_in_group("generic_casts"):
				for p in c.parts:
					if is_instance_valid(p) and not p.done:
						parts.append({"id": c.plan.id, "part": p.part_name, "age": p.age, "armed": p.armed, "radius": p.geo("radius"), "x": p.global_position.x, "y": p.global_position.y})
			events.append({"frame": frame, "movie_frame": Engine.get_frames_drawn(), "parts": parts, "enemy_hp": foes.map(func(e): return e.current_health)})
		if frame % 2 == 0:
			assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) == OK)
	FileAccess.open(folder + "/events.json", FileAccess.WRITE).store_string(JSON.stringify(events, "\t"))
	print("TRAP_CAPTURE id=", id, " rank=", rank, " args=", args)
	quit()
