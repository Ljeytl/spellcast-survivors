extends SceneTree
## The 0.3.2 contract for new catalog spells: a spell that exists only as data (a spells.json entry
## and a spell_shapes.json shape, no code) is preparable, learnable, castable, targeted by its data
## rule, grows with rank, takes keywords and gets a rank-up card. Injected at runtime so the test
## spell never ships.

var checks = 0
var failures = 0

class Dummy extends Node2D:
	const FX = preload("res://scripts/engine/Effects.gd")
	var element = ""
	var resistances = {}
	var status = null
	var max_health = 100000.0
	var current_health = 100000.0
	var dying = false
	var taken: Array = []
	func apply_effect(effect, source = {}, origin = Vector2.INF):
		return FX.apply_to_entity(self, effect, source, origin)
	func receive_damage(amount, _origin = Vector2.INF, _source = {}):
		taken.append(float(amount))
		current_health -= amount
	func take_damage(amount, _origin = Vector2.INF, _source = {}):
		receive_damage(amount)

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var SM = load("res://scripts/SpellManager.gd")
	var ST = load("res://scripts/engine/SpellTemplate.gd")
	root.get_node("DataManager").get_all_spells()["data_probe"] = {"id": "data_probe", "name": "Data Probe", "incantation": "data probe",
		"element": "fire", "damage": 30, "preparable": true, "rank_growth": {"damage": {"per_rank": 10.0}}, "role": "Test only.",
		"unlock_condition": {"type": "default"}}
	SM.BASE_SPELL_IDS.append("data_probe")
	ST.shapes()["data_probe"] = {"root": "orb", "cast_rules": {"targeting": {"rule": "select"}}, "parts": {
		"orb": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 18.0, "pad": "hurtbox"},
			"motion": [{"type": "straight", "speed": "=650.0 * speed", "range": 900.0}], "payload": [{"$damage": ""}],
			"limits": {"pierce": 0}, "events": {"on_hit": {"part": "blast"}}},
		"blast": {"delivery": "volume", "origin": "parent", "geometry": {"type": "disk", "radius": 90.0, "pad": 0.0},
			"propagation": {"type": "instant", "linger": 0.1}, "payload": [{"$damage": "", "amount": "=damage * 2.0"}]}}}
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	var m = game.spell_manager
	m.set_process(false)
	check("data_probe" in load("res://scripts/Preparation.gd").base_ids(), "a data spell is preparable")
	check(m.spell_catalog.has("data_probe") and m.learn_spell("data_probe"), "a data spell is learnable")
	var slot = m.find_spell_slot("data_probe")
	check(slot > 0, "it takes a slot")
	var foe = Dummy.new()
	foe.position = game.player.global_position + Vector2(200, 0)
	game.add_child(foe)
	foe.add_to_group("enemies")
	check(m.cast_freeform_spell("data probe"), "it casts by its incantation (%s)" % m.last_cast_failure)
	var cast = m.last_generic_cast
	check(cast != null and cast.plan.parts.has("orb") and cast.plan.parts.has("blast"), "its parts come from its data shape")
	if cast:
		cast.manual = true
		for i in 60:
			cast.step(1.0 / 60.0)
	check(foe.taken.size() >= 2, "the orb and its blast both hit the target its rule picked (%s)" % [foe.taken])
	var base_hit = m.calculate_spell_damage(m.resolve_cast_info(slot))
	m.get_spell_info(slot).level = 4
	check(m.calculate_spell_damage(m.resolve_cast_info(slot)) > base_hit, "rank growth from data raises its damage")
	check(m.rank_change_summary("data_probe") == "+damage", "it gets a rank-up card (%s)" % m.rank_change_summary("data_probe"))
	check(m.cast_freeform_spell("big data probe"), "it takes keywords")
	var big = m.last_generic_cast
	check(big != null and float(big.plan.parts.orb.geometry.radius) > 18.0, "BIG grows its data-defined body")
	print("data_only_spell: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
