extends SceneTree

var checks = 0
var failures = 0
var game

class DisabledConsolidation extends "res://scripts/XPConsolidation.gd":
	func consolidate():
		pass

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func orb(point, value):
	var node = load("res://scenes/XPOrb.tscn").instantiate()
	node.position = point
	node.xp_value = value
	game.add_child(node)
	node.set_process(false)
	return node

func total():
	var value = 0.0
	for node in get_nodes_in_group("xp_orbs"):
		if not node.collected and not node.is_queued_for_deletion():
			value += node.xp_value
	return value

func run():
	root.get_node("AudioManager").quitting = true
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	var system = game.get_node("XPConsolidation")
	if "--known-bad" in OS.get_cmdline_user_args():
		system.set_script(DisabledConsolidation)
	var near = orb(game.player.position, 3.25)
	var near2 = orb(game.player.position + Vector2(10, 0), 4.75)
	var far = Vector2(10000, 10000)
	var anchor = orb(far, 10.25)
	var donor = orb(far + Vector2(5, 5), 20.5)
	var moving = orb(far + Vector2(10, 0), 8)
	moving.is_moving_to_player = true
	var remote = orb(far + Vector2(1000, 0), 40)
	var before = total()
	system.consolidate()
	check(is_equal_approx(total(), before), "Consolidation preserves fractional XP exactly")
	check(anchor.xp_value == 30.75 and donor.collected, "Local offscreen gems consolidate")
	check(not near.collected and not near2.collected, "Visible nearby gems remain separate")
	check(not moving.collected and moving.xp_value == 8, "Attracted gem is excluded")
	check(remote.xp_value == 40, "Unrelated distant area is not merged")
	check(anchor.position == far, "XP stays where it accumulated")
	system.consolidate()
	check(is_equal_approx(total(), before), "Repeated consolidation cannot double-count queued donor")
	await process_frame
	var extra = orb(far + Vector2(2, 2), 100)
	system.consolidate()
	check(anchor.xp_value == 130.75 and extra.collected, "Previously consolidated gem can absorb more XP")
	var levels_before = game.player.level
	game.player.position = far
	anchor.collect_xp()
	check(game.player.level > levels_before, "Returning and collecting consolidated value grants progression")
	var xp = game.player.xp
	anchor.collect_xp()
	check(game.player.xp == xp, "Collection is exactly once")
	paused = false
	game.queue_free()
	await process_frame
	check(get_nodes_in_group("xp_orbs").is_empty(), "Run teardown leaves no old pickups")
	print("XP consolidation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
