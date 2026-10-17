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
	var rank = int(args[1])
	var full = args.has("full")
	var events: Array = []
	var checks := 0
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"audio": event, "movie_frame": Engine.get_frames_drawn()}))
	await setup()
	await create_timer(1.0).timeout
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000, 10000)
	root.size = Vector2i(720, 850) if args.has("narrow") else Vector2i(1280, 850)
	root.content_scale_size = root.size
	var vfx = root.get_node("Vfx")
	vfx.clear()
	vfx.reduced_effects = args.has("reduced")
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position + Vector2(100, 0)
	game.camera.force_update_scroll()
	game.player.health = game.player.max_health if full else 30.0
	var start = game.player.global_position
	var foes = get_nodes_in_group("enemies")
	for i in foes.size():
		foes[i].global_position = start + Vector2(210 + i * 30, 0 if not args.has("crowd") else (i - 1.5) * 35)
	assert(game.spell_manager.learn_spell("life"))
	assert(game.spell_manager.learn_spell("life_bolt"))
	var slot = game.spell_manager.find_spell_slot("life_bolt")
	game.spell_manager.get_spell_info(slot).level = rank
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	DirAccess.make_dir_recursive_absolute(folder)
	for frame in (780 if full else 360):
		if frame == 12:
			assert(game.spell_manager.cast_spell_by_type(slot))
		if frame >= 150 and frame < 240:
			game.player.global_position = start + Vector2(minf((frame - 150) * 2.5, 210), 0)
		game.spell_manager.process_healing_effects(1.0 / 60.0)
		await physics_frame
		await process_frame
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if frame == 0:
			print("FIRST_PNG_MOVIE_FRAME=", Engine.get_frames_drawn())
		if frame == 144:
			assert(game.player.health == (game.player.max_health if full else 30.0))
			assert(not get_nodes_in_group("healing_seeds").is_empty())
			assert(foes.any(func(enemy): return enemy.current_health < 10000.0))
			checks += 3
		if frame == 240 and full:
			assert(game.player.health == game.player.max_health)
			assert(not get_nodes_in_group("healing_seeds").is_empty())
			checks += 2
		if frame % 6 == 0:
			var seeds: Array = []
			for pickup in get_nodes_in_group("healing_seeds"):
				seeds.append({"x": pickup.global_position.x, "remaining": pickup.remaining, "radius": pickup.radius})
			events.append({"frame": frame, "hp": game.player.health, "seeds": seeds, "enemy_hp": foes.map(func(e): return e.current_health)})
		if frame % 2 == 0:
			assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) == OK)
	assert(game.player.health == game.player.max_health if full else game.player.health > 30.0)
	assert(get_nodes_in_group("healing_seeds").is_empty())
	checks += 2
	print("LIFE_BOLT_LIFECYCLE checks=", checks, " failures=0")
	FileAccess.open(folder + "/events.json", FileAccess.WRITE).store_string(JSON.stringify(events, "\t"))
	print("LIFE_BOLT_CAPTURE hp=", game.player.health, " seeds=", get_nodes_in_group("healing_seeds").size())
	quit()
