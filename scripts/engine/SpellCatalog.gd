extends RefCounted
## One place to read a spell's definition by id, whether it is a base spell (data/spells.json) or a
## combination (data/recipes.json), and its presentation: the short description, cast sound, icon,
## spellbook preview and projectile scale. A spell that leaves a presentation field out gets a
## default from its element and shape, so a new spell is shown and heard without any code.

const ELEMENT_ALIASES = {"ice": "water", "steel": "earth", "spirit": "plague", "death": "plague", "holy": "life", "lightning": "storm"}
const SOUND_BY_ELEMENT = {"arcane": "SPELL_BOLT", "fire": "SPELL_IMPACT_FIRE", "water": "SPELL_ICE_BLAST", "storm": "SPELL_LIGHTNING", "earth": "SPELL_EARTHSHIELD", "plague": "SPELL_LIFE", "life": "SPELL_LIFE"}
const ICON_BY_ELEMENT = {"arcane": "mana", "fire": "flame", "water": "ice", "storm": "lightning", "earth": "stone", "plague": "plague", "life": "heal"}
const COLOR_BY_ELEMENT = {"life": "91de83", "plague": "91de83", "water": "8ce6ee", "fire": "ffa66b", "storm": "f4ed96"}
const GLYPH_BY_DELIVERY = {"projectile": "bolt", "beam": "beam", "field": "ring", "aura": "ring", "trap": "ring", "volume": "cone", "self": "cross", "infection": "bolt"}

static var _spells: Dictionary = {}
static var _recipes: Dictionary = {}

static func _load():
	if _spells.is_empty():
		var s = JSON.parse_string(FileAccess.get_file_as_string("res://data/spells.json"))
		_spells = s.get("spells", {}) if s is Dictionary else {}
		var r = JSON.parse_string(FileAccess.get_file_as_string("res://data/recipes.json"))
		_recipes = r.get("recipes", {}) if r is Dictionary else {}

## The spell's own data entry (a combination's is its recipe), or {}.
static func entry(id: String) -> Dictionary:
	_load()
	return _recipes.get(id, _spells.get(id, {}))

static func is_combination(id: String) -> bool:
	_load()
	return _recipes.has(id)

## A combination's element is its first ingredient's.
static func element(id: String) -> String:
	var e = entry(id)
	var raw = str(e.get("element", ""))
	if raw == "" and is_combination(id):
		raw = str(_spells.get(str(e.ingredients[0]), {}).get("element", ""))
	return ELEMENT_ALIASES.get(raw, raw)

static func presentation(id: String) -> Dictionary:
	return entry(id).get("presentation", {})

static func summary(id: String) -> String:
	var e = entry(id)
	return str(presentation(id).get("summary", e.get("role", e.get("card_description", ""))))

## AudioManager.SoundType name for the cast.
static func sound(id: String) -> String:
	return str(presentation(id).get("sound", SOUND_BY_ELEMENT.get(element(id), "SPELL_BOLT")))

static func sound_on_cast(id: String) -> bool:
	return bool(presentation(id).get("sound_on_cast", true))

## EffectArt motif for inventory and slot icons ("beam" draws the ray glyph).
static func icon(id: String) -> String:
	return str(presentation(id).get("icon", ICON_BY_ELEMENT.get(element(id), "rune")))

## {glyph, color} for the spellbook preview.
static func preview(id: String) -> Dictionary:
	var p: Dictionary = presentation(id).get("preview", {})
	var glyph = str(p.get("glyph", ""))
	if glyph == "":
		var shape = load("res://scripts/engine/SpellTemplate.gd").template(id)
		var root = shape.get("parts", {}).get(str(shape.get("root", "")), {})
		glyph = GLYPH_BY_DELIVERY.get(str(root.get("delivery", "")), "bolt")
	return {"glyph": glyph, "color": str(p.get("color", COLOR_BY_ELEMENT.get(element(id), "bc8fff")))}

## Hit and look size of the spell's projectiles relative to the base body (1 = unchanged).
static func projectile_scale(id: String) -> float:
	return float(presentation(id).get("projectile_scale", 1.0))
