extends RefCounted

static var _spells: Dictionary = {}

## Damage an ingredient deals at a rank, following its own curve (rank_growth or +15% per rank).
static func ingredient_damage(id: String, rank: int, fallback: float) -> float:
	if _spells.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/spells.json"))
		_spells = parsed.get("spells", {}) if parsed is Dictionary else {}
	var data = _spells.get(id, {})
	if data.is_empty():
		return fallback * (1.0 + 0.15 * maxi(0, rank - 1))
	var growth = data.get("rank_growth", {}).get("damage", {})
	if growth.is_empty():
		return float(data.get("damage", fallback)) * (1.0 + 0.15 * maxi(0, rank - 1))
	return float(data.damage) + float(growth.get("per_rank", 0.0)) * maxi(0, rank - 1)

static func resolve(data: Dictionary, ranks: Dictionary) -> Dictionary:
	var info = data.duplicate(true)
	var own = maxi(0, int(info.get("level", 1)) - 1)
	var bonus = func(id: String) -> int: return maxi(0, int(ranks.get(id, 1)) - 1)
	match str(info.get("id", "")):
		"life_bolt":
			info.damage = 40.0 * (1.0 + 0.15 * bonus.call("bolt"))
			info.healing_seed_amount = 6.0 * (1.0 + 0.15 * bonus.call("life"))
			info.projectile_count = 1 + int(ceil(own / 2.0))
			info.healing_seed_radius = 44.0 * (1.0 + 0.2 * int(own / 2))
			info.healing_seed_duration = 2.0
			info.healing_seed_lifetime = 10.0
		"lightning_bolt":
			info.damage = 40.0 * (1.0 + 0.15 * bonus.call("bolt"))
			info.splash_damage = 80.0 * (1.0 + 0.15 * bonus.call("lightning_arc"))
			info.splash_radius = 80.0 * (1.0 + 0.05 * bonus.call("lightning_arc"))
			info.splash_duration = 0.2
			info.bounce_count = 4 + own
		"meteor_lance":
			info.damage = 45.0 * (1.0 + 0.15 * bonus.call("ember_lance") + 0.1 * own)
			info.explosion_damage = 25.0 * (1.0 + 0.15 * bonus.call("meteor_shower") + 0.1 * own)
			info.explosion_radius = 90.0 * (1.0 + 0.05 * bonus.call("meteor_shower") + 0.1 * own)
			info.explosion_duration = 0.2
			info.body_size_multiplier = 1.0 + 0.1 * own
		"soul_bloom":
			info.damage = ingredient_damage("plague_seed", int(ranks.get("plague_seed", 1)), 9.0)
			info.healing_bloom_amount = 6.0 * (1.0 + 0.15 * bonus.call("regeneration"))
			info.healing_bloom_radius = 60.0
			info.healing_bloom_lifetime = 10.0 * (1.0 + 0.1 * own)
			info.duration = 5.0 * (1.0 + 0.1 * own)
			info.orphan_lifetime = 5.0 * (1.0 + 0.1 * own)
		"steam_field":
			info.damage = ingredient_damage("cinder_field", int(ranks.get("cinder_field", 1)), 12.0)
			info.slow = minf(0.75, 0.4 + 0.025 * bonus.call("ice_blast"))
			info.radius = 150.0 * (1.0 + 0.1 * own)
			info.duration = 5.0 * (1.0 + 0.1 * own)
		"prism_ray":
			info.damage = 18.0 * (1.0 + 0.15 * (bonus.call("focus_ray") + bonus.call("ember_lance") + own))
			info.beam_radius = 32.0
			info.beam_turn_speed = 0.25
		"frost_sigil":
			info.damage = 60.0 * (1.0 + 0.15 * bonus.call("rune_trap"))
			info.trap_radius = 170.0 * (1.0 + 0.05 * (bonus.call("rune_trap") + bonus.call("ice_blast")))
			info.slow = minf(0.75, 0.4 + 0.025 * bonus.call("ice_blast"))
			info.slow_duration = 2.0
			info.arm_delay = maxf(0.4, 1.2 - 0.1 * own)
		_:
			return info
	info.erase("rank_steps")
	info.erase("damage_multiplier")
	info.erase("lifesteal")
	info.combination_scaled = true
	return info

static func next_description(id: String, rank: int) -> String:
	match id:
		"life_bolt": return "+1 bolt" if rank % 2 == 1 else "+20% base healing area radius"
		"lightning_bolt": return "+1 bounce"
		"meteor_lance": return "+10% base damage, lance size and explosion radius"
		"soul_bloom": return "+10% base infection, spore and healing bloom duration"
		"steam_field": return "+10% base field radius and duration"
		"prism_ray": return "+15% base beam damage"
		"frost_sigil": return "Arms 0.1 seconds sooner" if rank < 9 else "Minimum arming time reached"
	return ""
