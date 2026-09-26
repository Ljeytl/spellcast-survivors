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

func configure(data: Dictionary, amount: float, player: Node2D, target: Node2D):
	info = data.duplicate(true)
	damage = amount
	caster = weakref(player)
	global_position = player.global_position
	remaining = float(info.get("duration", 5.0))
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		if info.type == "field":
			global_position = target.global_position
		if info.type == "plague":
			infect(target)
	if info.type == "piercing":
		remaining = 1.5
	if info.type == "plague":
		color = Color.GREEN_YELLOW
	if info.type == "orbit":
		color = Color.MEDIUM_PURPLE
	if info.get("slow", 0.0) > 0:
		color = Color.LIGHT_CYAN
	add_to_group("build_spell_effects")

func _physics_process(delta):
	advance(delta)

func advance(delta: float):
	var player = caster.get_ref() if caster else null
	if not is_instance_valid(player) or remaining <= 0.0:
		queue_free()
		return
	var elapsed = minf(delta, remaining)
	remaining -= elapsed
	if info.type == "piercing":
		var start = global_position
		global_position += direction * 700.0 * elapsed
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not valid_target(enemy) or hit_ids.has(enemy.get_instance_id()):
				continue
			if Geometry2D.get_closest_point_to_segment(enemy.global_position, start, global_position).distance_to(enemy.global_position) <= 24.0:
				hit_ids[enemy.get_instance_id()] = true
				deal_damage(enemy, damage)
				if info.get("explosive", false):
					pulse(enemy.global_position, 90.0, damage * 0.5, enemy)
	else:
		if info.type == "orbit":
			global_position = player.global_position
			angle += elapsed * 4.0
		tick_remaining -= elapsed
		while tick_remaining <= 0.0:
			tick_remaining += 0.5
			match info.type:
				"field": pulse(global_position, 150.0, damage)
				"orbit":
					for i in range(3):
						pulse(global_position + Vector2.from_angle(angle + TAU * i / 3.0) * 65.0, 38.0, damage)
				"plague": tick_infections()
	queue_redraw()
	if remaining <= 0.0:
		queue_free()

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

func infect(enemy):
	if not valid_target(enemy) or hit_ids.has(enemy.get_instance_id()) or infections.size() >= 8:
		return
	hit_ids[enemy.get_instance_id()] = true
	infections.append(weakref(enemy))

func tick_infections():
	healing_remaining = 2.0
	var enemies = get_tree().get_nodes_in_group("enemies")
	for reference in infections.duplicate():
		var enemy = reference.get_ref()
		if not valid_target(enemy):
			continue
		var center = enemy.global_position
		deal_damage(enemy, damage)
		if infections.size() >= 8:
			continue
		for other in enemies:
			if valid_target(other) and center.distance_to(other.global_position) <= 130.0 and not hit_ids.has(other.get_instance_id()):
				infect(other)
				break

func _draw():
	match info.type:
		"piercing":
			draw_line(-direction * 55.0, direction * 15.0, color, 8.0)
		"field":
			draw_circle(Vector2.ZERO, 150.0, Color(color, 0.16))
			draw_arc(Vector2.ZERO, 150.0, 0, TAU, 48, color, 3.0)
		"orbit":
			for i in range(3):
				draw_circle(Vector2.from_angle(angle + TAU * i / 3.0) * 65.0, 15.0, color)
		"plague":
			for reference in infections:
				var enemy = reference.get_ref()
				if valid_target(enemy):
					draw_arc(to_local(enemy.global_position), 22.0, 0, TAU, 16, color, 3.0)
