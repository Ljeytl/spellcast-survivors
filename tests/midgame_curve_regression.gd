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
	manager.set_process(false)
	manager.spawn_timer.stop()
	var rows = []
	for seconds in [0, 120, 180, 300, 420, 480, 540, 660]:
		manager.game_time = seconds
		var base = maxf(0.6, manager.spawn_phase_interval(seconds) / pow(1.28, maxf(0, seconds - 180) / 180.0))
		var candidate = manager.calculate_spawn_interval()
		check(is_equal_approx(candidate, base) if seconds <= 120 or seconds >= 540 else candidate < base, "Only middle minutes have increased spawn pressure: %s" % seconds)
		rows.append({"seconds": seconds, "baseline_interval": base, "candidate_interval": candidate, "population_cap": manager.max_monsters, "pressure_multiplier": manager.midgame_pressure(seconds)})
		check(manager.get_available_variants(seconds).all(func(item): return seconds >= 600 or item.family != "shooter"), "Ranged timing preserved")
	for second in range(119, 541):
		check(absf(manager.midgame_pressure(second + 0.01) - manager.midgame_pressure(second)) < 0.001, "Pressure envelope continuous")
	manager.monsters_alive = manager.max_monsters
	var attempted = manager.spawn_attempts
	var blocked = manager.cap_rejections
	check(manager.spawn_monster() == null and manager.spawn_attempts == attempted + 1 and manager.cap_rejections == blocked + 1, "Population cap rejections are measured")
	print("MIDGAME_CURVE=", JSON.stringify(rows))
	game.queue_free()
	await process_frame
	print("Midgame curve: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
