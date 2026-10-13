extends RefCounted
## Typed damage for the shipping spells (doc 18 §6.1). A spell hit arrives as one number; this splits it
## into damage-type entries from data/spell_damage.json and names the spell's element for the type chart.
## Unknown sources (enemy contact, props) are plain raw damage.

const TypeChart = preload("res://scripts/engine/TypeChart.gd")
const TABLE_PATH = "res://data/spell_damage.json"
const SPELLS_PATH = "res://data/spells.json"
const RESISTANCES_PATH = "res://data/resistances.json"

static var _table: Dictionary = {}
static var _elements: Dictionary = {}
static var _resistances: Dictionary = {}

static func _read(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

static func _load():
	if not _table.is_empty():
		return
	_table = _read(TABLE_PATH).get("spells", {})
	var spells: Dictionary = _read(SPELLS_PATH).get("spells", {})
	for id in spells:
		_elements[id] = TypeChart.normalize(str(spells[id].get("element", "")))

## {element, damage: {type: share}, statuses: [{status, part?, strength?}]}
static func profile(spell_id: String) -> Dictionary:
	_load()
	var row: Dictionary = _table.get(spell_id, {})
	var element = TypeChart.normalize(str(row.get("element", _elements.get(spell_id, ""))))
	var mix: Dictionary = row.get("damage", {})
	if mix.is_empty():
		mix = {"raw": 1.0} if element == "" else {element: 1.0}
	var statuses: Array = row.get("statuses", [])
	return {"element": element, "damage": mix, "statuses": statuses}

## Statuses a hit of this spell applies; a rule with a part only matches hits tagged with that part.
static func statuses_for(spell_id: String, part: String) -> Array:
	var matched: Array = []
	for rule in profile(spell_id).statuses:
		if str(rule.get("part", "")) == "" or str(rule.get("part", "")) == part:
			matched.append(rule)
	return matched

const STATUS_WORDS = {"burn": "burns", "bleed": "bleeds", "chilled": "chills", "shocked": "shocks"}

## "bleeds", "trail burns", "chills".
static func status_line(spell_id: String) -> String:
	var parts: Array[String] = []
	for rule in profile(spell_id).statuses:
		var word = str(STATUS_WORDS.get(str(rule.status), str(rule.status)))
		parts.append((str(rule.part) + " " + word) if str(rule.get("part", "")) != "" else word)
	return ", ".join(parts)

## Effect for Effects.resolve_damage / apply. Raw shares read the spell's element on the type chart;
## elemental shares read their own element (so Steam Field's water share beats fire enemies).
static func effect(amount: float, spell_id: String) -> Dictionary:
	var p = profile(spell_id)
	var entries: Array = []
	for kind in p.damage:
		var type = TypeChart.normalize(str(kind))
		entries.append({"amount": amount * float(p.damage[kind]), "damage_type": type, "chart_element": p.element if type == "raw" else type})
	return {"type": "damage", "entries": entries, "element": p.element if p.element != "" else "raw", "hit": amount}

## Named resistance profile from data/resistances.json, e.g. "elite_armored".
static func resistance_profile(id: String) -> Dictionary:
	if _resistances.is_empty():
		_resistances = _read(RESISTANCES_PATH)
	var found = _resistances.get(id, {})
	return found.duplicate() if found is Dictionary else {}

## True for spells with an authored damage mix (heals like Life have none).
static func deals_damage(spell_id: String) -> bool:
	_load()
	return _table.has(spell_id)

## "75% raw · 25% Fire", for the Necronomicon and preparation screen. Empty for heals.
static func mix_line(spell_id: String) -> String:
	if not deals_damage(spell_id):
		return ""
	var p = profile(spell_id)
	var parts: Array[String] = []
	var kinds = p.damage.keys()
	kinds.sort_custom(func(a, b): return float(p.damage[a]) > float(p.damage[b]))
	for kind in kinds:
		var share = int(round(float(p.damage[kind]) * 100.0))
		parts.append("%d%% %s" % [share, TypeChart.display_name(str(kind)) if str(kind) != "raw" else "raw"])
	var line = " · ".join(parts)
	var statuses = status_line(spell_id)
	if not statuses.is_empty():
		line += " · " + statuses
	return line

## Element and damage lines shown under a spell in menus.
static func describe(spell_id: String) -> String:
	var element = profile(spell_id).element
	var lines: Array[String] = []
	var matchup = TypeChart.matchup_line(element)
	if not matchup.is_empty():
		lines.append(matchup)
	var mix = mix_line(spell_id)
	if not mix.is_empty():
		lines.append("Damage: " + mix)
	return "\n".join(lines)
