extends SceneTree
## Doc 19 step 1 / doc 20 G1: every data file is validated against its schema; broken data fails
## with a useful message; TypeChart agrees with data/damage_types.json until it reads it (G2).

const DataValidator = preload("res://scripts/core/DataValidator.gd")
const TypeChart = preload("res://scripts/engine/TypeChart.gd")

var checks: int = 0
var failures: int = 0

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func load_json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func load_all() -> Array:
	var docs := {}
	var schemas := {}
	for file in DirAccess.get_files_at("res://data"):
		if file.ends_with(".json"):
			docs[file] = load_json("res://data/" + file)
			schemas[file] = load_json("res://data/schemas/" + file.get_basename() + ".schema.json")
	return [docs, schemas]

## Validates the real data with one file replaced by a mutated copy; returns the errors.
func broken(file: String, mutate: Callable) -> Array:
	var loaded = load_all()
	var docs: Dictionary = loaded[0]
	docs[file] = docs[file].duplicate(true)
	mutate.call(docs[file])
	return DataValidator.validate_documents(docs, loaded[1])

func has_error(errors: Array, fragment: String) -> bool:
	for e in errors:
		if fragment in str(e):
			return true
	return false

func run():
	# 1. All current data passes, and every data file has a schema.
	var errors = DataValidator.validate_all()
	check(errors.is_empty(), "All data is valid: %s" % str(errors.slice(0, 5)))
	for file in DirAccess.get_files_at("res://data"):
		if file.ends_with(".json"):
			check(FileAccess.file_exists("res://data/schemas/" + file.get_basename() + ".schema.json"), "%s has a schema" % file)

	# 2. Each kind of mistake is caught, with the file and path in the message.
	var cases = [
		["unknown key", "spells.json", func(d): d.spells.bolt["damgae"] = 5, "spells.json $.spells.bolt.damgae: unknown key"],
		["wrong type", "spells.json", func(d): d.spells.bolt.damage = "lots", "$.spells.bolt.damage: expected number"],
		["missing required", "spells.json", func(d): d.spells.bolt.erase("name"), "missing required 'name'"],
		["id must match key", "spells.json", func(d): d.spells.bolt.id = "bolt2", "id must equal its key 'bolt'"],
		["unknown element", "spells.json", func(d): d.spells.bolt.element = "fyre", "'fyre' is not a known element or element_alias"],
		["unknown status", "statuses.json", func(d): d.chilled.threshold = "frozzen", "'frozzen' is not a known status"],
		["unknown damage type in a resistance profile", "resistances.json", func(d): d.elite_armored["physical"] = 0.3, "'physical' is not a known damage_type"],
		["resistance out of range", "resistances.json", func(d): d.elite_armored.fire = 1.5, "above the maximum"],
		["damage share for an unknown spell", "spell_damage.json", func(d): d.spells["bolts"] = {"damage": {"arcane": 1.0}}, "'bolts' is not a known spell"],
		["keyword in an unknown category", "keywords.json", func(d): d.words.mega.category = "tierr", "'tierr' is not a known keyword_category"],
		["recipe with an unknown ingredient", "recipes.json", func(d): d.recipes.life_bolt.ingredients[1] = "lif", "'lif' is not a known spell"],
		["boss names an unknown variant", "encounters.json", func(d): d.bosses[0].variant = "juggernot", "'juggernot' is not a known enemy_variant"],
		["unknown delivery", "generic_spells.json", func(d): d.spells.spear.parts.spear.delivery = "lazer", "'lazer' is not one of"],
		["unknown pressure", "encounters.json", func(d): d.scaling.spawn_phases[0].pressure = "extreme", "'extreme' is not one of"],
		["_doc must be text", "statuses.json", func(d): d.burn["_doc"] = 3, "_doc must be a string"],
	]
	for c in cases:
		var errs = broken(c[1], c[2])
		check(has_error(errs, c[3]), "%s is reported (%s); got %s" % [c[0], c[3], str(errs.slice(0, 3))])

	# 3. A typo in a schema keyword is itself an error, so a rule cannot be switched off by accident.
	var loaded = load_all()
	var schemas: Dictionary = loaded[1].duplicate(true)
	schemas["statuses.json"]["additionalPropertys"] = false
	check(has_error(DataValidator.validate_documents(loaded[0], schemas), "unknown schema keyword 'additionalPropertys'"), "Schema typos are reported")

	# 4. Registries are collected across files.
	var regs = DataValidator.registries_of(loaded[0], loaded[1])
	for reg in ["spell", "ability", "status", "element", "damage_type", "keyword", "keyword_category", "enemy_variant", "resistance_profile"]:
		check(regs.has(reg) and not regs[reg].is_empty(), "Registry '%s' is collected" % reg)

	# 5. TypeChart agrees with data/damage_types.json until it reads it directly (doc 20 G2).
	var types = load_json("res://data/damage_types.json")
	check(Array(TypeChart.CYCLE) == types.type_cycle, "TypeChart.CYCLE matches type_cycle")
	check(TypeChart.ALIASES == types.element_aliases, "TypeChart.ALIASES matches element_aliases")
	check(is_equal_approx(TypeChart.STRONG, types.type_chart.strong) and is_equal_approx(TypeChart.SAME, types.type_chart.same), "Type chart multipliers match")
	for id in types.damage_types:
		check(TypeChart.NAMES.get(id, "") == types.damage_types[id].name, "Damage type name matches for %s" % id)
	for id in types.elements:
		check(TypeChart.COLORS.has(id) and TypeChart.COLORS[id].to_html(false) == types.elements[id].color, "Element colour matches for %s" % id)

	# 6. Combinations and Atomic come from data, not code.
	var Synergies = load("res://scripts/SynergyCatalog.gd")
	check(Synergies.RECIPES.has("lightning_bolt") and Synergies.RECIPES.lightning_bolt.ingredients == ["bolt", "lightning"], "Recipes load from data/recipes.json")
	check(Synergies.RECIPES.reaping_spirit.get("enabled", true) == false, "Disabled recipes stay disabled")
	var Score = load("res://scripts/StyleScore.gd")
	check(Score.ATOMIC_COMBO_PER_CHARGE == 10000 and Score.ATOMIC_MAX_CHARGES == 3 and Score.ATOMIC_RANK == 6, "Atomic charge rules load from data/abilities.json")

	print("data_validation_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
