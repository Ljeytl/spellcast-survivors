extends Node2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 230.0
var damage: float = 7.0
var remaining: float = 6.0
var warning_time: float = 0.0
var blast_radius: float = 0.0
var detonated: bool = false
var damage_source: String = ""
var attacker: WeakRef
var source_position: Vector2 = Vector2.INF
var player: Node2D

func _ready():
	add_to_group("enemy_projectiles")
	player = get_tree().get_first_node_in_group("player")
	z_index = 20

func _physics_process(delta):
	if not is_instance_valid(player):
		queue_free()
		return
	if blast_radius > 0.0:
		warning_time -= delta
		if warning_time <= 0.0 and not detonated:
			detonated = true
			remaining = 0.18
			if global_position.distance_to(player.global_position) <= blast_radius + 16.0:
				player.take_damage(damage, damage_context("blast"))
		if detonated:
			remaining -= delta
	else:
		var start = global_position
		global_position += direction * speed * delta
		var closest = Geometry2D.get_closest_point_to_segment(player.global_position, start, global_position)
		if closest.distance_to(player.global_position) <= 24.0:
			player.take_damage(damage, damage_context("projectile"))
			queue_free()
		remaining -= delta
	if remaining <= 0.0:
		queue_free()
	queue_redraw()

func _draw():
	if blast_radius > 0.0:
		draw_circle(Vector2.ZERO, blast_radius, Color(1, 0.08, 0.05, 0.5 if detonated else 0.12))
		draw_arc(Vector2.ZERO, blast_radius, 0, TAU, 48, Color(1, 0.15, 0.1), 4.0)
		draw_line(Vector2(-12, 0), Vector2(12, 0), Color.WHITE, 2.0)
		draw_line(Vector2(0, -12), Vector2(0, 12), Color.WHITE, 2.0)
	else:
		draw_rect(Rect2(-9, -9, 18, 18), Color(0.08, 0.02, 0.02))
		draw_rect(Rect2(-7, -7, 14, 14), Color("ff6b62"))
		draw_rect(Rect2(-7, -7, 14, 14), Color("fff0de"), false, 1.5)

func damage_context(kind: String) -> Dictionary:
	return {"kind": kind, "source": damage_source, "attacker": attacker, "source_position": source_position if source_position.is_finite() else global_position, "incoming_direction": direction}
