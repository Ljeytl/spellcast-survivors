extends SceneTree

const Tactical = preload("res://scripts/TacticalSpellEffect.gd")
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
	for id in ["focus_ray", "ember_lance"]:
		check(spells.learn_spell(id), "Learn " + id)
	check(spells.learn_spell("prism_ray"), "Learn Prism")
	var focus_slot = spells.find_spell_slot("focus_ray")
	var prism_slot = spells.find_spell_slot("prism_ray")
	for slot in [focus_slot, focus_slot, prism_slot, prism_slot]:
		check(spells.cast_build_spell(slot), "Beam recast succeeds")
	var beams = get_nodes_in_group("build_spell_effects").filter(func(e): return e.info.type == "beam" and not e.is_queued_for_deletion())
	check(beams.size() == 4, "Two Focus and two Prism beams coexist")
	for beam in beams:
		beam.set_physics_process(false)
	check(beams[0].target_ref.get_ref() != beams[1].target_ref.get_ref(), "Recast seeks a second enemy")
	check(is_equal_approx(beams[0].info.beam_radius, 12), "Focus radius reduced")
	var prism = beams.filter(func(e): return e.info.id == "prism_ray")[0]
	if "--known-bad-prism" in OS.get_cmdline_user_args():
		prism.info.beam_piercing = false
	prism.info.beam_origin_offset = Vector2.ZERO
	prism.direction = Vector2.RIGHT
	prism.target_ref = weakref(enemies[0])
	prism.advance_beam(0.25, game.player)
	for enemy in enemies:
		check(enemy.current_health < 1000, "Prism damages every aligned enemy including fourth")
	check(is_equal_approx(prism.beam_end.length(), 450), "Prism remains full length through targets")
	var focus = beams[0]
	focus.info.beam_origin_offset = Vector2.ZERO
	focus.direction = Vector2.RIGHT
	enemies[0].global_position = game.player.global_position + Vector2(0, 150)
	focus.target_ref = weakref(enemies[0])
	focus.advance_beam(0.05, game.player)
	check(focus.direction.angle() > 0 and focus.direction.angle() < 0.21, "Focus turns smoothly without snapping")
	for index in range(4):
		spells.cast_build_spell(focus_slot)
	var surviving_focus = get_nodes_in_group("build_spell_effects").filter(func(e): return e.info.id == "focus_ray" and not e.is_queued_for_deletion())
	var focus_limit = int(preload("res://scripts/SpellProgression.gd").resolve(spells.spells[focus_slot]).active_limit)
	check(surviving_focus.size() == focus_limit, "Repeated recasts retain exactly the rank's Focus beam limit")
	var lanes = {}
	for beam in surviving_focus:
		lanes[beam.info.beam_lane] = true
	check(lanes.size() == focus_limit, "Replacement keeps distinct visual emission lanes")
	for beam in get_nodes_in_group("build_spell_effects"):
		beam.queue_free()
	await process_frame
	for index in range(enemies.size()):
		enemies[index].global_position = game.player.global_position + Vector2(70 + index * 50, 0)
		enemies[index].current_health = 1000
	var blade = Tactical.new()
	blade.configure(spells.spell_catalog.returning_blade, 20, game.player, enemies[0])
	game.add_child(blade)
	blade.set_physics_process(false)
	blade.global_position = game.player.global_position + Vector2(300, 0)
	blade.leg = 1
	blade.linger_remaining = 0
	blade.advance_returning(0.5, game.player)
	for enemy in enemies:
		check(is_equal_approx(enemy.current_health, 960), "Return pierces and damages each enemy once at double strength")
	blade.advance_returning(0, game.player)
	check(is_equal_approx(enemies[0].current_health, 960), "Return does not double-hit same enemy")
	blade.queue_free()
	check(spells.spell_catalog.seeking_spirit.damage == 15 and spells.spell_catalog.seeking_spirit.hit_interval == 1.0, "Seeker hits for 15 at most once per second at rank 1")
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
		var base = spells.calculate_spell_damage(spells.get_spell_info(slot))
		for ingredient in spells.Synergies.RECIPES[id].ingredients:
			spells.upgrade_spell(ingredient)
			var improved = spells.calculate_spell_damage(spells.get_spell_info(slot))
			check(improved > base, id + " benefits from " + ingredient)
			base = improved
		check(spells.get_spell_rank(id) == 1, "Inherited bonuses do not mutate combo own rank")
		var before_buff = spells.calculate_spell_damage(spells.get_spell_info(slot))
		game.player.spell_damage_multiplier *= 2
		check(is_equal_approx(spells.calculate_spell_damage(spells.get_spell_info(slot)), before_buff * 2), "Player buff applies once")
		game.player.spell_damage_multiplier /= 2
		if id == "steam_field":
			check(spells.resolve_cast_info(slot).radius > 150, "Ice improves steam area")
		if id == "soul_bloom":
			check(spells.resolve_cast_info(slot).healing_tick_cap > 2, "Regeneration improves capped recovery")
	game.queue_free()
	await process_frame
	print("CASTING_FEEDBACK checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
