extends RefCounted

const SPELLS = {
	"bolt": "Fire a bolt at a nearby enemy.",
	"life": "Restore a little health immediately.",
	"regeneration": "Restore health over time.",
	"ice_blast": "Blast a cone of enemies with ice and push them back.",
	"earth_shield": "Block one hit and erupt toward the attacker; recasts add charges.",
	"lightning": "Strike nearby enemies with an area of lightning.",
	"meteor_shower": "Rain explosive meteors onto nearby enemies.",
	"ember_spear": "Pierce a line of enemies with fire.",
	"infestation": "Infect a nearby enemy with lingering damage.",
	"cinder_field": "Burn enemies inside a lingering fire field.",
	"arcane_orbit": "Surround yourself with damaging orbiting magic.",
	"focus_ray": "Track a nearby enemy with a damaging beam.",
	"rune_trap": "Place an explosive trap ahead of you.",
	"seeker": "Summon a hunter that pursues nearby enemies.",
	"firewalk": "Leave burning tracks as you move.",
	"cross_blade": "Throw spinning blades around you that return to strike again."
}

const EVOLUTIONS = {
	"lightning_bolt": "Bounce lightning between enemies with a blast on every hit.",
	"life_bolt": "Hits plant a healing seed you can collect.",
	"meteor_spear": "Pierce enemies with explosive meteor hits.",
	"soul_bloom": "Infect enemies; their deaths leave healing blooms.",
	"steam_field": "Scald and slow enemies in a lingering steam field.",
	"prism_ray": "Carve through a line with a broad, slowly tracking laser.",
	"frost_sigil": "Place a persistent frost rune that bursts and slows enemies.",
	"reaping_spirit": "Summon a hunter with explosive kills and 25% less contact damage."
}

static func number(value: float) -> String:
	return ("%.2f" % value).trim_suffix("0").trim_suffix("0").trim_suffix(".")

static func description(upgrade: Dictionary, manager: Node) -> String:
	var effect = upgrade.get("effect", {})
	var id = str(effect.get("spell", ""))
	var value = float(effect.get("value", 0))
	match effect.get("type", ""):
		"learn_spell":
			return EVOLUTIONS.get(id, SPELLS.get(id, "Learn a new spell."))
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
