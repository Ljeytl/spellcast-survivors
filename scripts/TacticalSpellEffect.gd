extends "res://scripts/BuildSpellEffect.gd"

var target_ref: WeakRef
var age = 0.0
var beam_end = Vector2.RIGHT * 450
var triggered = false
var strike_ready = 0.0
var trail_points: Array = []
var trail_sample = 0.0
var last_trail_position = Vector2.ZERO
var leg = 0
var leg_hits = [{}, {}]
var outbound_remaining = 0.7
var burst_remaining = 0.0
var burst_position = Vector2.ZERO

func configure(data: Dictionary, amount: float, player: Node2D, target: Node2D):
	if not valid_target(target):
		target = null
	super.configure(data, amount, player, target)
	target_ref = weakref(target) if is_instance_valid(target) else null
	match info.type:
		"beam":
			color = Color("a5eaff")
			tick_remaining = 0.25
		"trap":
			color = Color("b7a0ff") if not info.get("frost", false) else Color("9fe9ee")
			global_position += direction * minf(160, player.global_position.distance_to(target.global_position) if is_instance_valid(target) else 160)
		"spirit":
			color = Color("b6f5d2")
		"trail":
			color = Color("efc276")
			last_trail_position = global_position
			trail_points.append({"position": global_position, "age": 0.0})
		"returning":
			color = Color("d7e5ff")

func advance(delta: float):
	var player = caster.get_ref() if caster else null
	if not is_instance_valid(player) or player.is_queued_for_deletion() or remaining <= 0:
		queue_free()
		return
	var budget = minf(maxf(delta, 0), remaining)
	while budget > 0.000001 and remaining > 0.000001:
		var step = minf(minf(budget, remaining), 0.05)
		budget -= step
		remaining -= step
		age += step
		burst_remaining = maxf(0, burst_remaining - step)
		match info.type:
			"beam": advance_beam(step, player)
			"trap": advance_trap()
			"spirit": advance_spirit(step, player)
			"trail": advance_trail(step, player)
			"returning": advance_returning(step, player)
	queue_redraw()
	if remaining <= 0.000001:
		queue_free()

func deal_damage(enemy, amount: float) -> float:
	if not valid_target(enemy):
		return 0
	var before = float(enemy.current_health)
	enemy.take_damage(amount, global_position)
	return maxf(0, before - float(enemy.current_health)) if is_instance_valid(enemy) else 0

func closest_target(center: Vector2, radius: float):
	var nearest = null
	var distance = radius
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if valid_target(enemy):
			var candidate = center.distance_to(enemy.global_position)
			if candidate <= distance:
				distance = candidate
				nearest = enemy
	return nearest

func tracking_target(center: Vector2, radius: float):
	var target = target_ref.get_ref() if target_ref else null
	if not valid_target(target) or center.distance_to(target.global_position) > radius:
		target = closest_target(center, radius)
		target_ref = weakref(target) if target else null
	return target

func advance_beam(delta: float, player: Node2D):
	global_position = player.global_position
	var target = tracking_target(global_position, 450)
	if target:
		direction = global_position.direction_to(target.global_position)
	var reach = global_position + direction * 450
	var targets: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if valid_target(enemy) and Geometry2D.get_closest_point_to_segment(enemy.global_position, global_position, reach).distance_to(enemy.global_position) <= 20:
			targets.append(enemy)
	targets.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	var hits = targets.slice(0, int(info.get("beam_targets", 1)))
	beam_end = direction * 450
	if not hits.is_empty():
		beam_end = direction * minf(450, (hits[-1].global_position - global_position).dot(direction) + 8)
	tick_remaining -= delta
	if tick_remaining > 0.000001:
		return
	tick_remaining += 0.25
	for enemy in hits:
		deal_damage(enemy, damage)

func advance_trap():
	if triggered or age + 0.000001 < float(info.get("arm_delay", 0.8)):
		return
	if not closest_target(global_position, 70):
		return
	triggered = true
	var radius = float(info.get("trap_radius", 130))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if valid_target(enemy) and global_position.distance_to(enemy.global_position) <= radius:
			deal_damage(enemy, damage)
			if valid_target(enemy) and info.get("frost", false) and enemy.has_method("apply_slow"):
				enemy.apply_slow(0.6, 2.0)
	remaining = minf(remaining, 0.25)

