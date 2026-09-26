extends SceneTree

func _initialize():
	run.call_deferred()

func shot(name: String):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/casting-evidence/" + name + ".png")

func run():
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://builds/casting-evidence")
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var monsters = game.get_node("MonsterManager")
	monsters.set_process(false)
	monsters.spawn_timer.stop()
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	game.player.is_invincible = true
	var def = monsters.encounter_config.variants.pursuer.duplicate(true)
	def.id = "pursuer"
	var enemy = monsters.spawn_monster(def, true)
	enemy.global_position = game.player.global_position + Vector2(210, 90)
	enemy.set_physics_process(false)
	game.spell_manager.space_casting = true
	game.spell_manager.start_freeform_typing()
	game.spell_manager.current_typing_text = "lightning bolt"
	game.spell_manager.update_freeform_typing_display()
	await create_timer(0.7, true, false, true).timeout
	await shot("typed-spell")
	game.spell_manager.current_typing_text = "lightning bol"
	game.spell_manager.update_freeform_typing_display()
	await create_timer(0.1, true, false, true).timeout
	await shot("backspace")
	root.size = Vector2i(960, 540)
	game.get_node("GameplayReadability").layout()
	await create_timer(0.3, true, false, true).timeout
	await shot("typed-narrow")
	game.spell_manager.current_typing_text = "meteor shower deluxe ".repeat(4)
	game.spell_manager.update_freeform_typing_display()
	await create_timer(0.3, true, false, true).timeout
	await shot("long-narrow")
	game.spell_manager.cancel_typing()
	root.size = Vector2i(1280, 720)
	game.get_node("GameplayReadability").layout()
	await create_timer(0.5, true, false, true).timeout
	await shot("boss-orbit")
	game.queue_free()
	await process_frame
	quit()
