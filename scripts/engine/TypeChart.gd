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
