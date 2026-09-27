extends RefCounted

const BOLT_RADIUS = 17.0
const LANCE_RADIUS = 24.0
const BEAM_RADIUS = 20.0
const SPIRIT_RADIUS = 24.0

static func multiplier(player: Node) -> float:
	if not is_instance_valid(player):
		return 1.0
	var value = player.get("spell_size_multiplier")
	return maxf(0.1, float(value)) if value != null else 1.0

static func scaled_data(data: Dictionary, player: Node) -> Dictionary:
	var result = data.duplicate(true)
	var factor = multiplier(player)
	var defaults = {"field": {"radius": 150.0}, "orbit": {"body_radius": 42.0}, "returning": {"blade_radius": 42.0}, "trail": {"trail_radius": 65.0}, "trap": {"trap_radius": 130.0, "trigger_radius": 70.0}}
	for key in defaults.get(str(result.get("type", "")), {}):
		if not result.has(key):
			result[key] = defaults[result.type][key]
	for key in ["radius", "body_radius", "blade_radius", "trail_radius", "trap_radius", "trigger_radius"]:
		if result.has(key):
			result[key] = float(result[key]) * factor
	result.spell_size_multiplier = factor
	return result

static func stamp_dimensions(kind: String, radius: float) -> Vector2:
	match kind:
		"lance": return Vector2(radius * 3.0, radius * 2.0 * 24.0 / 10.0)
		"spirit": return Vector2.ONE * radius * 2.0 * 24.0 / 12.0
		"bolt", "mana": return Vector2.ONE * radius * 2.0 * 24.0 / 16.0
		"blade": return Vector2.ONE * radius * 2.0 * 24.0 / 22.0
	return Vector2.ONE * radius * 2.0
