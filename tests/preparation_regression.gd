extends SceneTree
## Preparation runs: slot 1 starts, prepared spells open at 2/4/7/11/16 without a power-up choice,
## empty slots fall back to power-ups, and level-up never offers base spells.

const PREP = preload("res://scripts/Preparation.gd")

var checks = 0
var failures = 0

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func run():
	check(PREP.sanitize(["life", "bolt"])[0] == "bolt" and PREP.sanitize(["life", "bolt"])[1] == "life", "Non-attack opener swaps with Bolt")
	check(PREP.sanitize(["bolt", "bolt", "nope"]) == ["bolt", "", "", "", "", ""], "Duplicates and unknown ids are cleared")
	check(PREP.sanitize(["ember_spear"])[0] == "ember_spear", "Any attack can open")
	PREP.save_slots(["ice_blast", "bolt", "", "life", "lightning", "seeker"])
	PREP.slots = []
	check(PREP.load_slots() == ["ice_blast", "bolt", "", "life", "lightning", "seeker"], "Kit persists")
	var run_mode = preload("res://scripts/RunMode.gd")
	run_mode.prepared = true
	run_mode.training = false
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	var spells = game.spell_manager
	check(spells.get_unlocked_spell_names() == ["mana_bolt", "ice_blast"], "Run starts with the prepared opener only")
	check(spells.get_spell_info(1).id == "ice_blast", "Opener sits in key 1")
	game._on_player_level_up(2, {})
	check(spells.acquired_spells.has("bolt"), "Level 2 opens slot 2")
	check(game.pending_level_ups.is_empty() and not game.level_up_screen.visible, "Spell level gives no power-up choice")
	game._on_player_level_up(3, {})
	check(game.pending_level_ups.size() + int(game.level_up_screen.visible) >= 1, "Level 3 gives a power-up")
	game.pending_level_ups.clear()
	var offered = game.level_up_screen.generate_upgrade_options({}, 3)
	check(not game.level_up_screen.current_upgrade_pool.any(func(c): return c.effect.type == "learn_spell" and c.effect.spell in spells.BASE_SPELL_IDS), "Level-up never offers base spells")
	game.level_up_screen.hide()
	game.change_state(game.GameState.PLAYING)
	var before = game.pending_level_ups.size()
	game._on_player_level_up(4, {})
	check(spells.spells.size() == 2, "Empty slot 3 opens nothing")
	game._on_player_level_up(7, {})
	check(spells.acquired_spells.has("life") and spells.get_spell_info(3).id == "life", "Level 7 opens slot 4 into key 3")
	game._on_player_level_up(11, {})
	game._on_player_level_up(16, {})
	check(spells.acquired_spells.has("lightning") and spells.acquired_spells.has("seeker"), "Levels 11 and 16 open slots 5 and 6")
	PREP.save_slots(PREP.DEFAULT_SLOTS)  # other tests share this save folder and expect Bolt in slot 1
	run_mode.prepared = false
	print("preparation_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
