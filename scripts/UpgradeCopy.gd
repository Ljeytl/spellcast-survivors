extends RefCounted

const SPELLS = {
	"bolt": "Fire a bolt at a nearby enemy.",
	"life": "Restore a little health immediately.",
	"regeneration": "Restore health over time.",
	"ice_blast": "Blast a cone of enemies with ice and push them back.",
	"earth_shield": "Gain temporary bonus health.",
	"lightning_arc": "Strike nearby enemies with an area of lightning.",
	"meteor_shower": "Rain explosive meteors onto nearby enemies.",
	"ember_lance": "Pierce a line of enemies with fire.",
	"plague_seed": "Infect a nearby enemy with lingering damage.",
	"cinder_field": "Burn enemies inside a lingering fire field.",
	"arcane_orbit": "Surround yourself with damaging orbiting magic.",
	"focus_ray": "Track a nearby enemy with a damaging beam.",
	"rune_trap": "Place an explosive trap ahead of you.",
	"seeking_spirit": "Summon a hunter that pursues nearby enemies.",
	"ember_trail": "Leave burning tracks as you move.",
	"returning_blade": "Throw spinning blades around you that return to strike again."
}

const EVOLUTIONS = {
	"lightning_bolt": "Bounce lightning between enemies with a blast on every hit.",
	"life_bolt": "Hits plant a healing seed you can collect.",
	"meteor_lance": "Pierce enemies with explosive meteor hits.",
	"soul_bloom": "Infect enemies; their deaths leave healing blooms.",
	"steam_field": "Scald and slow enemies in a lingering steam field.",
	"prism_ray": "Carve through a line with a broad, fixed-direction laser.",
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
			return "Gain %s%% Mana Bolt attack speed." % number(value * 100)
		"spell_area":
			return "Gain %s%% spell size." % number(value * 100)
		"projectile_speed":
			return "Spells travel and turn %s%% faster." % number(value * 100)
		"spell_duration":
			return "Effects last %s%% longer." % number(value * 100)
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
	if preload("res://scripts/SynergyCatalog.gd").RECIPES.has(id):
		return preload("res://scripts/CombinationScaling.gd").next_description(id, rank)
	var slot = manager.find_spell_slot(id)
	var info = manager.get_spell_info(slot)
	if info.has("rank_steps"):
		return preload("res://scripts/SpellProgression.gd").next_description(info)
	if id == "life":
		return "Restore %s more health per cast." % number(float(info.heal_amount) * 0.15 * manager.player.spell_damage_multiplier)
	if id == "regeneration":
		return "Restore %s more health each second." % number(float(info.heal_amount) * 0.15 * manager.player.spell_damage_multiplier)
	if id == "earth_shield":
		return "Gain %s more bonus health per cast." % number(float(info.shield_hp) * 0.15 * manager.player.spell_damage_multiplier)
	var base = manager.mana_bolt_damage if id == "mana_bolt" else float(info.get("damage", 0)) * float(info.get("damage_multiplier", 1))
	var gain = base * 0.15 * manager.player.spell_damage_multiplier
	var extra = ""
	if id == "mana_bolt" and rank + 1 in [3, 6, 10]:
		extra = " and fire one extra bolt"
	elif id == "bolt" and rank < 5:
		extra = " and fire one extra bolt"
	elif id == "lightning_bolt":
		extra = " and bounce to one more enemy"
	elif id == "meteor_shower":
		extra = " and drop one extra meteor"
	elif id == "ice_blast":
		extra = " with a wider, stronger push"
	return "Deal %s more damage per hit%s." % [number(gain), extra]
