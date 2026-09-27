extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func settle():
	for i in range(12):
		await process_frame

func run():
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	var manager = game.spell_manager
	var pause_input = game.get_node("PauseInput")
	check(manager.spells.size() == 1 and manager.find_spell_slot("bolt") == 1, "Fresh run has only owned starter Bolt")
	for id in ["life", "regeneration", "ice_blast", "earth_shield", "lightning_arc"]:
		check(manager.learn_spell(id), "Learn base for six-slot UI journey: " + id)
	check(manager.learn_spell("lightning_bolt"), "Acquire bonus at full active capacity")
	var bonus_slot = manager.find_spell_slot("lightning_bolt")
	check(bonus_slot > 6 and manager.spells.size() == 6, "Bonus sits outside the six primary slots")
	for geometry in [Vector2i(1280, 720), Vector2i(800, 600)]:
		root.size = geometry
		game.get_node("GameplayReadability").layout()
		game.change_state(game.GameState.PAUSED)
		pause_input.open_spellbook()
		await settle()
		var book = pause_input.spellbook
		check(is_instance_valid(book), "Ordinary pause opens spellbook")
		check(not game.interface_debug, "Spellbook does not require debug")
		check(book.spell_buttons.size() == 7, "Every owned base and bonus has a cast button")
		check(book.spell_buttons.has(bonus_slot), "Bonus is discoverable without memorizing incantation")
		check(book.get_global_rect().encloses(book.panel.get_global_rect()), "Spellbook panel fits window")
		check(book.panel.get_global_rect().encloses(book.close_button.get_global_rect()), "Back stays inside panel")
		for button in book.spell_buttons.values():
			check(button.size.y >= button.get_minimum_size().y, "Owned name fits its button")
			check(button.get_theme_font_size("font_size") >= 32, "Spell keys remain legible")
		book.cast_requested.emit(9999)
		check(game.current_state == game.GameState.PAUSED and is_instance_valid(pause_input.spellbook), "Invalid slot cannot leave pause or cast")
		book.spell_buttons[bonus_slot].pressed.emit()
		await settle()
		check(game.current_state == game.GameState.PLAYING and not paused, "Selecting owned bonus resumes gameplay")
		check(manager.is_typing and manager.target_spell == "lightning bolt", "Bonus selection opens its owned typing prompt")
		manager.cancel_typing()
		game.change_state(game.GameState.PAUSED)
		pause_input.open_spellbook()
		await settle()
		pause_input.spellbook.close_button.pressed.emit()
		await settle()
		check(paused and game.pause_overlay.visible and not is_instance_valid(pause_input.spellbook), "Back returns to pause without resuming")
		game.change_state(game.GameState.PLAYING)
	manager.start_freeform_typing()
	manager.current_typing_text = "meteor shower"
	manager.attempt_freeform_cast()
	check(manager.is_typing, "Unowned phrase cannot be cast after browsing owned spells")
	manager.cancel_typing()
	check(game.typing_keycaps.KEY_SIZE >= 48, "Typed keys are enlarged without new source assets")
	game.queue_free()
	paused = false
	await settle()
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
	await settle()
	print("Run spellbook: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
