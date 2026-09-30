extends RefCounted

static func resolve(data: Dictionary) -> Dictionary:
	var result = data.duplicate(true)
	var steps = data.get("rank_steps", [])
	for index in range(mini(maxi(0, int(data.get("level", 1)) - 1), steps.size())):
		for key in steps[index]:
			if key != "description":
				result[key] = steps[index][key]
	# Optional capped linear growth per rank above one, e.g. Firewalk trail width.
	var growth = data.get("rank_growth", {})
	for key in growth:
		var grown = float(result.get(key, 0.0)) + float(growth[key].get("per_rank", 0.0)) * maxi(0, int(data.get("level", 1)) - 1)
		result[key] = minf(grown, float(growth[key].max)) if growth[key].has("max") else grown
	return result

static func can_upgrade(data: Dictionary) -> bool:
	if data.get("id", "") == "frost_sigil" and int(data.get("level", 1)) >= 9:
		return false
	return not data.has("rank_steps") or int(data.get("level", 1)) <= data.rank_steps.size()

static func next_description(data: Dictionary) -> String:
	var steps = data.get("rank_steps", [])
	var index = int(data.get("level", 1)) - 1
	return str(steps[index].get("description", "")) if index >= 0 and index < steps.size() else "Maximum rank."
