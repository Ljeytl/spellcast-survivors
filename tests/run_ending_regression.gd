extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func click(control: Control):
	var event = InputEventMouseButton.new()
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)

func key(code: int):
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)

func settle():
	for index in range(10):
		await process_frame

func run():
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://builds/endless-evidence")
	var progression = root.get_node("CharacterManager")
	for outcome in ["extract", "endless", "death"]:
		var game = load("res://scenes/Game.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		await settle()
		var manager = game.get_node("MonsterManager")
		game.player.is_invincible = true
		for state in [game.GameState.PAUSED, game.GameState.LEVEL_UP]:
			game.change_state(state)
			var frozen = manager.game_time
			await create_timer(0.1).timeout
			check(manager.game_time == frozen, "Pause and upgrade selection freeze real clock")
		game.level_up_screen.hide()
		game.change_state(game.GameState.PLAYING)
		manager.set_process(false)
		manager.spawn_timer.stop()
		game.spell_manager.set_process(false)
		manager.spawned_bosses = {300: true, 600: true, 900: true}
		var recorded_before = progression.total_games_played
		manager.game_time = 1199.5
		if outcome == "death":
			game.player.is_invincible = false
			game.player.take_damage(10000)
			manager.advance_time(1)
			check(not game.extraction_screen.visible, "Death before cutoff cannot open extraction")
		else:
			manager.advance_time(0.49)
			check(not game.extraction_screen.visible and not game.result_recorded, "Known pre-boundary control does not offer extraction")
			game.spell_manager.activate_spell_slot(1)
			manager.advance_time(1)
			await settle()
			check(game.current_state == game.GameState.EXTRACTION and paused, "20:00 opens paused extraction choice")
			check(game.game_time == 1200 and manager.game_time == 1200, "Choice clamps elapsed time to 20:00")
			check(not game.spell_manager.is_typing, "Choice cancels active typing")
			var held = InputEventKey.new()
			held.keycode = KEY_ENTER
			held.pressed = true
			held.echo = true
			root.push_input(held, true)
			held.keycode = KEY_SPACE
			root.push_input(held, true)
			check(game.current_state == game.GameState.EXTRACTION, "Held casting keys cannot select an ending")
			check(progression.total_games_played == recorded_before, "Choice does not record a result")
			manager.advance_time(30)
			game.toggle_pause()
			check(manager.game_time == 1200 and paused, "Choice cannot be escaped by pause or clock advance")
			check(manager.spawn_monster() == null, "Choice prevents enemy spawning")
			for size in [Vector2i(1280, 720), Vector2i(480, 800)]:
				root.size = size
				await settle()
				for button in [game.extraction_screen.extract_button, game.extraction_screen.continue_button]:
					check(root.get_visible_rect().encloses(button.get_global_rect()), "Choice buttons fit viewport")
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://builds/endless-evidence/choice-%s-%d.png" % [outcome, size.x])
			if outcome == "extract":
				await create_timer(0.4).timeout
				key(KEY_TAB)
				check(game.extraction_screen.extract_button.has_focus(), "Tab focuses Extract for deliberate keyboard selection")
				key(KEY_ENTER)
			else:
				game._on_player_level_up(2, {})
				click(game.extraction_screen.continue_button)
				await settle()
				check(manager.endless_mode and not game.result_recorded, "Continue enables endless without banking result")
				check(game.current_state == game.GameState.LEVEL_UP and paused, "Pending upgrade survives choice")
				game.level_up_screen.hide()
				game.change_state(game.GameState.PLAYING)
				var stats_before = manager.calculate_monster_stats(manager.encounter_config.variants.pursuer)
				var pressure_before = manager.spawn_difficulty_multiplier()
				var batch_before = manager.spawn_batch_amount()
				manager.advance_time(120)
				await settle()
				check(manager.game_time == 1320 and game.timer_label.text == "22:00", "Endless clock and HUD advance past twenty")
				var stats_after = manager.calculate_monster_stats(manager.encounter_config.variants.pursuer)
				check(stats_after.health > stats_before.health and stats_after.damage > stats_before.damage and manager.spawn_difficulty_multiplier() >= pressure_before and manager.spawn_batch_amount() > batch_before, "Endless stats and group size rise while cadence respects its cap")
				check(is_equal_approx(manager.spawn_difficulty_multiplier(), minf(float(manager.encounter_config.scaling.get("maximum_spawn_difficulty", INF)), manager.timed_spawn_difficulty_multiplier())), "Endless cadence obeys configured cap")
				check(manager.calculate_spawn_interval() >= 0.1 and manager.max_monsters == 160, "Existing spawn safeguards preserved")
				check(not game.extraction_screen.visible, "Choice does not reappear")
				game.toggle_pause()
				check(paused and game.pause_overlay.visible, "Endless pause menu works")
				await settle()
				click(game.get_node("UI/PauseOverlay/PauseMenu/VBoxContainer/ResumeButton"))
				check(not paused, "Resume button restores endless gameplay")
				game.player.is_invincible = false
				game.player.take_damage(10000)
		var won = outcome == "extract"
		check(game.run_won == won, "Outcome matches extraction or death")
		check(paused and game.game_over_screen.visible, "Result freezes run and opens screen")
		check(game.game_over_screen.title_label.text == ("VICTORY!" if won else "GAME OVER"), "Outcome title is correct")
		check(progression.total_games_played == recorded_before + 1, "One result recorded")
		var saved = JSON.parse_string(FileAccess.get_file_as_string("user://spellcast_save_slot_%d.save" % progression.current_save_slot))
		check(saved.total_games_played == recorded_before + 1, "One result persisted to disk")
		var end_time = manager.game_time
		game.finish_run(not won)
		game.extract_run()
		game.continue_endless()
		game.show_game_over_screen()
		game._on_player_level_up(20, {})
		game._on_upgrade_selected({})
		manager.advance_time(30)
		check(manager.game_time == end_time and game.run_won == won and paused, "Late events cannot change or resume result")
		check(progression.total_games_played == recorded_before + 1, "Duplicate events award no additional progression")
		check(not manager.spawned_bosses.has(1200), "No twenty-minute boss added")
		paused = false
		game.queue_free()
		await settle()
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	await create_timer(0.2).timeout
	print("ENDING_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
