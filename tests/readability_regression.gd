extends SceneTree

var checks = 0
var failures = 0
var restart_count = 0

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
	for i in range(15):
		await process_frame

func contains(outer: Control, inner: Control) -> bool:
	return outer.get_global_rect().grow(0.1).encloses(inner.get_global_rect())

func run():
	root.size = Vector2i(1280, 720)
	var progression = root.get_node("CharacterManager")
	progression.discovered_synergies = ["life_bolt"]
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.set_interface_debug(true)
	var manager = game.spell_manager
	var ui = game.get_node("GameplayReadability")
	var hud = game.get_node("UI/HUD")
	var camera_zoom = game.get_node("Camera2D").zoom
	for geometry in [Vector2i(1280, 720), Vector2i(800, 900), Vector2i(960, 540)]:
		root.size = geometry
		ui.layout()
		await settle()
		check(game.get_node("Camera2D").zoom == camera_zoom, "UI resize preserves camera zoom")
		check(hud.size.x >= 790, "HUD has readable logical width")
		for slot in game.spell_slots:
			check(slot.get_node("SlotBackground").size == slot.size, "Selection background covers whole card")
			check(contains(hud, slot), "Spell card stays within viewport")
			check(contains(slot, slot.get_node("LevelLabel")), "Rank/empty text remains inside card")
			check(slot.get_node("LevelLabel").size.y >= slot.get_node("LevelLabel").get_minimum_size().y, "Rank/empty text has all wrapped lines")
			check(contains(slot, slot.get_node("VBox/SpellName")), "Spell name remains inside card")
		check(not hud.get_node("StatsPanel").get_global_rect().intersects(hud.get_node("TimerPanel").get_global_rect()), "Health and clock never overlap")
		game.update_typing_display("CAST · meteor shower\nmeteor shx\nMismatch · Backspace to correct")
		await settle()
		check(hud.get_node("TypingPanel").position.y + hud.get_node("TypingPanel").size.y <= hud.size.y * 0.5 - 39, "Casting clears player projection at screen center")
		check(contains(hud, hud.get_node("TypingPanel")), "Casting prompt stays in viewport")
		check(contains(hud.get_node("TypingPanel"), game.typing_label.get_parent()), "Casting scroll area contained")
		check(not hud.get_node("TypingPanel").get_global_rect().intersects(hud.get_node("SpellSlotsPanel").get_global_rect()), "Casting does not cover spell slots")
		var pause_panel = game.get_node("UI/PauseOverlay/PauseMenu")
		check(contains(pause_panel, pause_panel.get_node("VBoxContainer/MainMenuButton")), "Pause actions contained")
		game.level_up_screen.show_level_up(2, {})
		await settle()
		check(contains(game.level_up_screen.panel, game.level_up_screen.reroll_button), "Offer actions contained")
		game.level_up_screen.hide()
	root.size = Vector2i(960, 540)
	ui.layout()
	manager.queue_spell(1)
	manager.start_typing()
	manager.current_typing_text = "b"
	manager.update_typing_display()
	await settle()
	var typing_area = game.typing_label.get_parent()
	check("b" in game.typing_label.text, "Short window includes actual typed character")
	check(game.typing_label.get_minimum_size().y <= typing_area.size.y, "Normal numbered cast needs no vertical scroll at 540px")
	check(typing_area.get_global_rect().encloses(game.typing_label.get_global_rect()), "Typed character body fully visible at 540px")
	for supplemental in [ui.passive_label, ui.focus_label, ui.focus_bar]:
		check(not supplemental.visible or not hud.get_node("TypingPanel").get_global_rect().intersects(supplemental.get_global_rect()), "Casting never overlaps visible supplemental HUD")
	manager.cancel_typing()
	await settle()
	check(ui.passive_label.visible and ui.focus_label.visible and ui.focus_bar.visible, "Supplemental HUD returns after casting")
	manager.space_casting = true
	manager.start_freeform_typing()
	manager.current_typing_text = "lightning bolt"
	manager.update_freeform_typing_display()
	await settle()
	check(game.typing_label.get_minimum_size().y <= typing_area.size.y, "Normal Space cast needs no vertical scroll at 540px")
	check(typing_area.get_global_rect().encloses(game.typing_label.get_global_rect()), "Space input visible at 540px")
	manager.current_typing_text = "meteor shower"
	manager.update_freeform_typing_display()
	await settle()
	check(game.typing_label.get_minimum_size().y <= typing_area.size.y, "Unowned name feedback stays visible at 540px")
	manager.attempt_freeform_cast()
	await settle()
	check(game.typing_label.get_minimum_size().y <= typing_area.size.y, "Rejected cast retains visible input at 540px")
	game.typing_label.text = "CAST · bolt\nb\nKeep typing · Esc cancels"
	await settle()
	check(game.typing_label.get_minimum_size().y > typing_area.size.y, "Known-bad old three-line prompt fails visible-input budget at 540px")
	manager.cancel_typing()
	root.size = Vector2i(1280, 720)
	ui.layout()
	await settle()
	var choices = game.level_up_screen
	choices.show_level_up(3, {})
	choices._on_lock_mode_toggled()
	check("lock or unlock" in choices.get_node("Panel/VBoxContainer/UpgradeLabel").text, "Lock mode explains card action")
	choices.lock_upgrade(0)
	check(choices.upgrade_buttons[0].get_node("CardText").text.begins_with("LOCKED"), "Locked card has textual marker")
	check(choices.upgrade_cards[0].modulate == Color.WHITE, "Locked card does not tint its whole contents")
	choices.lock_upgrade(0)
	check(not choices.upgrade_buttons[0].get_node("CardText").text.begins_with("LOCKED"), "Unlock removes textual marker")
	choices._on_banish_mode_toggled()
	check("banish from this run" in choices.get_node("Panel/VBoxContainer/UpgradeLabel").text, "Banish mode explains card action")
	choices.hide()
	manager.learn_spell("earth_shield")
	manager.space_casting = true
	manager.start_freeform_typing()
	check("Enter casts" in hud.get_node("TypingPanel/SlowdownStatus").text, "Space prompt requires Enter")
	for alias in ["lightning bolt", "earth shield", "earth_shield"]:
		manager.current_typing_text = alias
		manager.update_freeform_typing_display()
		check(not "No matching spell" in game.typing_label.text, "Owned visible/canonical alias matches: " + alias)
	manager.current_typing_text = "meteor shower"
	manager.update_freeform_typing_display()
	check("No matching spell" in game.typing_label.text, "Unowned name shows no match")
	check(not manager.cast_freeform_spell("meteor shower"), "Feedback never grants ownership")
	manager.cancel_typing()
	manager.queue_spell(1)
	manager.start_typing()
	check("Finish name to cast" in hud.get_node("TypingPanel/SlowdownStatus").text and not "Enter casts" in hud.get_node("TypingPanel/SlowdownStatus").text, "Numbered prompt explains automatic completion")
	manager.current_typing_text = "bx"
	manager.update_typing_display()
	check("Mismatch" in game.typing_label.text, "Numbered casting exposes typo")
	check(game.typing_label.modulate == Color("ff8175"), "Mismatch has danger color")
	manager.current_typing_text = "b"
	manager.update_typing_display()
	check(not "Mismatch" in game.typing_label.text, "Correction removes stale mismatch")
	manager.typing_slowdown_remaining = 0
	ui._process(0)
	check("EMPTY" in ui.focus_label.text, "Exhaustion visibly says normal speed")
	manager.cancel_typing()
	ui._process(0)
	check("full in" in ui.focus_label.text, "Recharge visible outside casting")
	manager.typing_slowdown_remaining = manager.typing_slowdown_capacity
	ui._process(0)
	check("READY" in ui.focus_label.text, "Full budget visibly ready")
	var slot_style = game.spell_slots[0].get_node("SlotBackground").get_theme_stylebox("panel")
	game.highlight_spell_slot(0)
	check(slot_style.border_color == Color("79d9e8"), "Selected slot cyan")
	game.clear_spell_slot_highlights()
	check(slot_style.border_color != Color("79d9e8"), "Cancel clears selected slot")
	game.change_state(game.GameState.PAUSED)
	game._on_pause_options_pressed()
	await settle()
	var options = game.get_node("UI/Options")
	check(options.process_mode == Node.PROCESS_MODE_ALWAYS and options.can_process(), "Pause options interactive while paused")
	check(contains(hud, options), "Pause options shares HUD viewport bounds")
	var escape = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	options._input(escape)
	await settle()
	check(game.current_state == game.GameState.PAUSED and game.pause_overlay.visible, "Options Escape returns to paused menu")
	game.change_state(game.GameState.PLAYING)
	manager.learn_spell("cinder_field")
	manager.learn_spell("ice_blast")
	manager.learn_spell("steam_field")
	game.get_node("MonsterManager").game_time = 472
	game.finish_run(false)
	await settle()
	var result = game.game_over_screen
	check("7:52" in result.survival_time_label.text, "Result shows simulation survival time")
	check("Steam Field" in result.kit_label.text and not "Cinder Field" in result.kit_label.text, "Result snapshots evolved current kit")
	check("Steam Field" in result.discovery_label.text and not "Life Bolt" in result.discovery_label.text, "Only discoveries new this run appear")
	for geometry in [Vector2i(1280, 720), Vector2i(800, 900), Vector2i(960, 540)]:
		root.size = geometry
		ui.layout()
		await settle()
		check(contains(result.panel, result.play_again_button), "Result actions contained")
		check(contains(result.panel, result.get_node("Background/Panel/VBoxContainer/RunSummaryScroll")), "Summary scroll stays inside results")
	result.restart_game.disconnect(game._on_restart_game)
	result.restart_game.connect(func(): restart_count += 1)
	result._on_play_again_pressed()
	result._on_play_again_pressed()
	check(restart_count == 1, "Repeated result action dispatches once")
	var label = game.spell_slots[1].get_node("LevelLabel")
	label.position.x = -1000
	check(not contains(game.spell_slots[1], label), "Known-bad displaced label rejected by containment")
	manager.current_typing_text = "meteor shower"
	check(manager.find_spell_slot(manager.current_typing_text) == 0, "Known-bad unowned match rejected independently of display")
	game.queue_free()
	paused = false
	await settle()
	for menu_data in [["MainMenu", "MenuPanel"], ["Options", "OptionsPanel"], ["HowToPlay", "HowToPlayPanel"]]:
		var menu = load("res://scenes/" + menu_data[0] + ".tscn").instantiate()
		root.add_child(menu)
		for geometry in [Vector2i(1280, 720), Vector2i(800, 900), Vector2i(960, 540)]:
			root.size = geometry
			menu._layout_readable_menu()
			await settle()
			var panel = menu.get_node(menu_data[1])
			check(contains(menu, panel), "Menu panel within viewport: " + menu_data[0])
			for button in panel.find_children("*", "Button", true, false):
				check(contains(panel, button), "Menu action contained: " + str(button.name))
			check(menu.get_theme_font_size("font_size", "Label") >= 18, "Menu readable label size")
		if menu_data[0] == "MainMenu":
			menu._on_collection_pressed()
			await settle()
			var collection = menu.get_child(menu.get_child_count() - 1)
			for label_node in collection.find_children("*", "Label", true, false):
				check(label_node.get_theme_font_size("font_size") >= 18, "Collection text retains readable size")
			collection.close_collection()
		menu.queue_free()
		await settle()
	print("Readability: ", checks, " assertions, ", failures, " failures")
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	paused = false
	await create_timer(0.2).timeout
	quit(1 if failures else 0)
