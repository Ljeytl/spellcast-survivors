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
	# QUICK works on shipping spells: initials, or word starts when initials are shared.
	var before_quick = casts_of(game, "ember_spear").size()
	check(manager.cast_keyword_spell("quick em s"), "QUICK casts Ember Spear by word starts (" + manager.last_cast_failure + ")")
	check(casts_of(game, "ember_spear").size() == before_quick + 1, "QUICK threw a spear")
	check(not manager.parse_incantation("quick es").ok or manager.parse_incantation("quick es").spell == "ember spear", "Shared initials need more letters or pick the one unlocked")
	var spear_slot = manager.find_spell_slot("ember_spear")
	var before_num = casts_of(game, "ember_spear").size()
	check(manager.cast_keyword_spell("quick %d" % spear_slot), "QUICK + slot number casts that slot (" + manager.last_cast_failure + ")")
	check(casts_of(game, "ember_spear").size() == before_num + 1, "QUICK %d threw a spear" % spear_slot)
	check(not manager.parse_incantation("quick 9").ok, "QUICK on an empty slot fails")

	# --- Bolt, Ice Blast, Life, Lightning, Rune Trap ------------------------------------------
	root.size = Vector2i(1280, 720)
	await process_frame
	for id in ["ice_blast", "life", "lightning", "rune_trap"]:
		manager.learn_spell(id)
	var foe = dummy(game, start + Vector2(140, 0))
	for text in ["bolt", "ice blast", "lightning", "rune trap", "life"]:
		check(manager.cast_freeform_spell(text), text + " casts")
		var c = manager.last_generic_cast
		check(c != null and str(c.plan.id) == text.replace(" ", "_"), text + " runs on the generic engine")
		check(manager.cast_keyword_spell("fiery " + text) or text == "life", "fiery " + text + " casts (" + manager.last_cast_failure + ")")
	var bolt_slot = manager.find_spell_slot("bolt")
	manager.cast_freeform_spell("bolt")
	var bolt_cast = manager.last_generic_cast
	check(is_equal_approx(float(bolt_cast.plan.parts.bolt.payload[0].hit), manager.calculate_spell_damage(manager.spells[bolt_slot])), "Bolt keeps its damage")
	game.player.health = 10.0
	var life_slot = manager.find_spell_slot("life")
	manager.cast_spell_by_type(life_slot)
	check(game.player.health > 10.0, "Life heals at once")

	# --- Meteor Shower -------------------------------------------------------------------------
	# Six slots are full: Meteor Shower takes Rune Trap's.
	var meteor_slot = manager.find_spell_slot("rune_trap")
	manager.spells[meteor_slot] = manager.spell_catalog["meteor_shower"].duplicate(true)
	manager.spells[meteor_slot].level = 1
	manager.acquired_spells["meteor_shower"] = true
	foe.queue_free()
	await process_frame
	var crowd = [dummy(game, start + Vector2(160, 40)), dummy(game, start + Vector2(260, -40))]
	check(manager.cast_freeform_spell("meteor shower"), "Meteor Shower casts")
	var shower = manager.last_generic_cast
	shower.manual = true
	var marks = shower.root_parts()
	check(marks.size() == 3, "All three marks show at once")
	check(marks.all(func(m): return crowd.any(func(c): return c.global_position == m.global_position)), "Marks sit on enemies")
	var before_land = crowd.map(func(c): return c.current_health)
	shower.run(0.6)
	check(crowd.map(func(c): return c.current_health) == before_land, "Nothing lands before the warning")
	shower.run(1.0)
	check(crowd.all(func(c): return c.current_health < 100000.0), "Meteors land on the marks")
	print("legacy_port_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
