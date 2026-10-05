extends SceneTree

var checks := 0
var failures := 0
var game
var console

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func command(value: String):
	console.execute_command(value)

func run():
	root.get_node("AudioManager").quitting = true
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	console = game.console_instance
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	var manager = game.get_node("MonsterManager")
	# This suite covers the classic 20-minute run: the day cycle (experiment) is switched off.
	manager.day_cycle_driven = false
	var day_cycle = game.get_node_or_null("DayCycle")
	if day_cycle:
		day_cycle.set_process(false)
	manager.set_process(false)
	manager.spawn_timer.stop()
	await process_frame
	check(game.style_session.eligible, "fresh run eligible")
	for unavailable in ["laser", "rainbow", "blackhole", "matrix", "time_scale"]:
		console.clear_console()
		command(unavailable)
		check("unavailable" in console.output_label.text, unavailable + " honest unavailable")
		check(not console.commands.has(unavailable), unavailable + " hidden from registry")
	check(game.style_session.eligible, "unavailable command doesn't assist run")
	for read_command in ["spell_list", "progression", "save_slots", "character", "persistent_xp", "unknown_command"]:
		command(read_command)
	check(game.style_session.eligible, "read only and unknown commands preserve eligibility")
	command("  speed   2  ")
	check(game.player.movement_speed_multiplier == 2.0, "speed changes real stat")
	check(not game.style_session.eligible, "assisted run excluded")
	for value in ["speed banana", "speed -1", "speed 0", "speed inf", "speed 2 3"]:
		command(value)
		check(game.player.movement_speed_multiplier == 2.0, "reject " + value)
	console.input_field.text = "rainb"
	console.auto_complete()
	check(console.input_field.text == "rainb", "unavailable absent autocomplete")
	command("ui_debug off")
	command("ui_debug rubbish")
	check(not game.interface_debug, "invalid diagnostics toggle unchanged")
	command("damage 3")
	check(game.player.spell_damage_multiplier == 3.0, "power actual stat")
	command("invincibility on")
	command("invincibility on")
	check(game.player.is_invincible, "on idempotent")
	command("god_mode off")
	check(not game.player.is_invincible, "god off")
	var mask = game.player.collision_mask
	var layer = game.player.collision_layer
	command("noclip on")
	command("noclip on")
	check(game.player.collision_mask == 0 and game.player.collision_layer == 0, "noclip clears both")
	command("noclip off")
	check(game.player.collision_mask == mask and game.player.collision_layer == layer, "noclip restores exact collision")
	command("set_health 10")
	check(game.player.health == 10, "health actual property")
	command("heal 4")
	check(game.player.health == 14, "heal actual amount")
	var xp = game.player.xp
	command("add_xp 1")
	check(game.player.xp > xp, "xp actual API")
	command("rerolls 8")
	command("banishes 7")
	command("locks 6")
	check(game.level_up_screen.rerolls_remaining == 8 and game.level_up_screen.banishes_remaining == 7 and game.level_up_screen.locks_remaining == 6, "upgrade resources actual properties")
	var expected_position = game.player.get_global_mouse_position()
	command("spawn_chest")
	check(game.chest_manager.active_chests.back().global_position.is_equal_approx(expected_position), "chest uses world mouse coordinates")
	command("teleport")
	check(game.player.global_position.is_equal_approx(expected_position), "teleport uses world mouse coordinates")
	command("difficulty 2")
	check(manager.game_time == 120.0, "difficulty target minute")
	command("difficulty 2")
	check(manager.game_time == 120.0, "difficulty not additive")
	command("difficulty +15")
	check(manager.game_time == 135.0, "difficulty add seconds")
	command("difficulty 1")
	check(manager.game_time == 135.0, "no rewind")
	command("spawn_enemy pursuer 2")
	var enemies = get_nodes_in_group("enemies")
	check(enemies.size() >= 2, "spawn real enemies")
	if not enemies.is_empty():
		var sprite = enemies[0].get_node("Sprite2D")
		var original = sprite.scale
		command("bighead on")
		command("bighead on")
		check(sprite.scale.is_equal_approx(original * 2), "bighead relative and idempotent")
		command("bighead off")
		check(sprite.scale.is_equal_approx(original), "bighead exact restore")
		command("freeze 2")
		check(enemies[0].slow_multiplier == 0 and enemies[0].slow_timer == 2, "freeze real slow")
		enemies[0].process_status_effects(2.1)
		check(enemies[0].slow_multiplier == 1.0, "freeze expires")
	command("kill_all")
	await process_frame
	await process_frame
	check(manager.monsters_alive == 0, "kill updates population bookkeeping")
	command("spawn_enemy pursuer")
	check(manager.monsters_alive == 1, "spawn after clear works")
	console.clear_console()
	game.spell_manager.acquired_spells["lightning_bolt"] = true
	command("spell_list")
	check("lightning bolt" in console.output_label.text and not "lightning arc" in console.output_label.text, "spell list current combos without obsolete spells")
	console.open_console()
	command("level_up")
	await create_timer(0.3, true, false, true).timeout
	check(game.current_state == game.GameState.LEVEL_UP and paused, "level up console close preserves upgrade pause")
	game.current_state = game.GameState.PLAYING
	game.level_up_screen.hide()
	paused = false
	command("difficulty 5")
	check(manager.spawned_bosses.has(300), "difficulty triggers boss milestone")
	command("difficulty 20")
	check(manager.awaiting_extraction, "difficulty triggers extraction")
	game.current_state = game.GameState.PLAYING
	paused = false
	console.open_console()
	command("set_health 0")
	check(game.current_state == game.GameState.GAME_OVER, "zero health transitions game over")
	command("heal")
	check(game.player.health == 0, "cannot revive finished run")
	console.close_console()
	await create_timer(0.3, true, false, true).timeout
	check(paused, "console close preserves game over pause")
	paused = false
	game.free()
	await process_frame
	print("Console regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
