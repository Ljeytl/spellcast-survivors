extends SceneTree

class BossProbe extends Node2D:
	var dying = false
	var encounter_name = "King Slime"
	var current_health = 500.0

var checks = 0
var failures = 0
var game: Node
var known_bad = "--known-bad-pause" in OS.get_cmdline_user_args()

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func settle(seconds: float = 0.25):
	await create_timer(seconds, true, false, true).timeout
	await process_frame
	await process_frame

func key(code: int, character: int = 0):
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.unicode = character
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await process_frame

func screenshot(name: String):
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/ui-ux-evidence/" + name + ".png")

func open_scene(path: String):
	root.get_node("SceneManager").goto_scene(path)
	await settle()
	return current_scene

func run():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(5000, 5000)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(800, 600)
	root.get_node("AudioManager").quitting = true
	DirAccess.make_dir_recursive_absolute("res://builds/ui-ux-evidence")
	var menu = await open_scene("res://scenes/MainMenu.tscn")
	check(root.gui_get_focus_owner() == menu.get_node("MenuPanel/VBoxContainer/PlayButton"), "Main menu starts at Play: %s" % root.gui_get_focus_owner())
	await screenshot("menu-800")
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	await settle()
	var options = current_scene
	check(options.has_node("OptionsPanel"), "Keyboard opens Options")
	var slider = options.get_node("OptionsPanel/VBoxContainer/MasterVolumeContainer/MasterSlider")
	var initial = root.get_node("AudioManager").master_volume
	check(is_equal_approx(slider.value, initial * 100), "Slider reflects current volume")
	slider.grab_focus()
	await key(KEY_LEFT)
	var changed = slider.value
	check(changed < initial * 100, "Keyboard changes volume")
	await key(KEY_ESCAPE)
	await settle()
	check(current_scene.has_node("MenuPanel"), "Escape exits main-menu Options")
	check(root.gui_get_focus_owner().name == "OptionsButton", "Return restores Options focus")
	await key(KEY_ENTER)
	await settle()
	options = current_scene
	check(is_equal_approx(options.get_node("OptionsPanel/VBoxContainer/MasterVolumeContainer/MasterSlider").value, changed), "Reopened Options retains volume")
	await screenshot("options-800")
	var config = ConfigFile.new()
	check(config.load("user://presentation.cfg") == OK and is_equal_approx(float(config.get_value("audio", "master", -1)), changed / 100), "Volume is durable in config")
	await key(KEY_ESCAPE)
	await settle()
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	await settle()
	check(current_scene.has_node("HowToPlayPanel"), "Keyboard opens help")
	check("1–6" in current_scene.get_node("HowToPlayPanel/VBoxContainer/Instructions").text, "Help explains all six shortcuts")
	await key(KEY_ESCAPE)
	await settle()
	check(root.gui_get_focus_owner().name == "HowToPlayButton", "Help Escape restores origin focus")
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	await settle()
	var collection = current_scene.get_node("SpellCollection") if current_scene.has_node("SpellCollection") else current_scene.get_children().filter(func(n): return n.get_script() == load("res://scripts/SpellCollection.gd"))[0]
	var scroll = collection.find_child("CatalogScroll", true, false)
	var before = scroll.scroll_vertical
	for i in range(10):
		await key(KEY_DOWN)
	await settle()
	check(scroll.scroll_vertical > before, "Keyboard scrolls the collection")
	await screenshot("collection-keyboard-800")
	await key(KEY_ESCAPE)
	await settle()
	check(root.gui_get_focus_owner().name == "CollectionButton", "Collection returns to its entry point")
	game = await open_scene("res://scenes/Game.tscn")
	game.get_node("MonsterManager").set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.player.is_invincible = true
	await screenshot("hud-800")
	await key(KEY_ESCAPE)
	await settle()
	check(paused and root.gui_get_focus_owner().name == "ResumeButton", "Pause focuses Resume")
	await key(KEY_DOWN)
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	await settle()
	check(game.has_node("UI/Options") and paused, "Keyboard opens paused Options")
	await key(KEY_QUOTELEFT)
	await key(KEY_ENTER)
	check(game.has_node("UI/Options") and paused, "Immediate Enter stays in Console")
	await settle()
	game.console_instance.trigger_level_up()
	await settle()
	check(game.current_state == game.GameState.PAUSED and game.pending_level_ups.size() == 1, "Console XP queues behind Options")
	await key(KEY_QUOTELEFT)
	await settle()
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	await settle()
	check(game.current_state == game.GameState.PAUSED, "Second Escape cannot leak through closing Console")
	if known_bad:
		paused = false
	check(paused and game.has_node("UI/Options"), "Console close preserves Options pause")
	await key(KEY_ESCAPE)
	await settle()
	check(paused and game.pause_overlay.visible and root.gui_get_focus_owner().name == "OptionsButton", "Options Back restores paused menu")
	await key(KEY_ESCAPE)
	await settle()
	check(paused and game.current_state == game.GameState.LEVEL_UP and not game.has_node("UI/Options"), "Resume presents queued reward after submenu closes")
	await settle()
	await key(KEY_ENTER)
	await settle(0.4)
	check(not paused, "Queued reward returns to play")
	await key(KEY_QUOTELEFT)
	await settle()
	game.player.add_xp(game.player.xp_to_next_level - game.player.xp)
	await key(KEY_ESCAPE)
	await settle()
	check(paused and game.level_up_screen.visible, "Console close preserves level-up pause")
	var t = game.game_time
	await settle(0.4)
	check(is_equal_approx(game.game_time, t), "Time remains frozen behind level-up")
	await screenshot("choices-800")
	await key(KEY_ENTER)
	await settle(0.4)
	check(not paused and not game.level_up_screen.visible, "Keyboard choice resumes run")
	game.console_instance.open_console()
	game.console_instance.close_console()
	game.console_instance.open_console()
	await settle(0.4)
	check(paused and game.console_instance.visible and game.console_instance.is_console_open, "Stale console tween cannot close a reopened console")
	game.console_instance.close_console()
	await settle()
	check(not paused, "Closing console from play resumes")
	for id in ["life", "regeneration", "ice_blast", "earth_shield", "lightning_arc"]:
		game.spell_manager.learn_spell(id)
	game.spell_manager.learn_spell("lightning_bolt")
	game.update_spell_slot_lock_status()
	check(game.spell_slots.filter(func(card): return card.visible).size() == 6, "All six equipped spells are represented")
	for geometry in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(480, 640)]:
		root.size = geometry
		await settle()
		var hud = game.get_node("UI/HUD")
		check(hud.get_node("SpellSlotsPanel/SpellSlots").columns == (6 if geometry.x >= 800 else 3), "Spell grid uses available width %s" % geometry)
		for card in game.spell_slots:
			check(hud.get_global_rect().encloses(card.get_global_rect()), "Equipped spell fits %s" % geometry)
		check(not hud.get_node("StatsPanel").get_global_rect().intersects(hud.get_node("TimerPanel").get_global_rect()), "HUD top panels do not overlap %s" % geometry)
		await screenshot("full-hud-%d" % geometry.x)
		var boss = BossProbe.new()
		game.add_child(boss)
		boss.add_to_group("bosses")
		await settle()
		check(not hud.get_node("StatsPanel").get_global_rect().intersects(hud.get_node("TimerPanel").get_global_rect()), "Boss HUD panels do not overlap %s" % geometry)
		await screenshot("boss-hud-%d" % geometry.x)
		await key(KEY_F3)
		await settle()
		check(not hud.get_node("StatsPanel").get_global_rect().intersects(hud.get_node("TimerPanel").get_global_rect()), "Debug HUD panels do not overlap %s" % geometry)
		for name in ["PassiveSpell", "FocusStatus", "FocusBar"]:
			check(not hud.get_node(name).get_global_rect().intersects(hud.get_node("TimerPanel").get_global_rect()), "Debug %s clears timer at %s" % [name, geometry])
		await screenshot("debug-hud-%d" % geometry.x)
		await key(KEY_F3)
		boss.queue_free()
		await settle()
		await key(KEY_SPACE)
		for letter in "regeneration":
			await key(letter.to_upper().unicode_at(0), letter.unicode_at(0))
		check(game.spell_manager.current_typing_text == "regeneration", "Long cast types at %s" % geometry)
		await screenshot("typing-%d" % geometry.x)
		await key(KEY_ESCAPE)
		await key(KEY_ESCAPE)
		await key(KEY_DOWN)
		await key(KEY_ENTER)
		await settle()
		var book = game.get_node("PauseInput").spellbook
		check(is_instance_valid(book), "Keyboard opens spellbook")
		for button in book.spell_buttons.values():
			for word in button.text.split(" "):
				check(button.get_theme_font("font").get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x <= button.size.x - 20, "Spellbook word fits: %s at %s" % [word, geometry])
		var last = book.spell_buttons.values().back()
		for i in range(14):
			if root.gui_get_focus_owner() == last:
				break
			await key(KEY_TAB)
		await settle()
		check(root.gui_get_focus_owner() == last, "Tab reaches bonus spell")
		var book_scroll = book.find_child("BuildScroll", true, false)
		check(book_scroll.get_global_rect().intersects(last.get_global_rect()), "Focused bonus spell scrolls into view")
		await screenshot("book-%d" % geometry.x)
		await key(KEY_ESCAPE)
		await key(KEY_ESCAPE)
		await settle()
	game.typing_keycaps.completion_remaining = 1.0
	game.get_node("UI/HUD/TypingPanel").show()
	game.change_state(game.GameState.PAUSED)
	check(not game.get_node("UI/HUD/TypingPanel").visible, "Pause clears stale cast completion")
	game.spell_manager.last_spell_cast_time = game.spell_manager.casting_clock
	game.get_node("PauseInput").open_spellbook()
	await settle()
	var recovering_book = game.get_node("PauseInput").spellbook
	recovering_book.spell_buttons[1].pressed.emit()
	check(is_instance_valid(recovering_book) and recovering_book.notice.visible and paused, "Recovering spell stays in book with visible explanation")
	recovering_book.close()
	game.change_state(game.GameState.PLAYING)
	await settle(0.5)
	game.finish_run(false)
	await settle(0.5)
	await screenshot("death-480")
	check(paused and game.game_over_screen.visible, "Death pauses with ending visible")
	await key(KEY_ENTER)
	await settle(0.5)
	game = current_scene
	check(game.game_time < 2 and game.spell_manager.spells.size() == 1 and not paused, "Retry resets time, kit and pause")
	game.finish_run(true)
	await settle(0.5)
	check(game.game_over_screen.title_label.text == "VICTORY!", "Victory gets its own ending")
	await screenshot("victory-480")
	await key(KEY_ESCAPE)
	await settle()
	check(current_scene.has_node("MenuPanel") and not paused, "Ending returns to usable menu")
	for geometry in [Vector2i(480, 640), Vector2i(800, 600), Vector2i(1280, 720)]:
		root.size = geometry
		await settle()
		var menu_panel = current_scene.get_node("MenuPanel")
		check(current_scene.get_global_rect().encloses(menu_panel.get_global_rect()), "Main panel fits %s" % geometry)
		await screenshot("menu-%d" % geometry.x)
		current_scene._on_options_button_pressed()
		await settle()
		var panel = current_scene.get_node("OptionsPanel")
		check(panel.get_global_rect().encloses(current_scene.get_node("OptionsPanel/VBoxContainer/BackButton").get_global_rect()), "Options Back fits %s" % geometry)
		await screenshot("options-%d" % geometry.x)
		await key(KEY_ESCAPE)
		await settle()
	print("UI UX journeys: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
