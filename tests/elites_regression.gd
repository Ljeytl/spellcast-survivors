extends SceneTree
## 0.3.3 elites: a monster plus words from data/elites.json. Each word changes what it says; patrols
## arrive on schedule with escorts and roll more words later; ley waves after the first are led by an
## elite; LEECHING heals on contact; the elite shows its words and keeps its own behaviour.

const Elites = preload("res://scripts/Elites.gd")

var checks = 0
var failures = 0

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var monsters = game.get_node("MonsterManager")
	monsters.spawn_timer.stop()
	monsters.set_process(false)
	game.player.set_physics_process(false)
	var data = Elites.data()
	var def = monsters.encounter_config.variants.charger.duplicate(true)
	def.id = "charger"

	# --- one word at a time --------------------------------------------------------------------
	var plain = monsters.spawn_monster(def, false, true)
	var quick = monsters.spawn_monster(def, false, true, NAN, -1.0, ["quick"])
	var base: Dictionary = data.base
	check(quick.is_in_group("elites") and not plain.is_in_group("elites"), "elites are marked")
	check(is_equal_approx(quick.max_health, plain.max_health * float(base.health_mult)), "base elite health (%s vs %s)" % [quick.max_health, plain.max_health])
	check(is_equal_approx(quick.speed, plain.speed * float(data.words.quick.speed_mult)), "QUICK is faster")
	check(is_equal_approx(quick.scale.x, plain.scale.x * float(base.size_mult)), "elites are bigger")
	check(quick.encounter_name == "QUICK Charger", "name carries the word: " + quick.encounter_name)
	check(quick.variant == "charger" and quick.family == plain.family, "keeps its own behaviour")
	check(quick.has_node("EliteWords") and quick.get_node("EliteWords").text == "QUICK", "shows its word")
	check(quick.get_node("Sprite2D").self_modulate != Color.WHITE, "darker colour shift")
	var massive = monsters.spawn_monster(def, false, true, NAN, -1.0, ["massive"])
	check(massive.scale.x > quick.scale.x and massive.speed < plain.speed, "MASSIVE is bigger and slower")
	var icy = monsters.spawn_monster(def, false, true, NAN, -1.0, ["icy"])
	check(icy.element == "water", "ICY is a water monster (type chart decides its resist and weakness)")
	var two = Elites.roll(2)
	check(two.size() == 2 and two[0] != two[1], "two distinct words")
	for i in 30:
		var r = Elites.roll(3)
		check(r.filter(func(w): return data.words[w].has("element")).size() <= 1, "at most one element word")

	# --- LEECHING heals on contact ---------------------------------------------------------------
	var leech = monsters.spawn_monster(def, false, true, NAN, -1.0, ["leeching"])
	leech.current_health = leech.max_health * 0.5
	leech.on_dealt_contact(10.0)
	check(is_equal_approx(leech.current_health, leech.max_health * (0.5 + float(data.words.leeching.heal_per_hit))), "LEECHING heals when its hit lands")

	# --- patrols ------------------------------------------------------------------------------------
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await process_frame
	monsters.monsters_alive = 0
	monsters.game_time = float(data.patrols.first) - 1.0
	check(monsters.check_elite_patrol() == null, "no patrol before its time")
	monsters.game_time = float(data.patrols.first)
	var leader = monsters.check_elite_patrol()
	check(leader != null and leader.elite.words.size() == 1, "first patrol: one word")
	await process_frame
	var patrol_size = get_nodes_in_group("enemies").size()
	check(patrol_size == 1 + int(data.patrols.escorts), "elite plus escorts (%d)" % patrol_size)
	check(monsters.check_elite_patrol() == null, "one patrol per interval")
	monsters.game_time = float(data.patrols.words[1].from) + 1.0
	monsters.next_patrol = monsters.game_time
	var later = monsters.check_elite_patrol()
	check(later != null and later.elite.words.size() == int(data.patrols.words[1].count), "later patrols roll more words")
	monsters.game_time = float(data.patrols.until) + 1.0
	monsters.next_patrol = monsters.game_time
	check(monsters.check_elite_patrol() == null, "no patrols at the end of the run")

	# --- ley waves --------------------------------------------------------------------------------
	var ley = game.get_node_or_null("LeyLines")
	if ley and not ley.sites.is_empty():
		var site = ley.sites[0]
		ley.summon_wave(site)
		check(not site.wave_members.any(func(m): return is_instance_valid(m) and m.is_in_group("elites")), "the opening ley wave has no elite")
		ley.summon_wave(site)
		check(site.wave_members.size() > 0 and site.wave_members[0].is_in_group("elites"), "later ley waves are led by an elite")
	else:
		check(true, "no ley sites in this scene (skipped)")
	print("elites: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
