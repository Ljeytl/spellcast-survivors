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
	game.player.is_invincible = true
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	game.chest_manager.set_process(false)
	game.player.level_up.disconnect(game._on_player_level_up)
	var boss_count = 0
	var collected_count = 0
	for second in range(1, 1201):
		manager.advance_time(1.0)
		if second % 60 == 0 and second < 1200:
			var enemy = manager.spawn_monster()
			check(is_instance_valid(enemy), "Normal spawns work at minute %d" % (second / 60))
			if enemy:
				enemy.take_damage(100000, game.player.position)
		for boss in get_nodes_in_group("bosses"):
			if not boss.dying:
				boss_count += 1
				boss.position = game.player.position + Vector2(300, 0)
				boss.take_damage(100000, game.player.position)
		await process_frame
		await process_frame
		for reward in get_nodes_in_group("boss_rewards"):
			if reward.collect():
				collected_count += 1
				game.level_up_screen._on_upgrade_button_pressed(0)
				await create_timer(0.3, true, false, true).timeout
		check(manager.game_time == second, "Clock advances exactly through run")
	check(boss_count == 3 and collected_count == 3, "All three boss milestones drop collectable rewards")
	check(game.run_won and game.current_state == game.GameState.GAME_OVER, "Full clock reaches immediate victory")
	check(manager.game_time == 1200 and not manager.spawned_bosses.has(1200), "No additional final boss at cutoff")
	check(not game.queue_boss_reward(), "No upgrade can reopen the completed run")
	paused = false
	game.queue_free()
	await process_frame
	check(get_nodes_in_group("boss_rewards").is_empty() and get_nodes_in_group("xp_orbs").is_empty(), "Full-run teardown clears reward and XP state")
	print("Full-run accelerated lifecycle: %d checks, %d failures; scripted damage, invulnerable player, not balance evidence" % [checks, failures])
	quit(1 if failures else 0)
