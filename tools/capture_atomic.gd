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
	var events: Array = []
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"frame": Engine.get_process_frames(), "type": event}))
	var frame_stride := 1 if OS.get_cmdline_user_args().has("full-rate") else 2
	var label := "after" if OS.get_cmdline_user_args().is_empty() else OS.get_cmdline_user_args()[0]
	for rank in [1, 2, 3]:
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
		game.particle_manager.reduced_effects = rank == 3
		game.player.global_position += Vector2(-100, 50) if rank == 2 else Vector2.ZERO
		var boss = foes[0]
		boss.add_to_group("bosses")
		var folder: String = "res://builds/atomic/" + label + "/case-" + str(rank)
		DirAccess.make_dir_recursive_absolute(folder)
		for frame in 240:
			if OS.get_cmdline_user_args().has("moving"):
				for i in foes.size():
					if not is_instance_valid(foes[i]) or foes[i].is_queued_for_deletion():
						continue
					foes[i].global_position = positions[i] + Vector2(0, sin(float(frame) / 32.0 + i) * 65.0)
			if frame == 12:
				game.style_session.score.atomic_charges = 1
				game.style_session.score.combo = 3700.0
				assert(game.style_session.cast_atomic())
				assert(game.style_session.score.atomic_charges == 0)
				events.append({"frame": Engine.get_process_frames(), "type": "atomic_cast", "case": rank})
			await physics_frame
			await process_frame
			stage.canvas_transform = root.get_canvas_transform()
			game.get_node("Background").queue_redraw()
			await RenderingServer.frame_post_draw
			if frame % frame_stride == 0:
				if stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / frame_stride)) != OK:
					quit(2)
					return
		print("ATOMIC_CAPTURE case=", rank, " boss_health=", boss.current_health)
		if not is_equal_approx(boss.current_health, 4000.0):
			quit(1)
			return
		stage.queue_free()
		await teardown()
	var event_file = FileAccess.open("res://builds/atomic/" + label + "/events.json", FileAccess.WRITE)
	event_file.store_string(JSON.stringify(events, "\t"))
	quit()
