extends "res://tests/vfx_presenter_regression.gd"

func run():
	root.get_node("AudioManager").quitting = true
	vfx = root.get_node("Vfx")
	var camera = Camera2D.new()
	root.add_child(camera)
	camera.make_current()
	await process_frame
	await process_frame
	caster = Caster.new()
	root.add_child(caster)
	for text in ["slash", "large slash", "fiery slash"]:
		for reduced in [false, true]:
			clear()
			vfx.reduced_effects = reduced
			var parsed = KP.parse(text, Defs.by_incantation().keys())
			var plan = Planner.plan(Defs.get_def("slash"), parsed.bundle, {})
			var radius = float(plan.parts.cut.geometry.radius)
			var angle = deg_to_rad(float(plan.parts.cut.geometry.angle)) * 0.5
			var nearest = foe(Vector2(40, 0))
			var boundary = foe(Vector2(radius + 13.9, 0))
			var outside = foe(Vector2(radius + 14.1, 0))
			var side = foe(Vector2.from_angle(angle + 0.02) * 80.0)
			var behind = foe(Vector2(-80, 0))
			var c = cast(text, DT)
			check(nearest.taken() > 0 and boundary.taken() > 0, text + " immediate inside and padded-boundary damage")
			check(outside.taken() == 0 and side.taken() == 0 and behind.taken() == 0, text + " radius angle and behind remain unharmed")
			var damage = nearest.taken()
			check(not vfx.elements.slashes.is_empty(), text + " visual sweep remains after instant damage")
			c.run(0.5, DT, tick_all)
			check(nearest.taken() == damage, text + " visual linger never deals extra damage")
			for i in 90:
				tick_all(DT)
			check(vfx.elements.slashes.is_empty(), text + " sweep naturally retires")
	clear()
	var def = Defs.get_def("slash").duplicate(true)
	def.parts.cut.geometry.radius = 200.0
	var outside = foe(Vector2(160, 0))
	var bad = GenericCast.new()
	root.add_child(bad)
	bad.setup(Planner.plan(def, {}, {}), caster, root, {}, true, 1)
	bad.run(DT, DT, tick_all)
	check(outside.taken() > 0, "CONTROL enlarged radius violates native miss invariant")
	clear()
	def = Defs.get_def("slash").duplicate(true)
	def.parts.cut.propagation = {"type": "expanding", "speed": 20.0}
	var inside = foe(Vector2(80, 0))
	bad = GenericCast.new()
	root.add_child(bad)
	bad.setup(Planner.plan(def, {}, {}), caster, root, {}, true, 1)
	bad.run(DT, DT, tick_all)
	check(inside.taken() == 0, "CONTROL delayed front violates instant damage invariant")
	clear()
	var probe_cast = GenericCast.new()
	var probe = GenericCast.SpellPart.new()
	probe_cast.plan = {"id": "slash"}
	probe.cast = probe_cast
	probe.def = {"geometry": {"radius": 120.0, "angle": 100.0}}
	for target_group in ["enemies", "player"]:
		probe_cast.target_group = target_group
		vfx.presenter._slash(probe, {"native": "arcane", "accent": ""}, Vector2.ZERO)
		check(vfx.elements.slashes.back().sharp == (target_group == "enemies"), "Sharp refinement is friendly bare Slash only")
	probe_cast.plan.id = "other_cone"
	probe_cast.target_group = "enemies"
	vfx.presenter._slash(probe, {"native": "arcane", "accent": ""}, Vector2.ZERO)
	check(not vfx.elements.slashes.back().sharp, "Other cone effects retain their original material")
	probe.free()
	probe_cast.free()
	clear()
	vfx._origin = Vector2i.ZERO
	vfx._size = Vector2i(96, 96)
	var sample = {"cx": 48.0 / vfx.K, "cy": 48.0 / vfx.K, "rout": 32.0 / vfx.K, "rin": 9.6 / vfx.K, "a0": -0.87, "span": 1.74, "dir": 1, "t": 0.12, "dur": 0.13, "linger": 0.14, "cols": vfx.presenter.SMEAR.arcane, "sharp": true}
	for sharp in [true, false]:
		sample.sharp = sharp
		var pixels = PackedByteArray()
		pixels.resize(96 * 96 * 4)
		vfx.elements._draw_slash(pixels, sample)
		var inner_pixels = 0
		var visible_pixels = 0
		for y in 96:
			for x in 96:
				if pixels[(y * 96 + x) * 4 + 3] > 0:
					visible_pixels += 1
					if Vector2(x - 48, y - 48).length() < 21:
						inner_pixels += 1
		check(visible_pixels > 0, "Raster sweep has visible nonzero material")
		check(inner_pixels == 0 if sharp else inner_pixels > 0, "Thin edge keeps inner cone clear" if sharp else "CONTROL old filled wedge violates clear inner cone")
	print("Slash feel: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
