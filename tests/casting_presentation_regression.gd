extends SceneTree

var checks = 0
var failures = 0

class Threat extends Node2D:
	var encounter_name = "Test threat"
	var current_health = 10.0
	var max_health = 10.0
	var dying = false

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
	for i in range(10):
		await process_frame

func key(unicode: int, code: Key = KEY_NONE) -> InputEventKey:
	var event = InputEventKey.new()
	event.pressed = true
	event.unicode = unicode
	event.keycode = code
	return event

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
	manager.set_process(false)
	var caps = game.typing_keycaps
	for glyph in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_/\\+=[]{}',?.:;!~`$#@%^&*()<>|\"":
		check(caps.textures.has(glyph), "Texture exists: " + glyph)
		if caps.textures.has(glyph):
			var texture = caps.textures[glyph]
			check(texture.get_size() == Vector2(32, 32), "Native key dimensions: " + glyph)
			check(texture.get_image().get_used_rect().has_area(), "Key has pixels: " + glyph)
	manager.queue_spell(1)
	manager.start_typing()
	manager.handle_typing_input(key(98))
	check(caps.letters == "b", "Real numbered input creates a letter key")
	check(caps.ages.size() == 1 and caps.ages[0] == 0, "New key begins its drop")
	manager.handle_typing_input(key(120))
	check("Mismatch" in caps.feedback, "Incorrect input remains a visible mismatch")
	manager.handle_typing_input(key(0, KEY_BACKSPACE))
	check(caps.letters == "b", "Backspace removes only the final key")
	check(caps.fragments.size() == 4, "Removed key breaks into four fading pieces")
	for i in range(30):
		manager.handle_typing_input(key(120))
		manager.handle_typing_input(key(0, KEY_BACKSPACE))
	check(caps.fragments.size() <= 64, "Repeated input keeps particle allocation bounded")
	manager.handle_typing_input(key(111))
	manager.handle_typing_input(key(108))
	manager.handle_typing_input(key(116))
	check(not manager.is_typing, "Completed learned spell casts without visual delay")
	check(caps.letters == "bolt" and caps.completion_remaining > 0, "Successful cast preserves its final key briefly")
	await create_timer(0.4, true, false, true).timeout
	check(caps.letters.is_empty(), "Completed word clears after presentation")
	check(not game.get_node("UI/HUD/TypingPanel").visible, "Completion panel closes")
	manager.space_casting = true
	manager.start_freeform_typing()
	manager.handle_freeform_typing_input(key(98))
	check(caps.letters == "b", "Space casting shares the key renderer")
	check("Matches:" in caps.visible_caption(), "Owned spell suggestions remain visible")
	manager.current_typing_text = "bolt"
	manager.update_freeform_typing_display()
	check("Ready to cast" in caps.visible_caption(), "Completed owned incantation visibly says ready")
	manager.current_typing_text = "lightning bolt"
	manager.update_freeform_typing_display()
	check(not "Ready to cast" in caps.visible_caption(), "Unowned Lightning Bolt is not a starter alias")
	manager.current_typing_text = "a".repeat(caps.columns() + 1)
	manager.update_freeform_typing_display()
	var old_height = game.typing_label.custom_minimum_size.y
	manager.handle_freeform_typing_input(key(0, KEY_BACKSPACE))
	check(game.typing_label.custom_minimum_size.y == old_height, "Backspace preserves single-row height")
	await create_timer(0.4, true, false, true).timeout
	check(game.typing_label.custom_minimum_size.y == old_height, "Dissolving fragments do not resize the prompt")
	manager.current_typing_text = "meteor shower"
	manager.update_freeform_typing_display()
	manager.attempt_freeform_cast()
	check(manager.is_typing and caps.letters == "meteor shower", "Unowned spell stays rejected with input preserved")
	for geometry in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(800, 600)]:
		root.size = geometry
		game.get_node("GameplayReadability").layout()
		manager.current_typing_text = "long incantation ".repeat(8)
		manager.update_freeform_typing_display()
		await settle()
		check(caps.key_position(caps.letters.length() - 1).y == caps.key_position(0).y, "Long incantations stay on one line")
		check(caps.key_position(caps.letters.length() - 1).x + caps.fitted_key_size() <= caps.size.x and caps.key_position(caps.letters.length() - 1).x >= 0, "Horizontal overflow reveals the newest key")
		check(game.get_node("UI/HUD").get_global_rect().encloses(game.get_node("UI/HUD/TypingPanel").get_global_rect()), "Typing panel stays in viewport")
	manager.cancel_typing()
	check(caps.letters.is_empty() and caps.fragments.is_empty(), "Cancellation clears keys and fragments")
	check(not game.get_node("UI/HUD/TypingPanel").visible, "Cancellation closes presentation")
	root.size = Vector2i(1280, 720)
	await settle()
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await process_frame
	var staff = game.player.get_node("OrbitingStaff")
	staff.set_process(false)
	var near = Threat.new()
	var boss = Threat.new()
	for enemy in [near, boss]:
		game.add_child(enemy)
		enemy.add_to_group("enemies")
	near.global_position = game.player.global_position + Vector2(60, 0)
	boss.global_position = game.player.global_position + Vector2(-220, 0)
	check(staff.select_target() == near, "Nearest visible living threat selected")
	boss.add_to_group("bosses")
	check(staff.select_target() == boss, "Visible boss overrides nearer ordinary enemy")
	boss.global_position.x += 10000
	check(staff.select_target() == near, "Offscreen boss cannot steal targeting")
	boss.global_position = game.player.global_position + Vector2(-220, 0)
	boss.dying = true
	check(staff.select_target() == near, "Dying boss excluded")
	boss.dying = false
	boss.hide()
	check(staff.select_target() == near, "Hidden boss excluded")
	boss.show()
	boss.current_health = 0
	check(staff.select_target() == near, "Dead boss excluded")
	staff.orbit_angle = PI
	staff.update_orbit(0.1)
	check(absf(staff.orbit_angle - PI) <= staff.angular_speed * 0.1 + 0.001, "Angular movement is capped")
	check(is_equal_approx(staff.position.length(), staff.orbit_radius), "Staff follows circle rather than cutting through wizard")
	check(absf(staff.staff.rotation) < 0.07, "Staff stays upright with a small floating wobble")
	near.queue_free()
	check(staff.select_target() == null, "Queued enemy immediately excluded")
	await process_frame
	staff.update_orbit(0.1)
	check(staff.target == null, "Freed target clears safely")
	check(not staff.eligible(boss), "Known-bad dead visible threat fails eligibility")
	game.queue_free()
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await create_timer(0.25, true, false, true).timeout
	print("Casting presentation: %d assertions, %d failures" % [checks, failures])
	quit(1 if failures else 0)
