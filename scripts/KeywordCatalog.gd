extends RefCounted
## Player-facing keyword text, built from data/keywords.json so the Necronomicon never drifts from
## the numbers the parser uses. Words marked "planned" are left out.

const KP = preload("res://scripts/engine/KeywordParser.gd")
const TYPE_CHART = preload("res://scripts/engine/TypeChart.gd")
const STATUS_TEXT = {"vulnerable": "makes enemies vulnerable", "burn": "burns", "chilled": "chills", "shocked": "shocks",
	"bleed": "makes enemies bleed", "poison": "poisons", "entangled": "entangles"}

## Categories in display order: [{id, name, promise, words: [word...]}] (elements excluded; see elements()).
static func categories() -> Array:
	var data = KP.data()
	var cats: Dictionary = data.get("categories", {})
	var out: Array = []
	for id in cats:
		if id == "element":
			continue
		var words = live_words(id)
		if words.is_empty():
			continue
		out.append({"id": id, "name": str(cats[id].get("name", id.capitalize())), "promise": str(cats[id].get("promise", "")), "order": float(cats[id].get("order", 99)), "words": words})
	out.sort_custom(func(a, b): return a.order < b.order)
	return out

## Element words grouped by element, weakest first: [{element, name, words, status}].
static func elements() -> Array:
	var words: Dictionary = KP.data().get("words", {})
	var by := {}
	for w in live_words("element"):
		var e = str(words[w].element)
		if not by.has(e):
			by[e] = []
		by[e].append(w)
	var out: Array = []
	for e in ["arcane"] + Array(TYPE_CHART.CYCLE):
		if by.has(e):
			out.append({"element": e, "name": TYPE_CHART.display_name(e), "words": by[e], "status": str(KP.data().get("element_status", {}).get(e, ""))})
	return out

static func element_promise() -> String:
	return str(KP.data().get("categories", {}).get("element", {}).get("promise", ""))

## Words of a category that are built, weakest (shortest) first.
static func live_words(category: String) -> Array:
	var words: Dictionary = KP.data().get("words", {})
	var out: Array = words.keys().filter(func(w): return str(words[w].category) == category and not bool(words[w].get("planned", false)))
	out.sort_custom(func(a, b): return a.length() < b.length() if a.length() != b.length() else a < b)
	return out

static func pct(x: float) -> String:
	return "%d%%" % int(round(x * 100.0))

## One line per word with its numbers, e.g. "TRIPLE: 3 copies, 45% each".
static func word_line(word: String) -> String:
	var data = KP.data()
	var w: Dictionary = data.words[word]
	var c: Dictionary = data.categories.get(str(w.category), {})
	var n = word.length()
	var text := ""
	match str(w.category):
		"tier": text = "+%s power and size, %.2f s wind-up" % [pct(float(c.power_per_letter) * n), float(c.charge_base) + float(c.charge_per_letter) * maxi(0, n - 4)]
		"power": text = "+%s power" % pct(float(c.power_per_letter) * n)
		"size": text = "+%s size" % pct(float(c.size_per_letter) * n)
		"count": text = "%d copies, %s each" % [int(w.copies), pct(float(w.per_copy))]
		"twin": text = "a second cast %.2f s later at %s" % [float(w.delay), pct(float(w.power))]
		"duration": text = "lasts %s longer" % pct(float(w.duration) - 1.0)
		"sacrifice":
			text = "costs %s of your max health, ×%s power" % [pct(float(w.health_cost)), str(w.power)]
			if w.has("adds"):
				text += ", +%s %s damage%s" % [pct(float(w.adds.share)), str(w.adds.damage_type), (" and " + str(STATUS_TEXT.get(str(w.adds.get("status", "")), ""))) if str(w.adds.get("status", "")) != "" else ""]
		"element":
			var e = str(w.element)
			text = "+%s %s damage, %s" % [pct(float(c.share_per_letter) * n), TYPE_CHART.display_name(e), STATUS_TEXT.get(str(data.get("element_status", {}).get(e, "")), "")]
		_:
			match str(w.get("flag", word)):
				"homing": text = "steers toward enemies"
				"swift": text = "%s faster" % pct(float(w.speed) - 1.0)
				"orbiting": text = "circles you, then launches at enemies within %d" % int(w.range)
				"repeating": text = "an echo %.1f s later at %s" % [float(w.delay), pct(float(w.power))]
				"delayed": text = "waits %.1f s, then hits %s harder" % [float(w.delay), pct(float(w.power) - 1.0)]
				"charged": text = "%.1f s wind-up, ×%s power" % [float(w.delay), str(w.power)]
				"piercing": text = "goes through %d more enemies at %s" % [int(w.pierce), pct(float(w.power))]
				"splitting": text = "breaks into %d copies at %s on the first hit" % [int(w.copies), pct(float(w.power))]
				"chaining": text = "hops %d times between enemies at %s" % [int(w.hops), pct(float(w.power))]
				"exploding": text = "hits burst for %s" % pct(float(w.power))
				"cascading": text = "a kill spawns a copy at %s" % pct(float(w.power))
				"pulling": text = "drags enemies in"
				"repulsing": text = "shoves enemies away"
				"hunting": text = "aims at the toughest enemy (elites first)"
				"scattered": text = "copies take different targets"
				"blinking": text = "short teleport (%d) as you cast" % int(w.distance)
				"chaotic": text = "a random element each cast"
				_: text = ""
	if str(w.get("arrangement", "")) != "":
		text = "copies in a %s" % ("ring" if str(w.arrangement) == "ring" else "row")
	return "%s: %s" % [word.to_upper(), text] if text != "" else word.to_upper()
