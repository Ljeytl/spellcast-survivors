extends SceneTree
## Ley words typed inside an awakened ley circle build the casting circle in ley colours
## instead of reading as typos.

var checks = 0
var failures = 0

func _initialize():
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func frames(n: int):
	for i in n:
		await process_frame

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await frames(3)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	var ley = get_first_node_in_group("ley_lines")
	check(ley != null and not ley.sites.is_empty(), "Ley lines exist in a normal run")
	if ley == null or ley.sites.is_empty():
		print("casting_circle_ley_regression: %d checks, %d failures" % [checks, failures])
		quit(1)
		return
	var site = ley.sites[0]
	site.state = site.State.SIEGE
	game.player.global_position = site.global_position
	var word = str(site.words[0]).to_lower()
	var circle = game.player.get_node("CastingCircle")
	var manager = game.spell_manager
	manager.start_freeform_typing()
	manager.current_typing_text = word.substr(0, 3)
	await frames(3)
	check(circle.good_runes == 3 and not circle.runes.any(func(r): return r.bad), "Ley word prefix builds clean runes, not cracked ones")
	manager.current_typing_text = word
	await frames(3)
	check(str(circle.state.get("element", "")) == "ley", "A full ley word locks the ley colour")
	# Leaving the site: the same word is no longer a valid incantation.
	game.player.global_position = site.global_position + Vector2(5000, 0)
	manager.current_typing_text = word.substr(0, 2)
	await frames(3)
	var table_words = circle.spell_table().map(func(s): return s.incantation)
	check(not word in table_words, "Ley words only count while standing in an awakened site")
	manager.cancel_typing()
	print("casting_circle_ley_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
