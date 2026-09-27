extends Node2D

@export var orbit_radius = 94.5
@export var angular_speed = 3.0
@export var angle_deadzone = 0.08
var orbit_angle = -0.7
var hover_time = 0.0
var target: Node2D
var staff: Sprite2D

func _ready():
	name = "OrbitingStaff"
	staff = Sprite2D.new()
	staff.texture = preload("res://assets/typecast/Main Character/Wizard Staff 1.png")
	staff.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	staff.scale = Vector2(2.625, 2.625)
	add_child(staff)
	update_orbit(0.0)

func eligible(enemy: Node2D) -> bool:
	if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy.is_visible_in_tree():
		return false
	if enemy.get("dying") == true or float(enemy.get("current_health")) <= 0.0:
		return false
	return get_viewport_rect().has_point(enemy.get_global_transform_with_canvas().origin)

func select_target() -> Node2D:
	var nearest: Node2D
	var distance = INF
	var boss_selected = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not eligible(enemy):
			continue
		var is_boss = enemy.is_in_group("bosses")
		if boss_selected and not is_boss:
			continue
		var candidate_distance = get_parent().global_position.distance_squared_to(enemy.global_position)
		if (is_boss and not boss_selected) or candidate_distance < distance:
			nearest = enemy
			distance = candidate_distance
			boss_selected = is_boss
	return nearest

func update_orbit(delta: float):
	target = select_target()
	if is_instance_valid(target):
		var direction = target.global_position - get_parent().global_position
		if not direction.is_zero_approx():
			var difference = wrapf(direction.angle() - orbit_angle, -PI, PI)
			if absf(difference) > angle_deadzone:
				orbit_angle += clampf(difference, -angular_speed * delta, angular_speed * delta)
	hover_time += delta
	position = Vector2.from_angle(orbit_angle) * orbit_radius
	staff.position.y = sin(hover_time * 2.5) * 3.0
	staff.rotation = sin(hover_time * 1.7) * 0.06
	z_index = -1 if position.y < 0 else 1

func _process(delta):
	update_orbit(delta)
