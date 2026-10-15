extends RefCounted
## Reads data/<name>.json once and caches it. Validation happens in DataValidator (debug builds, tests).
##   const GameData = preload("res://scripts/core/GameData.gd")
##   GameData.file("recipes")

const SpellLibrary = preload("res://scripts/core/SpellLibrary.gd")
static var _cache: Dictionary = {}

## Spell documents (spells, recipes, spell_shapes, spell_damage, generic_spells) come from the
## per-spell files in data/spells/ (SpellLibrary), shaped exactly like the old single files.
static func file(name: String) -> Dictionary:
	if not _cache.has(name) and name in SpellLibrary.names():
		_cache[name] = SpellLibrary.document(name)
	if not _cache.has(name):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % name))
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("GameData: data/%s.json is missing or not an object" % name)
			parsed = {}
		_cache[name] = parsed
	return _cache[name]

## Drops the cache so the next read sees edited files (live iteration, tests).
static func reload() -> void:
	_cache.clear()
	SpellLibrary.reload()
