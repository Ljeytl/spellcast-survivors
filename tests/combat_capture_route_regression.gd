extends SceneTree

const Capture = preload("res://tools/capture_spell_combat.gd")
var checks := 0
var failures := 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value: bool, label: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.spell_manager.set_process(false)
	game.get_node("MonsterManager").set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	var manager = game.spell_manager
	for spell in ["nova", "orbit", "spear", "slash", "field", "trap"]:
		var route = Capture.prepare_capture_spell(manager, spell, 1)
		check(route.get("kind") == "bare_freeform", spell + " routes through bare incantation")
		check(Capture.release_capture_spell(manager, route), spell + " actually casts")
		check(is_instance_valid(manager.last_generic_cast), spell + " creates native cast")
		check(Capture.prepare_capture_spell(manager, spell, 8).has("error"), spell + " rejects fictitious rank")
	for spell in ["nova", "orbit"]:
		for modifier in ["large", "fiery"]:
			var route = Capture.prepare_capture_spell(manager, spell, 1, modifier)
			check(not route.has("error") and Capture.release_capture_spell(manager, route), modifier + " " + spell + " casts")
			check(manager.last_cracked.is_empty(), modifier + " " + spell + " is not silently rejected")
	check(Capture.prepare_capture_spell(manager, "nova", 1, "nonsense").has("error"), "Unknown keyword fails closed")
	check(Capture.prepare_capture_spell(manager, "not_a_spell", 1).has("error"), "Unknown spell fails closed")
	var named = Capture.prepare_capture_spell(manager, "lightning", 8)
	if OS.get_cmdline_user_args().has("known-bad-named-route"):
		named.kind = "bare_freeform"
	check(named.get("kind") == "learned_slot", "Named spell retains learned-slot route")
	check(manager.get_spell_info(manager.find_spell_slot("lightning")).level == 8, "Named rank remains applied")
	check(Capture.prepare_capture_spell(manager, "lightning", 1, "large").has("error"), "Bare modifier option does not alter named semantics")
	game.queue_free()
	await process_frame
	await process_frame
	print("CAPTURE_ROUTE checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
