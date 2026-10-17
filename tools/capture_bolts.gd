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
	if args.size() < 3 or args[1] not in ["bolt", "lightning_bolt"] or int(args[2]) not in [1, 8] or args.has("narrow"):
		printerr("Usage: capture_bolts folder bolt|lightning_bolt 1|8 [empty] (desktop only)")
		quit(2)
		return
	var folder = args[0]
	var spell = args[1]
	var rank = int(args[2])
	await setup()
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position + Vector2(170, 0)
	game.camera.force_update_scroll()
	if spell == "lightning_bolt":
		game.spell_manager.learn_spell("lightning")
		for ingredient in ["bolt", "lightning"]:
			game.spell_manager.get_spell_info(game.spell_manager.find_spell_slot(ingredient)).level = 8
	var route = Combat.prepare_capture_spell(game.spell_manager, spell, rank)
	if route.has("error"):
		printerr(route.error)
		await teardown()
		quit(2)
		return
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	var manager = game.get_node("MonsterManager")
	var enemies: Array = []
	if not args.has("empty"):
		for i in 12:
			var definition = manager.encounter_config.variants.pursuer.duplicate(true)
			definition.id = "pursuer"
			var enemy = manager.spawn_monster(definition, false, true)
			enemy.global_position = game.player.global_position + Vector2(180 + (i % 4) * 70, -70 + (i / 4) * 70)
			enemy.current_health = 10000
			enemy.max_health = 10000
			enemy.set_physics_process(false)
			enemies.append(enemy)
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	DirAccess.make_dir_recursive_absolute(folder)
	var frames: Array = []
	var events: Array = []
	var hits: Array = []
	var seen_parts: Dictionary = {}
	var cast
	var failures: Array = []
	var final_parts := 0
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"audio":event,"movie_frame":Engine.get_frames_drawn()}))
	for frame in 330:
		if frame == 12:
			if not Combat.release_capture_spell(game.spell_manager, route):
				failures.append("release_failed")
			cast = game.spell_manager.last_generic_cast
			if is_instance_valid(cast):
				events.append({"cast_plan":cast.plan.duplicate(true),"movie_frame":Engine.get_frames_drawn()})
		await physics_frame
		await process_frame
		var parts: Array = []
		if is_instance_valid(cast):
			hits = cast.hits_log.duplicate(true)
			for part in cast.parts:
				if is_instance_valid(part):
					seen_parts[str(part.get_instance_id())] = part.part_name
					if not part.done:
						parts.append({"name":part.part_name,"position":[part.global_position.x,part.global_position.y],"age":part.age})
		final_parts = parts.size()
		var health: Array = []
		for enemy in enemies:
			health.append(enemy.current_health)
		frames.append({"frame":frame,"movie_frame":Engine.get_frames_drawn(),"parts":parts,"health":health,"hits":hits.duplicate(true)})
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if frame % 2 == 0:
			if stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) != OK:
				failures.append("frame_write_failed")
			frames[-1].png = frame / 2
			frames[-1].movie_frame = Engine.get_frames_drawn()
	if final_parts != 0:
		failures.append("missing_expiry")
	if args.has("empty"):
		if not hits.is_empty():
			failures.append("empty_contacts")
	elif hits.is_empty():
		failures.append("missing_contacts")
	var warning_count = seen_parts.values().count("splash_warn")
	var strike_count = seen_parts.values().count("splash")
	var strike_hits = hits.filter(func(hit): return hit.part == "splash").size()
	if spell == "bolt" and seen_parts.values().count("bolt") == 0:
		failures.append("missing_bolt_launch")
	if spell == "lightning_bolt":
		if strike_count != (0 if args.has("empty") else 1):
			failures.append("incorrect_terminal_strike_count")
		if not args.has("empty") and strike_hits == 0:
			failures.append("missing_terminal_strike_contact")
	if spell == "lightning_bolt" and warning_count != (0 if args.has("empty") else 1):
		failures.append("incorrect_terminal_warning_count")
	var result = {"spell":spell,"rank":rank,"options":args,"frames":frames,"events":events,"hits":hits,"seen_parts":seen_parts,"terminal_warnings":warning_count,"terminal_strikes":strike_count,"terminal_strike_hits":strike_hits,"final_parts":final_parts,"failures":failures,"sound_grade":"U: not heard"}
	FileAccess.open(folder + "/manifest.json", FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("BOLT_CAPTURE ", JSON.stringify({"spell":spell,"rank":rank,"hits":hits.size(),"warnings":warning_count,"failures":failures}))
	cast = null
	stage.queue_free()
	await teardown()
	quit(0 if failures.is_empty() else 1)
