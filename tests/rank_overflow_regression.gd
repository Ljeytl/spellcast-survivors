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
	manager.upgrade_spell("bolt")
	check(manager.get_spell_rank("bolt") == 9, "Overflow allows rank 9")
	check(is_equal_approx(manager.calculate_spell_damage(bolt), rank8 * (1.0 + Progression.OVERFLOW_DAMAGE_PER_RANK)), "Rank 9 adds ten percent of rank-8 damage")
	check("+10% damage" in manager.get_rank_upgrade_description("bolt"), "Overflow upgrade card describes the percentage")
	var cinder = manager.spells[manager.find_spell_slot("cinder_field")]
	var size8 = float(Progression.resolve(cinder).radius)
	manager.upgrade_spell("cinder_field")
	check(is_equal_approx(float(Progression.resolve(cinder).radius), size8), "Sizes stop growing past rank 8")
	game.free()
	await process_frame
	print("Rank overflow: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
