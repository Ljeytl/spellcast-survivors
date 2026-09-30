extends Node2D

func _init():
	DamageSource.stamp(self)

var queued_casts: Array = []
var current_cast_remaining = -1.0
var info: Dictionary
var damage: float
var caster: WeakRef
var direction = Vector2.RIGHT
var remaining = 5.0
var tick_remaining = 0.5
var hit_ids: Dictionary = {}
var infections: Array = []
var angle = 0.0
var healing_remaining = 2.0
var color = Color.ORANGE_RED
var infection_links: Array = []
var death_transfers: Dictionary = {}
var orbit_hit_times: Dictionary = {}
var elapsed_time = 0.0
var infected_at: Dictionary = {}
var infection_expires: Dictionary = {}
var resting_spores: Array = []
var infection_duration = 5.0
var hosts_started = 0
const SPORE_LINGER = 3.0
const HOST_LIMIT = 8
const ENFORCE_HOST_LIMIT = false
const Geometry = preload("res://scripts/SpellGeometry.gd")
const Visual = preload("res://scripts/ProjectileVisual.gd")

func configure(data: Dictionary, amount: float, player: Node2D, target: Node2D):
	info = preload("res://scripts/SpellGeometry.gd").scaled_data(data, player)
	if info.type in ["field", "trail", "trap"]:
		z_as_relative = false
		z_index = -2
	damage = amount
	caster = weakref(player)
	global_position = player.global_position
	remaining = float(info.get("duration", 5.0))
	infection_duration = remaining
	healing_remaining = float(info.get("healing_tick_cap", 2.0))
	tick_remaining = float(info.get("tick_interval", 0.5))
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		if info.type == "field":
			global_position = target.global_position
		if info.type == "plague":
			infect(target, player.global_position, float(info.get("cast_range", 600.0)))
	if info.type == "piercing":
		remaining = 1.5
	if info.type == "plague":
		color = Color.GREEN_YELLOW
		z_index = 3
	if info.type == "orbit":
		color = Color.MEDIUM_PURPLE
	if info.get("slow", 0.0) > 0:
		color = Color.LIGHT_CYAN
	add_to_group("build_spell_effects")
	if info.type in ["piercing", "orbit", "plague", "spirit", "returning"]:
		Visual.register(self)

func queue_cast_extension(data: Dictionary, amount: float) -> float:
	if current_cast_remaining < 0:
		current_cast_remaining = remaining
	var added = extend_duration(data)
	queued_casts.append({"info": Geometry.scaled_data(data, caster.get_ref()), "damage": amount, "duration": added})
	return added

func advance_cast_segments(delta: float):
	if current_cast_remaining < 0:
		return
	current_cast_remaining -= delta
	while current_cast_remaining <= 0 and not queued_casts.is_empty():
		var next = queued_casts.pop_front()
		info = next.info
		damage = next.damage
		current_cast_remaining += next.duration

func extend_duration(data: Dictionary) -> float:
	var added = float(Geometry.scaled_data(data, caster.get_ref()).get("duration", 0.0))
	remaining += added
	return added

func _ready():
	if is_in_group("projectile_visuals"):
		Visual.register(self)

func _physics_process(delta):
	advance(delta)

