extends SceneTree

var checks = 0
var failures = 0
var screenshots = "res://builds/ux-evidence"

class Boss extends Node2D:
	var dying = false
	var encounter_name = "Test boss"
	var current_health = 1200.0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func settle():
	for index in range(15):
		await process_frame

func key(code: int, character: int = 0):
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.unicode = character
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)

func click(control: Control):
	var event = InputEventMouseButton.new()
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)

func capture(filename: String):
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(screenshots + "/" + filename + ".png")

func cast_uninterrupted(game) -> bool:
	return game.spell_manager.is_typing and game.current_state == game.GameState.PLAYING and not paused

func run():
	DirAccess.make_dir_recursive_absolute(screenshots)
	root.size = Vector2i(1280, 720)
	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	await settle()
	check("SHOULDA" in menu.get_node("MenuPanel/VBoxContainer/Title").text, "Player-facing title is correct")
	check(menu.get_node("BuildVersion").text == preload("res://scripts/BuildVersion.gd").text(), "Main menu version comes from project setting")
	await capture("menu")
	menu.queue_free()
	await settle()
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.is_invincible = true
	var manager = game.spell_manager
	var inventory = game.hud.get_node("RunInventory")
	var reference = game.hud.get_node("CastingReference")
	check(inventory.cards.has("bolt"), "Starting Bolt has icon/rank card")
	manager.learn_spell("lightning")
	manager.learn_spell("lightning_bolt")
	manager.upgrade_spell("bolt")
	game.player.apply_upgrade({"effect": {"type": "spell_damage", "value": 0.1}})
	await settle()
	check(reference.entries.bolt.text == "1  bolt", "Bottom reference shows Bolt binding and exact incantation")
	check(reference.entries.lightning_bolt.text == "lightning bolt", "Combination reference has exact name without shortcut")
	check(inventory.cards.has("lightning_bolt"), "Unlocked combination appears without occupying active slot")
	inventory.cards.lightning_bolt.hide()
	check(not inventory.cards.lightning_bolt.is_visible_in_tree(), "Known-bad hidden-combination control is detected")
	inventory.cards.lightning_bolt.show()
	check(inventory.cards.lightning_bolt.is_visible_in_tree(), "Restored combination is actually visible")
	check(inventory.cards.has("spell_damage"), "Passive appears in own row")
	check(inventory.cards.spell_damage.get_meta("full_text") == "Spell Power +10%" and "damage, healing and protection" in inventory.cards.spell_damage.tooltip_text, "Passive reads as a name and total")
	check("Rank 2" in inventory.cards.bolt.tooltip_text, "Upgrade rank refreshes")
	click(inventory.cards.lightning_bolt)
	check(manager.is_typing and "lightning" in manager.target_spell, "Combination card starts owned cast")
	manager.cancel_typing()
	await settle()
	manager.casting_clock += 1
	key(KEY_1)
	key(KEY_B, 98)
	game._on_player_level_up(2, {})
	game._on_player_level_up(3, {})
	check(manager.is_typing and game.current_state == game.GameState.PLAYING, "Level-up does not interrupt incantation")
	var prior_state = game.current_state
	game.current_state = game.GameState.LEVEL_UP
	check(not cast_uninterrupted(game), "Known-bad interrupted casting state rejected")
	game.current_state = prior_state
	check(cast_uninterrupted(game), "Restored active casting state accepted")
	check(game.pending_level_ups.size() == 2, "Multiple earned levels remain queued")
	key(KEY_O, 111)
	key(KEY_L, 108)
	key(KEY_T, 116)
	await settle()
	check(game.current_state == game.GameState.LEVEL_UP and game.spells_cast == 1, "Completed cast opens pending choice once")
	check(not game.hud.get_node("TypingPanel").visible, "Pending choice has no empty typing panel behind it")
	check(game.pending_level_ups.size() == 1, "Only one pending reward consumed")
	game.console_instance.open_console()
	await create_timer(0.4, true, false, true).timeout
	game.console_instance.input_field.text = ""
	for character in "ui_debug off":
		key(character.to_upper().unicode_at(0), character.unicode_at(0))
	check(game.console_instance.input_field.text == "ui_debug off", "Console retains spaces while an upgrade is open")
	game.console_instance.close_console()
	await create_timer(0.4, true, false, true).timeout
	game.level_up_screen.upgrade_buttons[0].grab_focus()
	key(KEY_SPACE)
	await settle()
	check(game.current_state == game.GameState.LEVEL_UP and game.pending_level_ups.size() == 1, "Space cannot accidentally select upgrade")
	await capture("level-up")
	click(game.level_up_screen.upgrade_buttons[0])
	await create_timer(0.35, true, false, true).timeout
	await settle()
	check(game.current_state == game.GameState.LEVEL_UP and game.pending_level_ups.is_empty(), "Next queued reward follows selection")
	click(game.level_up_screen.upgrade_buttons[0])
	await create_timer(0.35, true, false, true).timeout
	await settle()
	check(game.current_state == game.GameState.PLAYING, "Queue drains back to gameplay")
	manager.casting_clock += 1
	key(KEY_1)
	game._on_player_level_up(4, {})
	key(KEY_ESCAPE)
	await settle()
	check(game.current_state == game.GameState.LEVEL_UP, "Cancelling cast also releases queued reward")
	click(game.level_up_screen.upgrade_buttons[0])
	await create_timer(0.35, true, false, true).timeout
	await settle()
	manager.casting_clock += 1
	manager.activate_spell_slot(1)
	game._on_player_level_up(5, {})
	manager.cancel_typing()
	game.toggle_pause()
	await settle()
	check(game.current_state == game.GameState.PAUSED and game.pending_level_ups.size() == 1, "Deferred reward cannot replace a newly opened pause menu")
	game.toggle_pause()
	await settle()
	check(game.current_state == game.GameState.LEVEL_UP, "Resume releases reward deferred by pause")
	click(game.level_up_screen.upgrade_buttons[0])
	await create_timer(0.35, true, false, true).timeout
	await settle()
	var boss = Boss.new()
	game.add_child(boss)
	boss.add_to_group("bosses")
	boss.global_position = game.player.global_position + Vector2(3000, 0)
	await settle()
	var arrow = game.hud.get_node("BossDirection")
	check(arrow.has_target, "Offscreen boss receives edge arrow")
	await capture("inventory-desktop")
	boss.global_position = game.player.global_position
	await settle()
	check(not arrow.has_target, "Visible boss has no arrow")
	boss.global_position += Vector2(3000, 0)
	boss.dying = true
	await settle()
	check(not arrow.has_target, "Defeated boss has no arrow")
	manager.spells.clear()
	manager.bonus_spells.clear()
	manager.acquired_spells.clear()
	for id in ["bolt", "lightning", "life", "focus_ray", "ember_spear", "meteor_shower"]:
		check(manager.learn_spell(id), "Full-kit fixture learns " + id)
	for id in ["lightning_bolt", "life_bolt", "prism_ray", "meteor_spear"]:
		check(manager.learn_spell(id), "Full-kit fixture discovers " + id)
	game.player.passive_ranks = {"spell_damage": 6, "movement_speed": 2, "max_health": 3, "xp_range": 4, "projectile_speed": 1, "slowdown_duration": 5}
	boss.dying = false
	boss.global_position = game.player.global_position + Vector2(50, 0)
	await settle()
	check(inventory.cards.size() == 16, "Full kit shows six active, six passive, four combination cards")
	for geometry in [Vector2i(1280,720), Vector2i(640,480), Vector2i(480,640)]:
		root.size = geometry
		game.get_node("GameplayReadability").layout()
		await settle()
		for entry in reference.entries.values():
			check(entry.is_visible_in_tree(), "Full-kit incantation visible while planning")
			check(game.hud.get_global_rect().encloses(entry.get_global_rect()), "Incantation chip inside HUD")
			check(entry.size.x >= entry.get_minimum_size().x, "Incantation not clipped")
			for card in inventory.cards.values():
				check(not entry.get_global_rect().intersects(card.get_global_rect()), "Reference clears inventory")
			var guidance = game.get_node("GameplayReadability").guidance
			check(not entry.get_global_rect().intersects(guidance.get_global_rect()), "Reference clears acquisition feedback")
		var wizard_screen = game.player.get_global_transform_with_canvas() * Vector2.ZERO
		for card in inventory.cards.values():
			check(game.hud.get_global_rect().encloses(card.get_global_rect()), "Inventory cards remain inside HUD")
			check(not card.get_global_rect().grow(20).has_point(wizard_screen), "Inventory clears wizard and immediate movement space")
		check(game.hud.get_node("BuildVersion").text == preload("res://scripts/BuildVersion.gd").text(), "Gameplay shares version")
		await capture("inventory-" + str(geometry.x))
	game.toggle_pause()
	await settle()
	check(game.pause_overlay.get_node("BuildVersion").is_visible_in_tree(), "Pause version visible")
	await capture("pause")
	game.change_state(game.GameState.PLAYING)
	manager.casting_clock += 1
	manager.activate_spell_slot(1)
	game._on_player_level_up(5, {})
	game.finish_run(false)
	await settle()
	check(game.pending_level_ups.is_empty() and game.current_state == game.GameState.GAME_OVER, "Death clears pending rewards without reopening choice")
	await capture("result")
	game.queue_free()
	await settle()
	print("PLAYTEST_UX: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
