extends SceneTree
var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var manager = game.get_node("MonsterManager")
	# The 20-minute curve outside the day cycle (day runs follow scaling.day_spawn_phases).
	manager.day_cycle_driven = false
	manager.set_process(false)
	manager.spawn_timer.stop()
	var rows = []
	var previous_difficulty = 1.0
	var previous_batch = 1.0
	for seconds in range(1200):
		manager.game_time = seconds
		var difficulty = manager.spawn_difficulty_multiplier()
		check(difficulty >= previous_difficulty, "Difficulty never reverses at %s" % seconds)
		previous_difficulty = difficulty
		check(is_equal_approx(manager.calculate_spawn_interval() * difficulty, manager.spawn_phase_interval(seconds)), "Every phase shares the same difficulty factor")
		var batch_amount = manager.spawn_batch_amount()
		check(batch_amount >= previous_batch - 0.000001, "Batch amount never shrinks at %s" % seconds)
		previous_batch = batch_amount
		check(seconds >= 300 or manager.calculate_spawn_batch_size() == 1, "Opening keeps one regular roll per tick at %s" % seconds)
		if seconds % 120 == 0:
			rows.append({"seconds": seconds, "interval": manager.calculate_spawn_interval(), "difficulty": difficulty})
		check(manager.get_available_variants(seconds).all(func(item): return seconds >= 600 or item.family != "shooter"), "Ranged timing preserved")
	manager.encounter_config.scaling.spawn_batch_points = [{"time": 0, "count": 1.0}, {"time": 600, "count": 3.0}, {"time": 1200, "count": 3.0}]
	manager.spawn_batch_fraction = 0.0
	manager.game_time = 0
	check(manager.calculate_spawn_batch_size() == 1, "Future batch configuration does not affect opening")
	manager.game_time = 900
	check(manager.calculate_spawn_batch_size() == 3, "Later difficulty can choose larger batch")
	manager.encounter_config.variants = {"pursuer": manager.encounter_config.variants.pursuer}
	manager.monsters_alive = 0
	var spawned_before = manager.actual_spawns
	manager._on_spawn_timer_timeout()
	check(manager.actual_spawns - spawned_before == 3, "Real timer callback dispatches the configured batch")
	manager.monsters_alive = manager.max_monsters - 1
	spawned_before = manager.actual_spawns
	manager._on_spawn_timer_timeout()
	check(manager.actual_spawns - spawned_before == 1, "Multi-spawn tick respects remaining population capacity")
	manager.monsters_alive = manager.max_monsters
	var attempted = manager.spawn_attempts
	var blocked = manager.cap_rejections
	check(manager.spawn_monster() == null and manager.spawn_attempts == attempted + 1 and manager.cap_rejections == blocked + 1, "Population cap rejections are measured")
	print("MIDGAME_CURVE=", JSON.stringify(rows))
	game.queue_free()
	await process_frame
	print("Midgame curve: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
