extends "res://tools/capture_spell_gallery.gd"

var checks := 0
var failures := 0

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func projectile(offset: Vector2):
	var shot = preload("res://scripts/EnemyProjectile.gd").new()
	shot.global_position = game.player.global_position + offset
	shot.direction = -offset.normalized()
	shot.source_position = shot.global_position
	shot.speed = 180.0
	shot.damage = 7.0
	game.add_child(shot)

func run():
	var args = OS.get_cmdline_user_args()
	if args.size() < 2 or not args[1].is_valid_int() or int(args[1]) < 1 or int(args[1]) > 8:
		printerr("Usage: output_folder rank_1_through_8 [narrow] [reduced] [expiry]")
		quit(2)
		return
	var folder = args[0]
	var rank = int(args[1])
	var events: Array = []
	var eruptions: Dictionary = {}
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"audio": event, "movie_frame": Engine.get_frames_drawn()}))
	await setup()
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000, 10000)
	root.size = Vector2i(720, 850) if args.has("narrow") else Vector2i(1280, 850)
	root.content_scale_size = root.size
	var vfx = root.get_node("Vfx")
	vfx.clear()
	vfx.reduced_effects = args.has("reduced")
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	game.player.health = 100.0
	game.player.is_invincible = args.has("known-bad-invincible")
	game.player.set_physics_process(true)
	game.style_session.set_process(false)
	game.style_session.score.combo = 5000
	var origin: Vector2 = game.player.global_position
	var foes = get_nodes_in_group("enemies")
	for i in foes.size():
		foes[i].global_position = origin + Vector2(260 + i * 45, 100)
	assert(game.spell_manager.learn_spell("earth_shield"))
	var slot = game.spell_manager.find_spell_slot("earth_shield")
	game.spell_manager.get_spell_info(slot).level = rank
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	DirAccess.make_dir_recursive_absolute(folder)
	var total = 1400 if args.has("expiry") else 430
	for frame in total:
		if frame in [12, 60, 360]:
			check(game.spell_manager.cast_spell_by_type(slot), "cast succeeds")
		if frame == 90:
			check(game.player.earth_shield.charges.size() == 2, "recast stacks two independent charges")
			check(game.player.earth_shield.charges[0].remaining < game.player.earth_shield.charges[1].remaining, "recast preserves old expiry")
		if frame == 120:
			foes[0].global_position = origin + Vector2(18, 0)
			foes[1].global_position = origin + Vector2(20, 8)
		if frame == 130:
			check(game.player.earth_shield.charges.size() == 1, "real crowd contact spends exactly one charge")
			check(game.player.health == 100.0, "contact is fully absorbed")
			check(game.style_session.score.combo == 5000, "absorption preserves combo")
			check(game.player.last_damage_context.get("blocked", false), "real contact reported blocked")
			check(game.player.last_damage_context.get("kind", "") == "contact", "native enemy overlap caused contact")
			foes[0].global_position = origin + Vector2(90, 0)
			foes[1].global_position = origin + Vector2(100, 20)
		if frame == 150:
			check(foes[0].current_health < 10000.0, "eruption damages real attacker")
			check(foes[2].current_health == 10000.0, "outside-cone enemy is untouched")
		if frame == 180:
			projectile(Vector2(-150, 0))
		if frame == 250:
			check(game.player.earth_shield.charges.is_empty(), "real projectile spends final charge")
			check(game.player.health == 100.0, "projectile fully absorbed")
			check(game.player.last_damage_context.get("kind", "") == "projectile", "projectile damage route observed")
			check(game.player.last_damage_context.get("blocked", false), "projectile reported blocked")
		if frame == 270:
			projectile(Vector2(0, -120))
		if frame == 340:
			check(game.player.health == 93.0, "post-exhaustion projectile causes real damage")
			check(game.style_session.score.combo < 5000, "unblocked damage breaks combo")
		if frame == 400:
			check(game.player.earth_shield.charges.size() == 1, "recast after exhaustion restores protection")
		await physics_frame
		await process_frame
		for cast in get_nodes_in_group("generic_casts"):
			if str(cast.plan.get("id", "")) == "earth_shield":
				eruptions[cast.get_instance_id()] = true
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if frame == 0:
			print("FIRST_PNG_MOVIE_FRAME=", Engine.get_frames_drawn())
		if frame % 6 == 0:
			events.append({"frame": frame, "health": game.player.health, "charges": game.player.earth_shield.charges.duplicate(true) if is_instance_valid(game.player.earth_shield) else [], "context": game.player.last_damage_context.duplicate(), "enemy_hp": foes.map(func(e): return e.current_health)})
		if frame % 2 == 0 and (frame < 430 or frame > 1240):
			check(stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) == OK, "PNG saved")
	if args.has("expiry"):
		check(game.player.earth_shield.charges.is_empty(), "full authored sixteen second charge expires")
		check(game.player.health == 93.0, "quiet expiry does not hurt player")
		check(eruptions.size() == 2, "only real blocks erupt; natural expiry does not retaliate")
	FileAccess.open(folder + "/events.json", FileAccess.WRITE).store_string(JSON.stringify(events, "\t"))
	print("EARTH_SHIELD_LIFECYCLE checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