func advance(delta: float):
	if current_cast_remaining > 0 and delta > current_cast_remaining and not queued_casts.is_empty():
		var first = current_cast_remaining
		advance(first)
		advance(delta - first)
		return
	if info.type == "plague" and delta > 0.025:
		var budget = delta
		while budget > 0.000001 and not is_queued_for_deletion():
			var step = minf(budget, 0.025)
			advance(step)
			budget -= step
		return
	var player = caster.get_ref() if caster else null
	if not is_instance_valid(player) or remaining <= 0.0:
		queue_free()
		return
	var elapsed = minf(delta, remaining)
	remaining -= elapsed
	elapsed_time += elapsed
	if info.type == "plague":
		advance_spores(elapsed)
		refresh_plague_lifetime()
	if info.type == "piercing":
		var start = global_position
		global_position += direction * 700.0 * float(info.get("projectile_speed_multiplier", 1.0)) * elapsed
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not valid_target(enemy) or hit_ids.has(enemy.get_instance_id()):
				continue
			if Geometry2D.get_closest_point_to_segment(enemy.global_position, start, global_position).distance_to(enemy.global_position) <= Geometry.LANCE_RADIUS * float(info.projectile_size_multiplier):
				hit_ids[enemy.get_instance_id()] = true
				deal_damage(enemy, damage)
				if info.get("explosive", false):
					var blast = preload("res://scripts/LingeringArea.gd").new()
					DamageSource.stamp(blast, DamageSource.of(self))
					blast.configure(enemy.global_position, float(info.get("explosion_radius", 90.0 * float(info.spell_size_multiplier))), float(info.get("explosion_damage", damage * 0.5)), float(info.get("explosion_duration", 0.2 * float(info.spell_duration_multiplier))), Color("ee6257"), "meteor", {enemy.get_instance_id(): true})
					get_parent().add_child(blast)
	else:
		if info.type == "orbit":
			global_position = player.global_position
			advance_orbit(elapsed)
		tick_remaining -= elapsed
		while tick_remaining <= 0.000001:
			tick_remaining += float(info.get("tick_interval", 0.5))
			match info.type:
				"field": pulse(global_position, float(info.get("radius", 150.0)), damage)
				"plague": tick_infections()
	advance_cast_segments(elapsed)
	queue_redraw()
	if remaining <= 0.0:
		queue_free()

func advance_orbit(delta: float):
	var radius = float(info.get("orbit_radius", 130.0))
	var body_radius = float(info.get("body_radius", 42.0))
	var count = int(info.get("orb_count", 3))
	var steps = maxi(1, ceili(delta / 0.025))
	for step in range(steps):
		angle += delta / steps * float(info.get("angular_speed", 4.0)) * float(info.get("projectile_speed_multiplier", 1.0))
		var time = elapsed_time - delta + delta * (step + 1) / steps
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not valid_target(enemy) or time < float(orbit_hit_times.get(enemy.get_instance_id(), -INF)):
				continue
			for index in range(count):
				var center = global_position + Vector2.from_angle(angle + TAU * index / count) * radius
				if center.distance_to(enemy.global_position) <= body_radius:
					orbit_hit_times[enemy.get_instance_id()] = time + float(info.get("tick_interval", 0.5))
					deal_damage(enemy, damage)
					break

