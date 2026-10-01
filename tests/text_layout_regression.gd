extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func settle():
	for i in range(12):
		await process_frame

func contained(label: Label, card: Control) -> bool:
	return card.get_global_rect().encloses(label.get_global_rect()) and label.size.y >= label.get_minimum_size().y

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	await settle()
	var screen = game.level_up_screen
	var long_copy = "Learn a spell that restores health while you keep moving and casting other spells. "
	screen.available_upgrades = [
		{"name": "Regeneration", "description": long_copy, "effect": {}},
		{"name": "Life Bolt", "description": long_copy.repeat(8), "effect": {}},
		{"name": "Long word", "description": "abcdefghij".repeat(30), "effect": {}}
	]
	screen.update_ui(2)
	screen.show_screen()
	paused = true
	for width in [600.0, 420.0]:
		screen.panel.size.x = width
		await settle()
		for button in screen.upgrade_buttons:
			var copy = button.get_node("CardText") as Label
			check(contained(copy, button), "Wrapped card contains every line at width " + str(width))
			check(button.get_parent().size.y >= copy.get_minimum_size().y + 26, "Card reserves padding and progress bar")
			check(copy.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Text does not intercept selection")
		var scroll = screen.get_node("Panel/VBoxContainer/UpgradeScroll")
		check(scroll.get_v_scroll_bar().max_value > scroll.size.y, "Long offer can scroll")
		check(screen.panel.get_global_rect().encloses(screen.reroll_button.get_global_rect()), "Actions stay inside panel")
	var control = screen.upgrade_buttons[0].get_node("CardText") as Label
	control.autowrap_mode = TextServer.AUTOWRAP_OFF
	control.text = long_copy.repeat(10)
	await settle()
	check(not contained(control, screen.upgrade_buttons[0]), "Known-bad unwrapped text fails containment")
	screen.hide()
	paused = false
	# Compact incantation strip (cc78728): one line of fit-to-width keycaps with a bounded trailing window,
	# fixed strip height, width sized to the text. Long input no longer scrolls vertically.
	var manager = game.spell_manager
	var keys = game.typing_keycaps
	manager.space_casting = true
	manager.start_freeform_typing()
	manager.current_typing_text = long_copy.repeat(20)
	manager.update_freeform_typing_display()
	await settle()
	game._fit_typing_content()
	var area = game.typing_label.get_parent() as ScrollContainer
	var box = area.get_parent() as Control
	check(box.get_global_rect().encloses(area.get_global_rect()), "Typing scroll area fits box")
	check(box.get_global_rect().encloses(box.get_node("SlowdownStatus").get_global_rect()), "Budget status fits inside casting box")
	check(game.typing_label.size.x <= area.size.x, "Typing text wraps within box width")
	check(box.size.y <= game.get_viewport_rect().size.y * 0.35, "Long typing stays bounded")
	check(game.get_node("UI/HUD").get_rect().encloses(box.get_rect()), "Long typing strip stays on screen")
	check(not area.get_v_scroll_bar().visible, "Long typing needs no vertical scroll")
	var newest = keys.key_position(keys.letters.length() - 1)
	check(keys.letters.length() > 100 and newest.x >= 0 and newest.x + keys.fitted_key_size() <= keys.size.x, "Newest key of long typing stays visible")
	check(newest.y == keys.key_position(keys.visible_start()).y, "Long typing stays on one line")
	var long_size = box.size
	manager.current_typing_text = "bolt"
	manager.update_freeform_typing_display()
	await settle()
	game._fit_typing_content()
	check(box.size.x < long_size.x, "Short typing shrinks back")
	check(box.size.y <= long_size.y, "Short typing strip is no taller than long (error caption may add a line)")
	manager.cancel_typing()
	print("Text layout: ", checks, " assertions, ", failures, " failures")
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	game.queue_free()
	paused = false
	await create_timer(0.2).timeout
	quit(1 if failures else 0)
