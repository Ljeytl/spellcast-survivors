extends SceneTree

var checks := 0
var failures := 0

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
	var vfx = root.get_node("Vfx")
	check(spells.learn_spell("lightning"), "Learn Lightning through inventory")
	var slot = spells.find_spell_slot("lightning")
	check(spells.cast_spell_by_type(slot), "Cast Lightning through normal host")
	var cast = spells.last_generic_cast
	cast.manual = true
	var mark = cast.parts[0]
	var visuals = get_nodes_in_group("lightning_visuals")
	check(visuals.size() == 1, "One blue warning circle")
	var visual = visuals[0]
	visual.set_process(false)
	check(is_equal_approx(visual.radius, mark.geo("radius")), "Circle uses actual damage radius")
	check(is_equal_approx(mark.total_life(), 0.32), "Original warning duration restored")
	check(cast.plan.get("flags", {}).is_empty(), "Plain Lightning has no keyword flags")
	var baseline = enemies.map(func(e): return e.current_health)
	cast.advance(0.30)
	check(enemies.map(func(e): return e.current_health) == baseline, "Warning does no damage")
	cast.advance(0.03)
	visual._process(0.0)
	check(visual.is_queued_for_deletion(), "Circle ends at strike without custom aftershock")
	var hit_health = enemies.map(func(e): return e.current_health)
	check(hit_health != baseline, "Original strike deals damage")
	var strike = cast.parts.filter(func(p): return p.part_name == "strike")[0]
	check(vfx.presenter._parts.has(strike.get_instance_id()), "Strike uses original presenter")
	cast.advance(0.3)
	await process_frame
	vfx.clear()
	for i in enemies.size():
		enemies[i].current_health = baseline[i]
		if is_instance_valid(enemies[i].status):
			enemies[i].status.free()
			enemies[i].status = null
	vfx.presenter.enabled = false
	spells.cast_spell_by_type(slot)
	var plain = spells.last_generic_cast
	plain.manual = true
	plain.advance(0.33)
	check(enemies.map(func(e): return e.current_health) == hit_health, "Presentation does not change damage")
	check(get_nodes_in_group("lightning_visuals").is_empty(), "Disabled presentation has no circle")
	plain.advance(0.3)
	vfx.presenter.enabled = true
	spells.cast_spell_by_type(slot)
	var canceled = spells.last_generic_cast
	canceled.manual = true
	visual = get_nodes_in_group("lightning_visuals")[0]
	visual.set_process(false)
	canceled.parts[0].finish(false)
	visual._process(0.0)
	check(visual.is_queued_for_deletion(), "Canceled mark removes circle")
	await process_frame
	spells.get_spell_info(slot).level = 8
	spells.cast_spell_by_type(slot)
	var ranked = spells.last_generic_cast
	ranked.manual = true
	visual = get_nodes_in_group("lightning_visuals")[0]
	check(is_equal_approx(visual.radius, 175.0), "Rank eight retains original radius")
	vfx.clear()
	await process_frame
	check(get_nodes_in_group("lightning_visuals").is_empty(), "Reset clears circles")
	spells.cast_spell_by_type(slot)
	var accented = spells.last_generic_cast
	accented.manual = true
	accented.plan["elements"] = [{"element": "fire"}]
	accented.plan["flags"]["repulsing"] = true
	vfx.clear()
	accented.advance(0.33)
	check(vfx._f_count > 0, "Original strike retains fire accent")
	check(vfx.elements.streaks.size() >= 6, "Original strike retains repulsing cues")
	vfx.clear()
	await process_frame
	ranked.target_group = "player"
	vfx.presenter.part_spawned(ranked.parts[0])
	check(get_nodes_in_group("lightning_visuals").is_empty(), "Hostile warning retains original presentation")
	check(vfx.presenter._parts.has(ranked.parts[0].get_instance_id()), "Hostile warning remains visible")
	game.queue_free()
	await process_frame
	print("Lightning feel: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
