extends RefCounted
## Pre-run spellbook. The player picks and orders up to six base spells in the tower.
## Slot 1 is ready at level 1; slot N opens automatically at ACTIVATION_LEVELS[N - 1].
## Those levels give the spell instead of a power-up choice. Combinations stay outside the six slots.

const PATH = "user://preparation.cfg"
## The rules are data: data/spells.json "preparation" (slots, activation_levels, default_kit) and
## each spell's "preparable" / "opens_kit".
static var _data: Dictionary = _load()
static var SLOTS: int = int(_data.preparation.get("slots", 6))
static var ACTIVATION_LEVELS: Array = _data.preparation.get("activation_levels", []).map(func(l): return int(l))
## Slot 1 is your only spell until level 2, so it has to be able to kill things (opens_kit false).
static var NON_ATTACK: Array = _data.spells.keys().filter(func(id): return _data.spells[id].get("opens_kit", true) == false)
static var DEFAULT_SLOTS: Array = _data.preparation.get("default_kit", [])

static func _load() -> Dictionary:
	var parsed = preload("res://scripts/core/GameData.gd").file("spells")
	if not parsed is Dictionary:
		return {"spells": {}, "preparation": {}}
	return {"spells": parsed.get("spells", {}), "preparation": parsed.get("preparation", {})}

static var slots: Array = []

static func base_ids() -> Array:
	return load("res://scripts/SpellManager.gd").BASE_SPELL_IDS

## The saved kit, sanitized. "" marks an empty slot.
static func load_slots() -> Array:
	if slots.is_empty():
		var config = ConfigFile.new()
		var saved = DEFAULT_SLOTS
		if config.load(PATH) == OK:
			saved = config.get_value("spellbook", "slots", DEFAULT_SLOTS)
		slots = sanitize(saved)
	return slots.duplicate()

static func save_slots(new_slots: Array):
	slots = sanitize(new_slots)
	var config = ConfigFile.new()
	config.load(PATH)
	config.set_value("spellbook", "slots", slots)
	config.save(PATH)

## Six entries, known base spells only, no duplicates, attack in slot 1 (falls back to Bolt).
static func sanitize(raw: Array) -> Array:
	var ids = base_ids()
	var result: Array = []
	for i in SLOTS:
		var id = str(raw[i]) if i < raw.size() else ""
		if id not in ids or id in result:
			id = ""
		result.append(id)
	if not can_start(result[0]):
		var bolt_at = result.find("bolt")
		if bolt_at > 0:
			result[bolt_at] = result[0]
		result[0] = "bolt"
	return result

static func can_start(id: String) -> bool:
	return id in base_ids() and id not in NON_ATTACK

## Index of the prepared slot that opens at this level, or -1.
static func slot_for_level(level: int) -> int:
	return ACTIVATION_LEVELS.find(level)
