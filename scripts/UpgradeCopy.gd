extends RefCounted

## Short spell descriptions are data now (presentation.summary in data/spells.json / recipes.json).
static func summary(id: String) -> String:
	return preload("res://scripts/engine/SpellCatalog.gd").summary(id)

static func number(value: float) -> String:
	return ("%.2f" % value).trim_suffix("0").trim_suffix("0").trim_suffix(".")

static func description(upgrade: Dictionary, manager: Node) -> String:
	var effect = upgrade.get("effect", {})
	var id = str(effect.get("spell", ""))
	var value = float(effect.get("value", 0))
	match effect.get("type", ""):
		"learn_spell":
			var text = summary(id)
			return text if text != "" else "Learn a new spell."
		"spell_damage":
			return "Gain %s%% spell power." % number(value * 100)
		"cast_speed":
			return "Gain %s%% Magic Missile attack speed." % number(value * 100)
		"spell_area":
			return "Gain %s%% spell size." % number(value * 100)
		"projectile_speed":
			return "Spells travel and turn %s%% faster." % number(value * 100)
		"spell_duration":
			return "Effects last %s%% longer." % number(value * 100)
		"slowdown_duration":
			return "Gain %s seconds of slowdown per cast." % number(value)
		"mana_bolt_mastery":
			return "Strengthen your automatic Magic Missile and fire it faster."
		"movement_speed":
			return "Gain %s%% movement speed." % number(value * 100)
		"max_health":
			return "Gain %s maximum health and heal by the same amount." % number(value)
		"xp_range":
			return "Gain %s%% pickup range." % number(value * 100)
		"spell_upgrade":
			return rank_description(id, manager)
	return str(upgrade.get("description", "")).split("\n")[0]

static func rank_description(id: String, manager: Node) -> String:
	return manager.rank_change_summary(id)
