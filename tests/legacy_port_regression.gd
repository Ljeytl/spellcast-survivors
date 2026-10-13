extends SceneTree
## Doc 18 phase 2: shipping spells ported to the generic engine keep their numbers and gain keywords.
## Grows by one block per ported spell.

const Effects = preload("res://scripts/engine/Effects.gd")
const SpellDamage = preload("res://scripts/engine/SpellDamage.gd")

var checks = 0
var failures = 0

class Dummy extends Node2D:
	var element = ""
	var resistances = {}
	var status = null
	var current_health = 100000.0
	var dying = false
	var taken: Array = []
	func apply_effect(effect, source = {}, origin = Vector2.INF):
		return Effects.apply_to_entity(self, effect, source, origin)
	func receive_damage(amount, _origin = Vector2.INF, _source = {}):
		taken.append(float(amount))
		current_health -= amount
	func take_damage(amount, _origin = Vector2.INF, _source = {}):
		receive_damage(amount)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func casts_of(game, id) -> Array:
	return game.get_children().filter(func(n): return n.get("plan") is Dictionary and str(n.plan.get("id", "")) == id and not n.is_queued_for_deletion())

func dummy(game, at: Vector2, element := "", resist := {}) -> Dummy:
	var d = Dummy.new()
	d.position = at
	d.element = element
	d.resistances = resist
	game.add_child(d)
	d.add_to_group("enemies")
	return d

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	var manager = game.spell_manager
	manager.set_process(false)
	var start = game.player.global_position

	# --- Ember Spear -------------------------------------------------------------------------
	manager.learn_spell("ember_spear")
	var slot = manager.find_spell_slot("ember_spear")
	var water = dummy(game, start + Vector2(160, 0), "water", {"raw": 0.3})
	manager.cast_freeform_spell("ember spear")
	var cast = casts_of(game, "ember_spear").back()
	cast.manual = true
	cast.step(1.0 / 60.0)
	check(cast.parts.any(func(p): return p.part_name == "spear"), "Ember Spear runs on the generic engine")
	var guard = 0
	while water.taken.is_empty() and guard < 60:
		cast.step(1.0 / 60.0)
		guard += 1
	var burning_on_contact = water.status != null and water.status.has("burn")
	cast.run(0.4)
	var amount = manager.calculate_spell_damage(manager.spells[slot])
	var legacy = Effects.resolve_damage(water, SpellDamage.effect(amount, "ember_spear"))[0]
	check(not water.taken.is_empty() and is_equal_approx(water.taken[0], legacy), "Spear hit matches the old typed hit (%s vs %s)" % [water.taken[0] if not water.taken.is_empty() else -1, legacy])
	check(not burning_on_contact, "The spear itself does not burn")
	check(water.status != null and water.status.has("burn"), "Its trail burns")
	cast.run(3.5)
	for n in [water]:
		n.queue_free()
	await process_frame
	# Keywords now work on a shipping spell.
	check(manager.cast_keyword_spell("double ember spear"), "DOUBLE casts on Ember Spear")
	var twin = casts_of(game, "ember_spear").back()
	check(int(twin.plan.arrangement.count) == 2, "DOUBLE throws two spears")
	check(manager.cast_keyword_spell("fiery homing ember spear"), "Element and motion words cast on Ember Spear")
	check(manager.last_cracked.is_empty(), "No word cracks on a damaging projectile")
	print("legacy_port_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
