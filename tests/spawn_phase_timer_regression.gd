extends SceneTree

var checks = 0
var failures = 0
var emissions = 0

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func run():
	var parent = Node2D.new()
	var player = CharacterBody2D.new()
	player.name = "Player"
	parent.add_child(player)
	root.add_child(parent)
	var manager = load("res://scripts/MonsterManager.gd").new()
	parent.add_child(manager)
	manager.set_process(false)
	manager.spawn_timer.timeout.disconnect(manager._on_spawn_timer_timeout)
	manager.spawn_timer.timeout.connect(func(): emissions += 1)
	manager.game_time = 14.9
	manager.spawn_timer.start(3.0)
	manager.advance_time(0.1)
	check(is_equal_approx(manager.spawn_timer.wait_time, 1.0), "Crossing fifteen seconds immediately updates the real timer")
	await create_timer(1.15).timeout
	check(emissions == 1, "Pressure timer fires within its new one-second interval")
	manager.game_time = 44.9
	manager.spawn_timer.start(0.1)
	var before = emissions
	manager.advance_time(0.1)
	check(is_equal_approx(manager.spawn_timer.wait_time, 2.0), "Recovery boundary replaces pending fast timer")
	await create_timer(0.2).timeout
	check(emissions == before, "Old pressure deadline does not leak into recovery")
	manager.game_time = 119.9
	manager.advance_time(0.1)
	check(is_equal_approx(manager.spawn_timer.wait_time, 3.0), "Cycle wrap returns the real timer to light pressure")
	manager.spawn_timer.stop()
	manager.game_time = 14.9
	manager.advance_time(0.1)
	check(manager.spawn_timer.is_stopped(), "Advancing a stopped simulation does not restart spawning")
	manager.encounter_config.scaling = {"opening_spawn_interval": 3.0, "spawn_phases": [{"start": 10, "interval": 1}, {"start": 0, "interval": 3}, {"start": 9, "interval": -2}, {"start": 11, "interval": 0}]}
	manager.game_time = 12.0
	check(is_equal_approx(manager.calculate_spawn_interval(), 1.0), "Unsorted phases select latest valid positive interval")
	manager.encounter_config.scaling = {}
	check(is_equal_approx(manager.calculate_spawn_interval(), 3.0), "Missing phase data retains baseline fallback")
	parent.queue_free()
	await process_frame
	print("Spawn phase timer regression: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
