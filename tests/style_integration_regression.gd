extends SceneTree

var checks = 0
var failures = 0
var game
var manager
var session
var artifact_dir = "res://builds/style-verification"
var screenshots = false
var prior_scores: Dictionary = {}
const Store = preload("res://scripts/StyleScoreStore.gd")

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		printerr("Use the isolated Synergy Test profile")
		quit(2)
		return
	for suffix in ["", ".bak", ".tmp"]:
		var path = Store.DEFAULT_PATH + suffix
		prior_scores[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func fresh(bot_run: bool = false):
	paused = false
	Engine.time_scale = 1.0
	if is_instance_valid(game):
		game.free()
	game = load("res://scenes/Game.tscn").instantiate()
	game.set_meta("bot_run", bot_run)
	root.add_child(game)
	current_scene = game
	manager = game.spell_manager
	session = game.style_session
	manager.set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	manager.casting_clock = 10.0

func key(code: int, unicode: int = 0):
	var event = InputEventKey.new()
	event.keycode = code
	event.unicode = unicode
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func letters(text: String, interval: float = 0.25):
	for i in text.length():
		if i > 0:
			session.advance(interval)
		key(text[i].to_upper().unicode_at(0), text.unicode_at(i))

func click(button: Control):
	if DisplayServer.get_name() == "headless":
		button.pressed.emit()
		return
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_rect().get_center()
	event.global_position = event.position
	event.pressed = true
	root.push_input(event, true)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	Input.flush_buffered_events()

func capture(file: String):
	if screenshots:
		await create_timer(0.25, true, false, true).timeout
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(artifact_dir)
		root.get_texture().get_image().save_png(artifact_dir.path_join(file + ".png"))

func run():
	root.get_node("AudioManager").quitting = true
	fresh()
	await process_frame
	session.score.combo = 5000.0
	session.score.grace_remaining = 0.0
	manager.set_process(true)
	for i in 4:
		await process_frame
	key(KEY_SPACE)
	letters("b")
	var live_start = session.clock
	await create_timer(1.0, false, false, true).timeout
	check(session.clock - live_start > 0.8 and session.clock - live_start < 1.5, "Running slowed cast advances a real second")
	check(session.score.combo < 4970.0, "Typing does not freeze live decay")
	game.change_state(game.GameState.PAUSED)
	var pause_start = session.clock
	await create_timer(0.3, true, false, true).timeout
	check(session.clock == pause_start, "Running pause freezes input clock")
	game.change_state(game.GameState.PLAYING)
	key(KEY_ESCAPE)
	manager.set_process(false)
	manager.learn_spell("focus_ray")
	manager.cast_build_spell(manager.find_spell_slot("focus_ray"))
	var channel = get_first_node_in_group("active_spell_channels")
	check(is_instance_valid(channel), "Real Focus Ray exposes active channel lifetime")
	channel.set_physics_process(false)
	session.score.combo = 5000.0
	session.score.grace_remaining = 0.0
	var channel_bank = session.score.run_score
	session.advance(10.0)
	check(session.score.combo == 5000.0 and session.score.run_score == channel_bank, "Active channel without a target suspends decay but awards nothing")
	channel.advance(20.0)
	session.advance(0.1)
	check(session.score.grace_remaining == 5.0, "Channel expiry restores full normal grace")
	session.advance(2.0)
	check(session.score.combo == 5000.0, "Afterglow cannot consume channel-end grace early")
	session.advance(4.0)
	check(session.score.combo == 4950.0, "Decay resumes normally after channel grace")
	fresh()
	await process_frame
	key(KEY_1)
	letters("bolt")
	check(session.score.manual_casts == 1 and session.score.run_score == 46, "Real slot input scores once at reference pace")
	var bank = session.score.run_score
	manager.cast_bolt_spell(1)
	manager.handle_auto_attack(100.0)
	check(session.score.run_score == bank and session.score.manual_casts == 1, "Automatic and direct effect calls award nothing")
	manager.casting_clock += 2.0
	key(KEY_SPACE)
	letters("bolt")
	check(manager.is_typing and session.score.manual_casts == 1, "Space casting awaits Enter")
	session.advance(8.0)
	key(KEY_ENTER)
	check(session.score.manual_casts == 2 and session.score.run_score == 85, "Submit delay does not change final-letter speed or duplicate release")
	manager.casting_clock += 2.0
	key(KEY_1)
	letters("bx")
	check(session.mistakes == 1, "Invalid prefix opens typo episode")
	letters("zzz")
	check(session.mistakes == 1, "Same invalid episode is one mistake")
	for i in 4:
		key(KEY_BACKSPACE)
	letters("olt")
	check(session.score.manual_casts == 3 and session.score.clean_casts == 2, "Correction casts successfully with reduced clean bonus")
	manager.casting_clock += 2.0
	key(KEY_SPACE)
	letters("meteor shower")
	key(KEY_ENTER)
	check(manager.is_typing and session.score.manual_casts == 3, "Locked spell does not award")
	key(KEY_ESCAPE)
	var before = session.score.combo
	game.change_state(game.GameState.PAUSED)
	session.advance(30.0)
	key(KEY_1)
	check(session.score.combo == before and not manager.is_typing, "Pause freezes score and casting")
	game.change_state(game.GameState.PLAYING)
	game.change_state(game.GameState.LEVEL_UP)
	session.advance(30.0)
	check(session.score.combo == before, "Upgrade selection freezes score")
	game.change_state(game.GameState.PLAYING)
	game.level_up_screen.hide()
	key(KEY_1)
	var clock_before = session.clock
	manager._scale_change_frame = -1
	manager._process(0.1)
	check(is_equal_approx(session.clock - clock_before, 0.5), "Slowdown uses real scoring seconds")
	key(KEY_ESCAPE)
	session.score.combo = 5000.0
	game.player.overheal = 10.0
	game.player.take_damage(5.0)
	check(session.score.combo == 5000.0, "Fully absorbed damage preserves rank")
	game.player.overheal = 0.0
	game.player.take_damage(1.0)
	check(session.score.rank_index() == 5, "Health damage drops one grade")
	bank = session.score.run_score
	session.score.advance(1000.0)
	check(session.score.combo == 0.0 and session.score.run_score == bank, "Idle decay preserves banked run score")
	await capture("game-f")
	var model = preload("res://scripts/StyleScore.gd")
	var rank_hud = game.hud.get_node("StyleHUD")
	for rank in model.RANKS.size():
		var upper = model.THRESHOLDS[rank + 1] if rank < 8 else model.CAP
		session.score.combo = (model.THRESHOLDS[rank] + upper) / 2.0
		session.updated.emit()
		check(rank_hud.label.text.begins_with(model.RANKS[rank]) and is_equal_approx(rank_hud.meter.value, 0.5), "Rank glyph, label and segment fill agree: " + model.RANKS[rank])
	check(rank_hud.format_score(2500000) == "2.5M", "Large HUD scores use compact notation")
	manager.casting_clock += 2.0
	session.score.combo = 5000.0
	session.updated.emit()
	await capture("game-s")
	key(KEY_SPACE)
	letters("atomic", 0.1)
	session.score.combo = 4700.0
	key(KEY_ENTER)
	check(manager.is_typing and session.special_casts == 0 and session.score.combo == 4700.0, "Lost S rejects Atomic without spending or clearing text")
	session.score.combo = 9999.0
	key(KEY_ENTER)
	check(manager.is_typing and session.special_casts == 0 and session.score.combo == 9999.0, "SSS alone cannot bypass Atomic cost")
	session.score.combo = 10000.0
	session.updated.emit()
	await capture("atomic-ready")
	key(KEY_ENTER)
	check(not manager.is_typing and session.special_casts == 1 and session.score.combo == 0.0, "Atomic spends exactly 10000 once")
	check(session.score.run_score == bank, "Atomic does not repay itself")
	await capture("atomic-warning")
	await create_timer(0.8).timeout
	await capture("atomic-impact")
	session.score.combo = 6700.0
	session.score.peak_rank = 8
	session.score.peak_combo = 6700.0
	session.updated.emit()
	await capture("game-sss")
	root.size = Vector2i(480, 800)
	for i in 8:
		await process_frame
	session.updated.emit()
	check(rank_hud.score_label.get_rect().end.y <= rank_hud.note.position.y, "Narrow score and feedback never overlap")
	check(rank_hud.special.get_rect().end.y <= rank_hud.size.y, "Atomic label fits HUD bounds")
	await capture("game-narrow")
	var hud = game.hud.get_node("StyleHUD")
	check(hud.position.x >= 0 and hud.get_rect().end.x <= game.hud.size.x, "Style HUD fits narrow viewport")
	var saved_id = session.run_id
	game.finish_run(false)
	check(session.finalized and session.result.outcome == "death" and session.result.saved, "Eligible result is saved")
	check(Store.list_scores().any(func(record): return record.run_id == saved_id), "Saved run reloads from disk")
	var result = session.finish({"won": true})
	check(result.outcome == "death", "Second terminal callback cannot replace result")
	await capture("result-narrow")
	click(game.game_over_screen.play_again_button)
	for i in 10:
		await process_frame
	game = current_scene
	manager = game.spell_manager
	session = game.style_session
	manager.set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	check(session.score.run_score == 0 and session.score.combo == 0 and not session.finalized and not paused, "Retry starts a fresh live score session")
	manager.casting_clock = 10.0
	key(KEY_SPACE)
	letters("bolt")
	var count = session.score.manual_casts
	manager.manual_spell_released.emit("bolt", "bolt", "bolt")
	manager.manual_spell_released.emit("bolt", "bolt", "bolt")
	check(session.score.manual_casts == count + 1, "Duplicate adapter release consumes one receipt")
	key(KEY_ESCAPE)
	game.player.is_invincible = true
	session.advance(0.1)
	game.player.is_invincible = false
	game.finish_run(true)
	check(not session.result.eligible and not session.result.saved, "Turning invincibility off does not restore eligibility")
	click(game.game_over_screen.main_menu_button)
	for i in 10:
		await process_frame
	var menu = current_scene
	await capture("menu-narrow")
	var button = menu.get_node("MenuPanel/VBoxContainer/ScoresButton")
	check(button.get_global_rect().end.y <= menu.size.y * menu.scale.y, "High Scores button fits narrow menu")
	click(button)
	await process_frame
	check(menu.has_node("StyleLeaderboard") and not menu.get_node("MenuPanel").visible, "High Scores opens")
	await capture("leaderboard-narrow")
	key(KEY_ESCAPE)
	await process_frame
	check(not menu.has_node("StyleLeaderboard") and menu.get_node("MenuPanel").visible, "Escape returns to main menu")
	root.size = Vector2i(1280, 720)
	await capture("menu-desktop")
	menu.free()
	game = null
	fresh(true)
	check(not session.eligible and session.exclusion_reason == "Bot run", "Bot metadata excludes run before first input")
	game.free()
	game = null
	fresh()
	game.console_instance.execute_command("help")
	check(session.eligible, "Read-only console help retains eligibility")
	game.player.health = 50.0
	game.console_instance.execute_command("heal")
	check(game.player.health == game.player.max_health, "Console heal uses supported player health API")
	check(not session.eligible, "Console mutation permanently excludes run")
	game.free()
	await process_frame
	for path in prior_scores:
		if prior_scores[path] == null:
			DirAccess.remove_absolute(path)
		else:
			var restored = FileAccess.open(path, FileAccess.WRITE)
			restored.store_buffer(prior_scores[path])
			restored.close()
	print("Style integration: %d assertions, %d failures" % [checks, failures])
	quit(1 if failures else 0)
