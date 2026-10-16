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
	check(visuals.size() == 1, "One presentation owns charge and strike")
	var visual = visuals[0]
	visual.set_process(false)
	check(is_equal_approx(visual.radius, mark.geo("radius")), "Charge circle uses actual damage radius")
	check(is_equal_approx(mark.total_life(), 0.55), "Charge has intentional 0.55-second buildup")
	var baseline = enemies.map(func(e): return e.current_health)
	cast.advance(0.18)
	visual._process(0.0)
	check(not visual.struck and not visual.slam_emitted, "Staff gathers before slam")
	cast.advance(0.13)
	visual._process(0.0)
	check(visual.slam_emitted and not visual.struck, "Staff slam precedes lightning strike")
	check(enemies.map(func(e): return e.current_health) == baseline, "Charge and slam cause no early damage")
	cast.advance(0.25)
	check(visual.struck, "Authoritative strike triggers bolt")
	check(get_nodes_in_group("lightning_visuals").size() == 1, "Strike reuses charge visual")
	var hit_health = enemies.map(func(e): return e.current_health)
	check(hit_health != baseline, "Strike deals actual damage")
	visual._process(0.4)
	check(not visual.is_queued_for_deletion(), "Ground charge persists after bolt")
	cast.advance(0.3)
	check(enemies.map(func(e): return e.current_health) == hit_health, "Aftershock does not add repeated damage")
	visual._process(1.0)
	check(visual.is_queued_for_deletion(), "Aftershock expires")
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
	plain.advance(0.56)
	check(enemies.map(func(e): return e.current_health) == hit_health, "Presentation on/off preserves damage")
	check(get_nodes_in_group("lightning_visuals").is_empty(), "Disabled presentation spawns no custom effect")
	plain.advance(0.3)
	vfx.presenter.enabled = true
	spells.cast_spell_by_type(slot)
	var canceled = spells.last_generic_cast
	canceled.manual = true
	visual = get_nodes_in_group("lightning_visuals")[0]
	visual.set_process(false)
	canceled.parts[0].finish(false)
	visual._process(0.01)
	check(visual.is_queued_for_deletion() and not visual.struck, "Canceled mark never creates a false strike")
	await process_frame
	spells.get_spell_info(slot).level = 8
	spells.cast_spell_by_type(slot)
	spells.last_generic_cast.manual = true
	visual = get_nodes_in_group("lightning_visuals")[0]
	check(is_equal_approx(visual.radius, 175.0), "Rank-eight telegraph scales to true radius")
	vfx.clear()
	await process_frame
	check(get_nodes_in_group("lightning_visuals").is_empty(), "World reset clears custom lightning")
	spells.cast_spell_by_type(slot)
	var accented = spells.last_generic_cast
	accented.manual = true
	accented.plan["elements"] = [{"element": "fire"}]
	accented.plan["flags"]["repulsing"] = true
	vfx.clear()
	accented.advance(0.56)
	check(vfx._f_count > 0, "Lightning retains fire accent particles")
	check(vfx.elements.streaks.size() >= 6, "Lightning retains repulsing impact cues")
	vfx.clear()
	await process_frame
	spells.cast_spell_by_type(slot)
	var hostile = spells.last_generic_cast
	hostile.manual = true
	vfx.clear()
	await process_frame
	hostile.target_group = "player"
	vfx.presenter.part_spawned(hostile.parts[0])
	check(get_nodes_in_group("lightning_visuals").is_empty(), "Hostile lightning avoids friendly blue visual")
	check(vfx.presenter._parts.has(hostile.parts[0].get_instance_id()), "Hostile lightning retains warning presenter")
	var staff = game.player.get_node("OrbitingStaff")
	staff.set_lightning_pose(0.3)
	staff.update_orbit(0.01)
	check(staff.staff.position.y < -10.0, "Staff visibly raises while gathering")
	staff.update_orbit(0.2)
	check(absf(staff.staff.position.y) <= 3.0, "Staff pose recovers after cancellation")
	game.queue_free()
	await process_frame
	print("Lightning feel: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
