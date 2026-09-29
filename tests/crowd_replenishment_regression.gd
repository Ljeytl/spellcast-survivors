extends SceneTree

class NoRefill extends "res://scripts/SpawnPressure.gd":
	func refill_count(_population: int, _target: int) -> int:
		return 0

var checks := 0
var failures := 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run():
	var pressure = load("res://scripts/SpawnPressure.gd").new()
	for index in range(100):
		pressure.record_kill()
	pressure.advance(5.0, 0, 12)
	check(pressure.level == 0.0, "Single screen wipe never increases adaptive pressure")
	for window in range(8):
		for second in range(5):
			pressure.record_kill()
			pressure.record_kill()
			pressure.advance(1.0, 0, 12)
	check(pressure.level == 1.0, "Sustained clearing gradually reaches bounded maximum")
	pressure.advance(5.0, 30, 12)
	check(pressure.level < 1.0, "Crowded or inactive combat releases pressure")
	pressure.advance(120.0, 0, 12)
	check(pressure.level == 0.0, "Debug time jump cannot accumulate artificial pressure")
	check(pressure.refill_count(0, 12) == 6, "Empty arena queues a group immediately")
	check(pressure.refill_count(0, 12) == 0, "Refill is rate limited")
	pressure.advance(0.6, 6, 12)
	check(pressure.refill_count(6, 12) == 6, "Second group fills remaining population budget")
	pressure.advance(0.6, 12, 12)
	check(pressure.refill_count(12, 12) == 0, "Incoming population counts toward refill budget")
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	manager.monsters_alive = 0
	manager.game_time = 200.0
	manager.spawn_pressure = load("res://scripts/SpawnPressure.gd").new()
	if "--known-bad-refill" in OS.get_cmdline_user_args():
		manager.spawn_pressure = NoRefill.new()
	manager.replenish_population(0.1)
	check(manager.monsters_alive == 6, "Actual empty arena receives six offscreen enemies within one update")
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		check(not manager.encounter_director.visible_world_rect().has_point(enemy.global_position), "Refill never materializes on screen")
		check(enemy.family != "shooter", "Refill preserves timed ranged unlock")
	manager.replenish_population(0.6)
	check(manager.monsters_alive == manager.refill_population_target(), "Refill reaches target promptly without timer timeout")
	var population = manager.monsters_alive
	manager.replenish_population(0.6)
	check(manager.monsters_alive == population, "Healthy incoming population stops refill")
	if get_nodes_in_group("enemies").is_empty():
		manager.spawn_monster()
	var killed_enemy = get_nodes_in_group("enemies")[0]
	var kills_before = manager.spawn_pressure.kills
	killed_enemy.take_damage(100000.0)
	await process_frame
	await process_frame
	check(manager.spawn_pressure.kills == kills_before + 1, "Actual enemy death feeds sustained-clear tracking")
	manager.monsters_alive = 0
	manager.awaiting_extraction = true
	var spawns_before = manager.actual_spawns
	manager.replenish_population(1.0)
	check(manager.actual_spawns == spawns_before, "Extraction pauses replenishment")
	manager.awaiting_extraction = false
	manager.run_finished = true
	manager.replenish_population(1.0)
	check(manager.actual_spawns == spawns_before, "Finished run cannot refill")
	manager.run_finished = false
	manager.set_process(true)
	manager.spawn_timer.start(0.1)
	var time_before = manager.game_time
	paused = true
	await create_timer(0.25).timeout
	check(manager.actual_spawns == spawns_before and manager.game_time == time_before, "Tree pause stops both refill and normal timer")
	manager.spawn_timer.stop()
	manager.set_process(false)
	paused = false
	var baseline_interval = manager.calculate_spawn_interval()
	var baseline_batch = manager.calculate_spawn_batch_size()
	manager.spawn_pressure.level = 1.0
	check(manager.calculate_spawn_interval() < baseline_interval, "Sustained pressure accelerates regular timer")
	check(manager.calculate_spawn_batch_size() == baseline_batch + 1, "Sustained pressure adds bounded group size")
	var specialist = manager.encounter_config.variants.flanker.duplicate(true)
	specialist.id = "flanker"
	check(manager.variant_spawn_weight(specialist) > float(specialist.weight), "Pressure favors already unlocked specialists")
	for at_time in [0.0, 200.0, 599.0, 600.0]:
		for variant in manager.get_available_variants(at_time):
			check(float(variant.unlock_time) <= at_time and (variant.family != "shooter" or at_time >= 600.0), "Pressure cannot unlock future variants")
	manager.spawn_pressure.level = 0.0
	for point in [{"time": 180.0, "multiplier": 1.6}, {"time": 480.0, "multiplier": 4.0}, {"time": 660.0, "multiplier": 4.5}]:
		manager.game_time = point.time
		check(is_equal_approx(manager.spawn_difficulty_multiplier(), point.multiplier), "Compressed ramp meets explicit rate milestone")
	manager.game_time = 480.0
	check(is_equal_approx(manager.calculate_spawn_interval(), 0.75), "Eight-minute light phase reaches former fourfold target")
	check(manager.calculate_spawn_batch_size() == 1, "Eight-minute batches remain fractional rather than jumping early")
	for point in [{"time": 300.0, "sequence": [1, 2, 1, 2]}, {"time": 660.0, "sequence": [2, 2, 2, 2]}, {"time": 930.0, "sequence": [2, 3, 2, 3]}, {"time": 1200.0, "sequence": [3, 3, 3, 3]}]:
		manager.game_time = point.time
		manager.spawn_batch_fraction = 0.0
		if point.time >= 660.0:
			check(is_equal_approx(manager.spawn_difficulty_multiplier(), 4.5), "Cadence plateaus while later batches grow")
		for expected in point.sequence:
			check(manager.consume_spawn_batch_size() == expected, "Fractional spawn batches alternate deterministically")
	manager.game_time = 300.0
	manager.spawn_batch_fraction = 0.0
	manager.monsters_alive = 0
	for id in manager.encounter_config.variants:
		manager.encounter_config.variants[id].weight = 1 if id == "pursuer" else 0
	var spawned_before = manager.actual_spawns
	manager._on_spawn_timer_timeout()
	check(manager.actual_spawns - spawned_before == 1, "First real timer timeout spawns one enemy at fractional batch1.5")
	manager._on_spawn_timer_timeout()
	check(manager.actual_spawns - spawned_before == 3, "Second real timer timeout spawns two, conserving fractional budget")
	manager.game_time = 1320.0
	check(is_equal_approx(manager.spawn_batch_amount(), 3.5), "Endless mode continues batch progression")
	manager.game_time = 1000000.0
	check(manager.consume_spawn_batch_size() <= manager.max_monsters, "Endless batch work stays population bounded")
	manager.monsters_alive = manager.max_monsters
	check(manager.spawn_monster() == null, "Hard population cap remains enforced")
	game.queue_free()
	await process_frame
	print("Crowd replenishment regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
