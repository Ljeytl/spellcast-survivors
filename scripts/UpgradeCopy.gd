extends RefCounted

const SPELLS = {
	"bolt": "Fire a bolt at a nearby enemy.",
	"life": "Restore a little health immediately.",
	"regeneration": "Restore health over time.",
	"ice_blast": "Blast nearby enemies with ice and push them back.",
	"earth_shield": "Gain temporary bonus health.",
	"lightning_arc": "Chain lightning through nearby enemies.",
	"meteor_shower": "Rain explosive meteors onto nearby enemies.",
	"ember_lance": "Pierce a line of enemies with fire.",
	"plague_seed": "Infect a nearby enemy with lingering damage.",
	"cinder_field": "Burn enemies inside a lingering fire field.",
	"arcane_orbit": "Surround yourself with damaging orbiting magic.",
	"focus_ray": "Track a nearby enemy with a damaging beam.",
	"rune_trap": "Place an explosive trap ahead of you.",
	"seeking_spirit": "Summon a hunter that pursues nearby enemies.",
	"ember_trail": "Leave burning tracks as you move.",
	"returning_blade": "Throw a blade that strikes again on its return."
}

const EVOLUTIONS = {
	"lightning_bolt": "Fire a bolt that bounces between nearby enemies.",
	"life_bolt": "Hits plant a healing seed you can collect.",
	"meteor_lance": "Pierce enemies with explosive hits and 40% less direct damage.",
	"soul_bloom": "Spread healing infection with 25% less damage.",
	"steam_field": "Create slowing steam that lasts 3 seconds.",
	"prism_ray": "Pierce aligned enemies with 40% less damage per target.",
	"frost_sigil": "Place a larger slowing trap that arms after 1.4 seconds.",
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
			return "Gain %s%% Mana Bolt attack speed." % number(value * 100)
		"projectile_speed":
			return "Gain %s%% projectile speed." % number(value * 100)
		"slowdown_duration":
			return "Gain %s seconds of slowdown per cast." % number(value)
		"mana_bolt_mastery":
			return "Strengthen your automatic Mana Bolt and fire it faster."
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
	var rank = manager.get_spell_rank(id)
	var slot = manager.find_spell_slot(id)
	var info = manager.get_spell_info(slot)
	if id == "life":
		return "Restore %s more health per cast." % number(float(info.heal_amount) * 0.15)
	if id == "regeneration":
		return "Restore %s more health each second." % number(float(info.heal_amount) * 0.15)
	if id == "earth_shield":
		return "Gain %s more bonus health per cast." % number(float(info.shield_hp) * 0.15)
	var base = manager.mana_bolt_damage if id == "mana_bolt" else float(info.get("damage", 0)) * float(info.get("damage_multiplier", 1))
	var gain = base * 0.15 * manager.player.spell_damage_multiplier
	var extra = ""
	if id == "mana_bolt" and rank + 1 in [3, 6, 10]:
		extra = " and fire one extra bolt"
	elif id == "bolt" and rank < 5:
		extra = " and fire one extra bolt"
	elif id == "meteor_shower":
		extra = " and drop one extra meteor"
	elif id == "ice_blast":
		extra = " with a wider, stronger push"
	return "Deal %s more damage per hit%s." % [number(gain), extra]
