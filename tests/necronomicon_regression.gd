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
	root.mode = Window.MODE_WINDOWED
	var character = root.get_node("CharacterManager")
	var discoveries = character.discovered_synergies.duplicate()
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	var manager = game.spell_manager
	check(manager.get_all_spells().size() == 1, "Fresh run owns only Bolt")
	var original = manager.acquired_spells.duplicate()
	for geometry in [Vector2i(1280, 720), Vector2i(800, 600)]:
		root.size = geometry
		var layer = CanvasLayer.new()
		layer.layer = 100
		root.add_child(layer)
		var menu = load("res://scenes/MainMenu.tscn").instantiate()
		layer.add_child(menu)
		menu._on_collection_pressed()
		var book = menu.get_children().filter(func(child): return child.get_script() == preload("res://scripts/SpellCollection.gd"))[0]
		await settle()
		check(book.catalog_ids.size() == 24, "All 16 implemented actives, Magic Missile and seven enabled combinations")
		check(not book.catalog_ids.has("reaping_spirit"), "Disabled combination excluded")
		check(book.keyword_ids.has("mega") and book.find_child("Entry_keyword_mega", true, false) != null, "MEGA keyword is documented in the archive")
		check(book.catalog_ids.has("meteor_shower"), "Unlearned active visible")
		check(book.catalog_ids.has("life_bolt"), "Undiscovered recipe visible")
		check(manager.acquired_spells == original, "Browsing does not grant spells")
		check(character.discovered_synergies == discoveries, "Browsing does not record discoveries")
		check(manager.find_cast_spell_slot("meteor shower") == 0, "Visible unowned spell remains uncastable")
		check(book.get_global_rect().encloses(book.back.get_global_rect()), "Back fits geometry")
		if DisplayServer.get_name() != "headless":
			DirAccess.make_dir_recursive_absolute("res://builds/book-evidence")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://builds/book-evidence/necronomicon-%d.png" % geometry.x)
		var scroll = book.find_child("CatalogScroll", true, false)
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await settle()
		var last_card = book.entries.get_child(book.entries.get_child_count() - 1)
		check(last_card.get_global_rect().end.y <= book.back.get_global_rect().position.y, "Final recipe reachable above Back")
		for card in book.entries.get_children():
			check(card.get_global_rect().end.x <= book.get_global_rect().end.x, "Catalog card stays inside narrow width")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://builds/book-evidence/recipes-%d.png" % geometry.x)
		book.back.pressed.emit()
		await settle()
		check(menu.get_node("MenuPanel").visible, "Back restores menu")
		layer.queue_free()
		await settle()
	check(manager.learn_spell("life"), "Learn Life")
	check(manager.learn_spell("life_bolt"), "Learn combination")
	check(manager.spells.size() == 2 and manager.bonus_spells.size() == 1, "Bonus does not consume an active slot")
	game.change_state(game.GameState.PAUSED)
	game.get_node("PauseInput").open_spellbook()
	await settle()
	var run_book = game.get_node("PauseInput").spellbook
	check(run_book.spell_buttons.size() == 3, "Run book includes only learned actives and bonus")
	var copy = ""
	for label in run_book.find_children("*", "Label", true, false):
		copy += label.text
	check(not copy.contains("Discovered recipes"), "Run book excludes permanent archive")
	check(copy.contains("Type: life bolt"), "Run book gives exact bonus incantation")
	check(copy.contains("MEGA · +50% power, +50% size"), "Run book lists the live keyword and its effect")
	check(copy.contains("Now: %d damage" % int(round(manager.calculate_spell_damage(manager.spells[manager.find_spell_slot("bolt")])))), "Run book shows Bolt's current damage")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/book-evidence/run-book-800.png")
	run_book.close()
	game.change_state(game.GameState.PLAYING)
	game.queue_free()
	await settle()
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	check(game.spell_manager.get_all_spells().size() == 1, "Next run resets learned spells")
	check(game.spell_manager.find_cast_spell_slot("life bolt") == 0, "Discovered bonus remains uncastable next run")
	check(character.discovered_synergies.has("life_bolt"), "Discovery survives run reset")
	character.discovered_synergies = discoveries
	character.save_progression_data()
	game.queue_free()
	await settle()
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
	print("Necronomicon: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
