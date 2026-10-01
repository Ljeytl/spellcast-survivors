extends RefCounted

## Applies rank_steps and rank_growth for the spell's level. Safe to call twice.
const RANK_CAP = 8
## Past RANK_CAP each level-up card raises one property of one spell by this fraction.
const OVERFLOW_DAMAGE_PER_RANK = 0.10
const OVERFLOW_STEP = 0.10
const OVERFLOW_NAMES = {"power": "Power", "area": "Area", "duration": "Duration", "speed": "Speed"}
## Which data keys each property scales, per spell. Power scales damage for every spell.
## Counts (shards, orbs, meteors, active limits) are deliberately never scaled.
const OVERFLOW_KEYS = {
	"ice_blast": {"area": ["radius", "cone_degrees"], "duration": ["slow_duration"]},
	"lightning_arc": {"area": ["radius"], "duration": ["active_duration"]},
	"meteor_shower": {"area": ["radius"]},
	"plague_seed": {"area": ["spread_radius"], "duration": ["duration", "spore_linger"], "speed": ["spread_speed"]},
	"cinder_field": {"area": ["radius"], "duration": ["duration"]},
	"arcane_orbit": {"area": ["orbit_radius", "body_radius"], "duration": ["duration"], "speed": ["angular_speed"]},
	"focus_ray": {"area": ["beam_radius"], "duration": ["duration"], "speed": ["turn_speed"]},
	"rune_trap": {"area": ["trigger_radius", "trap_radius"], "duration": ["duration"]},
	"seeking_spirit": {"duration": ["duration"], "speed": ["move_speed"]},
	"ember_trail": {"area": ["trail_radius"], "duration": ["patch_duration"]},
	"returning_blade": {"area": ["blade_radius", "travel_distance"], "speed": ["speed"]},
}

## Power picks taken past rank 8; each adds OVERFLOW_DAMAGE_PER_RANK of rank-8 damage.
static func overflow_ranks(data: Dictionary) -> int:
	return int(data.get("overflow", {}).get("power", 0))

static func overflow_stats(spell_id: String) -> Array:
	var stats = ["power"]
	stats.append_array(OVERFLOW_KEYS.get(spell_id, {}).keys())
	return stats

static func add_overflow(data: Dictionary, stat: String):
	if not data.has("overflow"):
		data["overflow"] = {}
	data.overflow[stat] = int(data.overflow.get(stat, 0)) + 1

static func resolve(data: Dictionary) -> Dictionary:
	if data.get("rank_resolved", false):
		return data.duplicate(true)
	var result = data.duplicate(true)
	result["rank_resolved"] = true
	var steps = data.get("rank_steps", [])
	for index in range(mini(maxi(0, int(data.get("level", 1)) - 1), steps.size())):
		for key in steps[index]:
			if key != "description":
				result[key] = steps[index][key]
	# Linear growth per rank from 1 to 8. Past rank 8, only the overflow damage percentage applies.
	var growth = data.get("rank_growth", {})
	for key in growth:
		var grown = float(result.get(key, 0.0)) + float(growth[key].get("per_rank", 0.0)) * clampi(int(data.get("level", 1)) - 1, 0, RANK_CAP - 1)
		grown = minf(grown, float(growth[key].max)) if growth[key].has("max") else grown
		result[key] = int(floor(grown + 0.0001)) if growth[key].get("integer", false) else grown
	var picks = data.get("overflow", {})
	var table = OVERFLOW_KEYS.get(str(data.get("id", "")), {})
	for stat in picks:
		for key in table.get(stat, []):
			if result.has(key):
				result[key] = float(result[key]) * (1.0 + OVERFLOW_STEP * int(picks[stat]))
	return result

static func can_upgrade(data: Dictionary) -> bool:
	if data.get("id", "") == "frost_sigil" and int(data.get("level", 1)) >= 9:
		return false
	if int(data.get("level", 1)) >= RANK_CAP:
		return false
	return not data.has("rank_steps") or int(data.get("level", 1)) <= data.rank_steps.size()

static func next_description(data: Dictionary) -> String:
	var steps = data.get("rank_steps", [])
	var index = int(data.get("level", 1)) - 1
	return str(steps[index].get("description", "")) if index >= 0 and index < steps.size() else "Maximum rank."
