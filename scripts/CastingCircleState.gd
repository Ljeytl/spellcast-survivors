extends RefCounted
## Pure logic behind the casting circle: what the circle should show for the text typed so far.
## Rules: rings fill at 3 / 6 / 9 runes; spaces inside a spell take a rune slot, leading and
## trailing spaces do not; power words ("mega ") are split off as satellites; the colour locks
## once every spell that still fits shares one element, and ghost runes appear once one spell fits.

const RUNES_PER_RING = 3

## spells: Array of {"incantation": String, "element": String}
## power_words: Array of String (e.g. ["mega"])
static func analyze(text: String, spells: Array, power_words: Array) -> Dictionary:
	var rest = text.to_lower().replace("_", " ")
	rest = rest.lstrip(" ")
	var mods: Array = []
	var progressed = true
	while progressed:
		progressed = false
		for word in power_words:
			if rest.begins_with(str(word) + " "):
				mods.append(str(word))
				rest = rest.substr(str(word).length() + 1).lstrip(" ")
				progressed = true
				break
	var body = rest
	var spell_candidates: Array = []
	for spell in spells:
		if str(spell.incantation).begins_with(body):
			spell_candidates.append(spell)
	var power_candidates: Array = []
	if not body.is_empty():
		for word in power_words:
			if (str(word) + " ").begins_with(body):
				power_candidates.append(str(word))
	var elements: Dictionary = {}
	for spell in spell_candidates:
		elements[str(spell.get("element", "arcane"))] = true
	var element = ""
	if not body.is_empty() and power_candidates.is_empty() and elements.size() == 1:
		element = str(elements.keys()[0])
	var locked: Dictionary = {}
	if not body.is_empty() and power_candidates.is_empty() and spell_candidates.size() == 1:
		locked = spell_candidates[0]
	var runes = body.rstrip(" ")
	var total = str(locked.incantation).length() if not locked.is_empty() else runes.length()
	return {
		"power_words": mods,
		"runes": runes,
		"rune_count": runes.length(),
		"valid": body.is_empty() or not spell_candidates.is_empty() or not power_candidates.is_empty(),
		"forming_power_word": not body.is_empty() and spell_candidates.is_empty() and not power_candidates.is_empty(),
		# The power word being formed, once it is the only one that fits (for its ghost runes).
		"power_word": power_candidates[0] if power_candidates.size() == 1 and spell_candidates.is_empty() else "",
		"element": element,
		"spell": str(locked.incantation) if not locked.is_empty() else "",
		"total_runes": total,
		"full_rings": runes.length() / RUNES_PER_RING,
		"partial": runes.length() % RUNES_PER_RING,
		"ring_count": ceili(float(total) / RUNES_PER_RING),
		"complete": not locked.is_empty() and runes == str(locked.incantation),
		"candidates": spell_candidates.map(func(s): return str(s.incantation)),
	}

static func ring_of(index: int) -> int:
	return index / RUNES_PER_RING
