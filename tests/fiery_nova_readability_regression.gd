extends "res://tests/vfx_presenter_regression.gd"

func run():
	root.get_node("AudioManager").quitting = true
	vfx = root.get_node("Vfx")
	var camera = Camera2D.new()
	root.add_child(camera)
	camera.make_current()
	caster = Caster.new()
	root.add_child(caster)
	await process_frame
	await process_frame
	for variant in ["friendly", "hostile", "other_nova"]:
		clear()
		seed(73)
		var parsed = KP.parse("large fiery nova", Defs.by_incantation().keys())
		var plan = Planner.plan(Defs.get_def("nova"), parsed.bundle, {})
		if variant == "other_nova":
			plan.id = "other_nova"
		var c = GenericCast.new()
		root.add_child(c)
		c.setup(plan, caster, root, {}, true, 73)
		if variant == "hostile":
			c.target_group = "player"
		c.run(0.12, DT, tick_all)
		check(vfx._f_count > 0, variant + " collects actual flame particles")
		var small = 0
		for i in vfx._f_count:
			var offset = i * vfx.FS
			if vfx._fd[offset + vfx.SMALL] == 1.0:
				small += 1
			if variant == "friendly":
				check(vfx._fd[offset + vfx.LIFE] <= 0.28, "FIERY tongue cools within 0.28s")
		check(small == vfx._f_count if variant == "friendly" else small == 0, variant + " routes only intended material")
	clear()
	seed(73)
	vfx.presenter._fire_nova(Vector2.ZERO, 30.0, 0.4, DT)
	check(vfx._f_count > 0, "Native fire control collects particles")
	var violates_clearance = false
	for i in vfx._f_count:
		var offset = i * vfx.FS
		check(vfx._fd[offset + vfx.SMALL] == 0.0, "Native fire retains full flame disk")
		check(is_equal_approx(vfx._fd[offset + vfx.HEAT], 1.23), "Native fire retains baseline heat")
		violates_clearance = violates_clearance or vfx._fd[offset + vfx.LIFE] > 0.28
	check(violates_clearance, "CONTROL full native recipe violates FIERY short aftermath")
	for text in ["nova", "fiery nova", "large fiery nova", "icy nova"]:
		var visible = damage_profile(text, true)
		var silent = damage_profile(text, false)
		check(visible.max() > 0.0, text + " damage profile contains actual contact")
		check(visible == silent, text + " presentation preserves damage")
	print("FIERY Nova readability: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
