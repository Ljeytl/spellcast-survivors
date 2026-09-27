extends SceneTree

var checks = 0
var failures = 0
var game
var manager
var director

class DisabledRecycling extends "res://scripts/EncounterDirector.gd":
	func recycle_distant():
		pass

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

func spawn(id = "pursuer", boss = false):
	var definition = manager.encounter_config.variants[id].duplicate(true)
	definition.id = id
	var enemy = manager.spawn_monster(definition, boss, true)
	if enemy:
		enemy.set_physics_process(false)
	return enemy

func clear_enemies():
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	manager.monsters_alive = 0

func run():
	root.get_node("AudioManager").quitting = true
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	if "--known-bad" in OS.get_cmdline_user_args():
		manager.encounter_director = DisabledRecycling.new(manager)
	director = manager.encounter_director
	var camera = game.get_node("Camera2D")
	for zoom in [0.6, 1.2, 2.0]:
		camera.zoom = Vector2.ONE * zoom
		game.player.position = Vector2(-3500, -2800)
		camera.offset = Vector2(120, -70)
		camera.reset_smoothing()
		camera.force_update_scroll()
		await process_frame
		var bounds = director.visible_world_rect()
		check(is_equal_approx(bounds.size.x, root.get_visible_rect().size.x / zoom), "Visible bounds use actual zoom")
		for angle in [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]:
			var point = director.entry_position(angle, 25)
			check(point.is_finite() and not bounds.grow(150).has_point(point), "Spawn outside camera including offset/negative coordinates")
			check(game.get_node("Background").is_spawn_clear(point, 25), "Spawn clears tree trunks")
	game.position = Vector2(-200, 350)
	camera.ignore_rotation = false
	camera.rotation = 0.3
	camera.force_update_scroll()
	await process_frame
	var transformed = spawn()
	check(not director.visible_world_rect().grow(150).has_point(transformed.global_position), "Rotated camera and translated world keep spawned enemy offscreen")
	transformed.free()
	manager.monsters_alive -= 1
	var bounds = director.visible_world_rect()
	var distant = bounds.get_center() + Vector2(5000, 0)
	var enemy = spawn()
	enemy.global_position = distant
	enemy.current_health = 7.25
	enemy.slow_multiplier = 0.4
	enemy.slow_timer = 3.7
	var identity = enemy.get_instance_id()
	director.recycle_distant()
	check(enemy.global_position != distant, "Distant enemy reenters")
	check(enemy.get_instance_id() == identity and enemy.current_health == 7.25 and enemy.slow_timer == 3.7 and enemy.slow_multiplier == 0.4, "Recycling preserves identity, HP and status")
	check(absf((enemy.global_position - bounds.get_center()).angle()) >= PI * 0.5, "Reentry uses a different approach angle")
	check(not bounds.grow(150).has_point(enemy.global_position), "Reentry remains offscreen")
	check(game.get_node("Background").is_spawn_clear(enemy.global_position, 29 * enemy.scale.x), "Reentry clears terrain")
	var near = spawn()
	near.global_position = bounds.end + Vector2(100, 0)
	var near_before = near.global_position
	var boss = spawn("juggernaut", true)
	boss.global_position = distant
	var dying = spawn()
	dying.global_position = distant
	dying.dying = true
	var queued = spawn()
	queued.global_position = distant
	queued.queue_free()
	director.recycle_distant()
	check(near.global_position == near_before, "Just offscreen enemy continues normally")
	check(boss.global_position == distant and dying.global_position == distant and queued.global_position == distant, "Boss, dying and queued enemies never recycle")
	clear_enemies()
	for index in range(5):
		spawn().global_position = distant
	var before = director.recycled_count
	director.recycle_distant()
	check(director.recycled_count - before == 2, "Recycling spreads arrivals across updates")
	clear_enemies()
	manager.spawned_bosses = {300: true, 600: true, 900: true}
	manager.game_time = 209.9
	manager.advance_time(0.2)
	for step in range(40):
		manager.advance_time(0.1)
	check(director.wave_spawn_count == 8 and manager.monsters_alive == 8, "First rush spawns exact authored count")
	check(get_nodes_in_group("enemies").all(func(node): return node.variant == "skirmisher"), "Rush uses scheduled melee variant")
	manager.advance_time(-5)
	for step in range(60):
		manager.advance_time(0.1)
	check(director.wave_spawn_count == 8, "Rewinding across an event does not repeat it")
	manager.advance_time(800)
	check(director.wave_remaining == 0 and director.wave_spawn_count == 8, "Time jumps skip historical waves without catchup flood")
	clear_enemies()
	director.seen_waves.clear()
	manager.game_time = 254.9
	manager.max_monsters = 2
	manager.advance_time(0.2)
	for step in range(60):
		manager.advance_time(0.1)
	check(manager.monsters_alive == 2 and director.wave_remaining == 0, "Swarmer rush respects cap without triples or backlog")
	var old_count = director.wave_spawn_count
	clear_enemies()
	for step in range(20):
		manager.advance_time(0.1)
	check(director.wave_spawn_count == old_count, "Cap-rejected arrivals do not burst later")
	manager.max_monsters = 160
	for wave in manager.encounter_config.waves:
		check(float(wave.time) >= 180 and float(wave.time) < 1200, "Schedule protects opening and ending")
		check(manager.get_available_variants(wave.time).any(func(item): return item.id == wave.variant and item.family != "shooter"), "Rush respects variant unlock and melee contract")
		for milestone in manager.encounter_config.bosses:
			check(absf(wave.time - milestone.time) > 30, "Rush separated from boss milestones")
	director.wave_remaining = 12
	manager.game_time = 1199.9
	manager.advance_time(0.2)
	check(manager.run_finished and director.wave_remaining == 0, "20 minute victory cancels pending rush")
	var final_count = manager.actual_spawns
	manager.advance_time(10)
	director.recycle_distant()
	check(manager.actual_spawns == final_count, "No encounters after victory")
	game.queue_free()
	await process_frame
	print("Encounter waves: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
