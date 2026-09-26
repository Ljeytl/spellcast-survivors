extends SceneTree

var checks = 0
var failures = 0
const FONT = preload("res://assets/typecast/Keys/menu-font.fnt")

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func settle():
	for i in range(12):
		await process_frame

func run():
	for code in range(32, 127):
		check(FONT.has_char(code), "Printable glyph available: " + str(code))
	for size in [Vector2i(1280, 720), Vector2i(800, 600)]:
		root.size = size
		for scene in ["MainMenu", "Options", "HowToPlay"]:
			var menu = load("res://scenes/" + scene + ".tscn").instantiate()
			root.add_child(menu)
			current_scene = menu
			await settle()
			for button in menu.find_children("*", "Button", true, false):
				check(button.get_theme_font("font") == FONT, scene + " action uses real visible stone font")
				check(menu.get_global_rect().encloses(button.get_global_rect()), scene + " action stays in window")
				check(button.size.y >= button.get_minimum_size().y, scene + " action contains wrapped text")
			if scene == "MainMenu":
				menu._on_collection_pressed()
				await settle()
				for child in menu.get_children():
					if child.get_script() == preload("res://scripts/SpellCollection.gd"):
						check(child.scale == Vector2.ONE, "Nested collection does not apply root scaling twice")
						check(child.get_global_rect().is_equal_approx(menu.get_global_rect()), "Nested collection fills the actual menu")
			menu.queue_free()
			await process_frame
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	root.size = Vector2i(960, 540)
	game.get_node("GameplayReadability").layout()
	var choices = game.level_up_screen
	choices.show_level_up(2, {})
	choices.available_upgrades[0].name = "An exceptionally long magic upgrade name"
	choices.update_ui(2, {})
	await settle()
	var button = choices.upgrade_buttons[0]
	var title = button.get_node("KeyTitle")
	var body = button.get_node("CardText")
	check(title.get_theme_font("font") == FONT, "Upgrade name uses stone glyphs")
	check(body.get_theme_font("font") != FONT, "Long descriptions retain readable body font")
	check(title.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Heading cannot swallow clicks")
	check(title.size.y >= title.get_minimum_size().y, "Long heading wraps without clipping")
	check(title.get_global_rect().end.y <= body.get_global_rect().position.y, "Wrapped heading does not overlap description")
	check(button.get_global_rect().encloses(title.get_global_rect()), "Card contains title")
	var expected = title.text
	choices.lock_upgrade(0)
	check(title.text == expected and body.text.begins_with("LOCKED"), "Lock preserves title and shows separate lock state")
	choices.locks_remaining = 0
	choices.locked_upgrades.clear()
	choices.update_reroll_button_texts()
	check(choices.lock_button.disabled and "0" in choices.lock_button.text, "Disabled action preserves readable zero count")
	for action in [choices.reroll_button, choices.banish_button, choices.lock_button]:
		check(action.get_minimum_size().y <= 44, "Counts fit a single consistent action row")
	var correct_height = body.offset_top
	body.offset_top = 0
	check(title.get_global_rect().end.y > body.get_global_rect().position.y, "Known-bad missing heading spacing fails overlap invariant")
	body.offset_top = correct_height
	game.queue_free()
	await process_frame
	print("Menu keys: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
