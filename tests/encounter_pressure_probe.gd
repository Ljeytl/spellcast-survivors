extends SceneTree

var rows = []
var game
var seed_value = 44

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	root.get_node("AudioManager").quitting = true
	for mode in ["stationary", "moving", "casting"]:
		for baseline in [true, false]:
			for seconds in [0, 120, 180, 300, 420, 480, 540, 660]:
				await sample(mode, baseline, seconds)
	DirAccess.make_dir_recursive_absolute("res://builds/pass2-evidence")
	var output = FileAccess.open("res://builds/pass2-evidence/pressure-probe.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"seed": seed_value, "window_seconds": 30, "mana_rank": 4, "health_pool": 50000, "notes": "Controlled encounter windows; prior bosses suppressed; high health prevents early stop; fixed build and same seed; not a natural survival result", "samples": rows}, "\t"))
	print("PRESSURE_PROBE samples=", rows.size())
	quit(0 if rows.size() == 48 else 1)

func sample(mode, baseline, seconds):
	seed(seed_value)
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	var manager = game.get_node("MonsterManager")
	manager.game_time = seconds
	for milestone in manager.encounter_config.bosses:
		manager.spawned_bosses[int(milestone.time)] = true
	if baseline:
		manager.encounter_config.scaling.midgame_pressure = []
	manager.spawn_timer.start(manager.calculate_spawn_interval())
	game.player.health = 50000
	game.player.max_health = 50000
	game.player.level_up.disconnect(game._on_player_level_up)
	game.player.set_physics_process(false)
	game.chest_manager.set_process(false)
	game.spell_manager.mana_bolt_level = 4
	game.player.cast_speed_multiplier = 1.3
	var highest_population = 0
	for frame in range(1800):
		if mode == "moving":
			var target = game.spell_manager.get_closest_enemy()
			if is_instance_valid(target):
				game.player.velocity = target.global_position.direction_to(game.player.global_position) * game.player.BASE_SPEED
				game.player.move_and_slide()
		game.player.process_enemy_contact_damage(1.0 / 60)
		if mode == "casting" and frame % 120 == 0:
			game.spell_manager.cast_freeform_spell("bolt")
		highest_population = maxi(highest_population, manager.monsters_alive)
		await physics_frame
	var xp = game.player.xp
	for orb in get_nodes_in_group("xp_orbs"):
		if not orb.collected:
			xp += orb.xp_value
	rows.append({"mode": mode, "baseline": baseline, "start_seconds": seconds, "spawn_attempts": manager.spawn_attempts, "actual_spawns": manager.actual_spawns, "cap_rejections": manager.cap_rejections, "peak_population": highest_population, "active_population": manager.monsters_alive, "health_damage": 50000 - game.player.health, "kills": game.enemies_killed, "unspent_and_uncollected_xp": xp})
	print("PROBE ", rows.back())
	game.queue_free()
	await process_frame
	await process_frame
