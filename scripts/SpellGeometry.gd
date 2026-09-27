extends RefCounted

const BOLT_RADIUS = 17.0
const LANCE_RADIUS = 24.0
const BEAM_RADIUS = 20.0
const SPIRIT_RADIUS = 24.0
const Art = preload("res://scripts/EffectArt.gd")

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
	result.projectile_size_multiplier = factor * float(preload("res://scripts/VisualDefaults.gd").PROJECTILE_SCALES.get(str(result.get("id", "")), 1.0))
	return result

static func stamp_dimensions(kind: String, radius: float) -> Vector2:
	if Art.MOTIF_BODIES.has(kind):
		var crop: Rect2 = Art.motif_region(kind)
		var body: Rect2 = Art.MOTIF_BODIES[kind]
		return Vector2(radius * 2 * crop.size.x / body.size.x, radius * 2 * crop.size.y / body.size.y)
	match kind:
		"lance": return Vector2(radius * 2.0 * Art.motif_region("lance").size.aspect(), radius * 2.0)
		"blade", "orbit": return Vector2.ONE * radius * 2.0
	return Vector2.ONE * radius * 2.0

static func stamp_offset(kind: String, radius: float) -> Vector2:
	if Art.MOTIF_BODIES.has(kind):
		var crop: Rect2 = Art.motif_region(kind)
		var body: Rect2 = Art.MOTIF_BODIES[kind]
		var size = stamp_dimensions(kind, radius)
		var relative = (body.get_center() - crop.get_center()) / crop.size * size
		return Vector2(relative.x if kind in ["mana", "bolt"] else -relative.x, -relative.y)
	if kind == "lance":
		return Vector2(radius - stamp_dimensions(kind, radius).x * 0.5, 0)
	return Vector2.ZERO
