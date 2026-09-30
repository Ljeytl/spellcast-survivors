extends RefCounted

static func alive(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.get("dying") and float(enemy.get("current_health")) > 0.0

static func incoming(tree: SceneTree, enemy, excluding = null) -> float:
	var total = 0.0
	for projectile in tree.get_nodes_in_group("spell_projectiles"):
		if projectile == excluding or not projectile.has_method("reserved_damage"):
			continue
		total += projectile.reserved_damage(enemy)
	return total

static func select(tree: SceneTree, origin: Vector2, maximum_range: float = INF, excluded: Dictionary = {}, excluding = null):
	var useful = null
	var fallback = null
	var useful_distance = INF
	var fallback_distance = INF
	for enemy in tree.get_nodes_in_group("enemies"):
		if not alive(enemy) or excluded.has(enemy.get_instance_id()):
			continue
		var distance = origin.distance_to(enemy.global_position)
		if distance > maximum_range:
			continue
		if distance < fallback_distance:
			fallback = enemy
			fallback_distance = distance
		if distance < useful_distance and incoming(tree, enemy, excluding) < enemy.current_health:
			useful = enemy
			useful_distance = distance
	return useful if useful != null else fallback

## Pass the visible viewport rect to centre the area only on an enemy the player can see;
## nearby off-screen enemies still count toward that centre's coverage score.
static func select_area(tree: SceneTree, origin: Vector2, radius: float, maximum_range: float = INF, planned_damage: Dictionary = {}, viewport: Rect2 = Rect2()):
	var enemies = tree.get_nodes_in_group("enemies").filter(alive)
	var weights = {}
	for enemy in enemies:
		weights[enemy.get_instance_id()] = 1.0 if incoming(tree, enemy) + float(planned_damage.get(enemy.get_instance_id(), 0)) < enemy.current_health else 0.1
	var selected = null
	var best_score = -1.0
	var nearest = INF
	for candidate in enemies:
		var distance = origin.distance_to(candidate.global_position)
		if distance > maximum_range:
			continue
		if viewport.has_area() and (not candidate.is_visible_in_tree() or not viewport.has_point(candidate.get_global_transform_with_canvas().origin)):
			continue
		var score = 0.0
		for enemy in enemies:
			if candidate.global_position.distance_to(enemy.global_position) <= radius:
				score += weights[enemy.get_instance_id()]
		if score > best_score or (is_equal_approx(score, best_score) and distance < nearest):
			selected = candidate
			best_score = score
			nearest = distance
	return selected

static func meteor_weight(distance: float, health: float, coverage: float) -> float:
	return (1.0 / (1.0 + maxf(0.0, distance) / 300.0)) * clampf(sqrt(maxf(1.0, health) / 30.0), 1.0, 3.0) / (1.0 + maxf(0.0, coverage) * 3.0)

static func select_meteor(tree: SceneTree, origin: Vector2, viewport: Rect2, coverage: Dictionary = {}):
	var candidates = []
	var total = 0.0
	for enemy in tree.get_nodes_in_group("enemies"):
		if not alive(enemy) or not enemy.is_visible_in_tree() or not viewport.has_point(enemy.get_global_transform_with_canvas().origin):
			continue
		var weight = meteor_weight(origin.distance_to(enemy.global_position), float(enemy.current_health), float(coverage.get(enemy.get_instance_id(), 0.0)))
		candidates.append({"enemy": enemy, "weight": weight})
		total += weight
	if candidates.is_empty():
		return null
	var roll = randf() * total
	for candidate in candidates:
		roll -= candidate.weight
		if roll <= 0.0:
			return candidate.enemy
	return candidates.back().enemy

static func select_spirit(tree: SceneTree, player: Node2D, excluding = null, current = null):
	var reserved: Array = []
	for spirit in tree.get_nodes_in_group("build_spell_effects"):
		if spirit == excluding or spirit.is_queued_for_deletion() or spirit.info.get("type", "") != "spirit" or spirit.remaining <= 0:
			continue
		if not spirit.caster or spirit.caster.get_ref() != player:
			continue
		var other = spirit.target_ref.get_ref() if spirit.target_ref else null
		if alive(other):
			reserved.append(other)
	var chosen = null
	var best = INF
	var viewport = player.get_viewport().get_visible_rect()
	for enemy in tree.get_nodes_in_group("enemies"):
		if not alive(enemy) or not enemy.is_visible_in_tree() or not viewport.has_point(enemy.get_global_transform_with_canvas().origin):
			continue
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance > 600.0:
			continue
		var score = (0.0 if enemy == current else distance + 1.0) + (602.0 if enemy in reserved else 0.0)
		if score < best:
			best = score
			chosen = enemy
	return chosen
