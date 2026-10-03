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
	for i in ley.SITE_COUNT:
		check(ley.sites[i].global_position.distance_to(origin + ley.SITE_OFFSETS[i]) < 400.0, "Site %d sits at its fixed position" % i)
	var minimap = game.hud.get_node_or_null("Minimap")
	check(minimap != null, "The minimap is on the HUD")
	var edge = minimap.to_map(origin + Vector2(1.0e6, 0))
	check(edge.distance_to(Vector2(minimap.SIZE, minimap.SIZE) / 2.0) <= minimap.SIZE / 2.0, "Far sites pin to the minimap edge")
	var site = ley.sites[0]
	var LeySite = load("res://scripts/LeySite.gd")
	var monsters = game.get_node("MonsterManager")
	check(ley.sites.all(func(s): return s.words.size() == ley.WORDS_PER_SITE), "Each site has its words")
	var all_words: Array = []
	for s in ley.sites:
		all_words.append_array(s.words)
	check(all_words.all(func(w): return w.length() >= ley.WORD_LENGTH_MIN and w.length() <= ley.WORD_LENGTH_MAX), "Generated words fit the length range")
	var unique = {}
	for w in all_words:
		unique[w] = true
	check(unique.size() == all_words.size(), "Generated words never repeat in a run")
	# Asleep sites get no edge arrow; they are only on the minimap.
	ley.arrows._process(0.0)
	check(ley.arrows.marks.is_empty(), "No arrows to asleep sites")
	# Walking in wakes the site and the first wave arrives.
	var before = monsters.monsters_alive
	game.player.global_position = site.global_position
	ley._process(0.1)
	check(site.state == LeySite.State.DORMANT, "A brief step does not wake the site")
	ley._process(0.4)
	check(site.state == LeySite.State.SIEGE, "Standing in the circle wakes the site")
	ley._process(0.01)
	check(monsters.monsters_alive > before, "A wave arrives when the site wakes")
	# Words bind through Space casting, only inside the circle.
	var m = game.spell_manager
	m.last_spell_cast_time = -100.0
	m.space_casting = true
	m.start_freeform_typing()
	m.current_typing_text = site.words[0]
	m.attempt_freeform_cast()
	check(site.bound == [site.words[0]], "Typing a word in the circle binds it")
	check(not m.is_typing, "Binding a word ends typing")
	check(not ley.try_word(site.words[0]), "A bound word cannot be bound twice")
	check(not ley.try_word("notaword"), "Other text does not bind")
	game.player.global_position = site.global_position + Vector2(LeySite.RADIUS + 40, 0)
	check(not ley.try_word(site.words[1]), "Words cannot be typed outside the circle")
	# Walking far away pauses the site: progress is kept and waves stop.
	game.player.global_position = site.global_position + Vector2(ley.ENGAGE_RADIUS + 200, 0)
	var alive = monsters.monsters_alive
	ley._process(ley.WAVE_INTERVAL * 3)
	check(monsters.monsters_alive == alive, "No waves while the player is away")
	check(site.state == LeySite.State.SIEGE and site.bound.size() == 1, "Leaving keeps the site's progress")
	ley.arrows._process(0.0)
	check(ley.arrows.marks.size() == 1, "A woken site gets an arrow once off screen")
	game.player.global_position = site.global_position
	ley._process(ley.WAVE_INTERVAL + 0.1)
	check(monsters.monsters_alive > alive, "Waves resume when the player returns")
	# Binding every word summons the guardian.
	for w in site.words.slice(1):
		check(ley.try_word(w), "Binds " + w)
	check(site.state == LeySite.State.GUARDIAN and is_instance_valid(site.guardian), "The last word summons the guardian")
	check(site.guardian.boss and site.guardian.is_in_group("bosses"), "The guardian is a boss")
	alive = monsters.monsters_alive
	ley._process(ley.WAVE_INTERVAL * 2)
	check(monsters.monsters_alive == alive, "Waves stop once the guardian rises")
	# Killing the guardian attunes the site and drops the boss rewards.
	site.guardian.take_damage(1.0e9, game.player.global_position)
	for i in 30:
		await process_frame
	ley._process(0.1)
	check(site.state == LeySite.State.ATTUNED, "Killing the guardian attunes the site")
	check(get_nodes_in_group("boss_rewards").size() == 1, "The guardian drops one bonus chest")
	check(get_nodes_in_group("style_pickups").size() >= 3, "The guardian drops combo runes")
	check(get_nodes_in_group("health_potions").size() >= 1, "The guardian drops a health potion")
	# Standing in an attuned circle: +20% Spell Power and no combo decay.
	var DS = load("res://scripts/DamageSource.gd")
	DS.current = DS.make("bolt", 0.0)
	game.player.global_position = site.global_position + Vector2(LeySite.RADIUS + 120, 0)
	var outside = m.cast_stat("spell_damage_multiplier")
	game.player.global_position = site.global_position
	check(is_equal_approx(m.cast_stat("spell_damage_multiplier"), outside * 1.2), "An attuned circle gives +20% Spell Power")
	DS.current = {}
	var style = game.style_session
	style.score.combo = 500.0
	style.score.grace_remaining = 0.0
	style.advance(5.0)
	check(style.score.combo >= 500.0, "Combo does not decay inside an attuned circle")
	game.player.global_position = site.global_position + Vector2(LeySite.RADIUS + 120, 0)
	style.advance(0.016)
	style.score.grace_remaining = 0.0
	var held = style.score.combo
	style.advance(3.0)
	check(style.score.combo < held, "Combo decays again outside the circle")
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
