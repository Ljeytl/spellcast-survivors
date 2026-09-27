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

static func select_area(tree: SceneTree, origin: Vector2, radius: float, maximum_range: float = INF, planned_damage: Dictionary = {}):
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
		var score = 0.0
		for enemy in enemies:
			if candidate.global_position.distance_to(enemy.global_position) <= radius:
				score += weights[enemy.get_instance_id()]
		if score > best_score or (is_equal_approx(score, best_score) and distance < nearest):
			selected = candidate
			best_score = score
			nearest = distance
	return selected
