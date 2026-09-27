extends SceneTree

var checks = 0
var failures = 0

func check(value: bool, label: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL ", label)

func _initialize():
	run.call_deferred()

func settled(workshop):
	for frame in range(60):
		await process_frame
		if not workshop.busy:
			return
	check(false, "workshop settles within bounded frames")

func send(workshop, request: Dictionary):
	workshop.command([JSON.stringify(request)])

func run():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Visual Workshop"):
		quit(2)
		return
	var workshop = load("res://tools/workshop/VisualWorkshop.gd").new()
	root.add_child(workshop)
	await settled(workshop)
	send(workshop, {"action":"select", "id":"meteor_shower"})
	await settled(workshop)
	send(workshop, {"action":"play", "value":false})
	var health = workshop.fixture.targets[0].current_health
	var time = workshop.fixture.elapsed
	if "--known-bad-pause" in OS.get_cmdline_user_args():
		Engine.time_scale = 1.0
	for frame in range(70):
		await process_frame
	check(workshop.fixture.targets[0].current_health == health, "paused delayed meteor does not strike")
	check(workshop.fixture.elapsed == time, "paused clock holds")
	check(paused and not workshop.playing, "paused state truthful")
	send(workshop, {"action":"select", "id":"ice_blast"})
	await settled(workshop)
	check(workshop.playing and not paused, "select after pause starts playback")
	check(workshop.fixture.selected == "ice_blast", "Ice Blast actually selected")
	check(not get_nodes_in_group("ice_blasts").is_empty(), "Ice Blast spawns visible effect")
	send(workshop, {"action":"step"})
	send(workshop, {"action":"select", "id":"bolt"})
	await settled(workshop)
	check(workshop.playing and not paused, "stale step does not repause new selection")
	check(workshop.fixture.selected == "bolt", "latest selection wins")
	send(workshop, {"action":"play", "value":false})
	send(workshop, {"action":"replay"})
	await settled(workshop)
	check(workshop.playing and not paused, "Replay starts playback")
	send(workshop, {"action":"play", "value":false})
	send(workshop, {"action":"speed", "value":0.5})
	check(Engine.time_scale == 0.0 and paused, "speed change does not resume paused timers")
	send(workshop, {"action":"step"})
	await settled(workshop)
	check(paused and not workshop.playing and Engine.time_scale == 0.0, "step returns to frozen state")
	paused = false
	Engine.time_scale = 1.0
	workshop.free()
	print("TRANSPORT CHECKS ", checks, " FAILURES ", failures)
	quit(1 if failures else 0)
