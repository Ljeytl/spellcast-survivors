extends SceneTree
## Console "day" command: jump to a day, to dusk, or to the boss night.

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
	var cycle = game.get_node("DayCycle")
	check(cycle.debug_jump("sideways") == "", "Unknown targets are refused")
	cycle.debug_jump("dusk")
	cycle._process(3.5)
	check(cycle.dusk_announced and cycle.phase == cycle.Phase.DAY, "day dusk lands just before the dusk warning")
	cycle.debug_jump("night")
	check(cycle.phase == cycle.Phase.NIGHT and is_instance_valid(cycle.boss), "day night brings the boss now")
	check(cycle.debug_jump("night").begins_with("It is already night"), "No second boss while one is out")
	var before = monsters.game_time
	cycle.debug_jump("3")
	await process_frame
	check(cycle.day == 3 and cycle.phase == cycle.Phase.DAY and cycle.day_clock < 1.0, "day 3 starts day 3 at 3 pm")
	check(cycle.boss == null and get_nodes_in_group("bosses").filter(func(b): return not b.is_queued_for_deletion()).is_empty(), "Jumping clears the boss that was out")
	check(monsters.game_time >= 2.0 * (cycle.DAY_SECONDS + 30.0) and monsters.game_time >= before, "Run time moves forward to day 3, so difficulty matches")
	var later = monsters.game_time
	cycle.debug_jump("1")
	check(cycle.day == 1 and monsters.game_time == later, "Going back a day never rewinds run time")
	var console = game.console_instance
	check(is_instance_valid(console), "The developer console exists")
	console.jump_day(["2"])
	check(cycle.day == 2, "The console command drives the jump")
	print("Day console: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
