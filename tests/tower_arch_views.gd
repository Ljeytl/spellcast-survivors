extends SceneTree

const ARCH = preload("res://scripts/TowerArch.gd")
var checks = 0
var failures = 0
var fixtures: Array[Node2D] = []
var output = "res://builds/arch-evidence"

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func capture(name):
	if DisplayServer.get_name() == "headless":
		check(false, "Native renderer required for visual evidence")
		return
	await RenderingServer.frame_post_draw
	var result = root.get_texture().get_image().save_png(output + "/" + name + ".png")
	check(result == OK and FileAccess.file_exists(output + "/" + name + ".png"), "Saved native evidence: " + name)

func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.get_node("AudioManager").quitting = true
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(5000,5000)
	root.size = Vector2i(1440,1000)
	root.content_scale_size = Vector2i(1440,1000)
	RenderingServer.set_default_clear_color(Color("242633"))
	var sheet = Node2D.new()
	root.add_child(sheet)
	for index in 12:
		var phase = index * TAU / 12
		var arch = ARCH.new()
		arch.woodland = true
		arch.phase = phase
		arch.position = Vector2(180 + (index % 4) * 360, 200 + (index / 4) * 300)
		sheet.add_child(arch)
		fixtures.append(arch)
		var label = Label.new()
		label.text = "%d o'clock | inward %d deg" % [12 if index == 0 else index, posmod(270 - 30 * index,360)]
		label.position = arch.position + Vector2(-135,50)
		label.add_theme_font_size_override("font_size",20)
		sheet.add_child(label)
		var arrow = Line2D.new()
		arrow.width = 3
		arrow.default_color = Color("53ccd9")
		var origin = arch.position + Vector2(0,25)
		var inward = ARCH.ground(ARCH.inward(phase)).normalized()
		var end = origin + inward * 27
		arrow.points = PackedVector2Array([origin,end,end-inward.rotated(0.6)*9,end,end-inward.rotated(-0.6)*9])
		sheet.add_child(arrow)
		var radial = Vector2(sin(phase),-cos(phase))
		check(ARCH.inward(phase).dot(radial) < -0.999, "Slot %d inward normal" % index)
		check(ARCH.inward(phase).distance_to(-radial) < 0.001, "Slot %d exact antipodal" % index)
		check(arch.face_transform(0).x.distance_to(ARCH.ground(Vector2(cos(phase), sin(phase)))) < 0.001, "Draw face uses inward tangent basis %d" % index)
		var tangent = arch.project(Vector2(85,0),0)-arch.project(Vector2(-85,0),0)
		check(tangent.distance_to(ARCH.ground(Vector2(cos(phase),sin(phase))*170)) < 0.001,"Slot %d ground tangent" % index)
		check(absf(arch.project(Vector2(0,-100),0).y + 100) < 0.001,"Slot %d upright elevation" % index)
		if index not in [0,6]:
			check(ARCH.inward(-phase).distance_to(-radial) > 0.01,"Mirrored known-bad orientation rejected %d" % index)
		check(ARCH.inward(phase+PI).distance_to(-radial) > 1.9,"Outward known-bad orientation rejected %d" % index)
	await create_timer(3.0).timeout
	await capture("clock-contact-sheet")
	if DisplayServer.get_name() != "headless":
		var correct = root.get_texture().get_image()
		for arch in fixtures:
			arch.set_phase(-arch.phase)
		check(fixtures[1].face_transform(0).x.distance_to(ARCH.ground(Vector2(cos(TAU/12),sin(TAU/12)))) > 0.1, "Actual mirrored draw basis fails orientation invariant")
		await create_timer(0.3).timeout
		await capture("known-bad-mirrored-control")
		var wrong = root.get_texture().get_image()
		var changed = 0
		for y in range(0, correct.get_height(), 3):
			for x in range(0, correct.get_width(), 3):
				if correct.get_pixel(x,y) != wrong.get_pixel(x,y): changed += 1
		check(changed > 1000, "Native render distinguishes mirrored control (%d changed samples)" % changed)
	sheet.queue_free()
	await process_frame
	root.get_node("SceneManager").goto_scene("res://scenes/Tower.tscn")
	await create_timer(0.5).timeout
	var tower = current_scene
	tower.set_physics_process(false)
	await capture("tower-settled")
	tower.angle = TAU / 24
	tower.target_angle = tower.angle
	tower.update_ring()
	await create_timer(0.3).timeout
	await capture("tower-midpoint")
	for index in 12:
		var phase = index * TAU / 12 + tower.angle
		var arch = tower.arches[index].get_node("Arch")
		check(is_equal_approx(arch.phase,phase), "Actual ring phase applied %d" % index)
		check(arch.inward(phase).dot((tower.arches[index].position/tower.RADIUS).normalized()) < -0.999, "Midpoint remains inward %d" % index)
	await create_timer(3.0).timeout
	var start = Time.get_ticks_usec()
	var frames = 0
	while Time.get_ticks_usec() - start < 3000000:
		await process_frame
		frames += 1
	print("PERF idle frames/sec: ", frames / 3.0)
	start = Time.get_ticks_usec()
	frames = 0
	var update_us = 0
	while Time.get_ticks_usec() - start < 3000000:
		await process_frame
		tower.angle += 0.01
		var update_start = Time.get_ticks_usec()
		tower.update_ring()
		update_us += Time.get_ticks_usec() - update_start
		frames += 1
	print("PERF rotating frames/sec: ", frames / 3.0, " update_ring avg us: ", float(update_us)/maxi(frames,1))
	print("TOWER_ARCH_VIEWS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
