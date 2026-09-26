extends SceneTree

const ACTIONS = ["move_left", "move_right", "move_up", "move_down"]
var game
var rng = RandomNumberGenerator.new()
var run_seed = 11
var limit = 1200.0
var report_path = ""
var reaction = 0.0
var type_wait = 0.0
var cast_wait = 2.0
var choice_wait = 1.0
var pending_text = ""
var typed_index = 0
var attempts = 0
var successful_casts = 0
var failures = 0
var characters_typed = 0
var distance_walked = 0.0
var damage_taken = 0.0
var previous_health = 100.0
var previous_position = Vector2.ZERO
var upgrades: Array = []
var checkpoints: Array = []
var next_checkpoint = 60.0
var started = 0
var ready = false
var finished = false
var progress_wall = 0

func _initialize():
	for argument in OS.get_cmdline_user_args():
		var parts = argument.split("=", true, 1)
		if parts.size() != 2:
			continue
		match parts[0]:
			"--seed": run_seed = int(parts[1])
			"--limit": limit = clampf(float(parts[1]), 1.0, 1200.0)
			"--report": report_path = parts[1]
	if not OS.get_user_data_dir().contains("SpellCast Survivors Bot/") or report_path.is_empty():
		printerr("Bot requires isolated saves and report path; actual save directory: ", OS.get_user_data_dir())
		quit(2)
		return
	start.call_deferred()

func start():
	seed(run_seed)
	rng.seed = run_seed
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	previous_position = game.player.global_position
	previous_health = game.player.health
	game.player.health_changed.connect(observe_health)
	game.spell_manager.spell_cast.connect(func(_spell): successful_casts += 1)
	game.spell_manager.spell_locked_error.connect(func(_spell, _required, _level): failures += 1)
	started = Time.get_ticks_msec()
	DisplayServer.window_set_title("SpellCast Survivors — BASELINE BOT — seed %d" % run_seed)
	ready = true

func _process(delta):
	if not ready or finished:
		return false
	var time = game.get_node("MonsterManager").game_time
	if Time.get_ticks_msec() - progress_wall > 5000:
		progress_wall = Time.get_ticks_msec()
		print("BOT progress seconds=", time, " state=", game.current_state, " level=", game.player.level, " casts=", successful_casts)
	distance_walked += previous_position.distance_to(game.player.global_position)
	previous_position = game.player.global_position
	if game.current_state == game.GameState.GAME_OVER:
		finish("victory" if game.run_won else "death")
		return false
	if time >= limit:
		finish("time_limit")
		return false
	if Time.get_ticks_msec() - started > 3600000:
		finish("watchdog")
		return false
	if time >= next_checkpoint:
		checkpoints.append({"seconds": time, "level": game.player.level, "health": game.player.health, "kills": game.enemies_killed})
		print("BOT checkpoint ", checkpoints.back())
		next_checkpoint += 60.0
	var input_delta = delta / maxf(Engine.time_scale, 0.01)
	if game.current_state == game.GameState.LEVEL_UP:
		release_movement()
		choice_wait -= input_delta
		var screen = game.level_up_screen
		if choice_wait <= 0.0 and screen.visible and not screen.selecting_upgrade and not screen.available_upgrades.is_empty():
			var index = rng.randi_range(0, screen.available_upgrades.size() - 1)
			var button = screen.upgrade_buttons[index]
			if not button.disabled:
				upgrades.append({"seconds": time, "choice": screen.available_upgrades[index].key})
				button.pressed.emit()
				choice_wait = 1.0
		return false
	if paused:
		release_movement()
		return false
	choice_wait = 1.0
	var spells = game.spell_manager
	if spells.is_typing:
		release_movement()
		type_wait -= input_delta
		if type_wait <= 0.0:
			type_wait = 0.2
			if typed_index < pending_text.length():
				var character = pending_text.unicode_at(typed_index)
				press_key(character, character)
				typed_index += 1
				characters_typed += 1
			else:
				press_key(KEY_ENTER)
				if spells.is_typing:
					failures += 1
					press_key(KEY_ESCAPE)
		return false
	pending_text = ""
	reaction -= input_delta
	if reaction <= 0.0:
		reaction = 0.3
		move_decision()
	cast_wait -= input_delta
	if cast_wait <= 0.0:
		cast_wait = rng.randf_range(2.0, 4.0)
		var owned: Array = []
		for slot in spells.spells:
			if spells.is_spell_unlocked(slot):
				owned.append(slot)
		if not owned.is_empty():
			attempts += 1
			press_key(KEY_0 + owned[rng.randi_range(0, owned.size() - 1)])
			if spells.is_typing:
				pending_text = spells.target_spell
				typed_index = 0
				type_wait = 0.2
			else:
				failures += 1
	return false

func move_decision():
	var position = game.player.global_position
	var closest_enemy = nearest("enemies", position)
	var direction = Vector2.ZERO
	if closest_enemy and position.distance_to(closest_enemy.global_position) < 220.0:
		direction = position - closest_enemy.global_position
	else:
		var orb = nearest("xp_orbs", position)
		if orb:
			direction = orb.global_position - position
		else:
			direction = Vector2.from_angle(rng.randf_range(-PI, PI)) * 100.0
	release_movement()
	if absf(direction.x) > 8.0:
		Input.action_press("move_right" if direction.x > 0 else "move_left")
	if absf(direction.y) > 8.0:
		Input.action_press("move_down" if direction.y > 0 else "move_up")

func nearest(group: String, position: Vector2):
	var result = null
	var best = INF
	for node in get_nodes_in_group(group):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var distance = position.distance_squared_to(node.global_position)
		if distance < best:
			best = distance
			result = node
	return result

func press_key(keycode: int, unicode_value: int = 0):
	var event = InputEventKey.new()
	event.keycode = keycode
	event.unicode = unicode_value
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func release_movement():
	for action in ACTIONS:
		Input.action_release(action)

func observe_health(health: float, _maximum: float, _overheal: float):
	damage_taken += maxf(0.0, previous_health - health)
	previous_health = health

func finish(outcome: String):
	finished = true
	release_movement()
	var report = {"schema_version": 1, "seed": run_seed, "outcome": outcome,
		"survival_seconds": game.get_node("MonsterManager").game_time,
		"wall_seconds": (Time.get_ticks_msec() - started) / 1000.0,
		"level": game.player.level, "health": game.player.health,
		"kills": game.enemies_killed, "health_damage_taken": damage_taken,
		"spell_attempts": attempts, "successful_casts": successful_casts,
		"casting_failures": failures, "characters_typed": characters_typed,
		"distance_walked": distance_walked, "spells_acquired": game.spell_manager.get_unlocked_spell_names(),
		"upgrade_choices": upgrades, "checkpoints": checkpoints,
		"save_directory": OS.get_user_data_dir(), "reaction_seconds": 0.3,
		"characters_per_second": 5.0, "measured_fps": Engine.get_frames_per_second()}
	var file = FileAccess.open(report_path, FileAccess.WRITE)
	if not file:
		printerr("Cannot write bot report: ", report_path)
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("BOT_RESULT ", JSON.stringify(report))
	cleanup.call_deferred()

func cleanup():
	paused = false
	Engine.time_scale = 1.0
	game.queue_free()
	await process_frame
	await process_frame
	quit()
