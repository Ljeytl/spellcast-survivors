extends SceneTree

const ACTIONS = ["move_left", "move_right", "move_up", "move_down"]
var game
var rng = RandomNumberGenerator.new()
var run_seed = 11
var limit = 1200.0
var behavior_mode = "active"
## Debug: spell ids the bot levels evenly and casts exclusively (e.g. --focus=meteor_shower,plague_seed,ice_blast).
var focus_spells: Array = []
## Debug: passives taken when no focus card is offered, in priority order.
var focus_passives: Array = ["spell_damage"]
## Debug: player takes no damage, for measuring pace and kills without dying.
var invulnerable = false
var first_damage_seconds = -1.0
var report_path = ""
var reaction = 0.0
var type_wait = 0.0
var cast_wait = 2.0
var choice_wait = 1.0
var pending_text = ""
var typed_index = 0
var attempts = 0
var successful_casts = 0
var casts_by_spell: Dictionary = {}
var failures = 0
var characters_typed = 0
var distance_walked = 0.0
var damage_taken = 0.0
var damage_by_kind: Dictionary = {}
var damage_while_typing = 0.0
var damage_events: Array = []
var boss_events: Array = []
var previous_health = 100.0
var previous_overheal = 0.0
var pending_damage = 0.0
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
			"--mode": behavior_mode = parts[1]
			"--focus": focus_spells = Array(parts[1].split(",", false))
			"--passives": focus_passives = Array(parts[1].split(",", false))
			"--invulnerable": invulnerable = parts[1] in ["1", "true", "yes"]
	if not OS.get_user_data_dir().contains("SpellCast Survivors Bot/") or report_path.is_empty():
		printerr("Bot requires isolated saves and report path; actual save directory: ", OS.get_user_data_dir())
		quit(2)
		return
	if behavior_mode not in ["idle", "movement", "casting", "active"]:
		quit(2)
		return
	start.call_deferred()

func start():
	seed(run_seed)
	rng.seed = run_seed
	game = load("res://scenes/Game.tscn").instantiate()
	game.set_meta("bot_run", true)
	root.add_child(game)
	current_scene = game
	game.player.is_invincible = invulnerable
	previous_position = game.player.global_position
	previous_health = game.player.health
	previous_overheal = game.player.overheal
	game.player.health_changed.connect(observe_health)
	game.player.player_damaged.connect(observe_damage)
	game.get_node("MonsterManager").boss_arrived.connect(func(boss_name):
		boss_events.append({"event": "arrived", "name": boss_name, "seconds": run_time()})
	)
	game.get_node("MonsterManager").monster_died.connect(func(data):
		if data.get("boss", false):
			boss_events.append({"event": "defeated", "variant": data.variant, "seconds": run_time()})
	)
	game.spell_manager.spell_cast.connect(func(spell):
		successful_casts += 1
		casts_by_spell[spell] = casts_by_spell.get(spell, 0) + 1
	)
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
		checkpoints.append({"seconds": time, "level": game.player.level, "health": game.player.health, "kills": game.enemies_killed, "enemies_alive": get_nodes_in_group("enemies").size(), "uncollected_xp": uncollected_xp(), "bosses": boss_snapshot(), "focus_ranks": focus_ranks(), "spell_damage_multiplier": game.player.spell_damage_multiplier, "damage_by_kind": damage_by_kind.duplicate(), "damage_while_typing": damage_while_typing})
		print("BOT checkpoint ", checkpoints.back())
		next_checkpoint += 60.0
	var input_delta = delta / maxf(Engine.time_scale, 0.01)
	if game.current_state == game.GameState.LEVEL_UP:
		release_movement()
		choice_wait -= input_delta
		var screen = game.level_up_screen
		if choice_wait <= 0.0 and screen.visible and not screen.selecting_upgrade and not screen.available_upgrades.is_empty():
			if not focus_spells.is_empty() and steer_offer(screen):
				choice_wait = 0.3
				return false
			var index = choose_upgrade(screen.available_upgrades) if not focus_spells.is_empty() else rng.randi_range(0, screen.available_upgrades.size() - 1)
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
		if behavior_mode in ["movement", "active"]:
			move_decision()
		else:
			release_movement()
	cast_wait -= input_delta
	if cast_wait <= 0.0 and behavior_mode in ["casting", "active"]:
		cast_wait = rng.randf_range(2.0, 4.0)
		var owned = spells.get_owned_incantations()
		if not owned.is_empty():
			attempts += 1
			if not focus_spells.is_empty():
				var focused = focus_incantations()
				var pool = owned.filter(func(name): return name in focused)
				if not pool.is_empty():
					owned = pool
			var selected = owned[rng.randi_range(0, owned.size() - 1)]
			press_key(KEY_SPACE)
			if spells.is_typing:
				pending_text = selected
				typed_index = 0
				type_wait = 0.2
			else:
				failures += 1
	return false

