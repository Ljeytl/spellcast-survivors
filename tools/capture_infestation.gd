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
	var label = args[0] if args.size() else "candidate"
	root.get_node("AudioManager").quitting = not args.has("audio")
	var events: Array = []
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"frame": Engine.get_process_frames(), "type": event}))
	var spell_id = "soul_bloom" if args.has("soul") else "infestation"
	for rank in ([8] if args.has("soul") or args.has("resting") or args.has("crowded") else [1, 8]):
		await setup()
		await create_timer(1.0).timeout
		root.mode = Window.MODE_WINDOWED
		root.position = Vector2i(10000, 10000)
		root.size = Vector2i(1280, 850)
		root.content_scale_size = root.size
		for enemy in get_nodes_in_group("enemies"):
			if enemy.max_health != 10000:
				enemy.free()
		if args.has("crowded"):
			var manager = game.get_node("MonsterManager")
			for i in 8:
				var definition = manager.encounter_config.variants.pursuer.duplicate(true)
				definition.id = "pursuer"
				var enemy = manager.spawn_monster(definition, false, true)
				enemy.current_health = 10000
				enemy.max_health = 10000
				enemy.set_physics_process(false)
		var foes = get_nodes_in_group("enemies")
		var origins: Array = []
		for i in foes.size():
			foes[i].global_position = game.player.global_position + Vector2(160 + i * (250 if args.has("resting") else (50 if rank == 1 else 85)), 0)
			if args.has("crowded"):
				foes[i].global_position = game.player.global_position + Vector2(160 + (i % 4) * 55, (i / 4 - 1) * 48)
			origins.append(foes[i].global_position)
		var stage = SubViewport.new()
		stage.size = root.size
		stage.world_2d = root.world_2d
		stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(stage)
		var folder = "res://builds/infestation/" + label + "/rank-" + str(rank)
		DirAccess.make_dir_recursive_absolute(folder)
		if spell_id == "soul_bloom":
			for ingredient in load("res://scripts/SynergyCatalog.gd").RECIPES.soul_bloom.ingredients:
				game.spell_manager.learn_spell(ingredient)
				game.spell_manager.get_spell_info(game.spell_manager.find_spell_slot(ingredient)).level = 8
		assert(game.spell_manager.learn_spell(spell_id))
		var slot = game.spell_manager.find_spell_slot(spell_id)
		game.spell_manager.get_spell_info(slot).level = rank
		events.append({"type":"case_start", "rank":rank, "frame":Engine.get_process_frames()})
		for frame in 480:
			for i in foes.size():
				if is_instance_valid(foes[i]):
					foes[i].global_position = origins[i] + Vector2(0, sin(float(frame) / 50.0) * 36.0)
			if frame == 12 or (args.has("crowded") and frame in [60, 120, 180]):
				assert(game.spell_manager.cast_spell_by_type(slot))
			if frame == 110:
				foes[0].take_damage(20000, game.player.global_position)
			await physics_frame
			await process_frame
			if frame % 30 == 0:
				var cast = game.spell_manager.last_generic_cast
				if is_instance_valid(cast):
					var parts = cast.root_parts()
					if not parts.is_empty() and is_instance_valid(parts[0]):
						var infection = parts[0].infection
						if infection != null:
							events.append({"type":"lifecycle", "rank":rank, "frame":frame, "hosts":infection.hosts.size(), "started":infection.hosts_started, "links":infection.links.size(), "resting":infection.spores.size(), "ghosts":get_nodes_in_group("soul_ghosts").size()})
			stage.canvas_transform = root.get_canvas_transform()
			game.get_node("Background").queue_redraw()
			await RenderingServer.frame_post_draw
			if frame == 0:
				print("FIRST_PNG_MOVIE_FRAME rank=", rank, " frame=", Engine.get_frames_drawn())
			assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % frame) == OK)
		stage.queue_free()
		await teardown()
	FileAccess.open("res://builds/infestation/" + label + "/events.json", FileAccess.WRITE).store_string(JSON.stringify(events))
	quit()
