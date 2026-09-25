extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize():
	run.call_deferred()

func check(condition: bool, description: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", description)

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	var player = game.get_node("Player")
	var spells = game.get_node("SpellManager")
	spells.set_process(false)
	player.set_physics_process(false)
	check(player.xp_to_next_level == 25.0, "First upgrade requires 25 XP")
	check(game.xp_label.text.contains("25"), "Initial HUD shows actual XP threshold")
	for time in [0.0, 60.0, 179.9]:
		manager.game_time = time
		check(manager.get_current_difficulty_level() == 1, "Opening stays tier 1 at %s" % time)
		check(is_equal_approx(manager.calculate_spawn_interval(), 2.0), "Opening spawn pace at %s" % time)
	for pair in [[180.0, 2], [300.0, 3], [420.0, 4]]:
		manager.game_time = pair[0]
		check(manager.get_current_difficulty_level() == pair[1], "Tier transition at %s" % pair[0])
	manager.game_time = 0.0
	Input.action_press("ui_up")
	game.handle_input()
	Input.action_release("ui_up")
	check(manager.game_time == 0.0, "Up Arrow cannot jump difficulty")
	var letter = InputEventKey.new()
	letter.keycode = KEY_U
	letter.physical_keycode = KEY_U
	letter.pressed = true
	Input.parse_input_event(letter)
	game.handle_input()
	check(manager.game_time == 0.0, "Typing U cannot jump difficulty")
	letter.pressed = false
	Input.parse_input_event(letter)
	for monster in manager.monster_config.monster_roster.tier_1_basic:
		var stats = manager.calculate_monster_stats(monster, 1)
		check(stats.health <= 30.0, "%s dies within two base auto attacks" % monster.name)
		check(stats.xp >= 2.0, "%s supplies early XP" % monster.name)
	manager.game_time = 300.0
	var goblin = manager.monster_config.monster_roster.tier_1_basic[0]
	var later = manager.calculate_monster_stats(goblin, 3)
	check(is_equal_approx(later.health, 25.2), "Configured gentle growth drives actual health")
	check(manager.calculate_spawn_interval() < 2.0, "Pressure increases after grace period")
	manager.game_time = 0.0
	manager.spawn_monster()
	await process_frame
	var enemies = get_nodes_in_group("enemies")
	check(enemies.size() == 1, "Real spawn creates exactly one enemy")
	if enemies.size() == 1:
		check(enemies[0].current_health <= 30.0, "Spawned enemy retains opening health after ready")
		enemies[0].queue_free()
	player.health = 20.0
	spells.cast_spell_by_type(2)
	check(spells.active_healing_effects.size() == 1, "Numbered Regeneration creates healing")
	spells.process_healing_effects(1.0)
	check(is_equal_approx(player.health, 28.0), "Regeneration restores 8 health in one second")
	spells.process_healing_effects(10.0)
	check(is_equal_approx(player.health, 60.0), "Final healing tick is clamped to five second lifetime")
	check(spells.active_healing_effects.is_empty(), "Healing expires")
	player.health = 95.0
	spells.cast_freeform_spell_by_type("life", spells.freeform_spells["life"])
	check(spells.active_healing_effects.size() == 1, "Freeform Regeneration creates healing")
	spells.process_healing_effects(5.0)
	check(player.health == player.max_health, "Healing cannot exceed max health")
	player.xp = 15.0
	player.add_xp(50.0)
	check(player.level == 3 and player.xp == 0.0, "XP chest correctly crosses two thresholds")
	check(player.xp_to_next_level == 55.0, "Third threshold is 55 XP")
	check(game.pending_level_ups.size() == 1, "Second earned upgrade is queued")
	var screen = game.level_up_screen
	check(screen.visible and screen.level_label.text == "Level 2", "First choice is level 2")
	screen._on_upgrade_button_pressed(0)
	screen._on_upgrade_button_pressed(0)
	await create_timer(0.4, true, false, true).timeout
	check(game.current_state == game.GameState.LEVEL_UP, "Game remains paused for second choice")
	check(screen.visible and screen.level_label.text == "Level 3", "Second choice survives hide animation")
	screen._on_upgrade_button_pressed(0)
	await create_timer(0.4, true, false, true).timeout
	check(game.current_state == game.GameState.PLAYING and not paused, "Game resumes after both choices")
	check(game.pending_level_ups.is_empty() and not screen.visible, "No stale upgrade modal or queue")
	game.queue_free()
	await process_frame
	print("BALANCE_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
