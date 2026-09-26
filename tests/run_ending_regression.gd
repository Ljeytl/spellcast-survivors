extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func run():
	var progression = root.get_node("CharacterManager")
	for won in [true, false]:
		var game = load("res://scenes/Game.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		await process_frame
		var manager = game.get_node("MonsterManager")
		for state in [game.GameState.PAUSED, game.GameState.LEVEL_UP]:
			game.change_state(state)
			var frozen_time = manager.game_time
			await create_timer(0.1).timeout
			check(manager.game_time == frozen_time, "Pause and upgrade selection freeze the real clock")
		game.level_up_screen.hide()
		game.change_state(game.GameState.PLAYING)
		manager.set_process(false)
		manager.spawn_timer.stop()
		game.spell_manager.set_process(false)
		var recorded_before = progression.total_games_played
		manager.game_time = 1199.5
		if won:
			manager.advance_time(0.49)
			check(not game.result_recorded, "No victory before 20:00")
			manager.advance_time(1.0)
		else:
			game.player.take_damage(10000)
		check(game.run_won == won, "Outcome matches survival or death")
		check(paused and game.game_over_screen.visible, "Result freezes the run and opens its screen")
		check(game.game_over_screen.title_label.text == ("VICTORY!" if won else "GAME OVER"), "Outcome title is correct")
		check(progression.total_games_played == recorded_before + 1, "Progression records one result")
		var end_time = manager.game_time
		manager.advance_time(30)
		game.finish_run(not won)
		game.show_game_over_screen()
		game._on_player_level_up(20, {})
		game._on_upgrade_selected({})
		check(manager.game_time == end_time, "Clock stops after either outcome")
		check(game.run_won == won and paused, "Late events cannot change or resume the result")
		check(progression.total_games_played == recorded_before + 1, "Duplicate events do not award progression twice")
		check(manager.spawn_monster() == null, "No enemies spawn after ending")
		check(not manager.spawned_bosses.has(1200), "No boss spawns at the victory cutoff")
		if won:
			check(game.game_time == 1200 and game.game_over_screen.survival_time_label.text.ends_with("20:00"), "Victory clamps elapsed time to 20:00")
		paused = false
		game.queue_free()
		await process_frame
		await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	await create_timer(0.2).timeout
	await process_frame
	print("ENDING_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
