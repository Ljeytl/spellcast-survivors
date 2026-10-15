extends RefCounted
## Every spell lives in one file, data/spells/<id>.json, with up to five sections:
##   spell    identity, numbers, rank growth, preparation flags, presentation (was spells.json)
##   recipe   a combination's ingredients, overrides, scaling and level-up note (was recipes.json)
##   shape    parts, arrangement and cast_rules, built by SpellTemplate (was spell_shapes.json)
##   damage   damage types and statuses per part (was spell_damage.json)
##   generic  a bare or draft definition for the generic caster (was generic_spells.json)
## plus "order" (catalog order) and, for generic spells, "generic_order". data/spells/_book.json holds
## what is not about one spell. This script reassembles the five documents exactly as the old files
## read, so every reader goes through GameData.file("spells" | "recipes" | "spell_shapes" |
## "spell_damage" | "generic_spells").

const DIR = "res://data/spells"
const BOOK = "_book.json"
const SECTIONS = {"spell": "spells", "recipe": "recipes", "shape": "spell_shapes", "damage": "spell_damage", "generic": "generic_spells"}
const TOP_KEYS = ["id", "order", "generic_order", "spell", "recipe", "shape", "damage", "generic"]

static var _entries: Array = []
static var _book: Dictionary = {}

static func names() -> Array:
	return SECTIONS.values()

## Every spell file, parsed, sorted by catalog order.
static func entries() -> Array:
	if _entries.is_empty():
		for file in DirAccess.get_files_at(DIR):
			if not file.ends_with(".json") or file == BOOK:
				continue
			var e = JSON.parse_string(FileAccess.get_file_as_string(DIR.path_join(file)))
			if not e is Dictionary or str(e.get("id", "")) != file.get_basename():
				push_error("SpellLibrary: %s must be an object whose id is its file name" % file)
				continue
			for k in e:
				if not k in TOP_KEYS:
					push_error("SpellLibrary: %s: unknown section '%s'" % [file, k])
			_entries.append(e)
		_entries.sort_custom(func(a, b): return float(a.get("order", 0)) < float(b.get("order", 0)))
	return _entries

static func book() -> Dictionary:
	if _book.is_empty():
		var b = JSON.parse_string(FileAccess.get_file_as_string(DIR.path_join(BOOK)))
		_book = b if b is Dictionary else {}
	return _book

## One of the five spell documents, shaped exactly like the old data/<name>.json.
static func document(name: String) -> Dictionary:
	var section = ""
	for s in SECTIONS:
		if SECTIONS[s] == name:
			section = s
	var list: Array = entries().filter(func(e): return e.has(section))
	if section == "generic":
		list.sort_custom(func(a, b): return float(a.get("generic_order", 0)) < float(b.get("generic_order", 0)))
	var items := {}
	for e in list:
		items[str(e.id)] = e[section]
	var docs: Dictionary = book().get("docs", {})
	match name:
		"spells":
			return {"spells": items, "spell_categories": book().get("spell_categories", {}), "unlock_conditions": book().get("unlock_conditions", {}), "preparation": book().get("preparation", {})}
		"recipes":
			return {"_doc": str(docs.get("recipes", "")), "recipes": items}
		"spell_shapes":
			return {"_doc": str(docs.get("spell_shapes", "")), "shapes": items}
		_:
			return {"_doc": str(docs.get(name, "")), "spells": items}

static func reload() -> void:
	_entries.clear()
	_book.clear()
