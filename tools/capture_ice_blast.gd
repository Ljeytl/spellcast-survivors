extends "res://tools/capture_spell_gallery.gd"

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	root.hide()
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	root.get_node("AudioManager").quitting = true
	var label := "after" if OS.get_cmdline_user_args().is_empty() else OS.get_cmdline_user_args()[0]
	for rank in [1, 8]:
		await setup()
		await create_timer(1.0).timeout
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
			foes[i].global_position = game.player.global_position + Vector2(180 + i % 2 * 40, (i - 1.5) * 40)
			foes[i].speed = 0.0
			foes[i].set_physics_process(true)
			positions.append(foes[i].global_position)
		var stage := SubViewport.new()
		stage.size = root.size
		stage.world_2d = root.world_2d
		stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(stage)
		assert(game.spell_manager.learn_spell("ice_blast"))
		var slot = game.spell_manager.find_spell_slot("ice_blast")
		game.spell_manager.get_spell_info(slot).level = rank
		var folder: String = "res://builds/ice-blast/" + label + "/rank-" + str(rank)
		DirAccess.make_dir_recursive_absolute(folder)
		for frame in 120:
			if frame == 12:
				assert(game.spell_manager.cast_spell_by_type(slot))
			await physics_frame
			await process_frame
			stage.canvas_transform = root.get_canvas_transform()
			game.get_node("Background").queue_redraw()
			await RenderingServer.frame_post_draw
			if frame % 2 == 0:
				if stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) != OK:
					quit(2)
					return
		var hits := 0
		var moved := 0
		for i in foes.size():
			if foes[i].current_health < 10000:
				hits += 1
			if foes[i].global_position.distance_to(positions[i]) > 5:
				moved += 1
		print("ICE_CAPTURE rank=", rank, " hits=", hits, " pushed=", moved)
		if hits == 0 or moved == 0:
			quit(1)
			return
		stage.queue_free()
		await teardown()
	quit()
