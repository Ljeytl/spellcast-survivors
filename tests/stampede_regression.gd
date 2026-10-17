extends SceneTree
## The stampede set piece (data/events.json, scripts/Stampede.gd): scheduled by the day clock,
## telegraphed by a lane, a herd that runs straight through ignoring you and leaves at the far side.

var checks = 0
var failures = 0

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
	var monsters = game.get_node("MonsterManager")
	monsters.set_process(false)
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await process_frame
	monsters.monsters_alive = 0
	var herd = monsters.stampede
	var cfg = herd.config()
	check(herd != null and herd.state == "idle", "the stampede runner exists and waits")
	check(herd.herd_size(1) == int(cfg.counts[0]) and herd.herd_size(99) == int(cfg.counts[-1]), "herd size grows by day and repeats the last")

	# Schedule: the day clock reaching the first time starts one; a jump far past a time skips it.
	var cycle = get_first_node_in_group("day_cycle")
	check(cycle != null, "the day cycle drives the schedule")
	cycle.day_clock = float(cfg.by_day[0][0]) - 1.0
	herd.update(0.016)
	check(herd.state == "idle", "no stampede before its time")
	cycle.day_clock = float(cfg.by_day[0][0]) + 0.5
	herd.update(0.016)
	check(herd.state == "warning" and herd.started == 1, "the day clock starts the stampede")
	check(get_nodes_in_group("stampede_lanes").size() == 1, "the lane is telegraphed")
	herd.stop()
	await process_frame
	monsters.phase_override = "night"
	cycle.day = 2
	cycle.day_clock = float(cfg.by_day[1][0]) + 0.5
	herd.update(0.016)
	check(herd.state == "idle", "no stampede at night")
	monsters.phase_override = ""
	herd.seen.clear()
	cycle.day_clock = float(cfg.by_day[1][0]) + 30.0
	herd.update(0.016)
	check(herd.state == "idle", "jumping far past a stampede's time skips it")

	# The herd: warning, then it runs straight through, ignoring you.
	herd.start(20)
	var lane_dir = herd.direction
	herd.update(float(cfg.warning_seconds) + 0.01)
	check(herd.state == "running", "after the warning the herd comes")
	for i in 60:
		herd.update(0.05)
	var members = get_nodes_in_group("enemies").filter(func(e): return e.has_meta("stampede"))
	check(members.size() == 20, "the whole herd arrives (%d)" % members.size())
	check(herd.state == "idle", "the runner is free once the herd is out")
	var m = members[0]
	var before = m.global_position
	game.player.global_position = m.global_position + lane_dir.orthogonal() * 80.0
	m._physics_process(0.1)
	var moved = m.global_position - before
	check(moved.normalized().dot(lane_dir) > 0.99 and absf(moved.length() - float(cfg.speed) * 0.1) < 2.0, "a herd member runs straight down the lane, ignoring you")
	monsters.encounter_director.recycle_distant()
	check(m.global_position.is_equal_approx(before + moved), "recycling never teleports a herd member")
	var alive = monsters.monsters_alive
	m.stampede_left = 1.0
	m._physics_process(0.1)
	check(m.is_queued_for_deletion() and monsters.monsters_alive == alive - 1, "it leaves the field at the far side")

	# Console.
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await process_frame
	game.console_instance.execute_command("stampede 5")
	check(herd.state == "warning", "console `stampede` starts one")
	print("stampede: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
