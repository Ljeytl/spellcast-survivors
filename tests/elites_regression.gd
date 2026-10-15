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

	# --- element words do something ---------------------------------------------------------------
	var player = game.player
	player.is_invincible = false
	player.health = 1000.0
	player.max_health = 1000.0
	var iron = monsters.spawn_monster(def, false, true, NAN, -1.0, ["iron"])
	check(not iron.resistances.is_empty(), "IRON is armoured (resistance profile)")
	icy.on_dealt_contact(5.0)
	check(player.has_status("chilled") and player.status_speed_multiplier() < 1.0, "an ICY touch chills you (slower)")
	player.statuses.clear()
	var fiery = monsters.spawn_monster(def, false, true, NAN, -1.0, ["fiery"])
	fiery.global_position = player.global_position + Vector2(200, 0)
	var before = player.health
	var ball = Elites.cast(fiery, data.words.fiery.cast, player)
	check(ball != null and ball.target_group == "player", "a monster's spell targets the player")
	ball.manual = true
	ball.step(0.8)
	check(is_equal_approx(player.health, before), "the meteor's warning comes before it lands")
	for i in 120:
		ball.step(1.0 / 60.0)
	check(player.health < before, "FIERY's meteor lands on you (%s -> %s)" % [before, player.health])
	check(player.has_status("burn"), "and sets you on fire")
	var burning = player.health
	player.process_statuses(1.0)
	check(player.health < burning, "burn hurts over time")
	player.statuses.clear()
	var shocking = monsters.spawn_monster(def, false, true, NAN, -1.0, ["shocking"])
	before = player.health
	var strike = Elites.cast(shocking, data.words.shocking.cast, player)
	strike.manual = true
	strike.step(0.5)
	check(is_equal_approx(player.health, before), "SHOCKING warns before it strikes")
	for i in 60:
		strike.step(1.0 / 60.0)
	check(player.health < before and player.has_status("shocked"), "then the strike lands and shocks you")
	player.statuses.clear()
	var frosty = monsters.spawn_monster(def, false, true, NAN, -1.0, ["icy"])
	frosty.global_position = player.global_position + Vector2(90, 0)
	before = player.health
	var burst = Elites.cast(frosty, data.words.icy.cast, player)
	burst.manual = true
	burst.step(0.5)
	check(is_equal_approx(player.health, before), "ICY winds up before it throws")
	check(burst.root_parts().is_empty(), "nothing has left its hands during the windup")
	for i in 60:
		burst.step(1.0 / 60.0)
	check(player.health < before and player.has_status("chilled"), "then its ice shards hit and chill you")

	# --- small, element-coloured versions of the wizard's spells --------------------------------------
	var Shapes = preload("res://scripts/engine/SpellTemplate.gd")
	var radius_of = func(id: String) -> float:
		return float(Shapes.build({"id": id, "name": id, "range": 500.0, "level": 1}, 10.0, {"speed_mult": 1.0}).parts.values()[0].get("geometry", {}).get("radius", 0.0))
	check(radius_of.call("elite_meteor") < radius_of.call("meteor_shower") * 0.5, "the elite meteor is a small one")
	check(radius_of.call("elite_lightning") < radius_of.call("lightning") * 0.5, "the elite lightning is a small one")
	check(data.words.icy.cast.spell == "elite_frost_burst" and str(Shapes.build({"id": "elite_frost_burst", "name": "x", "range": 300.0, "level": 1}, 10.0, {}).parts.shard.delivery) == "projectile", "ICY throws a small Ice Blast, not a full ring")
	var Presenter = preload("res://scripts/vfx/VfxPresenter.gd")
	var yours = preload("res://scripts/engine/GenericCast.gd").new()
	check(Presenter.is_hostile({"cast": strike}) and not Presenter.is_hostile({"cast": yours}), "a monster's spell is drawn as hostile, yours is not")
	yours.free()
	var built = Elites.build(["fiery"], "Charger")
	check(built.color == data.words.fiery.color and built.casts[0].color == data.words.fiery.color, "FIERY carries its colour to its name and its spell")
	var fiery_label = fiery.get_node("EliteWords")
	check(fiery_label.get_theme_color("font_color") == Color(data.words.fiery.color), "FIERY's name is drawn in fire orange")
	check(quick.get_node("EliteWords").get_theme_color("font_color") == Color("f2c96b"), "a word with no element stays keyword gold")
	var coloured = Elites.cast(fiery, built.casts[0], player)
	check(str(coloured.plan.get("hostile_color", "")) == data.words.fiery.color, "the elite's spell carries its hostile colour")
	coloured.queue_free()
	var elites_casts = Elites.build(["fiery", "quick"], "Charger")
	check(elites_casts.casts.size() == 1 and elites_casts.contact_statuses == ["burn"], "words carry their casts and contact statuses")
	player.statuses.clear()
	for e in get_nodes_in_group("generic_casts"):
		e.queue_free()

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