## Focus mode: banish a non-focus spell card, or reroll, when the offer has nothing useful. Returns true if it acted.
func steer_offer(screen) -> bool:
	var cards = screen.available_upgrades
	if card_score(cards[choose_upgrade(cards)]) >= 0.0:
		return false
	if screen.banishes_remaining > 0:
		for i in cards.size():
			var key = str(cards[i].get("key", ""))
			if key.begins_with("learn:") and key.get_slice(":", 1) not in focus_spells:
				screen.banish_upgrade(i)
				upgrades.append({"seconds": game.get_node("MonsterManager").game_time, "choice": "banish:" + key})
				return true
	if screen.rerolls_remaining > 0:
		screen._on_reroll_pressed()
		upgrades.append({"seconds": game.get_node("MonsterManager").game_time, "choice": "reroll"})
		return true
	return false

## Focus mode card choice: learn a focus spell, else rank the lowest-ranked focus spell, else a listed passive, else any passive.
func choose_upgrade(cards: Array) -> int:
	var best = 0
	var best_score = -INF
	for i in cards.size():
		var score = card_score(cards[i])
		if score > best_score:
			best_score = score
			best = i
	return best

func card_score(card: Dictionary) -> float:
	var key = str(card.get("key", ""))
	var kind = key.get_slice(":", 0)
	var id = key.get_slice(":", 1)
	if kind == "learn" and id in focus_spells:
		return 1000.0
	if kind == "rank" and id in focus_spells:
		return 500.0 - game.spell_manager.get_spell_rank(id)
	if kind == "passive" and id in focus_passives:
		return 100.0 - focus_passives.find(id)
	if kind == "passive":
		return 10.0
	if kind == "learn":
		return -100.0
	return -10.0

func focus_incantations() -> Array:
	var names: Array = []
	for id in focus_spells:
		var info = game.spell_manager.spell_catalog.get(id, {})
		if not info.is_empty():
			names.append(str(info.display_name))
	return names

func focus_ranks() -> Dictionary:
	var ranks = {}
	for id in focus_spells:
		ranks[id] = game.spell_manager.get_spell_rank(id)
	return ranks

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

func observe_health(health: float, _maximum: float, overheal: float):
	damage_taken += maxf(0.0, previous_health - health)
	pending_damage = maxf(0.0, previous_health + previous_overheal - health - overheal)
	previous_health = health
	previous_overheal = overheal

func run_time() -> float:
	return game.get_node("MonsterManager").game_time

func uncollected_xp() -> float:
	var total = 0.0
	for orb in get_nodes_in_group("xp_orbs"):
		if is_instance_valid(orb) and not orb.is_queued_for_deletion() and not orb.collected:
			total += orb.xp_value
	return total

func boss_snapshot() -> Array:
	var result: Array = []
	for enemy in get_nodes_in_group("bosses"):
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.dying:
			result.append({"name": enemy.encounter_name, "variant": enemy.variant, "health": enemy.current_health, "max_health": enemy.max_health, "distance": enemy.global_position.distance_to(game.player.global_position)})
	return result

func observe_damage():
	var context = game.player.last_damage_context.duplicate(true)
	var amount = pending_damage
	pending_damage = 0.0
	if amount <= 0:
		return
	if first_damage_seconds < 0.0:
		first_damage_seconds = run_time()
	var kind = str(context.get("kind", "unknown"))
	damage_by_kind[kind] = damage_by_kind.get(kind, 0.0) + amount
	if game.spell_manager.is_typing:
		damage_while_typing += amount
	context["damage"] = amount
	context["seconds"] = run_time()
	context["typing"] = game.spell_manager.is_typing
	damage_events.append(context)
	if damage_events.size() > 12:
		damage_events.pop_front()

func finish(outcome: String):
	finished = true
	release_movement()
	var report = {"focus_spells": focus_spells, "focus_passives": focus_passives, "invulnerable": invulnerable, "focus_ranks": focus_ranks(),
		"damage_by_spell": game.style_session.damage_by_spell.duplicate() if game.get("style_session") else {},
		"behavior_mode": behavior_mode, "first_damage_seconds": first_damage_seconds, "schema_version": 2, "seed": run_seed, "outcome": outcome,
		"survival_seconds": game.get_node("MonsterManager").game_time,
		"wall_seconds": (Time.get_ticks_msec() - started) / 1000.0,
		"level": game.player.level, "health": game.player.health,
		"kills": game.enemies_killed, "health_damage_taken": damage_taken,
		"damage_by_kind": damage_by_kind, "damage_while_typing": damage_while_typing,
		"recent_damage": damage_events, "boss_events": boss_events, "surviving_bosses": boss_snapshot(),
		"uncollected_xp": uncollected_xp(),
		"spell_attempts": attempts, "successful_casts": successful_casts,
		"casting_input": "space_enter", "casts_by_spell": casts_by_spell,
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
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	var stop_time = Time.get_ticks_msec()
	while Time.get_ticks_msec() - stop_time < 250:
		await process_frame
	quit()
