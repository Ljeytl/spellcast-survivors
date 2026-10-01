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

func key(letter: String, code: int = 0):
	var event = InputEventKey.new()
	event.pressed = true
	event.keycode = code if code else OS.find_keycode_from_string(letter.to_upper())
	event.unicode = letter.unicode_at(0) if letter.length() == 1 else 0
	root.push_input(event)
	var release = event.duplicate()
	release.pressed = false
	root.push_input(release)

func type_word(word: String):
	for letter in word:
		key(letter)

func run():
	root.size = Vector2i(1280, 720)
	load("res://scripts/RunMode.gd").training = false
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 5:
		await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	var ley = game.get_node_or_null("LeyLines")
	check(ley != null, "Normal runs have ley lines")
	check(ley.sites.size() == ley.SITE_COUNT, "Three sites are placed")
	var origin = game.player.global_position
	check(ley.sites.all(func(s): return s.global_position.distance_to(origin) >= ley.SITE_DISTANCE_MIN - 1.0), "Sites are placed away from the start")
	var site = ley.sites[0]
	var LeySite = load("res://scripts/LeySite.gd")
	# Standing briefly in the circle starts the ritual and summons an ambush.
	var before = game.get_tree().get_nodes_in_group("enemies").size()
	game.player.global_position = site.global_position
	ley._process(0.2)
	check(not ley.ritual_active(), "A brief step does not start the ritual")
	ley._process(0.5)
	check(ley.ritual_active() and site.state == LeySite.State.RITUAL, "Dwelling in the circle starts the ritual")
	await process_frame
	check(game.get_tree().get_nodes_in_group("enemies").size() > before, "The ritual summons an ambush")
	game.player.handle_movement()
	check(game.player.velocity == Vector2.ZERO, "The player cannot move while typing a ritual")
	# Keys go to the ritual, not to spell casting.
	key("1", KEY_1)
	await process_frame
	check(not game.spell_manager.is_typing, "Number keys do not start a spell during a ritual")
	var word = ley.words[0]
	type_word(word.substr(0, 3))
	check(ley.typed == word.substr(0, 3), "Correct letters advance the word")
	var wrong = "q" if word[3] != "q" else "z"
	key(wrong)
	check(ley.typed == "" and ley.word_index == 0, "A typo resets only the current word")
	for w in ley.words.duplicate():
		type_word(w)
	check(site.state == LeySite.State.ATTUNED and not ley.ritual_active(), "Typing every word attunes the site")
	await process_frame
	check(game.current_state == game.GameState.LEVEL_UP, "Attuning grants an upgrade pick")
	game.level_up_screen.hide()
	game.pending_level_ups.clear()
	game.change_state(game.GameState.PLAYING)
	# Running out of time fails; the site cools, then needs the player to step out and back in.
	var second = ley.sites[1]
	game.player.global_position = second.global_position
	ley._process(0.7)
	check(ley.ritual_active(), "Second site starts")
	ley._process(ley.word_time_total + 0.1)
	check(not ley.ritual_active() and second.state == LeySite.State.COOLING, "Running out of time fails the ritual")
	ley._process(ley.RETRY_SECONDS + 0.1)
	ley._process(1.0)
	check(second.state == LeySite.State.DORMANT and not ley.ritual_active(), "A cooled site does not restart while the player stays inside")
	game.player.global_position = second.global_position + Vector2(400, 0)
	ley._process(0.1)
	game.player.global_position = second.global_position
	ley._process(0.7)
	check(ley.ritual_active(), "Stepping out and back in retries")
	key("", KEY_ESCAPE)
	check(not ley.ritual_active() and second.state == LeySite.State.COOLING, "Escape cancels the ritual")
	check(game.current_state == game.GameState.PLAYING, "Escape during a ritual does not pause")
	game.free()
	await process_frame
	load("res://scripts/RunMode.gd").training = true
	var training = load("res://scenes/Game.tscn").instantiate()
	root.add_child(training)
	await process_frame
	check(training.get_node_or_null("LeyLines") == null, "Training has no ley lines")
	training.free()
	load("res://scripts/RunMode.gd").training = false
	await process_frame
	print("Ley lines: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
