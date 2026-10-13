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
	var monsters = game.get_node("MonsterManager")
	monsters.set_process(false)
	monsters.spawn_timer.stop()
	game.player.set_physics_process(false)
	var spells = game.spell_manager
	spells.set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await process_frame
	var enemies: Array = []
	for index in range(4):
		var definition = monsters.encounter_config.variants.pursuer.duplicate(true)
		definition.id = "pursuer"
		var enemy = monsters.spawn_monster(definition)
		enemy.set_physics_process(false)
		enemy.global_position = game.player.global_position + Vector2(80 + 75 * index, 0)
		enemy.current_health = 1000
		enemies.append(enemy)
	spells.spells.clear()
	spells.bonus_spells.clear()
	spells.acquired_spells.clear()
	for id in ["focus_ray", "ember_spear"]:
		check(spells.learn_spell(id), "Learn " + id)
	check(spells.learn_spell("prism_ray"), "Learn Prism")
	var focus_slot = spells.find_spell_slot("focus_ray")
	var prism_slot = spells.find_spell_slot("prism_ray")
	# Focus Ray and Prism Ray run on the generic engine (doc 18 phase 2).
	for slot in [focus_slot, focus_slot, prism_slot, prism_slot]:
		check(spells.cast_spell_by_type(slot), "Beam recast succeeds")
	var focus_casts = spells.ported_casts("focus_ray")
	var prism_casts = spells.ported_casts("prism_ray")
	check(focus_casts.size() + prism_casts.size() == 4, "Two Focus and two Prism beams coexist")
	for c in focus_casts + prism_casts:
		c.manual = true
	var focus_beams = focus_casts.map(func(c): return c.root_parts()[0])
	check(focus_beams[0].target_ref.get_ref() != focus_beams[1].target_ref.get_ref(), "Recast seeks a second enemy")
	check(is_equal_approx(focus_beams[0].geo("width"), 24.0), "Focus radius reduced")
	var prism = prism_casts[0].root_parts()[0]
	if "--known-bad-prism" in OS.get_cmdline_user_args():
		prism.def.limits.beam_piercing = false
	prism.beam_offset = Vector2.ZERO
	prism.direction = Vector2.RIGHT
	prism.target_ref = weakref(enemies[0])
	prism.step(0.25)
	for enemy in enemies:
		check(enemy.current_health < 1000, "Prism damages every aligned enemy including fourth")
	check(is_equal_approx(prism.beam_end.length(), 450), "Prism remains full length through targets")
	var focus = focus_beams[0]
	focus.beam_offset = Vector2.ZERO
	focus.direction = Vector2.RIGHT
	enemies[0].global_position = game.player.global_position + Vector2(0, 150)
	focus.target_ref = weakref(enemies[0])
	focus.step(0.05)
	check(focus.direction.angle() > 0 and focus.direction.angle() < 0.21, "Focus turns smoothly without snapping")
	for index in range(4):
		spells.cast_spell_by_type(focus_slot)
	var surviving_focus = spells.ported_casts("focus_ray")
	var focus_limit = int(preload("res://scripts/SpellProgression.gd").resolve(spells.spells[focus_slot]).active_limit)
	check(surviving_focus.size() == focus_limit, "Repeated recasts retain exactly the rank's Focus beam limit")
	var lanes = {}
	for c in surviving_focus:
		lanes[int(c.get_meta("beam_lane", 0))] = true
	check(lanes.size() == focus_limit, "Replacement keeps distinct visual emission lanes")
	for c in get_nodes_in_group("generic_casts"):
		c.queue_free()
	await process_frame
	for index in range(enemies.size()):
		enemies[index].global_position = game.player.global_position + Vector2(70 + index * 50, 0)
		enemies[index].current_health = 1000
	# Cross Blade runs on the generic engine: one blade out and back along the line of enemies.
	var blade_info = spells.spell_catalog.cross_blade.duplicate(true)
	blade_info.blade_count = 1
	var blade_cast = spells.spawn_ported(blade_info, 20, {}, enemies[0])
	blade_cast.manual = true
	var blade = blade_cast.root_parts()[0]
	var guard = 0
	while blade.phase < 2 and guard < 600:
		blade_cast.step(1.0 / 60.0)
		guard += 1
	var before_return = enemies.map(func(e): return e.current_health)
	blade_cast.run(3.0)
	for index in range(enemies.size()):
		check(is_equal_approx(before_return[index] - enemies[index].current_health, 40), "Return pierces and damages each enemy once at double strength (%s)" % (before_return[index] - enemies[index].current_health))
	blade_cast.queue_free()
	check(spells.spell_catalog.seeker.damage == 15 and spells.spell_catalog.seeker.hit_interval == 1.0, "Seeker hits for 15 at most once per second at rank 1")
	for id in spells.Synergies.RECIPES:
		if not spells.Synergies.RECIPES[id].get("enabled", true):
			continue
		spells.spells.clear()
		spells.bonus_spells.clear()
		spells.acquired_spells.clear()
		for ingredient in spells.Synergies.RECIPES[id].ingredients:
			spells.learn_spell(ingredient)
		spells.learn_spell(id)
		var slot = spells.find_spell_slot(id)
		# Combinations scale per component: each ingredient improves the stat it governs
		# (damage, splash, explosion, healing, slow or area), not necessarily direct damage.
		var base_info = spells.resolve_cast_info(slot)
		for ingredient in spells.Synergies.RECIPES[id].ingredients:
			spells.upgrade_spell(ingredient)
			var improved_info = spells.resolve_cast_info(slot)
			var improved_any = false
			for key in improved_info:
				if typeof(improved_info[key]) in [TYPE_FLOAT, TYPE_INT] and typeof(base_info.get(key)) in [TYPE_FLOAT, TYPE_INT] and float(improved_info[key]) > float(base_info[key]) + 0.0001:
					improved_any = true
			check(improved_any, id + " benefits from " + ingredient)
			base_info = improved_info
		check(spells.get_spell_rank(id) == 1, "Inherited bonuses do not mutate combo own rank")
		var before_buff = spells.calculate_spell_damage(spells.get_spell_info(slot))
		game.player.spell_damage_multiplier *= 2
		check(is_equal_approx(spells.calculate_spell_damage(spells.get_spell_info(slot)), before_buff * 2), "Player buff applies once")
		game.player.spell_damage_multiplier /= 2
		if id == "steam_field":
			check(spells.resolve_cast_info(slot).slow > 0.4, "Ice improves steam slow")
		if id == "soul_bloom":
			check(spells.resolve_cast_info(slot).healing_bloom_amount > 6.0, "Regeneration improves bloom healing")
	game.queue_free()
	await process_frame
	print("CASTING_FEEDBACK checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
