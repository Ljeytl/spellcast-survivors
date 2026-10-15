extends RefCounted
## Elites (data/elites.json): an existing monster plus words from the player's keyword vocabulary,
## each adding one trait (QUICK, MASSIVE, FIERY, LEECHING...). The monster keeps its behaviour.

const GameData = preload("res://scripts/core/GameData.gd")
const Rng = preload("res://scripts/core/Rng.gd")   # seeded: a run replays the same elites

static func data() -> Dictionary:
	return GameData.file("elites")

## Word ids that can be rolled.
static func words() -> Array:
	return data().get("words", {}).keys()

## `count` distinct random word ids. Elemental words exclude each other (one element per monster).
static func roll(count: int, rng: RandomNumberGenerator = null) -> Array:
	var pool: Array = words()
	var out: Array = []
	var has_element = false
	while out.size() < count and not pool.is_empty():
		var i = (rng if rng else Rng.stream("elites")).randi_range(0, pool.size() - 1)
		var id = pool[i]
		pool.remove_at(i)
		var is_element = data().words[id].has("element")
		if is_element and has_element:
			continue
		has_element = has_element or is_element
		out.append(id)
	return out

## How many words a patrol elite rolls at this time.
static func patrol_word_count(at_time: float) -> int:
	var count = 1
	for step in data().get("patrols", {}).get("words", []):
		if at_time >= float(step.from):
			count = int(step.count)
	return count

## Everything a monster needs to become this elite: stat multipliers, size, element, tint, name, traits.
static func build(word_ids: Array, monster_name: String) -> Dictionary:
	var base: Dictionary = data().get("base", {})
	var out := {"words": word_ids.duplicate(), "health_mult": 1.0, "damage_mult": 1.0, "size_mult": 1.0, "speed_mult": 1.0, "xp_mult": 1.0,
		"element": "", "heal_per_hit": 0.0, "tint": base.get("tint", [1, 1, 1])}
	var labels: Array = []
	for mods in [base] + word_ids.map(func(id): return data().words.get(id, {})):
		for key in ["health_mult", "damage_mult", "size_mult", "speed_mult", "xp_mult"]:
			out[key] *= float(mods.get(key, 1.0))
		if mods.has("element"):
			out.element = str(mods.element)
		out.heal_per_hit += float(mods.get("heal_per_hit", 0.0))
		if mods.has("word"):
			labels.append(str(mods.word))
	out.label = " ".join(labels)
	out.name = (out.label + " " + monster_name).strip_edges()
	return out
