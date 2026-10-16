extends SceneTree
## Enemy load probe: fills the arena with swarmers in steps and prints the physics time per step.
## godot --headless --path . --script tools/probe_enemy_load.gd -- [nocrowd] [nohurt] [nohit] [off:<node>]
## Measures one physics step per frame (ticks raised to 1000/s while measuring), after enemies have
## closed in at normal speed. Headless, so rendering is not included.
func _initialize():
	run.call_deferred()
func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 5:
		await process_frame
	Engine.max_physics_steps_per_frame = 1
	Engine.max_fps = 0
	var monsters = game.get_node("MonsterManager")
	monsters.spawn_timer.stop()
	game.player.is_invincible = true
	monsters.max_monsters = 2000
	for name in OS.get_cmdline_user_args():
		if name.begins_with("off:"):
			var path = name.substr(4)
			var n = root.get_node_or_null(path) if path.begins_with("/") else game.get_node_or_null(path)
			if n:
				n.set_physics_process(false)
				n.set_process(false)
				print("disabled ", path)
	var def = monsters.encounter_config.variants["swarmer"].duplicate(true)
	def.id = "swarmer"
	for n in [100, 200, 300, 400, 500]:
		while get_nodes_in_group("enemies").size() < n:
			var m = monsters.spawn_monster(def, false, true, randf() * TAU, -1.0, [], )
			if m == null:
				break
		if OS.get_cmdline_user_args().has("nohurt"):
			for e in get_nodes_in_group("enemies"):
				var hb = e.get_node_or_null("HurtBox")
				if hb:
					hb.monitoring = false
					hb.monitorable = false
		if OS.get_cmdline_user_args().has("nohit"):
			game.player.get_node("HitBox").monitoring = false
		if OS.get_cmdline_user_args().has("nocrowd"):
			for e in get_nodes_in_group("enemies"):
				e.normal_collision_mask &= ~2
				e.collision_mask &= ~2
		Engine.physics_ticks_per_second = 60
		for i in 120:
			paused = false
			await physics_frame
		var ms = 0.0
		var pr = 0.0
		Engine.physics_ticks_per_second = 1000
		await physics_frame
		var w0 = Time.get_ticks_usec()
		for i in 120:
			paused = false
			await physics_frame
			ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			pr += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		var wall = (Time.get_ticks_usec() - w0) / 120000.0
		ms /= 120.0
		pr /= 120.0
		print("wall_ms=%.2f enemies=%d  physics_ms=%.2f  process_ms=%.2f pairs=%d active=%d" % [wall, get_nodes_in_group("enemies").size(), ms, pr, Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS), Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)])
	quit(0)
