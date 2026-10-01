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
	for id in ["life", "ice_blast", "lightning_arc", "cinder_field", "plague_seed"]:
		manager.learn_spell(id)
	check(manager.spells.size() == manager.MAX_EQUIPPED_SPELLS, "Fixture fills every slot")
	check(not manager.overflow_unlocked(), "Filled slots alone do not unlock overflow")
	for info in manager.spells.values():
		while manager.get_spell_rank(info.id) < 8:
			manager.upgrade_spell(info.id)
	check(manager.overflow_unlocked(), "Every slot filled at rank 8 unlocks overflow")
	var bolt = manager.spells[manager.find_spell_slot("bolt")]
	var rank8 = manager.calculate_spell_damage(bolt)
	var screen = game.level_up_screen
	screen.generate_upgrade_options({}, 20)
	var pool = screen.current_upgrade_pool
	var stat_keys = pool.map(func(card): return str(card.get("key", ""))).filter(func(key): return key.begins_with("rank:"))
	check(stat_keys.size() > 0 and stat_keys.all(func(key): return key.count(":") == 2), "Past rank 8 every rank card names a property")
	check("rank:cinder_field:area" in stat_keys and "rank:cinder_field:duration" in stat_keys and "rank:cinder_field:power" in stat_keys, "Cinder Field offers power, area and duration")
	check(not stat_keys.any(func(key): return key.ends_with(":count")), "Counts are never offered")
	game.change_state(game.GameState.PLAYING)
	game._on_upgrade_selected({"name": "Bolt · Power", "description": "+10% power (now +0%)", "effect": {"type": "spell_upgrade", "spell": "bolt", "stat": "power"}})
	check(int(bolt.get("overflow", {}).get("power", 0)) == 1, "Choosing a property card records the pick")
	check(manager.get_spell_rank("bolt") == 9, "Overflow allows rank 9")
	check(is_equal_approx(manager.calculate_spell_damage(bolt), rank8 * (1.0 + Progression.OVERFLOW_DAMAGE_PER_RANK)), "A power pick adds ten percent of rank-8 damage")
	var cinder = manager.spells[manager.find_spell_slot("cinder_field")]
	var size8 = float(Progression.resolve(cinder).radius)
	var duration8 = float(Progression.resolve(cinder).duration)
	var damage8 = manager.calculate_spell_damage(cinder)
	manager.upgrade_spell("cinder_field")
	Progression.add_overflow(cinder, "area")
	check(is_equal_approx(float(Progression.resolve(cinder).radius), size8 * 1.1), "An area pick widens by ten percent")
	check(is_equal_approx(float(Progression.resolve(cinder).duration), duration8), "An area pick leaves duration alone")
	check(is_equal_approx(manager.calculate_spell_damage(cinder), damage8), "An area pick leaves damage alone")
	manager.upgrade_spell("cinder_field")
	Progression.add_overflow(cinder, "area")
	check(is_equal_approx(float(Progression.resolve(cinder).radius), size8 * 1.2), "Area picks stack linearly")
	var plague = manager.spells[manager.find_spell_slot("plague_seed")]
	var linger8 = float(Progression.resolve(plague).spore_linger)
	manager.upgrade_spell("plague_seed")
	Progression.add_overflow(plague, "duration")
	check(is_equal_approx(float(Progression.resolve(plague).spore_linger), linger8 * 1.1), "Duration picks lengthen Plague's spores")
	check(int(Progression.resolve(Progression.resolve(plague)).get("shard_count", 0)) == 0 and is_equal_approx(float(Progression.resolve(Progression.resolve(plague)).spore_linger), linger8 * 1.1), "Resolve stays idempotent with picks")
	game.free()
	await process_frame
	print("Rank overflow: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
