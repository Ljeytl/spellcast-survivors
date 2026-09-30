extends SceneTree

var checks = 0
var failures = 0
var game

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func run():
	root.get_node("AudioManager").quitting = true
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	var monsters = game.get_node("MonsterManager")
	monsters.set_process(false)
	monsters.spawn_timer.stop()
	game.style_session.exclude("Health regression")
	await process_frame
	var player = game.player
	player.take_damage(99.6)
	await create_timer(0.4).timeout
	print("Fractional reproduction: actual=", player.health, " label=", game.health_label.text, " bar=", game.health_bar.value, " state=", game.current_state)
	check(player.health > 0 and player.health < 1, "actual fractional health survives")
	check(game.current_state == game.GameState.PLAYING, "positive health continues play")
	check(game.health_label.text == "<1 / 100", "living fraction never labelled zero")
	check(game.health_bar.value > 0, "fractional health bar not rounded empty")
	game.set_interface_debug(true)
	check(game.health_label.text == "Health · <1/100", "debug label agrees")
	player.overheal = 0.5
	player.health_changed.emit(player.health, player.max_health, player.overheal)
	check("<1/100 (+<1)" in game.health_label.text, "overheal label agrees")
	player.overheal = 0
	player.is_invincible = true
	player.take_damage(100)
	check(player.health > 0 and game.current_state == game.GameState.PLAYING, "invincibility retains real positive health")
	player.is_invincible = false
	player.heal(4)
	check(player.health > 4, "fractional survivor can recover")
	game.set_interface_debug(false)
	player.take_damage(player.health - 0.001)
	await create_timer(0.4).timeout
	check(game.health_label.text == "<1 / 100", "tiny positive health remains truthful")
	if "--visual" in OS.get_cmdline_user_args():
		for geometry in [Vector2i(1280,720), Vector2i(640,480)]:
			root.size = geometry
			await create_timer(0.4).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://builds/health-truth/alive-%d.png" % geometry.x)
	player.take_damage(1)
	check(player.health == 0, "lethal damage clamps health to zero")
	check(game.current_state == game.GameState.GAME_OVER and paused, "lethal damage ends and pauses run")
	check(game.health_label.text == "0 / 100", "dead player displays zero")
	player.heal(10)
	check(player.health == 0, "healing cannot revive dead player")
	player.take_damage(1)
	check(game.current_state == game.GameState.GAME_OVER, "repeat damage keeps terminal state")
	paused = false
	game.free()
	await process_frame
	print("Health truth: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
