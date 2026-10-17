extends "res://tests/vfx_presenter_regression.gd"

func advance_field(c, seconds: float):
	c.run(seconds, DT, func(dt):
		if OS.get_cmdline_user_args().has("known-bad-clock"):
			for f in vfx._fields:
				f.erase("part")
		vfx._step(dt * vfx.fx_speed))

func footprint_count() -> int:
	vfx._render(true)
	return int(vfx._ground_layer.material.get_shader_parameter("field_count"))

func run():
	root.get_node("AudioManager").quitting = true
	vfx = root.get_node("Vfx")
	var cam = Camera2D.new()
	root.add_child(cam)
	cam.make_current()
	caster = Caster.new()
	root.add_child(caster)
	await process_frame
	await process_frame
	vfx.set_process(false)
	var info: Dictionary = preload("res://scripts/core/GameData.gd").file("spells").spells.cinder_field.duplicate(true)
	info.incantation = "cinder field"
	Defs.register(preload("res://scripts/engine/SpellTemplate.gd").build(info, 8.0, {}))
	var rubble: Dictionary = Defs.get_def("cinder_field").duplicate(true)
	rubble.id = "rubble_fixture"
	rubble.incantation = "rubble fixture"
	rubble.parts.field.vfx = {"style": "rubble"}
	rubble.parts.field.timing.duration = 2.0
	check(Defs.register(rubble).is_empty(), "Rubble lifecycle fixture is a valid periodic damaging field")
	for speed in [1.0, 2.0, 3.0]:
		vfx.fx_speed = speed
		for spell in ["cinder field", "field", "flame wall", "rubble fixture"]:
			clear()
			var target = foe(Vector2(150, 0))
			var c = cast(spell, 0.1)
			var part = c.root_parts()[0]
			target.global_position = part.global_position
			var f: Dictionary = vfx.presenter._parts[part.get_instance_id()].field
			var duration: float = part.total_life()
			advance_field(c, duration - float(part.age) - 1.3)
			var damage_before: float = target.taken()
			advance_field(c, 1.2)
			check(target.taken() > damage_before, "%s %.1fx has real late damage" % [spell, speed])
			check(not part.done and vfx._fields.has(f) and footprint_count() > 0, "%s %.1fx retains active footprint through late damage" % [spell, speed])
			check(is_equal_approx(float(f.age), float(part.age)), "Field lifecycle follows authoritative age")
			var next_def: Dictionary = part.def.duplicate(true)
			next_def.geometry.radius = 180.0
			part.extend_with(next_def, 2.0)
			advance_field(c, 1.0)
			check(vfx._fields.has(f) and footprint_count() > 0 and not part.done, "Extended field remains painted beyond original expiry")
			if part.geo_type() == "disk":
				check(is_equal_approx(float(f.r), part.geo("radius") / vfx.presenter.WPS), "Recast geometry matches active segment")
			advance_field(c, part.remaining_life() + DT)
			check(part.done and not vfx.presenter._parts.has(part.get_instance_id()), "Natural expiry retires presenter ownership")
			vfx._step(0.6)
			check(not vfx._fields.has(f) and footprint_count() == 0, "Natural expiry clears footprint after brief aftermath")
	clear()
	foe(Vector2(150, 0))
	var c = cast("cinder field", 0.1)
	var part = c.root_parts()[0]
	var f: Dictionary = vfx.presenter._parts[part.get_instance_id()].field
	part.finish(false)
	vfx._step(0.6)
	check(not vfx._fields.has(f), "Early cancellation retires the field")
	clear()
	foe(Vector2(150, 0))
	c = cast("cinder field", 0.1)
	part = c.root_parts()[0]
	f = vfx.presenter._parts[part.get_instance_id()].field
	part.free()
	vfx._step(0.6)
	check(not vfx._fields.has(f), "Freed owner cannot leave a permanent field")
	clear()
	foe(Vector2(150, 0))
	c = cast("cinder field", 0.1)
	part = c.root_parts()[0]
	f = vfx.presenter._parts[part.get_instance_id()].field
	part.done = true
	vfx._step(0.6)
	check(not vfx._fields.has(f), "Done owner retires even without presenter callback")
	clear()
	var decorative: Dictionary = vfx.field(0, 0, 8, 1.0)
	vfx._step(0.6)
	check(vfx._fields.has(decorative) and is_equal_approx(float(decorative.age), 0.6), "Decorative fields retain FX time")
	vfx._step(0.5)
	check(not vfx._fields.has(decorative), "Decorative fields expire without gameplay owners")
	clear()
	print("Field lifetime: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
