extends "res://tools/capture_spell_gallery.gd"

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	root.get_node("AudioManager").quitting = not OS.get_cmdline_user_args().has("audio")
	var frame_stride := 1 if OS.get_cmdline_user_args().has("full-rate") else 2
	var label := "after" if OS.get_cmdline_user_args().is_empty() else OS.get_cmdline_user_args()[0]
	for rank in [1, 8]:
		await setup()
		await create_timer(1.0).timeout
		root.mode = Window.MODE_WINDOWED
		root.position = Vector2i(10000, 10000)
		root.size = Vector2i(1280, 850)
		root.content_scale_size = root.size
		var vfx = root.get_node("Vfx")
		vfx.clear()
		game.camera_shake.follow_offset = game.camera.global_position - game.player.global_position
		game.camera_shake.set_process(true)
		for extra in get_nodes_in_group("enemies"):
			if extra.max_health != 10000:
				extra.free()
		var foes = get_nodes_in_group("enemies")
		var positions: Array = []
		for i in foes.size():
			foes[i].global_position = game.player.global_position + Vector2((340 if OS.get_cmdline_user_args().has("long") else 180) + i % 2 * 40, (i - 1.5) * 40)
			foes[i].speed = 0.0
			foes[i].set_physics_process(true)
			positions.append(foes[i].global_position)
		var stage := SubViewport.new()
		stage.size = root.size
		stage.world_2d = root.world_2d
		stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(stage)
		game.spell_manager.mana_bolt_level = rank
		var folder: String = (label if label.begins_with("/") else "res://builds/magic-missile/" + label) + "/rank-" + str(rank)
		var frames: Array = []
		var casts: Array = []
		var contacts: Dictionary = {}
		DirAccess.make_dir_recursive_absolute(folder)
		for frame in 240:
			if OS.get_cmdline_user_args().has("moving"):
				for i in foes.size():
					foes[i].global_position = positions[i] + Vector2(0, sin(float(frame) / 32.0 + i) * 65.0)
			if frame in [12, 72, 132]:
				game.spell_manager.last_generic_cast = null
				game.spell_manager.fire_mana_bolt()
				if not is_instance_valid(game.spell_manager.last_generic_cast):
					printerr("Magic Missile release failed")
					quit(2)
					return
				casts.append(game.spell_manager.last_generic_cast)
			await physics_frame
			await process_frame
			for cast in casts:
				if is_instance_valid(cast):
					contacts[str(cast.get_instance_id())] = cast.hits_log.duplicate(true)
			stage.canvas_transform = root.get_canvas_transform()
			game.get_node("Background").queue_redraw()
			await RenderingServer.frame_post_draw
			if frame % frame_stride == 0:
				if stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / frame_stride)) != OK:
					quit(2)
					return
				frames.append({"png":frame / frame_stride,"movie_frame":Engine.get_frames_drawn()})
		var hits := 0
		var moved := 0
		for i in foes.size():
			if foes[i].current_health < 10000:
				hits += 1
			if foes[i].global_position.distance_to(positions[i]) > 5:
				moved += 1
		print("MISSILE_CAPTURE rank=", rank, " hits=", hits, " moved=", moved)
		if casts.size() != 3 or contacts.size() != 3 or contacts.values().any(func(cast_hits): return cast_hits.is_empty()):
			printerr("Expected three distinct Magic Missile releases with actual contacts")
			quit(1)
			return
		if hits == 0:
			quit(1)
			return
		FileAccess.open(folder + "/manifest.json", FileAccess.WRITE).store_string(JSON.stringify({"spell":"mana_bolt","rank":rank,"frames":frames,"contacts":contacts,"damaged_enemies":hits,"moving_targets":moved,"cast_count":casts.size(),"failures":[],"sound_grade":"U: not heard"},"\t"))
		casts.clear()
		stage.queue_free()
		await teardown()
	quit()
