extends SceneTree

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func shot(name: String):
	for i in range(15):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/minimal-ui-evidence/" + name + ".png")

func run():
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://builds/minimal-ui-evidence")
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.player.is_invincible = true
	game.player.set_physics_process(false)
	var choices = game.level_up_screen
	for geometry in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(800, 600)]:
		root.size = geometry
		game.get_node("GameplayReadability").layout()
		game.set_interface_debug(false)
		choices.hide()
		var suffix = "desktop" if geometry.x == 1280 else str(geometry.x) + "x" + str(geometry.y)
		await shot("hud-" + suffix)
		game.spell_manager.space_casting = true
		game.spell_manager.start_freeform_typing()
		game.spell_manager.current_typing_text = "lightning bolt"
		game.spell_manager.update_freeform_typing_display()
		await shot("typing-" + suffix)
		game.spell_manager.cancel_typing()
		choices.show_level_up(2, {})
		choices.available_upgrades = [
			{"name": "Learn Ice Blast", "description": "Blast a forward cone of enemies with ice.", "effect": {"type": "learn_spell", "spell": "ice_blast"}},
			{"name": "Spell Power", "description": "+10% Spell Damage (Currently: +0%)", "effect": {"type": "spell_damage", "value": 0.1}},
			{"name": "Discover Life Bolt", "description": "Hits plant a healing seed you can collect.", "effect": {"type": "learn_spell", "spell": "life_bolt"}}
		]
		choices.update_ui(2, {})
		await shot("choices-" + suffix)
		game.set_interface_debug(true)
		await shot("debug-choices-" + suffix)
		game.set_interface_debug(false)
		choices.hide()
		game.game_over_screen.show_game_over({"won": false, "survival_time": 42, "level": 3, "enemies_killed": 12, "spells_cast": 7, "final_kit": ["Bolt"], "final_hit": {"kind": "contact", "damage": 15}})
		await create_timer(0.25).timeout
		await shot("ending-" + suffix)
		game.game_over_screen.hide()
	for id in ["life", "regeneration", "ice_blast", "earth_shield", "lightning"]:
		game.spell_manager.learn_spell(id)
	game.spell_manager.learn_spell("lightning_bolt")
	for geometry in [Vector2i(1280, 720), Vector2i(800, 600)]:
		root.size = geometry
		game.get_node("GameplayReadability").layout()
		game.change_state(game.GameState.PAUSED)
		game.get_node("PauseInput").open_spellbook()
		await shot("spellbook-" + str(geometry.x))
		game.get_node("PauseInput").spellbook.close_button.pressed.emit()
		game.change_state(game.GameState.PLAYING)
	game.queue_free()
	await process_frame
	root.get_node("CharacterManager").discovered_synergies = ["life_bolt", "frost_sigil", "prism_ray"]
	for geometry in [Vector2i(1280, 720), Vector2i(800, 600)]:
		root.size = geometry
		var suffix = "desktop" if geometry.x == 1280 else str(geometry.x) + "x" + str(geometry.y)
		var help = load("res://scenes/HowToPlay.tscn").instantiate()
		root.add_child(help)
		current_scene = help
		await shot("help-" + suffix)
		help.queue_free()
		await process_frame
		var menu = load("res://scenes/MainMenu.tscn").instantiate()
		root.add_child(menu)
		current_scene = menu
		menu._on_collection_pressed()
		await shot("collection-" + suffix)
		menu.queue_free()
		await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await create_timer(0.25, true, false, true).timeout
	quit()
