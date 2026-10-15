extends RefCounted
## How each combination grows with its own rank and its ingredients' ranks. The rules are data:
## data/recipes.json "scaling" (one expression per spell-info field) and "rank_note" (the next
## rank's level-up line). Expression helpers: own, bonus(id), dmg(id, fallback), rank, pick(c, a, b).

static var _spells: Dictionary = {}
static var _recipes: Dictionary = {}
static var _parsed: Dictionary = {}

static func _recipe(id: String) -> Dictionary:
	if _recipes.is_empty():
		var parsed = preload("res://scripts/core/GameData.gd").file("recipes")
		_recipes = parsed.get("recipes", {}) if parsed is Dictionary else {}
	return _recipes.get(id, {})

## Damage an ingredient deals at a rank, following its own curve (rank_growth or +15% per rank).
static func ingredient_damage(id: String, rank: int, fallback: float) -> float:
	if _spells.is_empty():
		var parsed = preload("res://scripts/core/GameData.gd").file("spells")
		_spells = parsed.get("spells", {}) if parsed is Dictionary else {}
	var data = _spells.get(id, {})
	if data.is_empty():
		return fallback * (1.0 + 0.15 * maxi(0, rank - 1))
	var growth = data.get("rank_growth", {}).get("damage", {})
	if growth.is_empty():
		return float(data.get("damage", fallback)) * (1.0 + 0.15 * maxi(0, rank - 1))
	return float(data.damage) + float(growth.get("per_rank", 0.0)) * maxi(0, rank - 1)

static func resolve(data: Dictionary, ranks: Dictionary) -> Dictionary:
	var info = data.duplicate(true)
	var scaling: Dictionary = _recipe(str(info.get("id", ""))).get("scaling", {})
	if scaling.is_empty():
		return info
	var env = Env.new(ranks, maxi(0, int(info.get("level", 1)) - 1), 0)
	# Every rule reads the ranks, never another rule's result, so order does not matter.
	for key in scaling:
		info[key] = _run(str(scaling[key]), env, str(info.get("id", "")))
	info.erase("rank_steps")
	info.erase("damage_multiplier")
	info.erase("lifesteal")
	info.combination_scaled = true
	return info

static func next_description(id: String, rank: int) -> String:
	var note = str(_recipe(id).get("rank_note", ""))
	if note == "":
		return ""
	return str(_run(note, Env.new({}, 0, rank), id))

static func _run(source: String, env, id: String):
	var text = source.substr(1) if source.begins_with("=") else source
	var e: Expression = _parsed.get(text)
	if e == null:
		e = Expression.new()
		if e.parse(text, ["own", "rank"]) != OK:
			push_error("recipes.json %s: cannot parse '%s': %s" % [id, text, e.get_error_text()])
			return null
		_parsed[text] = e
	var result = e.execute([env.own, env.rank], env)
	if e.has_execute_failed():
		push_error("recipes.json %s: '%s' failed: %s" % [id, text, e.get_error_text()])
		return null
	return result

class Env:
	var ranks: Dictionary
	var own: int
	var rank: int
	func _init(r: Dictionary, own_rank: int, next_rank: int):
		ranks = r
		own = own_rank
		rank = next_rank
	## An ingredient's rank above 1.
	func bonus(id: String) -> int:
		return maxi(0, int(ranks.get(id, 1)) - 1)
	## An ingredient's damage at its rank, following its own curve.
	func dmg(id: String, fallback: float) -> float:
		return load("res://scripts/CombinationScaling.gd").ingredient_damage(id, int(ranks.get(id, 1)), fallback)
	func pick(cond, a, b):
		return a if cond else b
