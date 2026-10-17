extends SceneTree

class Layer extends RefCounted:
	var stars: Array = []
	var sparks: Array = []
	func star(x, y, radius, _life, _points, _color):
		stars.append([Vector2(x, y), radius])
	func spark(x, y, _vx, _vy, _life, _palette):
		sparks.append(Vector2(x, y))

class Beam extends Node2D:
	var cast = {"plan":{"id":"focus_ray"}}
	var beam_end = Vector2(200, 0)
	var def = {"delivery":"beam"}

var checks := 0
var failures := 0

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func _initialize():
	var layer = Layer.new()
	var presenter = preload("res://scripts/vfx/VfxPresenter.gd").new(layer)
	var beam = Beam.new()
	beam.position = Vector2(40, 80)
	var enemy = Node2D.new()
	var state = {"kind":"beam", "look":{"native":"arcane"}}
	presenter._parts[beam.get_instance_id()] = state
	presenter.part_hit(beam, enemy, Vector2(260, 80))
	check(layer.stars.size() == 1 and layer.sparks.size() == 2, "One real tick produces one small glint and two flecks")
	var terminal = (beam.position + beam.beam_end) / presenter.WPS
	check(not layer.stars.is_empty() and layer.stars[0][0] == terminal, "Contact sits at visible terminal, not victim center")
	check(layer.sparks.all(func(at): return at == terminal), "Flecks originate at actual beam termination")
	layer.stars.clear()
	layer.sparks.clear()
	if OS.get_cmdline_user_args().has("known-bad"):
		beam.cast.plan.id = "other_ray"
	presenter._beam_step(beam, state, beam.position / presenter.WPS, 1.0)
	check(layer.stars.is_empty() and layer.sparks.is_empty(), "Empty-lane presentation cannot fabricate contact sparks")
	beam.cast.plan.id = "focus_ray"
	presenter.part_hit(beam, enemy, Vector2.ZERO)
	check(layer.stars.size() == 1, "Next real tick remains eligible")
	layer.stars.clear()
	beam.cast.plan.id = "prism_ray"
	presenter.part_hit(beam, enemy, Vector2.ZERO)
	check(layer.stars.is_empty(), "Primary Prism beam does not receive Focus contact")
	beam.cast.plan.id = "focus_ray"
	beam.def.delivery = "volume"
	presenter.part_hit(beam, enemy, Vector2.ZERO)
	check(layer.stars.is_empty(), "Other delivery cannot receive Focus contact")
	beam.def.delivery = "beam"
	beam.cast.target_group = "player"
	presenter.part_hit(beam, enemy, Vector2.ZERO)
	check(layer.stars.is_empty(), "Hostile reuse does not receive player Focus glints")
	layer.sparks.clear()
	presenter._beam_step(beam, state, beam.position / presenter.WPS, 1.0)
	check(layer.sparks.size() == 1, "Hostile beam presentation retains its original sparks")
	beam.free()
	enemy.free()
	print("FOCUS_RAY_FEEL checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
