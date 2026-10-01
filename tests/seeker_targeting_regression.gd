extends SceneTree

var checks = 0
var failures = 0

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	var monsters = game.get_node("MonsterManager")
	monsters.set_process(false)
	monsters.spawn_timer.stop()
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	monsters.monsters_alive = 0
	var enemies: Array = []
	for offset in [Vector2(100, 0), Vector2(220, 60), Vector2(280, -60)]:
		var enemy = monsters.spawn_monster(monsters.get_available_variants(0)[0])
		enemy.set_physics_process(false)
		enemy.global_position = game.player.global_position + offset
		enemy.current_health = 10000
		enemies.append(enemy)
	var spells = game.spell_manager
	check(spells.learn_spell("seeking_spirit"), "Learn Seeker through normal inventory")
	var slot = spells.find_spell_slot("seeking_spirit")
	var spirits: Array = []
	for i in 2:
		check(spells.cast_build_spell(slot), "Cast another Seeker")
		spirits = get_nodes_in_group("build_spell_effects").filter(func(effect): return effect.info.type == "spirit")
		for spirit in spirits:
			spirit.set_physics_process(false)
	check(spirits[0].target_ref.get_ref() == enemies[0], "First Seeker takes nearest visible enemy")
	check(spirits[1].target_ref.get_ref() == enemies[1], "Second Seeker reserves another visible enemy")
	spirits[0].advance(0.01)
	check(spirits[0].target_ref.get_ref() == enemies[0], "Distinct current target stays stable")
	enemies[0].dying = true
	spirits[0].advance(0.01)
	check(spirits[0].target_ref.get_ref() == enemies[2], "Dead target releases reservation and picks unused enemy")
	var inverse = game.get_viewport().get_canvas_transform().affine_inverse()
	var outside = inverse * Vector2(-30, root.get_visible_rect().size.y / 2)
	enemies[2].global_position = outside
	spirits[0].global_position = outside
	var health_before = enemies[2].current_health
	spirits[0].advance(0.1)
	check(spirits[0].target_ref.get_ref() == enemies[1], "Only visible remaining enemy is shared")
	check(enemies[2].current_health == health_before, "Offscreen target is dropped before contact damage")
	enemies[0].dying = false
	enemies[0].global_position = game.player.global_position + Vector2(100, 0)
	spirits[0].advance(0.01)
	spirits[1].advance(0.01)
	check(spirits[0].target_ref.get_ref() != spirits[1].target_ref.get_ref(), "Shared Seekers spread out when a new target arrives")
	for spirit in spirits:
		spirit.target_ref = weakref(enemies[1])
	spirits[1].advance(0.01)
	spirits[0].advance(0.01)
	check(spirits[0].target_ref.get_ref() != spirits[1].target_ref.get_ref(), "Reverse update order also redistributes shared targets")
	var stable_target = spirits[1].target_ref.get_ref()
	spirits[1].advance(0.01)
	check(spirits[1].target_ref.get_ref() == stable_target, "Redistributed reservation remains stable")
	enemies[0].global_position = outside
	enemies[1].hide()
	var before_return = spirits[0].global_position.distance_to(game.player.global_position)
	spirits[0].advance(0.1)
	check(spirits[0].target_ref == null, "Offscreen and hidden enemies are not reacquired")
	check(spirits[0].global_position.distance_to(game.player.global_position) < before_return, "No visible enemy returns Seeker toward caster")
	check(spells.cast_build_spell(slot), "No-target cast remains available")
	spirits = get_nodes_in_group("build_spell_effects").filter(func(effect): return effect.info.type == "spirit")
	check(spirits.back().target_ref == null, "Initial cast also excludes hidden/offscreen enemies")
	enemies[0].global_position = game.player.global_position + Vector2(100, 0)
	spirits[0].target_ref = weakref(enemies[0])
	spirits[0].queue_free()
	spirits[1].target_ref = null
	spirits[1].advance(0.01)
	check(spirits[1].target_ref.get_ref() == enemies[0], "Queued deletion releases reservation immediately")
	var label = game.hud.get_node("BuildVersion")
	check(label.text == "v%s · Playtest" % ProjectSettings.get_setting("application/config/version"), "Real gameplay HUD uses requested version")
	game.queue_free()
	await process_frame
	print("Seeker targeting: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
