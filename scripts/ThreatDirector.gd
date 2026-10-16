extends RefCounted
## The threat director (doc 23, data/director.json), Risk of Rain style: it earns credits every
## second and spends them in bursts on monster cards. Income grows with a difficulty coefficient
## that climbs with run minutes and never resets; day phases shape it, night (the teleporter event)
## multiplies it and creeps up while the boss lives, rest and camp earn nothing. A purchase is a
## card bought several times (its group), sometimes upgraded to an elite (the word's cost_mult), and
## champions (unnamed bosses) come out of the same budget. Named bosses, patrols, packs and ley
## waves are events outside the director.
##
## The director only decides; `host` spawns. host provides: game_time, phase_override, ambient_share,
## current_spawn_phase(), get_available_variants(t), director_spawn(definition, count, words, champion),
## champions_alive(), room() (how many more monsters fit under the cap). tools/simulate_director.gd drives it with a stub host to print a run.

const Elites = preload("res://scripts/Elites.gd")
const GameData = preload("res://scripts/core/GameData.gd")

var host
var rng: RandomNumberGenerator
var credits := 0.0
var wait := 0.0
var champion_wait := 0.0
var champion_fund := 0.0   # a share of income set aside for unnamed bosses once they are allowed
var night_seconds := 0.0
var spent := 0.0
var history: Array = []   # {t, card, count, word, champion, cost} per purchase

func _init(p_host, p_rng: RandomNumberGenerator = null):
	host = p_host
	rng = p_rng if p_rng != null else preload("res://scripts/core/Rng.gd").stream("director")
	credits = float(data().get("income", {}).get("starting_credits", 0.0))

static func data() -> Dictionary:
	return GameData.file("director")

func minutes() -> float:
	return float(host.game_time) / 60.0

## The difficulty coefficient: 1 at the start, climbing with run minutes, never reset.
func coefficient() -> float:
	return 1.0 + float(data().income.difficulty_growth_per_minute) * minutes()

## Income multiplier for the current phase of the day.
func phase_multiplier() -> float:
	var phases: Dictionary = data().get("phases", {})
	var override := str(host.phase_override)
	if override == "rest":
		return float(phases.get("rest", 0.0))
	if override == "night":
		return float(phases.get("night", 2.0)) * (1.0 + float(phases.get("night_creep_per_minute", 0.0)) * night_seconds / 60.0)
	var pressure := str(host.current_spawn_phase().get("pressure", ""))
	if pressure == "rest":
		return 0.0
	return float(phases.get(pressure, 1.0))

func income_per_second() -> float:
	var income: Dictionary = data().income
	return float(income.base_per_second) * pow(coefficient(), float(income.get("income_exponent", 1.0))) * phase_multiplier() * clampf(float(host.ambient_share), 0.0, 1.0)

func bank_cap() -> float:
	var income: Dictionary = data().income
	return maxf(float(income.get("starting_credits", 0.0)), float(income.base_per_second) * pow(coefficient(), float(income.get("income_exponent", 1.0))) * float(income.get("bank_cap_seconds", 30.0)) * maxf(1.0, phase_multiplier()))

func update(delta: float) -> void:
	if delta <= 0.0 or delta > 5.0:
		return
	night_seconds = night_seconds + delta if str(host.phase_override) == "night" else 0.0
	var earned := income_per_second() * delta
	var champs: Dictionary = data().get("champions", {})
	if not champs.is_empty() and minutes() >= float(champs.get("from_minute", INF)):
		var share := clampf(float(champs.get("income_share", 0.25)), 0.0, 1.0)
		champion_fund = minf(float(champs.cost), champion_fund + earned * share)
		earned *= 1.0 - share
	credits = minf(bank_cap(), credits + earned)
	champion_wait = maxf(0.0, champion_wait - delta)
	wait -= delta
	if wait > 0.0:
		return
	# A burst: keep buying while the money lasts (up to burst_max purchases), then rest. This is
	# what turns steady income into waves.
	var spending: Dictionary = data().get("spending", {})
	var bought := 0
	while bought < int(spending.get("burst_max", 6)) and spend():
		bought += 1
	if bought > 0:
		wait = rng.randf_range(float(spending.get("wait_min", 1.5)), float(spending.get("wait_max", 4.0)))
	else:
		wait = float(spending.get("retry_wait", 0.6))   # saving up: try again soon

func realm() -> Dictionary:
	var d := data()
	return d.get("realms", {}).get(str(d.get("realm", "")), {})

## Cards the director may buy now: unlocked by run time (encounters.json) and allowed by the realm.
func available_cards() -> Array:
	var cards: Dictionary = data().cards
	var banned: Array = realm().get("banned", [])
	var out: Array = []
	for definition in host.get_available_variants(host.game_time):
		var id := str(definition.id)
		if cards.has(id) and id not in banned:
			out.append(definition)
	return out

func card_cost(id: String) -> float:
	return float(data().cards[id].cost) * float(realm().get("cost_mult", {}).get(id, 1.0))

func card_weight(definition: Dictionary) -> float:
	var card: Dictionary = data().cards[str(definition.id)]
	return float(card.get("weight", definition.get("weight", 1.0))) * float(realm().get("weight_mult", {}).get(str(definition.id), 1.0))

## One purchase. Returns false when nothing could be afforded (the director saves up).
func spend() -> bool:
	if int(host.room()) <= 0:
		return false   # at the cap: keep the money for when there is room
	if try_champion():
		return true
	var pool := available_cards()
	if pool.is_empty():
		return false
	var total := 0.0
	for definition in pool:
		total += card_weight(definition)
	var roll := rng.randf() * total
	var pick: Dictionary = pool.back()
	for definition in pool:
		roll -= card_weight(definition)
		if roll <= 0.0:
			pick = definition
			break
	var id := str(pick.id)
	var cost := card_cost(id)
	var group: Array = data().cards[id].group
	# Elite upgrade: one monster carrying a word, at the word's cost multiplier.
	var elites: Dictionary = data().get("elites", {})
	if minutes() >= float(elites.get("from_minute", INF)) and rng.randf() < float(elites.get("chance", 0.0)):
		var words := Elites.roll(1, rng)
		if not words.is_empty():
			var elite_cost := cost * float(Elites.data().words[words[0]].get("cost_mult", 3.0))
			if credits >= elite_cost:
				return buy(pick, 1, words, false, elite_cost)
	var count := mini(mini(int(group[1]), int(host.room())), int(floor(credits / cost)))
	if count < int(group[0]):
		return false
	return buy(pick, count, [], false, cost * count)

func try_champion() -> bool:
	var champs: Dictionary = data().get("champions", {})
	if champs.is_empty() or minutes() < float(champs.get("from_minute", INF)) or champion_wait > 0.0:
		return false
	if champion_fund < float(champs.cost) or int(host.champions_alive()) >= int(champs.get("max_alive", 1)):
		return false
	var allowed: Array = champs.get("cards", [])
	var pool := available_cards().filter(func(d): return str(d.id) in allowed)
	if pool.is_empty():
		return false
	champion_wait = float(champs.get("cooldown_seconds", 60.0))
	champion_fund = 0.0
	credits += float(champs.cost)   # paid from the fund, not the wave budget
	return buy(pool[rng.randi() % pool.size()], 1, [], true, float(champs.cost))

func buy(definition: Dictionary, count: int, words: Array, champion: bool, cost: float) -> bool:
	credits -= cost
	spent += cost
	history.append({"t": float(host.game_time), "card": str(definition.id), "count": count, "word": words[0] if not words.is_empty() else "", "champion": champion, "cost": cost})
	host.director_spawn(definition, count, words, champion)
	return true
