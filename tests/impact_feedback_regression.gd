extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ", label)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var camera := Camera2D.new()
	root.add_child(camera)
	var shake = preload("res://scripts/CameraShake.gd").new()
	shake.camera = camera
	root.add_child(shake)
	shake.set_process(false)
	shake.reduced_effects = false
	var vfx = root.get_node("Vfx")
	vfx.reduced_effects = false
	vfx.shake(0.0)
	check(shake.shake_timer == 0.0, "Zero strength does not shake")
	vfx.shake(0.2)
	check(is_equal_approx(shake.shake_intensity, 2.0), "Small impacts use requested strength")
	shake.shake_timer = 0.0
	vfx.shake(0.4)
	check(is_equal_approx(shake.shake_intensity, 4.0), "Medium impacts differ from small hits")
	vfx.shake(1.0)
	check(is_equal_approx(shake.shake_intensity, 11.0) and is_equal_approx(shake.shake_duration, 0.26), "Approved heavy impact parameters preserved")
	vfx.shake(0.2)
	check(is_equal_approx(shake.shake_intensity, 11.0), "Small hit cannot erase heavy impact")
	shake._process(0.3)
	check(camera.offset == Vector2.ZERO, "Shake settles to zero")
	vfx.reduced_effects = true
	vfx.shake(1.0)
	check(shake.shake_timer == 0.0, "Reduced effects suppress shake")
	var lights = vfx.impact_light
	lights.set_process(false)
	lights.emit(Vector2(20, 20), 50, Color.CYAN, 0.1)
	check(lights.pulses.is_empty(), "Reduced effects suppress local light")
	vfx.reduced_effects = false
	vfx.presenter.enabled = true
	vfx._active = true
	lights.emit(Vector2(20, 20), 50, Color.CYAN, 0.1)
	check(lights.pulses.size() == 1 and lights.pulses[0].at == Vector2(20, 20), "Light uses actual world hit position")
	lights.emit(Vector2(21, 21), 50, Color.CYAN, 0.1)
	check(lights.pulses.size() == 1, "Simultaneous nearby shard impacts coalesce")
	for i in 40:
		lights.emit(Vector2(100 + i * 30, 0), 1000, Color.CYAN, 10)
	check(lights.pulses.size() == 24, "Light pool is bounded")
	check(lights.pulses[-1].radius == 140.0 and lights.pulses[-1].strength <= 0.18, "Radius and brightness are bounded")
	lights._process(0.19)
	check(lights.pulses.is_empty(), "Light expires without residue")
	lights.emit(Vector2.ZERO, 50, Color.CYAN, 0.1)
	vfx.clear()
	check(lights.pulses.is_empty(), "World reset clears lighting")
	lights.emit(Vector2.ZERO, 50, Color.CYAN, 0.1)
	vfx.reduced_effects = true
	lights._process(0.01)
	check(lights.pulses.is_empty(), "Enabling reduced effects clears active pulses")
	vfx.reduced_effects = false
	lights.emit(Vector2.ZERO, 50, Color.CYAN, 0.1)
	vfx.presenter.enabled = false
	lights._process(0.01)
	check(lights.pulses.is_empty(), "Disabling presentation clears active pulses")
	vfx.presenter.enabled = true
	lights.emit(Vector2.ZERO, 50, Color.CYAN, 0.1)
	lights.set_process(true)
	paused = true
	await process_frame
	await process_frame
	check(lights.pulses.size() == 1 and lights.pulses[0].age == 0.0, "World pause freezes pulse age")
	paused = false
	lights.set_process(false)
	for id in ["lightning", "meteor_shower", "seeker", "mana_bolt"]:
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/spells/" + id + ".json"))
		for part in data.shape.parts.values():
			check(float(part.get("vfx", {}).get("impact_light", 0)) == 0.0, id + " is not opted into new lighting")
	print("IMPACT_FEEDBACK: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
