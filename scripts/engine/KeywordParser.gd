extends RefCounted
## Parses an incantation into a spell name plus keywords (doc 18 §8.2).
## Rules: keywords are adjectives; free word order; the longest known spell name wins; longer synonyms are
## stronger (per-letter values); same-category words stack with diminishing returns; a word twice is rejected;
## exclusive categories take one word; `quick` + initials casts a weak version with no keywords.

const DATA_PATH = "res://data/keywords.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		var file = FileAccess.open(DATA_PATH, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				_data = parsed
	return _data

static func is_keyword(word: String) -> bool:
	return data().get("words", {}).has(word.to_lower())

static func words_in(category: String) -> Array:
	var out := []
	var words: Dictionary = data().get("words", {})
	for w in words:
		if str(words[w].category) == category:
			out.append(w)
	return out

## spell_names: lowercase incantations the caster could mean (legacy and generic).
static func parse(text: String, spell_names: Array) -> Dictionary:
	var result := {"ok": false, "spell": "", "quick": false, "keywords": [], "unknown": [], "rejected": [], "bundle": empty_bundle(), "error": ""}
	var words: Array = []
	for w in text.strip_edges().to_lower().split(" ", false):
		words.append(w)
	if words.is_empty():
		result.error = "empty"
		return result
	var quick_word = str(data().get("quick", {}).get("word", "quick"))
	if words[0] == quick_word and words.size() >= 2:
		return _parse_quick(words.slice(1), spell_names, result)
	# Longest spell name found as a contiguous run of words.
	var best := ""
	var best_start := -1
	var best_len := 0
	for name in spell_names:
		var parts = str(name).to_lower().split(" ", false)
		if parts.is_empty():
			continue
		for start in range(0, words.size() - parts.size() + 1):
			var match_ok = true
			for k in parts.size():
				if words[start + k] != parts[k]:
					match_ok = false
					break
			if match_ok and (parts.size() > best_len or (parts.size() == best_len and str(name).length() > best.length())):
				best = str(name).to_lower()
				best_start = start
				best_len = parts.size()
	if best == "":
		result.error = "no spell"
		return result
	result.spell = best
	var seen := {}
	var categories_used := {}
	var by_category := {}
	var defs: Dictionary = data().get("words", {})
	var cats: Dictionary = data().get("categories", {})
	for i in words.size():
		if i >= best_start and i < best_start + best_len:
			continue
		var w: String = words[i]
		if not defs.has(w):
			result.unknown.append(w)
			continue
		if seen.has(w):
			result.rejected.append({"word": w, "reason": "used twice"})
			continue
		seen[w] = true
		var d: Dictionary = defs[w]
		var cat = str(d.category)
		if bool(cats.get(cat, {}).get("exclusive", false)) and categories_used.has(cat):
			result.rejected.append({"word": w, "reason": "only one " + cat + " word"})
			continue
		categories_used[cat] = true
		result.keywords.append(w)
		if not by_category.has(cat):
			by_category[cat] = []
		by_category[cat].append(w)
	result.bundle = build_bundle(by_category)
	result.ok = result.unknown.is_empty()
	if not result.ok:
		result.error = "unknown word: " + str(result.unknown[0])
	return result

static func _parse_quick(rest: Array, spell_names: Array, result: Dictionary) -> Dictionary:
	var initials = "".join(rest)
	var matches := []
	for name in spell_names:
		var key = ""
		for part in str(name).to_lower().split(" ", false):
			key += part.substr(0, 1)
		if key == initials:
			matches.append(str(name).to_lower())
	result.quick = true
	if matches.size() == 1:
		result.ok = true
		result.spell = matches[0]
		result.bundle.power = float(data().get("quick", {}).get("power", 0.35))
	else:
		result.error = "no spell has those initials" if matches.is_empty() else "initials match more than one spell"
	return result

static func empty_bundle() -> Dictionary:
	return {"power": 1.0, "size": 1.0, "charge": 0.0, "copies": 1, "per_copy": 1.0, "flags": {}, "elements": [], "arrangement": "", "words": {}}

static func _weights() -> Array:
	return data().get("diminishing", [1.0, 0.5, 0.25, 0.125])

static func _stack(values: Array) -> float:
	# values: per-word multipliers; strongest first at full value, then halves.
	values.sort()
	values.reverse()
	var w = _weights()
	var total = 1.0
	for i in values.size():
		total *= 1.0 + (float(values[i]) - 1.0) * float(w[mini(i, w.size() - 1)])
	return total

static func build_bundle(by_category: Dictionary) -> Dictionary:
	var b = empty_bundle()
	var defs: Dictionary = data().get("words", {})
	var cats: Dictionary = data().get("categories", {})
	var powers := []
	var sizes := []
	for w in by_category.get("tier", []):
		var c = cats.tier
		powers.append(1.0 + float(c.power_per_letter) * w.length())
		sizes.append(1.0 + float(c.size_per_letter) * w.length())
		b.charge += float(c.charge_base) + float(c.charge_per_letter) * maxi(0, w.length() - 4)
	var tier_power = _stack(powers)
	var tier_size = _stack(sizes)
	var p_only := []
	for w in by_category.get("power", []):
		p_only.append(1.0 + float(cats.power.power_per_letter) * w.length())
	var s_only := []
	for w in by_category.get("size", []):
		s_only.append(1.0 + float(cats.size.size_per_letter) * w.length())
	b.power = tier_power * _stack(p_only)
	b.size = tier_size * _stack(s_only)
	for w in by_category.get("count", []):
		b.copies = int(defs[w].copies)
		b.per_copy = float(defs[w].per_copy)
	for w in by_category.get("arrangement", []):
		b.arrangement = str(defs[w].arrangement)
	for cat in ["twin", "motion", "duration", "timing", "contact", "force", "target", "self", "sacrifice", "wild"]:
		for w in by_category.get(cat, []):
			var flag = str(defs[w].get("flag", w))
			b.flags[flag] = defs[w].duplicate()
	# Element words: share by letters; repeats of one element stack with diminishing returns.
	var per_element := {}
	for w in by_category.get("element", []):
		var e = str(defs[w].element)
		if not per_element.has(e):
			per_element[e] = []
		per_element[e].append(float(cats.element.share_per_letter) * w.length())
	var w8 = _weights()
	for e in per_element:
		var shares: Array = per_element[e]
		shares.sort()
		shares.reverse()
		var share = 0.0
		for i in shares.size():
			share += float(shares[i]) * float(w8[mini(i, w8.size() - 1)])
		b.elements.append({"element": e, "share": share, "status": str(data().get("element_status", {}).get(e, ""))})
	for cat in by_category:
		for w in by_category[cat]:
			b.words[w] = cat
	return b
