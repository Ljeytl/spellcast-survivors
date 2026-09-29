extends Node2D

const WARNING_SECONDS := 0.65
const AFTERGLOW_SECONDS := 0.85
const BOSS_HEALTH_FRACTION := 0.60
const ARMORED_ELITE_TYPE := 1

var footprint := Rect2()
var game: Node
var elapsed := 0.0
var impacted := false
var configured := false
var reduced_effects := false

func configure(source_game: Node) -> void:
	game = source_game
	var viewport := game.get_viewport()
	footprint = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	configured = true
	_read_reduced_effects()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	top_level = true
	global_transform = Transform2D.IDENTITY
	z_index = 90
	if not configured:
		queue_free()

func _read_reduced_effects() -> void:
	if not is_instance_valid(game):
		return
	var manager = game.get("particle_manager")
	if is_instance_valid(manager):
		reduced_effects = bool(manager.get("reduced_effects"))

func _process(delta: float) -> void:
	elapsed += delta
	_read_reduced_effects()
	if elapsed >= WARNING_SECONDS and not impacted:
		_impact()
	if elapsed >= WARNING_SECONDS + AFTERGLOW_SECONDS:
		queue_free()
	queue_redraw()

func _impact() -> void:
	if impacted:
		return
	impacted = true
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy is Node2D:
			continue
		if not footprint.has_point(enemy.global_position) or not enemy.has_method("take_damage"):
			continue
		var health = enemy.get("current_health")
		if health == null or float(health) <= 0.0:
			continue
		var damage := float(health)
		if enemy.is_in_group("bosses"):
			damage = float(enemy.get("max_health")) * BOSS_HEALTH_FRACTION
		else:
			var armored = enemy.get("is_elite")
			var elite_type = enemy.get("elite_type")
			if armored == true and elite_type == ARMORED_ELITE_TYPE:
				damage /= maxf(0.001, 1.0 - float(enemy.get("damage_reduction")))
			damage += 1.0
		enemy.take_damage(damage)
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"):
		if is_instance_valid(projectile) and projectile is Node2D and footprint.has_point(projectile.global_position):
			projectile.queue_free()
	if not reduced_effects and is_instance_valid(game) and game.has_method("shake_heavy"):
		game.shake_heavy()

func _draw() -> void:
	if not configured:
		return
	var center := footprint.get_center()
	var radius := minf(footprint.size.x, footprint.size.y) * 0.44
	var gold := Color(1.0, 0.72, 0.20)
	if not impacted:
		var progress := clampf(elapsed / WARNING_SECONDS, 0.0, 1.0)
		draw_rect(footprint, Color(0.82, 0.40, 0.08, 0.07))
		draw_rect(footprint, Color(1.0, 0.72, 0.20, 0.5 + progress * 0.4), false, 3.0)
		_draw_angular_circle(center, radius, gold, 3.0)
		_draw_angular_circle(center, radius * (0.35 + progress * 0.55), gold, 2.0)
		for i in 12:
			var direction := Vector2.from_angle(TAU * i / 12.0)
			var tangent := direction.orthogonal()
			var point := center + direction * radius
			draw_line(point - direction * 17.0, point + direction * 17.0, gold, 3.0)
			draw_line(point, point + direction * 10.0 + tangent * 9.0, gold, 3.0)
		return
	var age := elapsed - WARNING_SECONDS
	var fade := clampf(1.0 - age / AFTERGLOW_SECONDS, 0.0, 1.0)
	if not reduced_effects:
		var flash := maxf(0.0, 1.0 - age / 0.18)
		draw_rect(footprint, Color(1.0, 0.84, 0.44, flash * 0.55))
	else:
		draw_rect(footprint, Color(0.72, 0.42, 0.10, fade * 0.08))
	draw_rect(footprint, Color(1.0, 0.72, 0.20, fade), false, 4.0)
	var expansion := clampf(age / 0.45, 0.0, 1.0)
	var shock := Rect2(center - footprint.size * expansion * 0.5, footprint.size * expansion)
	draw_rect(shock, Color(1.0, 0.84, 0.40, fade * 0.8), false, 6.0 if not reduced_effects else 2.0)
	_draw_angular_circle(center, radius, Color(1.0, 0.72, 0.20, fade * 0.5), 2.0)

func _draw_angular_circle(center: Vector2, radius: float, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i in 17:
		points.append(center + Vector2.from_angle(TAU * i / 16.0) * radius)
	draw_polyline(points, color, width)
