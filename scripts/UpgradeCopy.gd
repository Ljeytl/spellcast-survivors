extends RefCounted

const SPELLS = {
	"bolt": "Fire a bolt at a nearby enemy.",
	"life": "Restore health over time.",
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
	"seeking_spirit": "Summon a spirit that hunts nearby enemies.",
	"ember_trail": "Leave burning tracks as you move.",
	"returning_blade": "Throw a blade that strikes again on its return."
}

const EVOLUTIONS = {
	"life_bolt": "Replace Bolt with a healing bolt that loses extra projectiles.",
	"meteor_lance": "Replace Ember Lance with explosive hits but 40% less direct damage.",
	"soul_bloom": "Replace Plague Seed with healing infection but 25% less damage.",
	"steam_field": "Replace Cinder Field with slowing steam that lasts 2 seconds less.",
	"prism_ray": "Replace Focus Ray with a piercing beam but 40% less damage per target.",
	"frost_sigil": "Replace Rune Trap with a larger slowing burst that arms 0.6 seconds slower.",
	"reaping_spirit": "Replace Seeking Spirit with explosive kills but 25% less contact damage."
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
	var info = manager.spells.get(slot, {})
	if id == "life":
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
