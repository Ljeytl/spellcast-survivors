extends "res://tests/vfx_presenter_regression.gd"

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
	for spell in ["cinder field", "field", "flame wall"]:
		clear()
		foe(Vector2(150, 0))
		var c = cast(spell, 0.1)
		var part = c.root_parts()[0]
		var field: Dictionary = vfx.presenter._parts[part.get_instance_id()].field
		if OS.get_cmdline_user_args().has("known-bad-profile"):
			field.profile = "cinder"
		vfx._render(true)
		var material = vfx._ground_layer.material
		var axes: PackedVector4Array = material.get_shader_parameter("field_axis")
		var cooling: PackedFloat32Array = material.get_shader_parameter("field_cooling")
		check(is_equal_approx(axes[0].w, 3.0) == (spell == "cinder field"), "%s isolates coal material to Cinder" % spell)
		check(cooling[0] < 0.1, "%s starts hot" % spell)
		var early_cooling = cooling[0]
		c.run(part.total_life() * 0.8, DT, func(dt): vfx._step(dt * vfx.fx_speed))
		vfx._render(true)
		cooling = material.get_shader_parameter("field_cooling")
		check(cooling[0] > 0.75 and cooling[0] < 1.0 and cooling[0] > early_cooling, "%s cooling follows living field age" % spell)
		check(not part.done and vfx._fields.has(field), "%s remains active while cooling" % spell)
	clear()
	caster.free()
	cam.queue_free()
	print("Cinder material: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
