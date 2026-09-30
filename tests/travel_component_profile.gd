extends SceneTree

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	seed(4217)
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	game.set_meta("bot_run", true)
	root.add_child(game)
	current_scene = game
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	game.player.is_invincible = true
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	var terrain = game.get_node("Background")
	await process_frame
	var definition = manager.encounter_config.variants.pursuer.duplicate(true)
	definition.id = "pursuer"
	var natural = "--natural" in OS.get_cmdline_user_args()
	if natural:
		manager.game_time = 450.0
	var steps = 3600 if natural else 600
	for index in (0 if natural else 160):
		var enemy = manager.spawn_monster(definition, false, true)
		if enemy:
			enemy.set_physics_process(false)
			enemy.position = game.player.position - Vector2(1000 + index * 35, (index % 9 - 4) * 100)
	var enemies = get_nodes_in_group("enemies")
	var started = Time.get_ticks_usec()
	var initial_generations = terrain.layout_generation_count
	var steer_usec = 0
	var max_layouts = 0
	var max_decorations = 0
	var timings: Array[int] = []
	var spawn_clock = 0.0
	for frame in steps:
		if natural:
			manager.advance_time(1.0 / 30.0)
			spawn_clock += 1.0 / 30.0
			if spawn_clock >= manager.calculate_spawn_interval():
				spawn_clock = 0.0
				manager._on_spawn_timer_timeout()
			enemies = get_nodes_in_group("enemies")
		game.player.position.x += 10.0
		game.get_node("Camera2D").position = game.player.position
		game.get_node("Camera2D").force_update_scroll()
		terrain.refresh_decorations()
		var steering_start = Time.get_ticks_usec()
		for enemy in enemies:
			enemy.set_physics_process(false)
			if natural:
				enemy._physics_process(1.0 / 30.0)
			else:
				var desired = (game.player.position - enemy.position).normalized() * enemy.speed
				enemy.position += terrain.steer(enemy.position, desired, 29 * enemy.scale.x) / 30.0
		var elapsed = Time.get_ticks_usec() - steering_start
		timings.append(elapsed)
		steer_usec += elapsed
		if not natural:
			manager.encounter_director.update(1.0 / 30.0)
		max_layouts = maxi(max_layouts, terrain.layouts.size())
		max_decorations = maxi(max_decorations, terrain.decorations.size())
		if frame % 30 == 0:
			await process_frame
	timings.sort()
	var report = {"natural_encounters":natural,"p50_step_ms":timings[int(timings.size()*0.5)]/1000.0,"p95_step_ms":timings[int(timings.size()*0.95)]/1000.0,"steps":steps,"simulated_seconds":steps/30,"travel_distance":steps*10,"enemies":enemies.size(),"alive":manager.monsters_alive,"recycled":manager.encounter_director.recycled_count,"layout_generations":terrain.layout_generation_count-initial_generations,"max_cached_layouts":max_layouts,"max_decorations":max_decorations,"steering_ms":steer_usec/1000.0,"wall_ms":(Time.get_ticks_usec()-started)/1000.0,"renderer":DisplayServer.get_name()}
	print("TRAVEL_PROFILE "+JSON.stringify(report))
	game.free()
	await process_frame
	quit()
