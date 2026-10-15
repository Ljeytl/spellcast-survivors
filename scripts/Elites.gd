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

## `count` distinct random word ids, at most `max_words` (data). Elemental words exclude each other
## (one element per monster).
static func roll(count: int, rng: RandomNumberGenerator = null) -> Array:
	count = mini(count, int(data().get("max_words", count)))
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
		"element": "", "heal_per_hit": 0.0, "tint": base.get("tint", [1, 1, 1]), "casts": [], "contact_statuses": [], "resist_profile": "", "color": ""}
	var labels: Array = []
	for mods in [base] + word_ids.map(func(id): return data().words.get(id, {})):
		for key in ["health_mult", "damage_mult", "size_mult", "speed_mult", "xp_mult"]:
			out[key] *= float(mods.get(key, 1.0))
		if mods.has("element"):
			out.element = str(mods.element)
		out.heal_per_hit += float(mods.get("heal_per_hit", 0.0))
		if mods.has("color"):
			out.color = str(mods.color)
		if mods.has("cast"):
			var cfg: Dictionary = mods.cast.duplicate()
			if mods.has("color"):
				cfg.color = str(mods.color)
			out.casts.append(cfg)
		if mods.has("contact_status"):
			out.contact_statuses.append(str(mods.contact_status))
		if mods.has("resist_profile"):
			out.resist_profile = str(mods.resist_profile)
		if mods.has("word"):
			labels.append(str(mods.word))
	out.label = " ".join(labels)
	out.name = (out.label + " " + monster_name).strip_edges()
	return out

## An elite casts one of its word spells (data/spells/elite_*.json) at the player through the same
## spell engine the player uses: the monster is the caster, the player the target. Damage scales with
## the monster's own contact damage. Returns the cast.
static func cast(monster: Node2D, cfg: Dictionary, target: Node2D):
	var Template = preload("res://scripts/engine/SpellTemplate.gd")
	var spell = str(cfg.get("spell", ""))
	if not Template.has_shape(spell) or not is_instance_valid(target):
		return null
	var damage = float(monster.get("base_damage")) * float(cfg.get("damage_mult", 1.0))
	var info = {"id": spell, "name": spell, "range": float(cfg.get("range", 500.0)), "level": 1}
	var plan = preload("res://scripts/engine/CastPlanner.gd").plan(Template.build(info, damage, {"speed_mult": 1.0}), {}, {})
	# Windup: the elite visibly charges (the same anticipation glow a charged wizard cast gets) before
	# the spell leaves, so even a thrown spell is telegraphed. Hostile colour: the word's colour,
	# used for the telegraph so a monster's spell never reads as one of yours.
	var windup = float(cfg.get("windup", 0.0))
	if windup > 0.0 and not plan.get("casts", []).is_empty():
		plan.casts[0].delay = float(plan.casts[0].delay) + windup
		plan.flags["charged"] = {}
	if str(cfg.get("color", "")) != "":
		plan.hostile_color = str(cfg.color)
	var c = preload("res://scripts/engine/GenericCast.gd").new()
	c.name = "EliteCast_" + spell
	c.forced_target = target
	var source = {"spell": spell, "hostile": true}
	c.setup(plan, monster, monster.get_parent(), source)
	monster.get_parent().add_child(c)
	c.step(0.0)
	return c
