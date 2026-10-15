extends RefCounted
## Element type chart (doc 18 §6.5): Storm > Water/Ice > Fire > Plague/Death > Life > Earth/Steel > Storm.
## Arcane and raw are neutral. Only enemies carry an element; the chart compares the attacking
## element with the enemy's element.

const CYCLE = ["storm", "water", "fire", "plague", "life", "earth"]
const STRONG = 1.25
const SAME = 0.75

## Maps legacy element names in spells.json onto the seven elements.
const ALIASES = {"ice": "water", "steel": "earth", "spirit": "plague", "death": "plague", "holy": "life", "lightning": "storm"}

static func normalize(element: String) -> String:
	var e = element.strip_edges().to_lower()
	return ALIASES.get(e, e)

static func beats(attacker: String) -> String:
	var a = normalize(attacker)
	var i = CYCLE.find(a)
	return "" if i < 0 else CYCLE[(i + 1) % CYCLE.size()]

static func multiplier(attacker: String, defender: String) -> float:
	var a = normalize(attacker)
	var d = normalize(defender)
	if a == "" or d == "" or a == "raw" or a == "arcane" or d == "arcane":
		return 1.0
	if a == d:
		return SAME
	if beats(a) == d:
		return STRONG
	return 1.0

## Player-facing names and colours for each element (doc 18 §6.1 colour families).
const NAMES = {"arcane": "Arcane", "fire": "Fire", "water": "Water/Ice", "storm": "Storm", "earth": "Earth/Steel", "plague": "Plague/Death", "life": "Life", "raw": "Raw", "bleed": "Bleed", "pure": "Pure"}
const COLORS = {"arcane": Color("b58cff"), "fire": Color("ff9a5a"), "water": Color("8ce6ee"), "storm": Color("f4ed96"), "earth": Color("d8b979"), "plague": Color("a8c46a"), "life": Color("91de83")}

static func display_name(element: String) -> String:
	var e = normalize(element)
	return str(NAMES.get(e, e.capitalize()))

static func color(element: String) -> Color:
	return COLORS.get(normalize(element), Color("eee8d8"))

## The element this one loses to, or "".
static func beaten_by(element: String) -> String:
	var e = normalize(element)
	for other in CYCLE:
		if beats(other) == e:
			return other
	return ""

## "Fire · strong vs Plague/Death, weak to Water/Ice" (Arcane: neutral to everything).
static func matchup_line(element: String) -> String:
	var e = normalize(element)
	if e == "arcane":
		return "Arcane · neutral to every element"
	if e not in CYCLE:
		return ""
	return "%s · strong vs %s, weak to %s" % [display_name(e), display_name(beats(e)), display_name(beaten_by(e))]
