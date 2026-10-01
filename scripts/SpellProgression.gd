extends RefCounted

## Applies rank_steps and rank_growth for the spell's level. Safe to call twice.
const RANK_CAP = 8
## Past RANK_CAP each level-up card raises one of a spell's own passive properties
## (Spell Power, Size, Duration, Velocity) by this fraction; SpellManager.cast_stat applies it.
const OVERFLOW_STEP = 0.10
const OVERFLOW_NAMES = {"power": "Spell Power", "size": "Spell Size", "duration": "Spell Duration", "velocity": "Velocity"}

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
	# Linear growth per rank from 1 to 8. Past rank 8, level-up picks scale the passive properties instead (SpellManager.cast_stat).
	var growth = data.get("rank_growth", {})
	for key in growth:
		var grown = float(result.get(key, 0.0)) + float(growth[key].get("per_rank", 0.0)) * clampi(int(data.get("level", 1)) - 1, 0, RANK_CAP - 1)
		grown = minf(grown, float(growth[key].max)) if growth[key].has("max") else grown
		result[key] = int(floor(grown + 0.0001)) if growth[key].get("integer", false) else grown
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
