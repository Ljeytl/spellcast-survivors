extends RefCounted

static func register(node: Node2D):
	node.add_to_group("projectile_visuals")
	if node.is_inside_tree() and node.get_tree().root.has_meta("projectile_preview_scale"):
		apply(node, node.get_tree().root.get_meta("projectile_preview_scale"))

static func apply(node: Node2D, multiplier: float):
	node.set_meta("projectile_visual_scale", maxf(0.01, multiplier))
	node.queue_redraw()

static func factor(node: Node2D) -> float:
	return float(node.get_meta("projectile_visual_scale", 1.0))

static func size(node: Node2D, dimensions: Vector2) -> Vector2:
	return dimensions * factor(node)
