extends SceneTree

class Probe extends "res://scripts/vfx/VfxPresenter.gd":
	var damage_contacts := 0
	var blooms := 0
	var bursts: Array = []
	func prop_burst(kind: String, at: Vector2, _size: float = 1.0) -> void:
		bursts.append({"kind": kind, "at": at})
	func _life_bolt_contact(_at: Vector2, _direction: Vector2) -> void:
		damage_contacts += 1
	func _life_impact(_x: float, _y: float, _s: float) -> void:
		blooms += 1

class Recipient extends Node2D:
	var health := 30.0
	var max_health := 100.0
	var recovery := 0.0
	func start_healing_over_time(amount: float, _duration: float):
		recovery += amount

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
	run.call_deferred()

func run():
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
	var generic = preload("res://scripts/engine/GenericCast.gd").new()
	generic.world = root
	generic.caster = part
	for id in ["life_bolt", "soul_bloom", ""]:
		generic.plan = {"id": id}
		generic.spawn_seed(Vector2.ZERO, {"amount": 7.0, "duration": 3.0, "lifetime": 11.0, "radius": 35.0, "cap": 4})
		var pickup = get_nodes_in_group("healing_seeds").back()
		check(pickup.healing_amount == 7.0 and pickup.healing_duration == 3.0 and pickup.remaining == 11.0 and pickup.radius == 35.0 and pickup.cap == 4, "Presentation preserves seed payload " + id)
		check(pickup.presentation_source == id, "Seed preserves exact source tag " + id)
		var kind = root.get_node("Vfx").presenter._props[pickup.get_instance_id()].kind
		check(kind == ("life_bolt_seed" if id == "life_bolt" else "seed"), "Only Life Bolt uses refined recovery prop " + id)
		pickup.free()
	var layer = root.get_node("Vfx")
	var original = layer.presenter
	var active = layer._active
	layer.presenter = presenter
	layer._active = true
	var recipient = Recipient.new()
	root.add_child(recipient)
	recipient.position = Vector2(20, 0)
	for id in ["life_bolt", "soul_bloom", ""]:
		var pickup = preload("res://scripts/HealingSeed.gd").new()
		pickup.presentation_source = id
		pickup.player_ref = weakref(recipient)
		root.add_child(pickup)
		pickup._physics_process(0.0)
		check(pickup.collected, "Source-tagged seed still collects " + id)
		check(presenter.bursts.back().kind == ("life_bolt_seed" if id == "life_bolt" else "seed"), "Pickup event remains source-isolated " + id)
		check(presenter.bursts.back().at == (recipient.position if id == "life_bolt" else pickup.position), "Life Bolt intake is at recipient; other seeds unchanged " + id)
	check(recipient.recovery == 18.0, "Pickup recovery budget unchanged")
	recipient.free()
	layer.presenter = original
	layer._active = active
	generic.free()
	part.free()
	print("LIFE_BOLT_FEEL checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