func advance_spirit(delta: float, player: Node2D):
	var target = tracking_target(player.global_position, 600)
	var destination = target.global_position if target else player.global_position
	global_position = global_position.move_toward(destination, 320 * delta)
	strike_ready = maxf(0, strike_ready - delta)
	if target and valid_target(target) and global_position.distance_to(target.global_position) <= 24 and strike_ready <= 0.000001:
		var center = target.global_position
		var before = float(target.current_health)
		deal_damage(target, damage)
		strike_ready = 0.5
		if info.get("reaping", false) and before > 0 and is_instance_valid(target) and float(target.current_health) <= 0:
			pulse(center, 100, damage * 0.5, target)
			burst_position = center
			burst_remaining = 0.25

func advance_trail(delta: float, player: Node2D):
	for point in trail_points:
		point.age += delta
	trail_points = trail_points.filter(func(point): return point.age < 2.0)
	trail_sample -= delta
	if age <= 5.0 and trail_sample <= 0.000001:
		trail_sample = 0.2
		if last_trail_position.distance_to(player.global_position) >= 32:
			last_trail_position = player.global_position
			trail_points.append({"position": player.global_position, "age": 0.0})
			if trail_points.size() > 24:
				trail_points.pop_front()
	tick_remaining -= delta
	if tick_remaining > 0.000001:
		return
	tick_remaining += 0.5
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if valid_target(enemy):
			for point in trail_points:
				if point.position.distance_to(enemy.global_position) <= 40:
					deal_damage(enemy, damage)
					break

func advance_returning(delta: float, player: Node2D):
	var start = global_position
	if leg == 0:
		global_position += direction * 500 * delta
		outbound_remaining -= delta
	else:
		global_position = global_position.move_toward(player.global_position, 500 * delta)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if valid_target(enemy) and not leg_hits[leg].has(enemy.get_instance_id()) and Geometry2D.get_closest_point_to_segment(enemy.global_position, start, global_position).distance_to(enemy.global_position) <= 24:
			leg_hits[leg][enemy.get_instance_id()] = true
			deal_damage(enemy, damage)
	if leg == 0 and outbound_remaining <= 0.000001:
		leg = 1
	elif leg == 1 and global_position.distance_to(player.global_position) <= 18:
		remaining = 0

func _draw():
	if burst_remaining > 0:
		var center = to_local(burst_position)
		var alpha = burst_remaining / 0.25
		draw_circle(center, 100, Color(color, alpha * 0.15))
		draw_arc(center, 100, 0, TAU, 40, Color(color, alpha), 3)
	match info.type:
		"beam":
			draw_line(Vector2.ZERO, beam_end, Color(color, 0.22), 22)
			draw_line(Vector2.ZERO, beam_end, color, 5)
		"trap":
			var radius = float(info.get("trap_radius", 130)) if triggered else 32.0
			draw_circle(Vector2.ZERO, radius, Color(color, 0.2))
			draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(color, 0.35), 3)
			draw_arc(Vector2.ZERO, radius, -PI / 2, -PI / 2 + TAU * clampf(age / float(info.get("arm_delay", 0.8)), 0.001, 1), 32, color, 3)
			if age >= float(info.get("arm_delay", 0.8)):
				draw_circle(Vector2.ZERO, 6, color)
			draw_line(Vector2(-18, 0), Vector2(18, 0), color, 3)
			draw_line(Vector2(0, -18), Vector2(0, 18), color, 3)
		"spirit":
			draw_circle(Vector2.ZERO, 13, Color(color, 0.3))
			draw_circle(Vector2.ZERO, 7, color)
			draw_arc(Vector2.ZERO, 19, age * 4, age * 4 + PI, 16, color, 2)
		"trail":
			for point in trail_points:
				draw_circle(to_local(point.position), 40, Color(color, 0.25 * (1 - point.age / 2)))
				draw_arc(to_local(point.position), 24, 0, TAU, 16, color, 2)
		"returning":
			var axis = Vector2.from_angle(age * 12) * 20
			draw_line(-axis, axis, color, 6)
			draw_line(-axis.rotated(PI / 2), axis.rotated(PI / 2), color, 3)
