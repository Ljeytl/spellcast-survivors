extends SceneTree

class Elements extends RefCounted:
	var lines: Array = []
	var bubbles := 0
	func line(_buf, a, b, color):
		lines.append([a, b, color])
	func bubble(_x, _y, _big):
		bubbles += 1

class Layer extends RefCounted:
	var elements = Elements.new()
	var _t := 0.0
	var _steps := 0
	var sparks := 0
	var stars: Array = []
	func star(x, y, _radius, _life, _points, _color):
		stars.append(Vector2(x, y))
	func spark(_x, _y, _vx, _vy, _life, _palette):
		sparks += 1

var checks := 0
var failures := 0

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

class Beam extends Node2D:
	var cast = {"plan":{"id":"prism_ray"}}
	var beam_end = Vector2(200, 0)
	var age := 0.5
	var def = {}
	func total_life():
		return 2.0
	func geo(_name, _default):
		return 64.0

func _initialize():
	run.call_deferred()

func run():
	var layer = Layer.new()
	var presenter = preload("res://scripts/vfx/VfxPresenter.gd").new(layer)
	var palette = presenter.BODY.fire
	var negative = OS.get_cmdline_user_args().has("known-bad")
	presenter._lasers = [[Vector2.ZERO, Vector2.RIGHT, 50.0, 2.0, 0.24, 0.32, palette, "fire", not negative]]
	presenter.draw_statuses(PackedByteArray())
	check(layer.elements.lines.size() > 0, "Renderer collected real branch lines")
	check(layer.elements.lines.all(func(line): return line[2].a < 0.5), "Prism tail fades rather than persistent full-bright afterimage")
	check(layer.elements.lines.all(func(line): return line[0].x == 0 and line[1].x == 50), "Tail retains exact ray endpoints")
	layer.elements.lines.clear()
	presenter._lasers[0][8] = false
	presenter.draw_statuses(PackedByteArray())
	check(layer.elements.lines.all(func(line): return line[2].a == 1.0), "Unrelated ray material unchanged")
	presenter._ray_flavour("plague", Vector2.ZERO, Vector2.RIGHT, 50, 2, true)
	check(layer.sparks == 4 and layer.elements.bubbles == 0, "Prism plague ray emits restrained flecks")
	presenter._ray_flavour("plague", Vector2.ZERO, Vector2.RIGHT, 50, 2, false)
	check(layer.elements.bubbles == 4, "Other plague flavour preserved")
	var beam = Beam.new()
	layer.elements.lines.clear()
	presenter._draw_beam(PackedByteArray(), beam, {"look":{"native":"arcane"}})
	var prism_lines = layer.elements.lines.duplicate()
	layer.elements.lines.clear()
	beam.cast.plan.id = "focus_ray"
	presenter._draw_beam(PackedByteArray(), beam, {"look":{"native":"arcane"}})
	check(prism_lines.size() == layer.elements.lines.size(), "Prism retains full beam width")
	for i in prism_lines.size():
		check(prism_lines[i][0] == layer.elements.lines[i][0] and prism_lines[i][1] == layer.elements.lines[i][1], "Prism retains primary endpoints")
	check(prism_lines.any(func(line): return line[2].a < 0.9), "Prism primary material translucent")
	check(layer.elements.lines.all(func(line): return line[2].a == 1.0), "Focus primary material untouched")
	layer.elements.lines.clear()
	presenter._lasers[0][7] = "lightning"
	presenter._lasers[0][8] = true
	presenter.draw_statuses(PackedByteArray())
	check(layer.elements.lines.size() == 1 and layer.elements.lines[0][2].a < 0.5, "Storm ray core follows same afterimage fade")
	presenter._advance_transients(0.09)
	check(presenter._lasers.is_empty(), "Ray tail expires at existing lifetime")
	presenter._lasers.append([Vector2.ZERO, Vector2.RIGHT, 50.0, 2.0, 0.0, 0.32, palette, "fire", true])
	presenter.clear_transients()
	check(presenter._lasers.is_empty(), "Clear retires refraction tails")
	beam.cast.plan.id = "prism_ray"
	beam.def = {"vfx":{"family":"ray","look":"fire"}}
	var enemy = Node2D.new()
	presenter.part_hit(beam, enemy, Vector2(60, 80))
	presenter.part_hit(beam, enemy, Vector2(65, 85))
	check(layer.stars.size() == 1 and layer.stars[0].is_equal_approx(Vector2(60,80) / presenter.WPS), "Real ray hit glints at actual contact, one per target per frame")
	presenter._prism_contact_frame = -1
	presenter.part_hit(beam, enemy, Vector2(70, 90))
	check(layer.stars.size() == 2, "Later contact frame can punctuate again")
	beam.cast.plan.id = "focus_ray"
	presenter.part_hit(beam, enemy, Vector2.ZERO)
	check(layer.stars.size() == 2, "Other spell hits do not add Prism glints")
	presenter.clear_transients()
	check(presenter._prism_contacts.is_empty(), "Clear retires contact throttle IDs")
	enemy.free()
	beam.free()
	print("PRISM_RAY_FEEL checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
