extends "res://scripts/BuildSpellEffect.gd"

var target_ref: WeakRef
var age = 0.0
var beam_end = Vector2.RIGHT * 450
var triggered = false
var strike_ready = 0.0
var trail_points: Array = []
var trail_sample = 0.0
var emission_deadline = 0.0
var trail_strip = 0
var last_trail_position = Vector2.ZERO
var leg = 0
var leg_hits = [{}, {}]
var outbound_distance = 350.0
var linger_remaining = 0.4
var burst_remaining = 0.0
var burst_position = Vector2.ZERO
var linger_tick = 0.0

func configure(data: Dictionary, amount: float, player: Node2D, target: Node2D):
	if not valid_target(target):
		target = null
	super.configure(data, amount, player, target)
	target_ref = weakref(target) if is_instance_valid(target) else null
	match info.type:
		"beam":
			global_position += info.get("beam_origin_offset", Vector2.ZERO)
			if target:
				direction = global_position.direction_to(target.global_position)
			color = Color("a5eaff")
			tick_remaining = 0.25
			beam_end = direction * 450
		"trap":
			color = Color("b7a0ff") if not info.get("frost", false) else Color("9fe9ee")
			global_position += direction * minf(160, player.global_position.distance_to(target.global_position) if is_instance_valid(target) else 160)
		"spirit":
			color = Color("b6f5d2")
		"trail":
			emission_deadline = float(info.get("emission_duration", 5.0))
			color = Color("efc276")
			last_trail_position = global_position
			trail_points.append({"position": global_position, "age": 0.0, "strip": trail_strip})
		"returning":
			outbound_distance = float(info.get("travel_distance", 350.0))
			linger_remaining = float(info.get("linger_duration", 0.9))
			linger_tick = float(info.get("linger_interval", 0.3))
			color = Color("d7e5ff")

func extend_duration(data: Dictionary) -> float:
	if info.type != "trail":
		return super.extend_duration(data)
	var added = float(data.get("emission_duration", 5.0))
	if age >= emission_deadline:
		var player = caster.get_ref() if caster else null
		if is_instance_valid(player):
			last_trail_position = player.global_position
			trail_strip += 1
			trail_points.append({"position": last_trail_position, "age": 0.0, "strip": trail_strip})
	emission_deadline = maxf(age, emission_deadline) + added
	remaining = maxf(remaining, emission_deadline - age + float(info.get("patch_duration", 6.0)))
	return added

func advance(delta: float):
	var player = caster.get_ref() if caster else null
	if not is_instance_valid(player) or player.is_queued_for_deletion() or (player.get("health") != null and float(player.health) <= 0) or remaining <= 0:
		queue_free()
		return
	var persistent = info.type == "trap" and not triggered
	if persistent:
		remaining = maxf(remaining, delta + 1.0)
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
	global_position = player.global_position + info.get("beam_origin_offset", Vector2.ZERO)
	var target = tracking_target(global_position, 450)
	if target:
		var desired = global_position.direction_to(target.global_position).angle()
		direction = Vector2.from_angle(rotate_toward(direction.angle(), desired, float(info.get("turn_speed", 4.0)) * delta))
	var reach = global_position + direction * 450
	var targets: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if valid_target(enemy) and Geometry2D.get_closest_point_to_segment(enemy.global_position, global_position, reach).distance_to(enemy.global_position) <= float(info.get("beam_radius", Geometry.BEAM_RADIUS)) * float(info.spell_size_multiplier):
			targets.append(enemy)
	targets.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	var hits = targets if info.get("beam_piercing", false) else targets.slice(0, int(info.get("beam_targets", 1)))
	beam_end = direction * 450
	if not info.get("beam_piercing", false) and not hits.is_empty():
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
	if not closest_target(global_position, float(info.get("trigger_radius", 70))):
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
	global_position = global_position.move_toward(destination, 320 * float(info.get("projectile_speed_multiplier", 1.0)) * delta)
	strike_ready = maxf(0, strike_ready - delta)
	if target and valid_target(target) and global_position.distance_to(target.global_position) <= Geometry.SPIRIT_RADIUS * float(info.spell_size_multiplier) and strike_ready <= 0.000001:
		var center = target.global_position
		var before = float(target.current_health)
		deal_damage(target, damage)
		strike_ready = 0.5
		if info.get("reaping", false) and before > 0 and is_instance_valid(target) and float(target.current_health) <= 0:
			pulse(center, 100 * float(info.spell_size_multiplier), damage * 0.5, target)
			burst_position = center
			burst_remaining = 0.25

