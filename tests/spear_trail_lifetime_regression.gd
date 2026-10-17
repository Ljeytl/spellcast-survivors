extends SceneTree

const Presenter = preload("res://scripts/vfx/VfxPresenter.gd")
const Part = preload("res://scripts/engine/SpellPart.gd")
const Cast = preload("res://scripts/engine/GenericCast.gd")
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
		printerr("FAIL: " + message)

func run():
	await process_frame
	var vfx = root.get_node("Vfx")
	vfx.set_process(false)
	for speed in [1.0, 2.0, 3.0]:
		for hz in [30, 60, 120]:
			vfx.clear()
			vfx.fx_speed = speed
			var presenter = Presenter.new(vfx)
			var part = Part.new()
			var cast = Cast.new()
			cast.plan = {"id":"ember_spear", "element":"fire"}
			part.cast = cast
			part.part_name = "trail"
			part.def = {"geometry":{"type":"line","length":600.0,"width":48.0},"timing":{"duration":3.0},"vfx":{"style":"smoulder"}}
			part.delivery = "field"
			root.add_child(part)
			presenter.part_spawned(part)
			var state: Dictionary = presenter._parts[part.get_instance_id()]
			check(state.get("smoulder", false), "Real smoulder registration selects lifecycle synchronization")
			var field: Dictionary = state.field
			field.rate = 0.0
			if OS.get_cmdline_user_args().has("known-bad"):
				state.smoulder = false
			for frame in int(hz * 2.8):
				part.age += 1.0 / hz
				presenter.step(speed / hz)
				vfx._update_fields(speed / hz)
			check(vfx._fields.has(field), "Active trail remains visible at 2.8 seconds: %.1fx %dHz" % [speed,hz])
			check(field.life - field.age > 0.5, "Active trail has not entered retirement fade")
			presenter.part_finished(part, false)
			vfx._update_fields(0.51)
			check(not vfx._fields.has(field), "Capped or expired trail retires promptly")
			part.free()
			cast.free()
	vfx.clear()
	var ordinary = vfx.field(0,0,8,3.5,{"axis":Vector2(40,0),"rate":0.0})
	vfx._update_fields(5.6)
	check(not vfx._fields.has(ordinary), "Ordinary line fields retain their existing visual clock")
	vfx.fx_speed = vfx.FX_SPEED
	print("spear_trail_lifetime_regression: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
