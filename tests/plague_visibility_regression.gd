extends SceneTree

var checks = 0
var failures = 0

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

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	var manager = game.get_node("MonsterManager")
	manager.spawn_timer.stop()
	manager.set_process(false)
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	var targets = []
	for point in [Vector2(100, 0), Vector2(180, 0), Vector2(500, 0)]:
		var enemy = manager.spawn_monster(manager.get_available_variants(0)[0])
		enemy.position = game.player.position + point
		enemy.set_physics_process(false)
		enemy.current_health = 100
		targets.append(enemy)
	game.spell_manager.learn_spell("plague_seed")
	check(game.spell_manager.cast_freeform_spell("plague seed"), "Owned typed Plague Seed casts on a real visible enemy")
	var effect = get_nodes_in_group("build_spell_effects").back()
	effect.set_physics_process(false)
	effect.advance(0.25)
	targets[0].take_damage(1000, game.player.position)
	await process_frame
	await process_frame
	effect.advance(0.75)
	check(targets[1].current_health == 91, "Infection survives external host death before first tick and damages real neighbor")
	check(targets[2].current_health == 100, "Death transfer respects spread distance")
	check(effect.infections.size() == 2, "Death transfers only once to a nearby host")
	check(effect.z_index > 2, "Plague feedback draws above tree canopies")
	var before = targets[1].current_health
	effect.advance(0.5)
	check(targets[1].current_health < before, "Surviving host receives repeated damage ticks")
	effect.remaining = 0
	targets[1].take_damage(1000, game.player.position)
	await process_frame
	check(effect.infections.size() == 2, "Expired infection cannot transfer on death")
	var terrain = game.get_node("Background")
	var trunk = null
	for holder in terrain.decorations.values():
		for body in holder.get_children():
			if body.has_node("Canopy"):
				trunk = body
				break
		if trunk != null:
			break
	check(trunk != null, "Real forest contains a canopy fixture")
	if trunk != null:
		var origin = game.player.position
		targets[2].position = trunk.global_position + Vector2(0, -50)
		terrain._process(0)
		check(trunk.get_node("Canopy").modulate.a == 1, "Enemy under tree does not fade canopy")
		game.player.position = targets[2].position
		terrain._process(0)
		check(is_equal_approx(trunk.get_node("Canopy").modulate.a, 0.35), "Player under tree retains visibility")
		game.player.position = origin
		terrain._process(0)
		check(trunk.get_node("Canopy").modulate.a == 1, "Canopy restores opacity after player leaves")
	var group = []
	for index in range(10):
		var enemy = manager.spawn_monster(manager.get_available_variants(0)[0])
		enemy.position = game.player.position + Vector2(40 + index * 4, 60)
		enemy.set_physics_process(false)
		enemy.current_health = 1
		group.append(enemy)
	var chain = load("res://scripts/BuildSpellEffect.gd").new()
	chain.configure({"type": "plague", "duration": 12.0}, 9, game.player, group[0])
	game.add_child(chain)
	chain.set_physics_process(false)
	chain.advance(1.25)
	check(chain.infections.size() == 2, "Plague killing tick launches spore which transfers on arrival")
	await process_frame
	check(chain.infections.size() == 2, "Deferred death signal does not transfer twice")
	for index in range(16):
		chain.advance(0.5)
		await process_frame
	check(chain.infections.size() == 8, "Death chains retain eight-host cap")
	var survivors = group.filter(func(enemy): return is_instance_valid(enemy) and not enemy.dying)
	check(survivors.size() == 2, "Bounded chain leaves two of ten enemies untouched")
	game.queue_free()
	await process_frame
	print("Plague visibility regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
