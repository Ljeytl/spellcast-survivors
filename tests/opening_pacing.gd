extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize():
	run.call_deferred()

func run():
	for run_seed in [11, 29, 73]:
		seed(run_seed)
		var game = load("res://scenes/Game.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		await process_frame
		var player = game.player
		var manager = game.get_node("MonsterManager")
		while player.level == 1 and player.health > 0 and manager.game_time < 60.0:
			var target_position = player.global_position
			var nearest = INF
			for orb in get_nodes_in_group("xp_orbs"):
				var distance = orb.global_position.distance_squared_to(player.global_position)
				if distance < nearest:
					nearest = distance
					target_position = orb.global_position
			var direction = target_position - player.global_position
			for action in ["move_left", "move_right", "move_up", "move_down"]:
				Input.action_release(action)
			if absf(direction.x) > 10:
				Input.action_press("move_right" if direction.x > 0 else "move_left")
			if absf(direction.y) > 10:
				Input.action_press("move_down" if direction.y > 0 else "move_up")
			await physics_frame
		checks += 1
		var passed = player.level >= 2 and player.health > 0
		if not passed:
			failures += 1
		print("OPENING seed=%d time=%.2f health=%.1f level=%d pass=%s" % [run_seed, manager.game_time, player.health, player.level, passed])
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
		paused = false
		game.queue_free()
		await process_frame
		await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	OS.delay_msec(200)
	await process_frame
	print("PACING_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
