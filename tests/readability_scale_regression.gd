extends SceneTree

var checks = 0
var failures = 0
var visual = "--visual" in OS.get_cmdline_user_args()

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
	await create_timer(0.4, true, false, true).timeout
	await process_frame

func run():
	if visual:
		root.set_flag(Window.FLAG_NO_FOCUS, true)
		root.position = Vector2i(5000, 5000)
		DirAccess.make_dir_recursive_absolute("res://builds/readability-evidence")
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.is_invincible = true
	check(game.get_node("Camera2D").zoom == Vector2.ONE * 1.2, "Camera candidate is baseline times 1.2")
	check(game.player.get_node("Sprite2D").scale == Vector2.ONE * 3.5, "Player visual growth is 1.75")
	check(game.player.get_node("CollisionShape2D").shape.size == Vector2(64, 64), "Trunk navigation footprint remains deliberate baseline")
	if visual:
		root.size = Vector2i(1280, 720)
		var monsters = game.get_node("MonsterManager")
		var index = 0
		for id in monsters.encounter_config.variants:
			if index >= 4:
				break
			var definition = monsters.encounter_config.variants[id].duplicate(true)
			definition.id = id
			var enemy = monsters.spawn_monster(definition, index == 3)
			enemy.global_position = game.player.global_position + Vector2(-400 + index * 260, 180)
			enemy.set_physics_process(false)
			index += 1
		for value in [10, 25, 100]:
			var gem = load("res://scenes/XPOrb.tscn").instantiate()
			gem.xp_value = value
			gem.position = game.player.global_position + Vector2(-220 + 100 * [10, 25, 100].find(value), -170)
			game.add_child(gem)
			gem.set_process(false)
		await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/readability-evidence/scale-candidate.png")
		game.camera.zoom = Vector2.ONE
		game.player.get_node("Sprite2D").scale /= 1.75
		for enemy in get_nodes_in_group("enemies"):
			enemy.get_node("Sprite2D").scale /= 1.75
		for gem in get_nodes_in_group("xp_orbs"):
			gem.get_node("Visual").scale = Vector2.ONE * 1.5
		await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/readability-evidence/scale-baseline-reference.png")
		game.camera.zoom = Vector2.ONE * 1.2
		game.player.get_node("Sprite2D").scale *= 1.75
		for enemy in get_nodes_in_group("enemies"):
			enemy.queue_free()
		for gem in get_nodes_in_group("xp_orbs"):
			gem.queue_free()
	var manager = game.spell_manager
	var keys = game.typing_keycaps
	for geometry in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(480, 640)]:
		root.size = geometry
		manager.is_typing = true
		manager.target_spell = ""
		for name in ["regeneration", "super extreme meteor shower deluxe", "lightning bolt"]:
			manager.current_typing_text = name
			game.update_typing_display(name)
			await settle()
			if visual:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://builds/readability-evidence/%s-%s.png" % [geometry.x, name.replace(" ", "-")])
			check(keys.key_position(0).y == keys.key_position(name.length() - 1).y, "One line at %s for %s" % [geometry, name])
			check(keys.key_position(name.length() - 1).x + keys.KEY_SIZE <= keys.size.x, "Newest key remains inside prompt")
			check(keys.key_position(name.length() - 1).x >= 0, "Newest key remains fully visible")
			check(game.typing_label.custom_minimum_size.y == 88, "Typing height is fixed")
			manager.current_typing_text = name.left(name.length() - 1)
			game.update_typing_display(manager.current_typing_text)
			await settle()
			check(keys.letters == manager.current_typing_text, "Backspace updates visible letters")
		manager.cancel_typing()
		await settle()
		check(keys.letters.is_empty(), "Cancel clears letters")
	var orb = load("res://scenes/XPOrb.tscn").instantiate()
	orb.position = Vector2(2000, 2000)
	root.add_child(orb)
	await settle()
	var visual = orb.get_node("Visual")
	check(visual.scale == Vector2.ONE * 2.5, "Low XP apparent scale is twice baseline including camera")
	var low_texture = visual.texture
	orb.xp_value = 25
	check(visual.texture != low_texture, "Stored XP setter updates tier immediately")
	var green_texture = visual.texture
	orb.set_xp_value(100)
	check(visual.texture != green_texture, "High stored XP selects purple")
	var stable = visual.scale
	await create_timer(1.1).timeout
	check(visual.scale == stable, "Crystal size does not pulse")
	check(orb.xp_value == 100, "Visual updates preserve XP")
	var burst = load("res://scripts/EffectBurst.gd").new()
	check(burst.particle_size == 25, "Cosmetic particles grow independently of radius")
	check(burst.radius == 24, "Particle geometry remains unchanged")
	burst.free()
	orb.queue_free()
	game.queue_free()
	await settle()
	print("Readability scale checks: ", checks, ", failures: ", failures)
	for child in get_root().get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await create_timer(0.3, true, false, true).timeout
	quit(1 if failures else 0)
