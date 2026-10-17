extends SceneTree

class Probe extends "res://scripts/vfx/VfxPresenter.gd":
	var damage_contacts := 0
	var blooms := 0
	func _life_bolt_contact(_at: Vector2, _direction: Vector2) -> void:
		damage_contacts += 1
	func _life_impact(_x: float, _y: float, _s: float) -> void:
		blooms += 1

class Part extends Node2D:
	var cast = {"plan": {"id": "life_bolt"}}
	var direction = Vector2.RIGHT
	var def = {}
	var part_name = "bolt"

var checks := 0
var failures := 0

func check(value: bool, title: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", title)

func _initialize():
	var presenter = Probe.new(null)
	var part = Part.new()
	presenter._parts[part.get_instance_id()] = {"family": "bolt", "look": {"native": "life", "accent": ""}}
	presenter._part_hit_look(part, null, Vector2.ZERO)
	check(presenter.damage_contacts == 1 and presenter.blooms == 0, "Life Bolt damage is crisp contact, no recovery bloom")
	part.cast.plan.id = "life"
	presenter._part_hit_look(part, null, Vector2.ZERO)
	check(presenter.blooms == 1, "Other life contact remains intact")
	presenter.damage_contacts = 0
	presenter.blooms = 0
	part.cast.plan.id = "life_bolt"
	if OS.get_cmdline_user_args().has("known-bad"):
		presenter._life_impact(0, 0, 1)
	else:
		presenter._part_hit_look(part, null, Vector2.ZERO)
	check(presenter.damage_contacts == 1 and presenter.blooms == 0, "Known-bad recovery bloom is rejected at damaging contact")
	part.free()
	print("LIFE_BOLT_FEEL checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
