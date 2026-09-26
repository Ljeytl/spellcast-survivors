extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Slowdown Test"):
		printerr("Refusing nonisolated slowdown regression")
		quit(2)
		return
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func key(code: int, character: int = 0) -> InputEventKey:
	var event = InputEventKey.new()
	event.pressed = true
	event.keycode = code
	event.unicode = character
	return event

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var spells = game.spell_manager
	spells.set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	check(is_equal_approx(spells.typing_slowdown_remaining, 3.0), "Fresh run starts with three seconds")
	spells.handle_key_input(key(KEY_SPACE))
	check(spells.is_typing and Engine.time_scale < 1, "Space starts slowdown")
	spells.handle_key_input(key(KEY_B, 98))
	spells.advance_typing_slowdown(1.0)
	check(is_equal_approx(spells.typing_slowdown_remaining, 2.0), "Budget consumes unscaled seconds")
	spells.cancel_typing()
	check(is_equal_approx(Engine.time_scale, 1), "Cancel restores speed")
	spells.queue_spell(1)
	spells.start_typing()
	check(is_equal_approx(spells.typing_slowdown_remaining, 2), "Numbered casting shares the existing budget")
	spells.advance_typing_slowdown(3.0)
	check(is_equal_approx(spells.typing_slowdown_remaining, 0), "Budget clamps at zero")
	check(spells.is_typing and is_equal_approx(Engine.time_scale, 1), "Expiry keeps typing at normal speed")
	for letter in "bolt":
		spells.handle_key_input(key(letter.unicode_at(0), letter.unicode_at(0)))
	check(not spells.is_typing, "Numbered spell still casts after expiry")
	spells.start_freeform_typing()
	spells.space_casting = true
	check(is_equal_approx(Engine.time_scale, 1), "Reopening cannot reset empty budget")
	spells.current_typing_text = "unknown"
	spells.attempt_freeform_cast()
	var error_copy = game.typing_label.text
	spells.advance_typing_slowdown(1.0)
	check(game.typing_label.text == error_copy, "Budget status does not erase invalid-spell feedback")
	check(spells.current_typing_text == "unknown", "Expiry preserves input")
	spells.handle_key_input(key(KEY_BACKSPACE))
	check(spells.current_typing_text == "unknow", "Invalid input remains editable at normal speed")
	spells.cancel_typing()
	spells.advance_typing_slowdown(5.0)
	check(is_equal_approx(spells.typing_slowdown_remaining, 1.5), "Five seconds refills half the budget")
	spells.advance_typing_slowdown(100.0)
	check(is_equal_approx(spells.typing_slowdown_remaining, 3.0), "Refill cannot exceed capacity")
	spells.start_freeform_typing()
	spells._scale_change_frame = -1
	spells._process(0.2)
	check(is_equal_approx(spells.typing_slowdown_remaining, 2), "Scaled process delta consumes one unscaled second")
	spells.set_process(true)
	game.change_state(game.GameState.PAUSED)
	var before_pause = spells.typing_slowdown_remaining
	for i in range(5):
		await process_frame
	check(is_equal_approx(spells.typing_slowdown_remaining, before_pause), "Pause freezes budget consumption")
	spells.cancel_typing()
	game.change_state(game.GameState.LEVEL_UP)
	for i in range(5):
		await process_frame
	check(is_equal_approx(spells.typing_slowdown_remaining, before_pause), "Level-up freezes refill")
	spells.set_process(false)
	game.change_state(game.GameState.PLAYING)
	spells.start_freeform_typing()
	game.finish_run(false)
	check(not spells.is_typing and is_equal_approx(Engine.time_scale, 1), "Death ends typing and restores normal speed")
	game.queue_free()
	paused = false
	await process_frame
	var fresh = load("res://scenes/Game.tscn").instantiate()
	root.add_child(fresh)
	await process_frame
	check(is_equal_approx(fresh.spell_manager.typing_slowdown_remaining, 3), "Next run gets a fresh budget")
	fresh.spell_manager.start_freeform_typing()
	fresh.finish_run(true)
	check(not fresh.spell_manager.is_typing and is_equal_approx(Engine.time_scale, 1), "Victory also restores speed")
	fresh.queue_free()
	paused = false
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	await create_timer(0.25).timeout
	print("TYPING_BUDGET_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
