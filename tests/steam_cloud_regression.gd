extends SceneTree

const CLOUD = preload("res://scripts/vfx/SteamCloud.gd")
var checks := 0
var failures := 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr(message)

func run():
	if not root.is_node_ready():
		await root.ready
	await process_frame
	var vfx = root.get_node("Vfx")
	for reduced in [false, true]:
		var cloud = CLOUD.new()
		cloud.setup(100.0, 5.0, reduced)
		vfx.add_child(cloud)
		cloud.set_process(false)
		check(cloud.scale == Vector2(270, 300), "Volume follows spell radius")
		check(cloud.material.get_shader_parameter("reduced") == reduced, "Cloud honors effects mode")
		vfx.reduced_effects = not reduced
		cloud._process(0.01)
		check(cloud.material.get_shader_parameter("reduced") == not reduced, "Existing cloud follows live preference changes")
		cloud._process(2.0)
		check(not cloud.is_queued_for_deletion(), "Sustained cloud remains live")
		cloud.finish()
		cloud._process(0.7)
		check(not cloud.is_queued_for_deletion(), "Expiry disperses before removal")
		cloud.finish()
		cloud._process(0.71)
		check(cloud.is_queued_for_deletion(), "Repeated finish cannot extend vapor lifetime")
		await process_frame
	var cloud = CLOUD.new()
	cloud.setup(80.0, 1.0, false)
	vfx.add_child(cloud)
	cloud.set_process(false)
	cloud._process(3.0)
	check(cloud.is_queued_for_deletion(), "Missing finish signal has bounded lifetime")
	await process_frame
	cloud = CLOUD.new()
	cloud.setup(80.0, 5.0, false)
	vfx.add_child(cloud)
	await process_frame
	paused = true
	var before: float = cloud.age
	await create_timer(0.05, true).timeout
	check(cloud.age == before, "Game pause freezes cloud motion and expiry")
	paused = false
	vfx.clear()
	await process_frame
	check(get_nodes_in_group("steam_clouds").is_empty(), "World reset removes cloud nodes")
	print("Steam cloud: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
