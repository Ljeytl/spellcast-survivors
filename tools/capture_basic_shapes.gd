extends "res://tools/capture_spell_gallery.gd"

const Combat = preload("res://tools/capture_spell_combat.gd")

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var args = OS.get_cmdline_user_args()
	if args.size() < 2 or args[1] not in ["nova", "orbit"]:
		printerr("Usage: capture_basic_shapes folder nova|orbit [empty moving narrow reduced large fiery]")
		quit(2)
		return
	var folder = args[0]
	var spell = args[1]
	await setup()
	root.size = Vector2i(720, 850) if args.has("narrow") else Vector2i(1280, 850)
	root.content_scale_size = root.size
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position
	game.camera.force_update_scroll()
	root.get_node("Vfx").reduced_effects = args.has("reduced")
	var words: Array[String] = []
	for word in ["large", "fiery"]:
		if args.has(word):
			words.append(word)
	var route = Combat.prepare_capture_spell(game.spell_manager, spell, 1, " ".join(words))
	var enemies = get_nodes_in_group("enemies")
	if args.has("empty"):
		for enemy in enemies:
			enemy.free()
		enemies = []
	var offsets = [Vector2.ZERO, Vector2(80, 0), Vector2(160, 0), Vector2(330, 0)] if spell == "nova" else [Vector2.ZERO, Vector2(90, 0), Vector2(0, -90), Vector2(330, 0)]
	for i in enemies.size():
		enemies[i].global_position = game.player.global_position + offsets[i]
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	DirAccess.make_dir_recursive_absolute(folder)
	var events: Array = []
	var frames: Array = []
	var hits: Array = []
	var cast
	var failures: Array = []
	var active_samples := 0
	var final_parts := 0
	var start: Vector2 = game.player.global_position
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"audio":event,"movie_frame":Engine.get_frames_drawn()}))
	if args.has("moving"):
		game.player.set_physics_process(true)
	for frame in 330:
		if args.has("moving"):
			Input.action_release("move_right")
			if frame >= 30 and frame < 90:
				Input.action_press("move_right")
			for i in enemies.size():
				enemies[i].global_position = game.player.global_position + offsets[i]
		if frame == 12:
			if not Combat.release_capture_spell(game.spell_manager, route):
				failures.append("cast_failed")
			cast = game.spell_manager.last_generic_cast
			if is_instance_valid(cast):
				events.append({"cast_plan":cast.plan.duplicate(true),"movie_frame":Engine.get_frames_drawn()})
		await physics_frame
		await process_frame
		var parts: Array = []
		if is_instance_valid(cast):
			hits = cast.hits_log.duplicate(true)
			for part in cast.parts:
				if is_instance_valid(part) and not part.done:
					parts.append({"position":[part.global_position.x,part.global_position.y],"age":part.age,"hits":part.hit_count})
		if not parts.is_empty():
			active_samples += 1
		final_parts = parts.size()
		var health: Array = []
		for enemy in enemies:
			health.append(enemy.current_health)
		frames.append({"frame":frame,"movie_frame":Engine.get_frames_drawn(),"player":[game.player.global_position.x,game.player.global_position.y],"parts":parts,"health":health,"hits":hits.duplicate(true)})
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if frame % 2 == 0:
			if stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) != OK:
				failures.append("frame_write_failed")
			frames[-1].png = frame / 2
			frames[-1].movie_frame = Engine.get_frames_drawn()
	Input.action_release("move_right")
	if active_samples == 0 or final_parts != 0:
		failures.append("missing_active_or_expiry_boundary")
	if args.has("empty"):
		if not hits.is_empty():
			failures.append("empty_cast_has_contact")
	else:
		if hits.is_empty():
			failures.append("missing_contacts")
		if enemies.back().current_health < 10000:
			failures.append("outside_target_damaged")
		if spell == "orbit" and enemies[0].current_health < 10000:
			failures.append("orbit_center_gap_damaged")
		if spell == "nova" and enemies[0].current_health == 10000:
			failures.append("nova_center_not_damaged")
	var travel = game.player.global_position.distance_to(start)
	if args.has("moving") and travel < 100:
		failures.append("missing_player_motion")
	var result = {"spell":spell,"route":route,"scenario":"controlled_geometry","options":args,"frames":frames,"events":events,"hits":hits,"active_samples":active_samples,"final_parts":final_parts,"travel":travel,"failures":failures,"sound_grade":"U: not heard"}
	FileAccess.open(folder + "/manifest.json", FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("BASIC_CAPTURE ", JSON.stringify({"spell":spell,"hits":hits.size(),"active":active_samples,"final_parts":final_parts,"travel":travel,"failures":failures}))
	cast = null
	stage.queue_free()
	await teardown()
	quit(0 if failures.is_empty() else 1)
