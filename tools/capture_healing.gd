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
	var label = args[0] if args.size() > 0 else "after"
	var spell_id = args[1] if args.size() > 1 else "life"
	var rank = int(args[2]) if args.size() > 2 else 1
	await setup()
	await create_timer(1.0).timeout
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000, 10000)
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	root.get_node("Vfx").clear()
	game.player.health = game.player.max_health if args.has("full") else 1.0
	game.camera.position = game.player.position
	game.camera.force_update_scroll()
	assert(game.spell_manager.learn_spell(spell_id))
	var slot = game.spell_manager.find_spell_slot(spell_id)
	game.spell_manager.get_spell_info(slot).level = rank
	if args.has("crowded"):
		var foes = get_nodes_in_group("enemies")
		for i in foes.size():
			foes[i].global_position = game.player.global_position + Vector2.from_angle(float(i) / foes.size() * TAU) * 105.0
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var record = AudioEffectRecord.new()
	record.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, record)
	record.set_recording_active(true)
	var folder = "res://builds/healing/" + label + "/" + spell_id + "-" + str(rank) + ("-full" if args.has("full") else "-hurt") + ("-crowded-large" if args.has("crowded") else "")
	DirAccess.make_dir_recursive_absolute(folder)
	var initial_hp = game.player.health
	var frames = 480 if spell_id == "regeneration" else 150
	for frame in frames:
		if frame == 12:
			assert(game.spell_manager.cast_spell_by_type(slot, 2.0 if args.has("crowded") else 1.0))
		game.player.position += Vector2(0.30, sin(float(frame) / 40.0) * 0.18)
		await physics_frame
		await process_frame
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if frame % 2 == 0:
			assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) == OK)
	record.set_recording_active(false)
	var recording = record.get_recording()
	assert(recording.save_to_wav(folder + "/audio.wav") == OK)
	print("HEAL_CAPTURE id=", spell_id, " rank=", rank, " before=", initial_hp, " after=", game.player.health, " audio=", recording.get_length())
	quit()
