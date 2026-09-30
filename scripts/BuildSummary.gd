extends RefCounted
## Player-facing totals for the current run build: passive totals and each spell's
## present numbers. Shared by the HUD inventory and the run spellbook so both agree.

const PROGRESSION = preload("res://scripts/SpellProgression.gd")
const COMBINATIONS = preload("res://scripts/CombinationScaling.gd")
const RECIPES = preload("res://scripts/SynergyCatalog.gd").RECIPES
const KEYWORDS = preload("res://scripts/KeywordRules.gd")

const PASSIVE_NAMES = {"spell_damage": "Spell Power", "spell_area": "Spell Size", "spell_duration": "Spell Duration", "projectile_speed": "Velocity", "movement_speed": "Move Speed", "max_health": "Max Health", "xp_range": "Pickup Range", "slowdown_duration": "Focus", "mana_bolt_mastery": "Missile Mastery"}
const PASSIVE_SHORT_NAMES = {"spell_damage": "Power", "spell_area": "Size", "spell_duration": "Duration", "projectile_speed": "Velocity", "movement_speed": "Speed", "max_health": "HP", "xp_range": "Pickup", "slowdown_duration": "Focus", "mana_bolt_mastery": "Missile"}
const PASSIVE_EFFECTS = {"spell_damage": "damage, healing and protection", "spell_area": "spell size", "spell_duration": "active spell duration", "projectile_speed": "spell travel and turning speed", "movement_speed": "movement speed", "max_health": "maximum health", "xp_range": "pickup range", "slowdown_duration": "slowed time per cast"}
const LASTING_TYPES = ["field", "orbit", "trail", "plague", "heal_over_time", "shield", "beam", "spirit"]
const COUNTS = {"projectile_count": "projectiles", "meteor_count": "meteors", "blade_count": "blades", "bounce_count": "bounces", "orb_count": "sparks"}

static func passive_name(family: String) -> String:
	return PASSIVE_NAMES.get(family, family.replace("_", " ").capitalize())

static func passive_short_name(family: String) -> String:
	return PASSIVE_SHORT_NAMES.get(family, passive_name(family))

static func per_rank(data: Node, family: String) -> float:
	var upgrades = data.get_generic_upgrades() if data and data.has_method("get_generic_upgrades") else {}
	for key in upgrades:
		var effect = upgrades[key].get("effect", {})
		if effect.get("type", "") == family:
			return float(effect.get("value", 0.0))
	return 0.0

## Short total shown on the HUD chip, e.g. "+20%", "+30", "+1.0s".
static func passive_total(data: Node, family: String, rank: int) -> String:
	var value = per_rank(data, family) * rank
	match family:
		"mana_bolt_mastery":
			return "Lv.%d" % rank
		"max_health":
			return "+%d" % int(round(value))
		"slowdown_duration":
			return "+%.1fs" % value
	if value == 0.0:
		return "Lv.%d" % rank
	return "+%d%%" % int(round(value * 100.0))

## Full sentence for tooltips and the spellbook.
static func passive_detail(data: Node, family: String, rank: int) -> String:
	if family == "mana_bolt_mastery":
		var missiles = 1 + [3, 6, 10].filter(func(step): return rank >= step).size()
		return "+%d%% Magic Missile damage, +%d%% attack rate, %d missile%s" % [15 * rank, 10 * rank, missiles, "" if missiles == 1 else "s"]
	var total = passive_total(data, family, rank)
	if not PASSIVE_EFFECTS.has(family):
		return total
	return "%s %s" % [total, PASSIVE_EFFECTS[family]]

static func number(value: float) -> String:
	return str(int(round(value))) if absf(value - round(value)) < 0.05 else "%.1f" % value

## One line describing what an owned spell does right now, with every rank and passive applied.
static func spell_now(manager: Node, player: Node, raw: Dictionary) -> String:
	if raw.is_empty():
		return ""
	var id = str(raw.get("id", ""))
	var level = int(raw.get("level", 1))
	var power = maxf(0.0, float(player.spell_damage_multiplier))
	var info = PROGRESSION.resolve(raw)
	var rank_multiplier = 1.0 + 0.15 * (level - 1)
	var parts: Array[String] = []
	if RECIPES.has(id):
		info = COMBINATIONS.resolve(info, manager.get_combination_ingredient_ranks(id))
		if float(info.get("damage", 0)) > 0:
			parts.append("%s damage" % number(float(info.damage) * power))
	elif float(raw.get("damage", 0)) > 0:
		parts.append("%s damage" % number(float(raw.damage) * (1.0 if raw.has("rank_steps") else rank_multiplier) * power))
	for key in ["splash_damage", "explosion_damage"]:
		if info.has(key):
			parts.append("%s blast" % number(float(info[key]) * power))
	if float(raw.get("heal_amount", 0)) > 0:
		var heal = float(raw.heal_amount) * rank_multiplier * power
		parts.append(("heals %s per second" if raw.get("type", "") == "heal_over_time" else "heals %s") % number(heal))
	for key in ["healing_seed_amount", "healing_bloom_amount"]:
		if info.has(key):
			parts.append("heals %s" % number(float(info[key]) * power))
	if raw.has("retaliation_damage"):
		parts.append("%s retaliation damage" % number(float(raw.retaliation_damage) * rank_multiplier * power))
	for key in COUNTS:
		if int(info.get(key, 0)) > 1:
			parts.append("%d %s" % [int(info[key]), COUNTS[key]])
	if str(info.get("type", "")) in LASTING_TYPES and float(info.get("duration", 0)) > 0:
		parts.append("lasts %ss" % number(float(info.duration) * maxf(1.0, float(player.spell_duration_multiplier))))
	return " · ".join(parts)

## Build-wide modifiers that apply to every manual cast, as readable lines.
static func global_lines(data: Node, player: Node) -> Array[String]:
	var lines: Array[String] = []
	var families = player.passive_ranks.keys()
	families.sort()
	for family in families:
		var rank = int(player.passive_ranks[family])
		lines.append("%s · Rank %d · %s" % [passive_name(family), rank, passive_detail(data, family, rank)])
	return lines

static func keyword_line(word: String) -> String:
	var rule = KEYWORDS.DEFINITIONS.get(word, {})
	if rule.is_empty():
		return ""
	return "%s · +%d%% power, +%d%% size" % [word.to_upper(), int(round((float(rule.get("power", 1.0)) - 1.0) * 100.0)), int(round((float(rule.get("size", 1.0)) - 1.0) * 100.0))]
