extends RefCounted
## Pure logic behind the casting circle: what the circle should show for the text typed so far.
## Rules: rings fill at 3 / 6 / 9 runes; spaces inside a spell take a rune slot, leading and
## trailing spaces do not; power words ("mega ") are split off as satellites; the colour locks
## once every spell that still fits shares one element, and ghost runes appear once one spell fits.

const RUNES_PER_RING = 3

## spells: Array of {"incantation": String, "element": String}
## power_words: Array of String (e.g. ["mega"])
## A word that also starts a spell name ("arcane" in Arcane Orbit) stays part of the spell
## while the text still fits that spell.
static func _spell_continues(rest: String, spells: Array) -> bool:
	for spell in spells:
		var inc := str(spell.incantation)
		if inc.contains(" ") and (inc.begins_with(rest) or rest.begins_with(inc)):
			return true
	return false

const KP = preload("res://scripts/engine/KeywordParser.gd")

## While QUICK is typed: could the text still become this spell (initials or word starts)?
static func quick_fits(body: String, incantation: String) -> bool:
	var tokens: Array = Array(body.split(" ", false))
	if tokens.is_empty():
		return true
	var parts: Array = Array(incantation.split(" ", false))
	if tokens.size() == 1 and initials(incantation).begins_with(str(tokens[0])):
		return true
	if tokens.size() > parts.size():
		return false
	for k in tokens.size():
		if not str(parts[k]).begins_with(str(tokens[k])):
			return false
	return true

static func initials(incantation: String) -> String:
	var key := ""
	for part in incantation.split(" ", false):
		key += part.substr(0, 1)
	return key

static func analyze(text: String, spells: Array, power_words: Array) -> Dictionary:
	var rest = text.to_lower().replace("_", " ")
	rest = rest.lstrip(" ")
	var mods: Array = []
	var progressed = true
	while progressed:
		progressed = false
		for word in power_words:
			if rest.begins_with(str(word) + " ") and not _spell_continues(rest, spells):
				mods.append(str(word))
				rest = rest.substr(str(word).length() + 1).lstrip(" ")
				progressed = true
				break
	var body = rest
	# QUICK: the rest is the spell's initials ("quick e s" = Ember Spear).
	var quick: bool = mods.has("quick")
	var spell_candidates: Array = []
	for spell in spells:
		if (quick and quick_fits(body, str(spell.incantation))) or (not quick and str(spell.incantation).begins_with(body)):
			spell_candidates.append(spell)
	var power_candidates: Array = []
	if not body.is_empty() and not quick:
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
	var total = (initials(str(locked.incantation)).length() if quick else str(locked.incantation).length()) if not locked.is_empty() else runes.length()
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
		"complete": not locked.is_empty() and ((quick and KP.quick_match(Array(body.split(" ", false)), str(locked.incantation))) or runes == str(locked.incantation)),
		"candidates": spell_candidates.map(func(s): return str(s.incantation)),
	}

static func ring_of(index: int) -> int:
	return index / RUNES_PER_RING
