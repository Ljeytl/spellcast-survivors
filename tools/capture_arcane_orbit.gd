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
	var label = args[0] if args.size() else "after"
	var rank = int(args[1]) if args.size() > 1 else 1
	await setup()
	await create_timer(1.0).timeout
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000, 10000)
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	root.get_node("Vfx").clear()
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position
	game.camera.force_update_scroll()
	assert(game.spell_manager.learn_spell("arcane_orbit"))
	var slot = game.spell_manager.find_spell_slot("arcane_orbit")
	game.spell_manager.get_spell_info(slot).level = rank
	if args.has("fast"):
		game.player.projectile_speed_multiplier = 2.0
	var foes = get_nodes_in_group("enemies")
	for i in foes.size():
		foes[i].global_position = game.player.global_position + Vector2.from_angle(float(i) / foes.size() * TAU) * (400.0 if args.has("empty") else (100.0 if i < 3 else 0.0))
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var folder = "res://builds/arcane-orbit/" + label + "-" + str(rank)
	DirAccess.make_dir_recursive_absolute(folder)
	for frame in (780 if args.has("recast") else 450):
		if frame == 12 or (frame == 180 and args.has("recast")):
			assert(game.spell_manager.cast_spell_by_type(slot, 1.7 if args.has("large") else 1.0))
		if args.has("moving"):
			game.player.position += Vector2(0.25, sin(float(frame) / 40.0) * 0.12)
		await physics_frame
		await process_frame
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if frame == 0:
			print("FIRST_PNG_MOVIE_FRAME=", Engine.get_frames_drawn())
		if frame % 2 == 0:
			assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) == OK)
	for i in foes.size():
		print("ORBIT_ENEMY index=", i, " health=", foes[i].current_health)
	print("ORBIT_CAPTURE rank=", rank, " args=", args)
	stage.queue_free()
	await teardown()
	quit()
