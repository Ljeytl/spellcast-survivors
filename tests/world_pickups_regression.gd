extends SceneTree

var checks = 0
var failures = 0

func check(value, label):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	var potion_script = load("res://scripts/HealthPotion.gd")
	check(potion_script.try_drop(game, Vector2.ZERO, 1.0) == null, "failed roll has no drop")
	var potion = potion_script.try_drop(game, game.player.position, 0.0)
	check(potion != null, "successful drop without healing spell")
	check(not potion.collect(), "full health preserves potion")
	check(not potion.is_queued_for_deletion(), "full health pickup remains")
	game.player.health = 50
	check(potion.collect(), "injured player collects")
	check(game.player.health == 60, "potion restores 10 HP")
	check(not potion.collect(), "no duplicate collection")
	await process_frame
	var near_full = potion_script.try_drop(game, Vector2(9000, 9000), 0.0)
	game.player.health = 98
	near_full.collect()
	check(game.player.health == 100, "healing caps at maximum")
	await process_frame
	for i in range(potion_script.MAX_DROPS):
		potion_script.try_drop(game, Vector2(9000, 9000), 0.0)
	check(potion_script.try_drop(game, Vector2.ZERO, 0.0) == null, "outstanding potion limit")
	for pickup in get_nodes_in_group("health_potions"):
		pickup.free()
	var xp_script = load("res://scripts/XPOrb.gd")
	for pair in [[1, 0], [24, 0], [25, 1], [99, 1], [100, 2], [499, 2], [500, 3], [10000, 3]]:
		check(xp_script.value_tier(pair[0]) == pair[1], "gem value boundary %s" % pair[0])
	check(xp_script.crystal_textures().size() == 4, "four distinct gem textures")
	var orb = load("res://scenes/XPOrb.tscn").instantiate()
	game.add_child(orb)
	orb.xp_value = 490
	orb.xp_value += 20
	check(orb.get_node("Visual").texture == xp_script.crystal_textures()[3], "consolidated XP refreshes gold tier")
	check(orb.xp_value == 510, "gem value conserved")
	var background = game.get_node("Background")
	var lower = Vector2i(100, 100)
	var upper = Vector2i(100, 99)
	background.layouts[lower] = {"trees": [Vector2(20, 80000)], "bushes": []}
	background.layouts[upper] = {"trees": [Vector2(20, 79980)], "bushes": []}
	background.decorations[lower] = background.create_decoration(lower)
	background.decorations[upper] = background.create_decoration(upper)
	var bottom_tree = background.decorations[lower].get_child(0)
	var top_tree = background.decorations[upper].get_child(0)
	check(bottom_tree.get_meta("canopy").get_parent() == top_tree.get_meta("canopy").get_parent() and background.tree_canopies.y_sort_enabled, "canopies from reverse-created chunks share Y-sorted parent")
	check(bottom_tree.get_meta("canopy").position.y > top_tree.get_meta("canopy").position.y, "canopy sort origin follows trunk base")
	check(bottom_tree.position == Vector2(20, 80000), "sorting leaves trunk collision position intact")
	var canopy = bottom_tree.get_meta("canopy")
	background.last_cell = Vector2i(2147483647, 2147483647)
	background.refresh_decorations()
	await process_frame
	await process_frame
	check(not is_instance_valid(canopy), "unloaded chunk frees its canopy")
	print("world_pickups_regression: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