func valid_target(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.get("dying") and float(enemy.get("current_health")) > 0.0

func deal_damage(enemy, amount: float) -> float:
	if not valid_target(enemy):
		return 0.0
	var before = float(enemy.current_health)
	enemy.take_damage(amount, global_position, DamageSource.of(self))
	var lost = maxf(0.0, before - float(enemy.current_health))
	var player = caster.get_ref()
	if is_instance_valid(player) and info.get("lifesteal", 0.0) > 0.0 and lost > 0.0:
		var healing = minf(healing_remaining, lost * float(info.lifesteal))
		healing_remaining -= healing
		player.heal(healing)
		if healing > 0:
			var bloom = preload("res://scripts/EffectBurst.gd").new()
			bloom.kind = "heal"
			bloom.radius = 22
			bloom.duration = 0.3
			get_parent().add_child(bloom)
			bloom.global_position = player.global_position
	return lost

func pulse(center: Vector2, radius: float, amount: float, excluded = null):
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == excluded or not valid_target(enemy) or center.distance_to(enemy.global_position) > radius:
			continue
		deal_damage(enemy, amount)
		if info.get("slow", 0.0) > 0.0 and enemy.has_method("apply_slow"):
			enemy.apply_slow(1.0 - float(info.slow), 0.7)

func show_area(center: Vector2, radius: float, tint: Color):
	var effect = preload("res://scripts/EffectBurst.gd").new()
	effect.mode = "area"
	effect.radius = radius
	effect.tint = tint
	effect.duration = 0.25
	get_parent().add_child(effect)
	effect.global_position = center

## Reach of each infection jump; Plague Seed starts shorter and grows with rank.
func spread_radius() -> float:
	return float(info.get("spread_radius", 130.0)) * float(info.spell_size_multiplier)

func spore_lifetime() -> float:
	return float(info.get("orphan_lifetime", float(info.get("spore_linger", SPORE_LINGER)) * float(info.get("spell_duration_multiplier", 1.0))))

func infect(enemy, source: Vector2 = Vector2.INF, search_range: float = 130.0, expires: float = -1.0):
	if not valid_target(enemy) or hit_ids.has(enemy.get_instance_id()) or (ENFORCE_HOST_LIMIT and hosts_started + infection_links.size() >= HOST_LIMIT):
		return
	hit_ids[enemy.get_instance_id()] = true
	var origin = global_position if source == Vector2.INF else source
	infection_links.append({"from": origin, "position": origin, "target": weakref(enemy), "target_id": enemy.get_instance_id(), "range": search_range, "expires": elapsed_time + spore_lifetime() if expires < 0 else expires})
	refresh_plague_lifetime()

func nearest_host(center: Vector2, search_range: float):
	var nearest = null
	var distance = search_range
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if valid_target(candidate) and not hit_ids.has(candidate.get_instance_id()):
			var candidate_distance = center.distance_to(candidate.global_position)
			if candidate_distance <= distance:
				distance = candidate_distance
				nearest = candidate
	return nearest

func rest_spore(center: Vector2, expires: float = -1.0):
	if ENFORCE_HOST_LIMIT and (hosts_started >= HOST_LIMIT or infections.size() + infection_links.size() + resting_spores.size() >= HOST_LIMIT):
		return
	resting_spores.append({"position": center, "expires": elapsed_time + spore_lifetime() if expires < 0 else expires, "fresh": expires < 0})
	refresh_plague_lifetime()

func refresh_plague_lifetime():
	var end = elapsed_time
	for id in infection_expires:
		end = maxf(end, float(infection_expires[id]))
	for link in infection_links:
		end = maxf(end, float(link.expires))
	for spore in resting_spores:
		end = maxf(end, float(spore.expires))
	if end > elapsed_time:
		remaining = maxf(remaining, end - elapsed_time + 0.025)

func advance_spores(delta: float):
	for reference in infections.duplicate():
		var host = reference.get_ref()
		if not is_instance_valid(host):
			infections.erase(reference)
		elif not valid_target(host):
			_on_infected_host_died(host)
		elif elapsed_time >= float(infection_expires.get(host.get_instance_id(), INF)):
			infections.erase(reference)
			infection_expires.erase(host.get_instance_id())
	for spore in resting_spores.duplicate():
		if elapsed_time >= spore.expires:
			resting_spores.erase(spore)
			continue
		var host = nearest_host(spore.position, spread_radius())
		if host:
			resting_spores.erase(spore)
			infect(host, spore.position, spread_radius(), elapsed_time + spore_lifetime() if spore.fresh else spore.expires)
	for link in infection_links.duplicate():
		if elapsed_time >= link.expires:
			infection_links.erase(link)
			continue
		var enemy = link.target.get_ref()
		if not valid_target(enemy):
			infection_links.erase(link)
			var replacement = nearest_host(link.position, float(link.range))
			if replacement:
				infect(replacement, link.position, float(link.range), link.expires)
			else:
				rest_spore(link.position, link.expires)
			continue
		link.position = link.position.move_toward(enemy.global_position, float(info.get("spread_speed", 460.0)) * float(info.get("projectile_speed_multiplier", 1.0)) * delta)
		if link.position.distance_to(enemy.global_position) <= 0.001:
			hosts_started += 1
			infections.append(weakref(enemy))
			infected_at[enemy.get_instance_id()] = elapsed_time
			infection_expires[enemy.get_instance_id()] = elapsed_time + infection_duration
			if enemy.has_signal("enemy_died"):
				enemy.connect("enemy_died", _on_infected_host_died, CONNECT_ONE_SHOT)
			infection_links.erase(link)

func tick_infections():
	healing_remaining = float(info.get("healing_tick_cap", 2.0))
	for reference in infections.duplicate():
		var enemy = reference.get_ref()
		if not valid_target(enemy) or elapsed_time - float(infected_at.get(enemy.get_instance_id(), elapsed_time)) + 0.000001 < float(info.get("tick_interval", 0.5)):
			continue
		var center = enemy.global_position
		deal_damage(enemy, damage)
		if valid_target(enemy):
			spread_from(center)
		else:
			_on_infected_host_died(enemy)

func _on_infected_host_died(enemy):
	var id = enemy.get_instance_id()
	if remaining <= 0 or is_queued_for_deletion() or death_transfers.has(id) or not infection_expires.has(id):
		return
	death_transfers[id] = true
	if float(info.get("healing_bloom_amount", 0.0)) > 0:
		var bloom = preload("res://scripts/HealingSeed.gd").new()
		bloom.player_ref = caster
		bloom.healing_amount = float(info.healing_bloom_amount)
		bloom.radius = float(info.get("healing_bloom_radius", 48.0))
		bloom.remaining = float(info.get("healing_bloom_lifetime", 10.0))
		bloom.position = get_parent().to_local(enemy.global_position)
		get_parent().add_child(bloom)
	infections = infections.filter(func(reference): return reference.get_ref() != enemy)
	infection_expires.erase(id)
	if not spread_from(enemy.global_position):
		rest_spore(enemy.global_position)

func spread_from(center: Vector2) -> bool:
	if ENFORCE_HOST_LIMIT and hosts_started >= HOST_LIMIT:
		return false
	var other = nearest_host(center, spread_radius())
	if other:
		infect(other, center, spread_radius())
		return true
	return false

func _draw():
	var art = preload("res://scripts/EffectArt.gd")
	match info.type:
		"piercing":
			art.stamp(self, "lance", direction * Geometry.stamp_offset("lance", Geometry.LANCE_RADIUS * float(info.projectile_size_multiplier)).x, Visual.size(self, Geometry.stamp_dimensions("lance", Geometry.LANCE_RADIUS * float(info.projectile_size_multiplier))), Color.WHITE, direction.angle())
			if info.get("explosive", false):
				art.stamp(self, "meteor", -direction * 18, Visual.size(self, Vector2.ONE * 24 * float(info.spell_size_multiplier)))
		"field":
			var radius = float(info.get("radius", 150.0))
			if info.get("slow", 0.0) > 0:
				preload("res://scripts/AreaArt.gd").steam_circle(self, Vector2.ZERO, radius, elapsed_time)
			else:
				preload("res://scripts/AreaArt.gd").fire_circle(self, Vector2.ZERO, radius, elapsed_time)
		"orbit":
			var count = int(info.get("orb_count", 3))
			var body_radius = float(info.get("body_radius", 42.0))
			for i in range(count):
				var center = Vector2.from_angle(angle + TAU * i / count) * float(info.get("orbit_radius", 130.0))
				preload("res://scripts/AreaArt.gd").circle(self, center, body_radius * Visual.factor(self), Color("b49bea"), 0.35)
				art.stamp(self, "orbit", center, Visual.size(self, Geometry.stamp_dimensions("orbit", body_radius)), Color.WHITE, angle + TAU * i / count)
		"plague":
			for spore in resting_spores:
				var pulse_size = 30.0 + sin(elapsed_time * 5.0) * 3.0
				art.stamp(self, "plague", to_local(spore.position), Visual.size(self, Vector2.ONE * pulse_size * float(info.spell_size_multiplier)), Color.WHITE)
			for link in infection_links:
				var from = to_local(link.from)
				var point = to_local(link.position)
				var heading = from.direction_to(point)
				for index in range(2, -1, -1):
					art.stamp(self, "plague", point - heading * index * 10, Visual.size(self, Vector2.ONE * (32 - index * 6) * float(info.spell_size_multiplier)))
			for reference in infections:
				var enemy = reference.get_ref()
				if valid_target(enemy):
					var center = to_local(enemy.global_position)
					art.stamp(self, "plague", center + Vector2(0, -58), Vector2.ONE * 34)
					for index in range(3):
						var phase = fmod(elapsed_time * 0.8 + index / 3.0, 1.0)
						art.stamp(self, "plague", center + Vector2((index - 1) * 17, -12 - phase * 30), Vector2.ONE * 12, Color(1, 1, 1, 1 - phase * 0.65))
