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
	game.spell_manager.learn_spell("infestation")
	check(game.spell_manager.cast_freeform_spell("infection"), "Owned typed Plague Seed casts on a real visible enemy")
	# Infestation runs on the generic engine (doc 18 phase 2): the plague lives on the cast's part.
	var plague_cast = game.spell_manager.last_generic_cast
	plague_cast.manual = true
	var part = plague_cast.root_parts()[0]
	var plague = part.infection
	# Lifecycle fixture: pin the full-rank spread so timings test transfer rules, not rank tuning.
	plague.cfg.spread_radius = 130.0
	plague.cfg.spread_speed = 460.0
	plague.cfg.spore_life = 3.0
	plague.cfg.duration = 5.0
	part.power_scale = 9.0 / float(part.def.payload[0].hit)
	var presenter = root.get_node("Vfx").presenter
	var presentation = presenter._parts[part.get_instance_id()]
	part.step(0.05)
	presenter._infection_step(part, presentation, 0.05)
	var link_id = plague.links[0].id
	var first_sample = presentation.infection_wakes[link_id][0].pos
	part.step(0.05)
	presenter._infection_step(part, presentation, 0.05)
	check(presentation.infection_wakes[link_id].size() == 2, "Transmission stores successive actual travel positions")
	check(presentation.infection_wakes[link_id][0].pos == first_sample, "Older wake remains at its historical position")
	part.step(0.15)
	presenter._infection_step(part, presentation, 0.15)
	check(presentation.infection_wakes.is_empty(), "Arrival removes the completed transfer wake")
	check(presentation.infection_hosts.has(targets[0].get_instance_id()), "Only arrived hosts acquire infection growth")
	check(presentation.infection_pulses.get(targets[0].get_instance_id(), 0.0) > 0.0, "Arrival starts restrained host pulse")
	targets[0].take_damage(1000, game.player.position)
	await process_frame
	await process_frame
	part.step(0.75)
	check(targets[1].current_health == 91, "Infection survives external host death before first tick and damages real neighbor")
	check(targets[2].current_health == 100, "Death transfer respects spread distance")
	check(plague.hosts_started == 2, "Death transfers only once to a nearby host")
	check(root.get_node("Vfx")._air_layer.z_index > 2, "Plague feedback draws above tree canopies")
	var before = targets[1].current_health
	presenter._infection_step(part, presentation, 0.2)
	part.step(0.5)
	check(presentation.infection_pulses.get(targets[1].get_instance_id(), 0.0) > 0.0, "Real damage tick drives infection pulse")
	check(targets[1].current_health < before, "Surviving host receives repeated damage ticks")
	var infection_visual = presentation.infection_visual
	part.finish(true)
	targets[1].take_damage(1000, game.player.position)
	await process_frame
	await process_frame
	check(not is_instance_valid(infection_visual), "Finished infection frees its material renderer")
	check(plague.hosts_started == 2, "Expired infection cannot transfer on death")
	var terrain = game.get_node("Background")
	var trunk = null
	for holder in terrain.decorations.values():
		for body in holder.get_children():
			if body.has_meta("canopy"):
				trunk = body
				break
		if trunk != null:
			break
	check(trunk != null, "Real forest contains a canopy fixture")
	if trunk != null:
		var origin = game.player.position
		targets[2].position = trunk.global_position + Vector2(0, -50)
		terrain._process(0)
		check(trunk.get_meta("canopy").modulate.a == 1, "Enemy under tree does not fade canopy")
		game.player.position = targets[2].position
		terrain._process(0)
		check(is_equal_approx(trunk.get_meta("canopy").modulate.a, 0.35), "Player under tree retains visibility")
		game.player.position = origin
		terrain._process(0)
		check(trunk.get_meta("canopy").modulate.a == 1, "Canopy restores opacity after player leaves")
	var group = []
	for index in range(10):
		var enemy = manager.spawn_monster(manager.get_available_variants(0)[0])
		enemy.position = game.player.position + Vector2(40 + index * 4, 60)
		enemy.set_physics_process(false)
		enemy.current_health = 1
		group.append(enemy)
	# Infestation runs on the generic engine (scripts/engine/Infection.gd).
	var chain = game.spell_manager.spawn_ported({"id": "infestation", "type": "plague", "duration": 12.0}, 9, {}, group[0])
	chain.manual = true
	var spread = chain.root_parts()[0].infection
	chain.advance(1.25)
	check(spread.hosts_started == 2, "Plague killing tick launches spore which transfers on arrival (%d)" % spread.hosts_started)
	await process_frame
	check(spread.hosts_started == 2, "Deferred death signal does not transfer twice")
	for index in range(20):
		chain.advance(0.5)
		await process_frame
	check(spread.hosts_started == 10, "Death chain reaches all ten available hosts (%d)" % spread.hosts_started)
	var survivors = group.filter(func(enemy): return is_instance_valid(enemy) and not enemy.dying)
	check(survivors.is_empty(), "No survivors protected by an eight-host cap")
	game.queue_free()
	await process_frame
	print("Plague visibility regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
