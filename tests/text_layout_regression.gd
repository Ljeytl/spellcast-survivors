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
	game.update_typing_display(long_copy.repeat(20))
	await settle()
	var area = game.typing_label.get_parent() as ScrollContainer
	var box = area.get_parent() as Control
	check(box.get_global_rect().encloses(area.get_global_rect()), "Typing scroll area fits box")
	check(game.typing_label.size.x <= area.size.x, "Typing text wraps within box width")
	check(box.size.y <= game.get_viewport_rect().size.y * 0.35, "Long typing stays bounded")
	check(area.get_v_scroll_bar().max_value > area.size.y, "All long typing text remains scrollable")
	check(area.scroll_vertical >= area.get_v_scroll_bar().max_value - area.get_v_scroll_bar().page - 1, "New input is scrolled to the end")
	game.update_typing_display("Type: bolt")
	await settle()
	check(is_equal_approx(box.size.y, 120), "Short typing shrinks back")
	print("Text layout: ", checks, " assertions, ", failures, " failures")
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	game.queue_free()
	paused = false
	await create_timer(0.2).timeout
	quit(1 if failures else 0)
