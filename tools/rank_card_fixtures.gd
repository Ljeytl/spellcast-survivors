extends SceneTree
## Records the 0.3.0 rank-up card lines (SpellManager.rank_change_summary), Magic Missile's count per
## rank and the rank caps, so moving their per-spell rules to data can be proved identical
## (tests/rank_cards_data_regression.gd). Ran once against the 0.3.0 code.

const OUT = "res://tests/fixtures/rank_cards_0_3_0.bin"

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var cases = await collect(root)
	var f = FileAccess.open(OUT, FileAccess.WRITE)
	f.store_var(cases)
	f.close()
	print("wrote %d cases" % cases.size())
	quit(0)

static func collect(tree_root: Node) -> Array:
	var game = load("res://scenes/Game.tscn").instantiate()
	tree_root.add_child(game)
	await tree_root.get_tree().process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	var manager = game.spell_manager
	manager.set_process(false)
	manager.slot_limit = 99
	var cases: Array = []
	for id in load("res://scripts/SpellManager.gd").BASE_SPELL_IDS:
		manager.learn_spell(id, false)
	for id in ["lightning_bolt", "life_bolt", "meteor_spear", "soul_bloom", "steam_field", "prism_ray", "frost_sigil"]:
		manager.learn_spell(id, false)
	for id in manager.acquired_spells:
		var slot = manager.find_spell_slot(id)
		if slot == 0:
			continue
		for rank in range(1, 12):
			manager.get_spell_info(slot).level = rank
			cases.append({"id": id, "rank": rank, "summary": manager.rank_change_summary(id), "can_upgrade": preload("res://scripts/SpellProgression.gd").can_upgrade(manager.get_spell_info(slot))})
	for level in range(1, 13):
		manager.mana_bolt_level = level
		cases.append({"id": "mana_bolt", "rank": level, "summary": manager.rank_change_summary("mana_bolt")})
	game.queue_free()
	return cases
