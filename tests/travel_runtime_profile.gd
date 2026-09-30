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
	manager.game_time = 450.0
	manager.spawned_bosses[300] = true
	var terrain = game.get_node("Background")
	await physics_frame
	var definition = manager.encounter_config.variants.pursuer.duplicate(true)
	definition.id = "pursuer"
	for index in 160:
		var enemy = manager.spawn_monster(definition, false, true)
		if enemy:
			enemy.position = game.player.position - Vector2(100 + (index / 10) * 70, (index % 10 - 5) * 90)
	var generations = terrain.layout_generation_count
	var started = Time.get_ticks_usec()
	var physics_times: Array[float] = []
	var process_times: Array[float] = []
	var max_nodes = 0
	var max_layouts = 0
	var max_decorations = 0
	var maximum_enemies = 0
	for frame in 1800:
		await physics_frame
		game.player.position.x += 300.0 / Engine.physics_ticks_per_second
		physics_times.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		process_times.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		max_nodes = maxi(max_nodes, get_node_count())
		max_layouts = maxi(max_layouts, terrain.layouts.size())
		max_decorations = maxi(max_decorations, terrain.decorations.size())
		maximum_enemies = maxi(maximum_enemies, manager.monsters_alive)
	physics_times.sort()
	process_times.sort()
	print("RUNTIME_TRAVEL_PROFILE " + JSON.stringify({"seed":4217,"physics_frames":1800,"travel_distance":9000,"wall_ms":(Time.get_ticks_usec()-started)/1000.0,"physics_p50_ms":physics_times[900],"physics_p95_ms":physics_times[1710],"process_p50_ms":process_times[900],"process_p95_ms":process_times[1710],"max_nodes":max_nodes,"max_enemies":maximum_enemies,"alive":manager.monsters_alive,"max_cached_layouts":max_layouts,"max_decorations":max_decorations,"generations":terrain.layout_generation_count-generations,"recycled":manager.encounter_director.recycled_count,"renderer":DisplayServer.get_name()}))
	game.free()
	await process_frame
	quit()
