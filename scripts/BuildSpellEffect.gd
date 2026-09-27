extends Node2D

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
const Visual = preload("res://scripts/ProjectileVisual.gd")

func configure(data: Dictionary, amount: float, player: Node2D, target: Node2D):
	info = data.duplicate(true)
	damage = amount
	caster = weakref(player)
	global_position = player.global_position
	remaining = float(info.get("duration", 5.0))
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

func _ready():
	if is_in_group("projectile_visuals"):
		Visual.register(self)

func _physics_process(delta):
	advance(delta)

func advance(delta: float):
	if info.type == "plague" and delta > 0.025:
		var budget = delta
		while budget > 0.000001 and remaining > 0.0:
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
	if info.type == "piercing":
		var start = global_position
		global_position += direction * 700.0 * float(info.get("projectile_speed_multiplier", 1.0)) * elapsed
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not valid_target(enemy) or hit_ids.has(enemy.get_instance_id()):
				continue
			if Geometry2D.get_closest_point_to_segment(enemy.global_position, start, global_position).distance_to(enemy.global_position) <= 24.0:
				hit_ids[enemy.get_instance_id()] = true
				deal_damage(enemy, damage)
				if info.get("explosive", false):
					pulse(enemy.global_position, 90.0, damage * 0.5, enemy)
					show_area(enemy.global_position, 90.0, Color("ee6257"))
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
	queue_redraw()
	if remaining <= 0.0:
		queue_free()

func advance_orbit(delta: float):
	var radius = float(info.get("orbit_radius", 130.0))
	var body_radius = float(info.get("body_radius", 42.0))
	var count = int(info.get("orb_count", 3))
	var steps = maxi(1, ceili(delta / 0.025))
	for step in range(steps):
		angle += delta / steps * float(info.get("angular_speed", 4.0))
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
	enemy.take_damage(amount, global_position)
	var lost = maxf(0.0, before - float(enemy.current_health))
	var player = caster.get_ref()
	if is_instance_valid(player) and info.get("lifesteal", 0.0) > 0.0 and lost > 0.0:
		var healing = minf(healing_remaining, lost * float(info.lifesteal))
		healing_remaining -= healing
		player.heal(healing)
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

func infect(enemy, source: Vector2 = Vector2.INF, search_range: float = 130.0):
	if not valid_target(enemy) or hit_ids.has(enemy.get_instance_id()) or infections.size() + infection_links.size() >= 8:
		return
	hit_ids[enemy.get_instance_id()] = true
	var origin = global_position if source == Vector2.INF else source
	infection_links.append({"from": origin, "position": origin, "target": weakref(enemy), "target_id": enemy.get_instance_id(), "range": search_range})

func advance_spores(delta: float):
	for link in infection_links.duplicate():
		var enemy = link.target.get_ref()
		if not valid_target(enemy):
			hit_ids.erase(link.target_id)
			enemy = null
			var nearest = INF
			for candidate in get_tree().get_nodes_in_group("enemies"):
				if valid_target(candidate) and not hit_ids.has(candidate.get_instance_id()) and link.from.distance_to(candidate.global_position) <= link.range:
					var distance = link.position.distance_squared_to(candidate.global_position)
					if distance < nearest:
						nearest = distance
						enemy = candidate
			if not enemy:
				infection_links.erase(link)
				continue
			link.target = weakref(enemy)
			link.target_id = enemy.get_instance_id()
			hit_ids[link.target_id] = true
		link.position = link.position.move_toward(enemy.global_position, 460.0 * float(info.get("projectile_speed_multiplier", 1.0)) * delta)
		if link.position.distance_to(enemy.global_position) <= 0.001:
			infections.append(weakref(enemy))
			infected_at[enemy.get_instance_id()] = elapsed_time
			if enemy.has_signal("enemy_died"):
				enemy.connect("enemy_died", _on_infected_host_died, CONNECT_ONE_SHOT)
			infection_links.erase(link)

func tick_infections():
	healing_remaining = 2.0
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
	if remaining > 0.0 and not is_queued_for_deletion() and not death_transfers.has(id):
		death_transfers[id] = true
		spread_from(enemy.global_position)

func spread_from(center: Vector2):
	if infections.size() + infection_links.size() >= 8:
		return
	for other in get_tree().get_nodes_in_group("enemies"):
		if valid_target(other) and center.distance_to(other.global_position) <= 130.0 and not hit_ids.has(other.get_instance_id()):
			infect(other, center)
			break

func _draw():
	var art = preload("res://scripts/EffectArt.gd")
	match info.type:
		"piercing":
			art.stamp(self, "lance", Vector2.ZERO, Visual.size(self, Vector2(56, 24)), Color.WHITE, direction.angle())
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
				preload("res://scripts/AreaArt.gd").circle(self, center, body_radius * Visual.factor(self), Color("b49bea"), 0.8)
				art.stamp(self, "mana", center, Visual.size(self, Vector2.ONE * body_radius * 2), Color.WHITE, angle + TAU * i / count + PI / 2)
		"plague":
			for link in infection_links:
				var from = to_local(link.from)
				var point = to_local(link.position)
				var heading = from.direction_to(point)
				for index in range(2, -1, -1):
					art.stamp(self, "plague", point - heading * index * 10, Visual.size(self, Vector2.ONE * (32 - index * 6)))
			for reference in infections:
				var enemy = reference.get_ref()
				if valid_target(enemy):
					var center = to_local(enemy.global_position)
					art.stamp(self, "plague", center + Vector2(0, -58), Vector2.ONE * 34)
					for index in range(3):
						var phase = fmod(elapsed_time * 0.8 + index / 3.0, 1.0)
						art.stamp(self, "plague", center + Vector2((index - 1) * 17, -12 - phase * 30), Vector2.ONE * 12, Color(1, 1, 1, 1 - phase * 0.65))
