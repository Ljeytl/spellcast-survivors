extends SceneTree

func _initialize():
	run.call_deferred()

func shot(path: String):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run():
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://builds/art-evidence")
	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await shot("res://builds/art-evidence/menu.png")
	root.size = Vector2i(800, 600)
	await shot("res://builds/art-evidence/menu-narrow.png")
	root.size = Vector2i(1280, 720)
	menu.queue_free()
	await process_frame
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	game.player.is_invincible = true
	var index = 0
	for id in manager.encounter_config.variants:
		var def = manager.encounter_config.variants[id].duplicate(true)
		def.id = id
		var enemy = manager.spawn_monster(def, false)
		enemy.global_position = game.player.global_position + Vector2(-350 + (index % 6) * 140, -150 + (index / 6) * 300)
		enemy.set_physics_process(false)
		index += 1
	await shot("res://builds/art-evidence/forest-roster.png")
	for health in [0, 50, 100]:
		var tween = game.health_bar.get_meta("value_tween", null)
		if tween and tween.is_valid():
			tween.kill()
		game.health_bar.value = health
		game.health_label.text = "Health · %d/100" % health
		game.update_overheal_display(health, 100, 25 if health == 50 else 0)
		await shot("res://builds/art-evidence/health-%d.png" % health)
	root.size = Vector2i(800, 600)
	await process_frame
	await shot("res://builds/art-evidence/narrow.png")
	game.queue_free()
	await process_frame
	quit()
