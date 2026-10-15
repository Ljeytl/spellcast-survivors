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

## The keyword to suggest for an unknown word: a listed noun ("fire" -> fiery), else the closest
## keyword within two letters of it.
static func suggestion(word: String) -> String:
	var listed: Dictionary = data().get("suggest", {})
	if listed.has(word):
		return str(listed[word])
	var best := ""
	var best_d := 3
	for w in data().get("words", {}):
		var d := _distance(word, str(w))
		if d < best_d:
			best_d = d
			best = str(w)
	return best

static func _distance(a: String, b: String) -> int:
	if absi(a.length() - b.length()) > 2:
		return 99
	var prev: Array = range(b.length() + 1)
	for i in a.length():
		var cur: Array = [i + 1]
		for j in b.length():
			cur.append(mini(mini(cur[j] + 1, prev[j + 1] + 1), prev[j] + (0 if a[i] == b[j] else 1)))
		prev = cur
	return prev[b.length()]

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
	var aliases: Dictionary = data().get("aliases", {})
	for w in text.strip_edges().to_lower().split(" ", false):
		words.append(str(aliases.get(w, w)))
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
		var hint := suggestion(str(result.unknown[0]))
		if hint != "":
			result.error += " - try " + hint.to_upper()
	return result

## QUICK: the spell by its initials ("quick es") or by word starts ("quick em s", "quick lig")
## when initials are shared (Ember Spear / Earth Shield, Life / Lightning).
static func quick_match(rest: Array, name: String) -> bool:
	var parts = name.to_lower().split(" ", false)
	if rest.size() == 1:
		var key := ""
		for part in parts:
			key += part.substr(0, 1)
		if key == str(rest[0]):
			return true
	if rest.size() != parts.size():
		return false
	for k in parts.size():
		if not str(parts[k]).begins_with(str(rest[k])):
			return false
	return true

static func _parse_quick(rest: Array, spell_names: Array, result: Dictionary) -> Dictionary:
	var matches := []
	for name in spell_names:
		if quick_match(rest, str(name)) and not matches.has(str(name).to_lower()):
			matches.append(str(name).to_lower())
	result.quick = true
	if matches.size() == 1:
		result.ok = true
		result.spell = matches[0]
		result.bundle.power = float(data().get("quick", {}).get("power", 0.35))
	else:
		result.error = "no spell has those initials" if matches.is_empty() else "initials match more than one spell - type more letters"
	return result

static func empty_bundle() -> Dictionary:
	return {"power": 1.0, "size": 1.0, "charge": 0.0, "copies": 1, "per_copy": 1.0, "flags": {}, "elements": [], "heal": 0.0, "arrangement": "", "words": {}}

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

## A size word's bonus: size_per_letter for the first `ramp_after` letters, then every further
## letter adds `size_ramp` more than the one before (BIG +21%, LARGE +42%, MASSIVE +67%, GIGANTIC +81%),
## so each extra letter feels like a jump.
static func size_bonus(n: int) -> float:
	var c: Dictionary = data().get("categories", {}).get("size", {})
	var per := float(c.get("size_per_letter", 0.07))
	var ramp := float(c.get("size_ramp", 0.0))
	var after := int(c.get("ramp_after", 3))
	var total := 0.0
	for k in range(1, n + 1):
		total += per + (ramp * (k - 1) if k > after else 0.0)
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
		s_only.append(1.0 + size_bonus(w.length()))
	b.power = tier_power * _stack(p_only)
	b.size = tier_size * _stack(s_only)
	for w in by_category.get("count", []):
		b.copies = int(defs[w].copies)
		b.per_copy = float(defs[w].per_copy)
	for w in by_category.get("arrangement", []):
		b.arrangement = str(defs[w].arrangement)
	for cat in ["twin", "motion", "duration", "timing", "contact", "force", "target", "self", "sacrifice", "wild", "payoff"]:
		for w in by_category.get(cat, []):
			var flag = str(defs[w].get("flag", w))
			b.flags[flag] = defs[w].duplicate()
	# Element words (doc 21 §4.2): each word's tier sets its damage share and effect strength per
	# letter; repeats of one element stack with diminishing returns, damage and effect separately.
	# Healing words (HEALING, BLOOMING) put their effect into a healing budget instead (doc 21 §4.3).
	var per_element := {}
	var heals := []
	for w in by_category.get("element", []):
		var e = str(defs[w].element)
		var tier: Dictionary = word_tier(w)
		if not per_element.has(e):
			per_element[e] = {"share": [], "effect": []}
		per_element[e].share.append(float(tier.share_per_letter) * w.length())
		if str(defs[w].get("effect", "")) == "healing":
			heals.append(float(tier.effect_per_letter) * w.length())
		else:
			per_element[e].effect.append(float(tier.effect_per_letter) * w.length())
	b.heal = _diminished(heals)
	for e in per_element:
		b.elements.append({"element": e, "share": _diminished(per_element[e].share), "effect": _diminished(per_element[e].effect),
			"status": str(data().get("element_status", {}).get(e, ""))})
	for cat in by_category:
		for w in by_category[cat]:
			b.words[w] = cat
	return b

## An element word's tier numbers, {share_per_letter, effect_per_letter} (data/keywords.json).
static func word_tier(word: String) -> Dictionary:
	var tiers: Dictionary = data().categories.element.tiers
	return tiers.get(str(data().words.get(word, {}).get("tier", "damage")), tiers.damage)

## Largest first at full weight, each next one weaker (data/keywords.json "diminishing").
static func _diminished(values: Array) -> float:
	var sorted = values.duplicate()
	sorted.sort()
	sorted.reverse()
	var w8 = _weights()
	var total = 0.0
	for i in sorted.size():
		total += float(sorted[i]) * float(w8[mini(i, w8.size() - 1)])
	return total
