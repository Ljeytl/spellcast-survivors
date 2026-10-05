extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		printerr("Use the isolated Synergy Test profile")
		quit(2)
		return
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func kill_boss(game, cycle, through_aftermath := true):
	cycle.boss.take_damage(1.0e9, game.player.global_position)
	for i in 30:
		await process_frame
	cycle._process(0.01)
	if through_aftermath and cycle.phase == cycle.Phase.AFTERMATH:
		cycle._process(cycle.AFTERMATH_SECONDS + 0.1)

func run():
	root.size = Vector2i(1280, 720)
	load("res://scripts/RunMode.gd").training = false
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 5:
		await process_frame
	var monsters = game.get_node("MonsterManager")
	monsters.spawn_timer.stop()
	game.player.is_invincible = true
	# Vacuumed boss XP would otherwise open level-up screens mid-test.
	game.player.xp_to_next_level = 1.0e12
	var cycle = game.get_node_or_null("DayCycle")
	check(cycle != null and monsters.day_cycle_driven, "Normal runs follow the day cycle")
	check(cycle.day == 1 and cycle.sky_time() < 0.02 and cycle.grade.get_shader_parameter("strength") == 0.0, "Day 1 starts in plain 3 pm light")
	check(cycle.clock_label.text == "DAY 1", "Clock reads DAY 1")
	# The grade shifts hue toward night; brightness only dips slightly.
	var night_grade = cycle.sky_grade(1.0)
	check(night_grade.gain.z > night_grade.gain.y and night_grade.gain.y > night_grade.gain.x, "Night shifts the light toward blue")
	check(night_grade.bright >= 0.85 and night_grade.keep >= 0.7, "Night stays bright enough to read, and spells keep their colour")
	var golden = cycle.sky_grade(0.7)
	check(golden.gain.x > golden.gain.z, "Golden hour warms the light")
	cycle.day_clock = 0.0
	# Fixed-time bosses and the 20:00 end no longer apply.
	monsters.advance_time(1300.0)
	check(not monsters.awaiting_extraction and get_nodes_in_group("bosses").is_empty(), "The run timer alone neither spawns bosses nor ends the run")
	# Spawn pressure follows the day clock: each day opens light and swells toward dusk.
	check(monsters.current_spawn_phase().pressure == "light", "Each day opens in a light phase")
	cycle._process(40.0)
	check(monsters.current_spawn_phase().pressure == "heavy", "Pressure follows the day clock, not the run timer")
	# Daylight runs out: night falls and the boss emerges.
	cycle._process(cycle.DAY_SECONDS * cycle.DUSK_AT + 0.1)
	check(cycle.dusk_announced and cycle.phase == cycle.Phase.DAY, "Dusk warning comes before nightfall")
	cycle._process(cycle.DAY_SECONDS)
	check(cycle.phase == cycle.Phase.NIGHT and is_instance_valid(cycle.boss) and cycle.boss.boss, "Night falls and the day's boss emerges")
	check(cycle.nightfall_dip > 0.0 and cycle.banner.text.contains("NIGHT FALLS"), "Nightfall is a moment: the world dips dark and the boss is named")
	check(is_equal_approx(cycle.sky_time(), 1.0), "The sky is night while the boss lives")
	var clock_before = cycle.day_clock
	cycle._process(30.0)
	check(is_equal_approx(cycle.day_clock, clock_before), "The day clock stops at night")
	# The boss night follows the normal 2-minute cycle on the run timer, difficulty still climbing.
	var cycle_phase = func(t): return monsters.spawn_phase_at(t).interval
	monsters.day_cycle_driven = false
	var expected = cycle_phase.call(monsters.game_time)
	monsters.day_cycle_driven = true
	check(is_equal_approx(monsters.spawn_phase_interval(monsters.game_time), expected), "The boss night runs the normal two-minute spawn cycle")
	var straggler = monsters.spawn_monster()
	# load(), not preload(): a preload compiles XPOrb.gd before the autoloads exist.
	var far_orb = load("res://scenes/XPOrb.tscn").instantiate()
	game.add_child(far_orb)
	far_orb.global_position = game.player.global_position + Vector2(1800, 0)
	check(is_instance_valid(straggler), "A straggler is out with the boss")
	# Killing it opens camp: paused, combo kept.
	var style = game.style_session
	style.score.combo = 500.0
	await kill_boss(game, cycle, false)
	check(cycle.phase == cycle.Phase.AFTERMATH and not game.current_state == game.GameState.CAMP, "The boss falls: a quiet moment before camp")
	check(not straggler.is_in_group("enemies") and straggler.dying, "Everything else flees when the boss falls")
	check(far_orb.is_moving_to_player, "Every XP orb on the map flies to the player when the boss falls")
	check(monsters.current_spawn_phase().pressure == "rest" and monsters.refill_population_target() == 0, "Nothing spawns in the quiet after the boss")
	cycle._process(cycle.AFTERMATH_SECONDS + 0.1)
	check(cycle.phase == cycle.Phase.CAMP and game.current_state == game.GameState.CAMP and cycle.camp.visible, "Killing the boss opens camp")
	check(paused, "Camp pauses the game")
	var camp_combo = style.score.combo
	style.advance(10.0)
	check(camp_combo > 0.0 and is_equal_approx(style.score.combo, camp_combo), "Combo is kept in camp")
	# Waking up starts the next day with a no-decay grace.
	cycle.wake()
	check(cycle.day == 2 and cycle.day_clock == 0.0 and game.current_state == game.GameState.PLAYING, "Waking starts day 2")
	check(style.score.grace_remaining >= cycle.WAKE_GRACE, "Waking gives a no-decay grace")
	style.advance(cycle.WAKE_GRACE - 1.0)
	check(is_equal_approx(style.score.combo, camp_combo), "No decay during the wake grace")
	# Days 2 to 4; the fourth boss leads to extraction instead of camp.
	for d in [2, 3]:
		cycle._process(cycle.DAY_SECONDS + 1.0)
		await kill_boss(game, cycle)
		cycle.wake()
	check(cycle.day == 4, "Reached day 4")
	cycle._process(cycle.DAY_SECONDS + 1.0)
	check(cycle.boss.encounter_name == "The Warden" or cycle.boss.get("encounter_name") != null, "Day 4 brings the final boss")
	await kill_boss(game, cycle)
	await process_frame
	check(monsters.awaiting_extraction and game.current_state == game.GameState.EXTRACTION, "The fourth boss leads to extraction")
	var title = game.extraction_screen.find_child("Title", true, false)
	check(title and title.text == "4 DAYS SURVIVED", "Extraction names the days survived")
	game.continue_endless()
	cycle._process(0.01)
	check(cycle.day == 5 and cycle.phase == cycle.Phase.DAY, "Endless continues into day 5")
	game.free()
	await process_frame
	load("res://scripts/RunMode.gd").training = true
	var training = load("res://scenes/Game.tscn").instantiate()
	root.add_child(training)
	await process_frame
	check(training.get_node_or_null("DayCycle") == null and not training.get_node("MonsterManager").day_cycle_driven, "Training has no day cycle")
	training.free()
	load("res://scripts/RunMode.gd").training = false
	await process_frame
	print("Day cycle: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
