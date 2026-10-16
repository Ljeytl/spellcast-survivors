extends SceneTree
## Doc 23 threat director (data/director.json): credits from a difficulty clock, cards with fixed
## costs, elite words as cost multipliers, realm overrides, an unnamed-champion fund, night as the
## expensive phase and rest as free; stopping the spawn timer still stops background spawning.

const Director = preload("res://scripts/ThreatDirector.gd")
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

class Host:
	extends RefCounted
	var game_time := 0.0
	var phase_override := ""
	var ambient_share := 1.0
	var pressure := "medium"
	var variants: Array = []
	var bought: Array = []
	var champions := 0
	var space := 999
	func current_spawn_phase() -> Dictionary:
		return {"pressure": pressure}
	func get_available_variants(_t: float) -> Array:
		return variants
	func director_spawn(definition: Dictionary, count: int, words: Array, champion: bool):
		bought.append({"id": definition.id, "count": count, "words": words, "champion": champion})
	func champions_alive() -> int:
		return champions
	func room() -> int:
		return space

func run():
	var data = Director.data()
	var host = Host.new()
	host.variants = [{"id": "pursuer", "weight": 1.0}]
	var rng = RandomNumberGenerator.new()
	rng.seed = 5
	var d = Director.new(host, rng)
	# Income: grows with the clock, night pays more, rest pays nothing.
	var early = d.income_per_second()
	host.game_time = 600.0
	check(d.income_per_second() > early * 2.0, "income grows with the difficulty clock (%.2f -> %.2f)" % [early, d.income_per_second()])
	var day = d.income_per_second()
	host.phase_override = "night"
	check(d.income_per_second() > day * 2.0, "night is the expensive phase")
	host.phase_override = "rest"
	check(d.income_per_second() == 0.0, "camp and aftermath earn nothing")
	host.phase_override = ""
	# A purchase is a group of the card at its fixed cost.
	d.credits = 100.0
	data.elites.chance_backup = data.elites.chance
	data.elites.chance = 0.0
	check(d.spend(), "the director buys when it can afford")
	var group: Array = data.cards.pursuer.group
	var first = host.bought.back()
	check(first.id == "pursuer" and first.count >= int(group[0]) and first.count <= int(group[1]), "a purchase is a group within the card's group size (%d)" % first.count)
	check(is_equal_approx(d.credits, 100.0 - first.count * float(data.cards.pursuer.cost)), "each monster costs the card's cost")
	# Saving up: not enough for the smallest group buys nothing.
	d.credits = float(data.cards.pursuer.cost) * (int(group[0]) - 0.5)
	check(not d.spend(), "too little money: the director saves up")
	# Elite words multiply the cost.
	data.elites.chance = 1.0
	d.credits = 1000.0
	host.bought.clear()
	d.spend()
	var elite = host.bought.back()
	var word = elite.words[0] if not elite.words.is_empty() else ""
	check(word != "" and elite.count == 1, "an elite purchase is one monster with one word")
	check(word != "" and is_equal_approx(1000.0 - d.credits, float(data.cards.pursuer.cost) * float(Elites.data().words[word].cost_mult)), "an elite costs the card x its word's multiplier")
	data.elites.chance = data.elites.chance_backup
	data.elites.erase("chance_backup")
	# Realm overrides: a banned card is never bought, a cost_mult changes the price.
	var realm = d.realm()
	realm.banned = ["pursuer"]
	check(d.available_cards().is_empty(), "a realm can ban a card")
	realm.banned = []
	realm.cost_mult["pursuer"] = 2.0
	check(is_equal_approx(d.card_cost("pursuer"), 2.0 * float(data.cards.pursuer.cost)), "a realm can change a card's cost")
	realm.cost_mult.erase("pursuer")
	# The cap: no room, no spending.
	host.space = 0
	d.credits = 100.0
	check(not d.spend(), "at the monster cap the director keeps its money")
	host.space = 999
	# Champions: a separate fund, then an unnamed boss.
	host.variants = [{"id": "juggernaut", "weight": 1.0}]
	host.game_time = float(data.champions.from_minute) * 60.0 + 1.0
	d.champion_wait = 0.0
	d.champion_fund = float(data.champions.cost)
	d.credits = 0.0
	host.bought.clear()
	check(d.spend() and host.bought.back().champion, "a full champion fund buys an unnamed boss")
	check(d.champion_fund == 0.0 and d.champion_wait > 0.0, "the fund empties and the cooldown starts")
	# Same seed, same run.
	var runs: Array = []
	for i in 2:
		var h = Host.new()
		h.variants = [{"id": "pursuer", "weight": 1.0}, {"id": "swarmer", "weight": 1.0}]
		var r = RandomNumberGenerator.new()
		r.seed = 11
		var dd = Director.new(h, r)
		for step in 1200:
			h.game_time += 0.25
			dd.update(0.25)
		runs.append(str(dd.history))
	check(runs[0] == runs[1], "a seeded director replays the same purchases")
	# In the game: director pacing by default, the spawn timer is the on/off switch, champions are unnamed.
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var monsters = game.get_node("MonsterManager")
	check(monsters.pacing() == "director" and monsters.threat_director != null, "the director runs the background spawns")
	monsters.spawn_timer.stop()
	monsters.threat_director.credits = 500.0
	monsters.threat_director.wait = 0.0
	var before = monsters.monsters_alive
	monsters.advance_time(0.5)
	check(monsters.monsters_alive == before, "a stopped spawn timer stops the director")
	monsters.spawn_timer.start()
	monsters.advance_time(0.5)
	check(monsters.monsters_alive > before, "a running director spawns monsters (%d -> %d)" % [before, monsters.monsters_alive])
	var def = monsters.encounter_config.variants.juggernaut.duplicate(true)
	def.id = "juggernaut"
	var champion = monsters.director_spawn(def, 1, [], true)
	await process_frame
	var champ_node = get_nodes_in_group("bosses").filter(func(b): return b.has_meta("champion"))
	check(champ_node.size() == 1, "a champion is a boss")
	var normal_health = monsters.calculate_monster_stats(def).health
	check(champ_node.size() == 1 and is_equal_approx(champ_node[0].max_health, normal_health * float(data.champions.health_mult)), "a champion has health_mult times a normal one")
	var arrow = game.hud.get_node("BossDirection")
	arrow._process(0.0)
	check(arrow.shown_boss == null, "a champion has no named boss bar")
	monsters.rout()
	check(champ_node[0].dying, "champions flee with everyone else when the night boss falls")
	print("threat director: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
