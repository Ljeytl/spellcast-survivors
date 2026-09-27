extends SceneTree

var checks = 0
var failures = 0
var game

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func key(code, unicode = 0):
	var event = InputEventKey.new()
	event.keycode = code
	event.unicode = unicode
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func capture(name):
	await create_timer(0.6, true, false, true).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/pass2-evidence/" + name + ".png")

func run():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(5000, 5000)
	root.get_node("AudioManager").quitting = true
	DirAccess.make_dir_recursive_absolute("res://builds/pass2-evidence")
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	var manager = game.get_node("MonsterManager")
	manager.spawn_timer.stop()
	manager.set_process(false)
	game.player.is_invincible = true
	game.spell_manager.learn_spell("regeneration")
	for geometry in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(480, 640)]:
		root.size = geometry
		await process_frame
		await key(KEY_SPACE)
		for letter in "regeneration":
			await key(letter.to_upper().unicode_at(0), letter.unicode_at(0))
		check(game.spell_manager.current_typing_text == "regeneration", "Actual key events form owned long incantation")
		await capture("typing-%s" % geometry.x)
		await key(KEY_BACKSPACE)
		check(game.spell_manager.current_typing_text == "regeneratio", "Actual backspace removes final key")
		await key(KEY_N, 110)
		await key(KEY_ENTER)
		await create_timer(0.6, true, false, true).timeout
		check(not game.spell_manager.is_typing and not game.get_node("UI/HUD/TypingPanel").visible, "Cast completion clears prompt")
		await key(KEY_SPACE)
		await key(KEY_ESCAPE)
		check(not game.spell_manager.is_typing, "Reopen and cancel works")
		await capture("after-cast-%s" % geometry.x)
	root.size = Vector2i(1280, 720)
	var definition = manager.encounter_config.variants.juggernaut.duplicate(true)
	definition.id = "juggernaut"
	var boss = manager.spawn_monster(definition, true)
	boss.position = game.player.position + Vector2(300, 0)
	boss.take_damage(100000, game.player.position)
	await process_frame
	await process_frame
	await capture("boss-drop")
	for orb in get_nodes_in_group("xp_orbs"):
		orb.queue_free()
	await process_frame
	var chest = get_nodes_in_group("boss_rewards")[0]
	game.player.position = chest.position
	await physics_frame
	await physics_frame
	await capture("boss-choice")
	check(game.current_state == game.GameState.LEVEL_UP, "Walking into boss chest opens reward")
	game.level_up_screen.upgrade_buttons[0].pressed.emit()
	await create_timer(0.6, true, false, true).timeout
	check(game.current_state == game.GameState.PLAYING, "Reward button returns to gameplay")
	await capture("boss-reward-applied")
	var terrain = game.get_node("Background")
	var trunk = null
	for holder in terrain.decorations.values():
		for body in holder.get_children():
			if body.has_node("Canopy"):
				trunk = body
				break
		if trunk != null:
			break
	check(trunk != null, "Real grove fixture found")
	if trunk:
		game.player.set_physics_process(false)
		game.player.position = trunk.global_position + Vector2(-110, 0)
		await physics_frame
		var impact = game.player.move_and_collide(Vector2(220, 0))
		check(impact != null, "Larger visible wizard still collides with trunk")
		await capture("trunk-contact")
		game.player.position = trunk.global_position + Vector2(-110, 100)
		await physics_frame
		impact = game.player.move_and_collide(Vector2(220, 0))
		check(impact == null, "Wizard can pass below canopy outside trunk footprint")
		await capture("trunk-clearance")
		var unit_data = manager.encounter_config.variants.pursuer.duplicate(true)
		unit_data.id = "pursuer"
		var unit = manager.spawn_monster(unit_data)
		unit.set_physics_process(false)
		unit.position = trunk.global_position + Vector2(-70, 0)
		unit.recoil_from_contact(unit.position - Vector2(100, 0))
		for frame in range(14):
			unit._physics_process(1.0 / 60)
			await physics_frame
		check(unit.position.x < trunk.global_position.x - 10, "Contact recoil cannot tunnel through trunk")
		unit.queue_free()
		unit_data = manager.encounter_config.variants.charger.duplicate(true)
		unit_data.id = "charger"
		var dasher = manager.spawn_monster(unit_data, true)
		dasher.set_physics_process(false)
		dasher.position = trunk.global_position + Vector2(-250, 0)
		dasher.action_direction = Vector2.RIGHT
		dasher.charge_remaining = 1.0
		for frame in range(55):
			dasher._physics_process(1.0 / 60)
			await physics_frame
		check(dasher.position.x < trunk.global_position.x - 10, "Faster boss dash still respects trunk collision")
		await capture("dash-trunk-collision")
	game.queue_free()
	await process_frame
	print("Pass2 native journeys: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
