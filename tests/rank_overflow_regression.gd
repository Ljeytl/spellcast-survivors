extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		printerr("Use the isolated Synergy Test profile")
		quit(2)
		return
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	var manager = game.spell_manager
	var Progression = preload("res://scripts/SpellProgression.gd")
	for i in 10:
		manager.upgrade_spell("bolt")
	check(manager.get_spell_rank("bolt") == 8, "Ranks stop at 8 while slots are empty")
	check(not manager.can_rank_up("bolt"), "Rank 9 is locked before every slot is filled")
	for id in ["life", "ice_blast", "lightning", "cinder_field", "infestation"]:
		manager.learn_spell(id)
	check(manager.spells.size() == manager.MAX_EQUIPPED_SPELLS, "Fixture fills every slot")
	check(not manager.overflow_unlocked(), "Filled slots alone do not unlock overflow")
	for info in manager.spells.values():
		while manager.get_spell_rank(info.id) < 8:
			manager.upgrade_spell(info.id)
	check(manager.overflow_unlocked(), "Every slot filled at rank 8 unlocks overflow")
	var DS = load("res://scripts/DamageSource.gd")
	# Casting records which passive properties each spell reads; those become its cards.
	for words in ["bolt", "cinder field", "life", "infection"]:
		manager.cast_freeform_spell(words)
		await process_frame
	check(manager.spell_properties("cinder_field").has("power") and manager.spell_properties("cinder_field").has("size"), "Cinder Field reads Spell Power and Spell Size")
	check(manager.spell_properties("life").has("power"), "Life reads Spell Power for healing")
	check(manager.spell_properties("never_cast") == ["power"], "An uncast spell falls back to Power")
	var screen = game.level_up_screen
	screen.generate_upgrade_options({}, 20)
	var keys = screen.current_upgrade_pool.map(func(card): return str(card.get("key", ""))).filter(func(key): return key.begins_with("rank:"))
	check(keys.size() > 0 and keys.all(func(key): return key.count(":") == 2), "Past rank 8 every rank card names a property")
	for property in manager.spell_properties("cinder_field"):
		check(("rank:cinder_field:" + property) in keys, "Cinder Field offers " + property)
	check(not keys.any(func(key): return key.ends_with(":count")), "Counts are never offered")
	var bolt = manager.spells[manager.find_spell_slot("bolt")]
	DS.current = DS.make("bolt", 0.0)
	var power8 = manager.cast_stat("spell_damage_multiplier")
	var damage8 = manager.calculate_spell_damage(bolt)
	var size8 = manager.cast_stat("spell_size_multiplier")
	DS.current = {}
	game.change_state(game.GameState.PLAYING)
	game._on_upgrade_selected({"name": "Bolt · Spell Power", "description": "+10% Spell Power for this spell (now +0%)", "effect": {"type": "spell_upgrade", "spell": "bolt", "stat": "power"}})
	check(manager.get_spell_rank("bolt") == 9 and int(bolt.get("overflow", {}).get("power", 0)) == 1, "Choosing a property card ranks up and records the pick")
	DS.current = DS.make("bolt", 0.0)
	check(is_equal_approx(manager.cast_stat("spell_damage_multiplier"), power8 * 1.1), "A Power pick raises that spell's Spell Power by ten percent")
	check(is_equal_approx(manager.calculate_spell_damage(bolt), damage8 * 1.1), "Bolt damage follows its Spell Power")
	check(is_equal_approx(manager.cast_stat("spell_size_multiplier"), size8), "A Power pick leaves Spell Size alone")
	DS.current = DS.make("cinder_field", 0.0)
	check(is_equal_approx(manager.cast_stat("spell_damage_multiplier"), power8), "Picks stay with their own spell")
	DS.current = {}
	check(is_equal_approx(manager.cast_stat("spell_damage_multiplier"), power8), "Outside a cast the passive is unchanged")
	var life = manager.spells[manager.find_spell_slot("life")]
	manager.upgrade_spell("life")
	Progression.add_overflow(life, "power")
	game.player.health = 10.0
	manager.cast_freeform_spell("life")
	await process_frame
	var healed_with = game.player.health
	check(healed_with > 10.0, "Life still heals with a Power pick")
	var cinder = manager.spells[manager.find_spell_slot("cinder_field")]
	var radius8 = float(Progression.resolve(cinder).radius)
	manager.upgrade_spell("cinder_field")
	check(is_equal_approx(float(Progression.resolve(cinder).radius), radius8), "Rank data stops growing past rank 8")
	# A Size pick widens the field the spell actually places.
	var Geometry = load("res://scripts/SpellGeometry.gd")
	DS.current = DS.make("cinder_field", 0.0)
	var placed8 = float(Geometry.scaled_data(Progression.resolve(cinder), game.player).radius)
	Progression.add_overflow(cinder, "size")
	check(is_equal_approx(float(Geometry.scaled_data(Progression.resolve(cinder), game.player).radius), placed8 * 1.1), "A Size pick widens the placed field by ten percent")
	DS.current = {}
	game.free()
	await process_frame
	print("Rank overflow: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