func advance_trail(delta: float, player: Node2D):
	var lifetime = float(info.get("patch_duration", 6.0))
	var radius = float(info.get("trail_radius", 65.0))
	for point in trail_points:
		point.age += delta
	trail_points = trail_points.filter(func(point): return point.age < lifetime)
	trail_sample -= delta
	if age <= emission_deadline and trail_sample <= 0.000001:
		trail_sample = 0.1
		var distance = last_trail_position.distance_to(player.global_position)
		if distance >= 24:
			var count = maxi(1, ceili(distance / radius))
			for index in range(count):
				trail_points.append({"position": last_trail_position.lerp(player.global_position, float(index + 1) / count), "age": 0.0, "strip": trail_strip})
			last_trail_position = player.global_position
	tick_remaining -= delta
	if tick_remaining > 0.000001:
		return
	tick_remaining += float(info.get("tick_interval", 0.5))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if valid_target(enemy) and trail_contains(enemy.global_position):
			deal_damage(enemy, damage)

func trail_contains(point: Vector2) -> bool:
	var radius = float(info.get("trail_radius", 65.0))
	for index in range(trail_points.size()):
		var start: Vector2 = trail_points[index].position
		var end: Vector2 = trail_points[index + 1].position if index + 1 < trail_points.size() and trail_points[index].get("strip", 0) == trail_points[index + 1].get("strip", 0) else start
		if Geometry2D.get_closest_point_to_segment(point, start, end).distance_to(point) <= radius:
			return true
	return false

func advance_returning(delta: float, player: Node2D):
	var start = global_position
	var radius = float(info.get("blade_radius", 33.6))
	var movement = float(info.get("speed", 500.0)) * float(info.get("projectile_speed_multiplier", 1.0)) * delta
	if leg == 0:
		var distance = minf(outbound_distance, movement)
		global_position += direction * distance
		outbound_distance -= distance
	elif linger_remaining > 0:
		linger_remaining -= delta
		linger_tick -= delta
		if linger_tick <= 0.000001:
			linger_tick += float(info.get("linger_interval", 0.3))
			pulse(global_position, radius, damage * float(info.get("linger_damage_multiplier", 0.5)))
		return
	else:
		global_position = global_position.move_toward(player.global_position, movement)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if valid_target(enemy) and not leg_hits[leg].has(enemy.get_instance_id()) and Geometry2D.get_closest_point_to_segment(enemy.global_position, start, global_position).distance_to(enemy.global_position) <= radius:
			leg_hits[leg][enemy.get_instance_id()] = true
			deal_damage(enemy, damage)
	if leg == 0 and outbound_distance <= 0.000001:
		leg = 1
	elif leg == 1 and global_position.distance_to(player.global_position) <= 18:
		remaining = 0

func _draw():
	var art = preload("res://scripts/EffectArt.gd")
	if burst_remaining > 0:
		art.burst(self, 3, to_local(burst_position), 200 * float(info.spell_size_multiplier), 1 - burst_remaining / 0.25)
	match info.type:
		"beam":
			art.beam(self, Vector2.ZERO, beam_end, float(info.get("beam_radius", Geometry.BEAM_RADIUS)) * 2 * float(info.spell_size_multiplier), 0.85, info.get("beam_piercing", false))
		"trap":
			var radius = float(info.get("trap_radius", 130)) if triggered else float(info.get("trigger_radius", 70))
			preload("res://scripts/AreaArt.gd").circle(self, Vector2.ZERO, radius, color, minf(remaining * 4, 1) if triggered else 1.0, clampf(age / float(info.get("arm_delay", 0.8)), 0, 1))
			art.stamp(self, "rune", Vector2.ZERO, Vector2.ONE * 48)
			if info.get("frost", false):
				art.stamp(self, "shard", Vector2.ZERO, Vector2.ONE * 25, Color(1, 1, 1, 0.75))
		"spirit":
			art.stamp(self, "spirit", Geometry.stamp_offset("spirit", Geometry.SPIRIT_RADIUS * float(info.spell_size_multiplier)) + Vector2(0, sin(age * 5) * 3), Visual.size(self, Geometry.stamp_dimensions("spirit", Geometry.SPIRIT_RADIUS * float(info.spell_size_multiplier))), Color(0.8, 1, 1))
		"trail":
			var strips = {}
			for point in trail_points:
				var strip = point.get("strip", 0)
				if not strips.has(strip):
					strips[strip] = PackedVector2Array()
				strips[strip].append(to_local(point.position))
			for points in strips.values():
				preload("res://scripts/AreaArt.gd").fire_path(self, points, float(info.get("trail_radius", 65.0)), age)
		"returning":
			var radius = float(info.get("blade_radius", 33.6))
			art.stamp(self, "blade", Vector2.ZERO, Visual.size(self, Geometry.stamp_dimensions("blade", radius)), Color.WHITE, age * 12)
