extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func press(code: int):
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func wait_seconds(seconds: float):
	var start = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000:
		await process_frame

func run():
	Engine.max_fps = 15
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	await wait_seconds(0.5)
	game.get_node("MonsterManager").spawn_timer.stop()
	var spells = game.spell_manager
	press(KEY_SPACE)
	var started = Time.get_ticks_msec()
	while spells.typing_slowdown_remaining > 0 and Time.get_ticks_msec() - started < 4500:
		await process_frame
	var elapsed = (Time.get_ticks_msec() - started) / 1000.0
	print("SLOWDOWN_ELAPSED_SECONDS=", elapsed)
	check(absf(elapsed - 1.5) < 0.2, "Slowdown lasts approximately 1.5 unscaled seconds at 15 FPS")
	check(spells.is_typing and is_equal_approx(Engine.time_scale, 1), "Real process restores normal speed on expiry")
	press(KEY_ESCAPE)
	press(KEY_SPACE)
	check(is_equal_approx(Engine.time_scale, 0.2), "Immediate reopen gets a fresh cast allowance")
	press(KEY_ESCAPE)
	await wait_seconds(1.0)
	var refilled = spells.typing_slowdown_remaining
	check(is_equal_approx(refilled, 1.5), "Idle process does not spend or refill inactive allowance")
	press(KEY_SPACE)
	game.change_state(game.GameState.PAUSED)
	await wait_seconds(0.5)
	check(is_equal_approx(spells.typing_slowdown_remaining, refilled), "Paused wall time consumes no budget")
	game.change_state(game.GameState.PLAYING)
	await wait_seconds(0.5)
	check(absf(spells.typing_slowdown_remaining - 1.0) < 0.15, "Resume spends only the elapsed half second")
	spells.cancel_typing()
	game.queue_free()
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	await wait_seconds(0.25)
	print("TYPING_TIMING_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
