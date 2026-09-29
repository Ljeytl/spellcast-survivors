extends Node2D

const DROP_CHANCE = 0.01
const PICKUP_RADIUS = 30.0
const MAX_DROPS = 12
const RECLAIM_DISTANCE = 2000.0
var collected = false
var player: Node2D

static func try_drop(parent: Node, point: Vector2, roll: float = -1.0, guaranteed: bool = false):
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return null
	var chance = randf() if roll < 0.0 else roll
	if not guaranteed and chance >= DROP_CHANCE:
		return null
	var drops = parent.get_tree().get_nodes_in_group("style_pickups")
	if not guaranteed and drops.size() >= MAX_DROPS:
		var target = parent.get_tree().get_first_node_in_group("player")
		var oldest_distant = null
		var farthest = RECLAIM_DISTANCE
		if is_instance_valid(target):
			for drop in drops:
				var distance = drop.global_position.distance_to(target.global_position)
				var screen = drop.get_global_transform_with_canvas().origin
				if distance > farthest and not drop.get_viewport_rect().grow(100).has_point(screen):
					farthest = distance
					oldest_distant = drop
		if oldest_distant == null:
			return null
		oldest_distant.remove_from_group("style_pickups")
		oldest_distant.queue_free()
	var pickup = load("res://scripts/StylePickup.gd").new()
	parent.add_child(pickup)
	pickup.global_position = point
	return pickup

func _ready():
	add_to_group("style_pickups")
	player = get_tree().get_first_node_in_group("player")
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(_delta):
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= PICKUP_RADIUS:
		collect()

func collect() -> bool:
	if collected or not is_instance_valid(player) or player.health <= 0.0:
		return false
	var game = get_tree().get_first_node_in_group("game")
	if not is_instance_valid(game) or not is_instance_valid(game.style_session):
		return false
	collected = true
	if not game.style_session.collect_style_pickup():
		collected = false
		return false
	get_node("/root/AudioManager").on_xp_collected()
	queue_free()
	return true

func _draw():
	var outer = PackedVector2Array([Vector2(0, -23), Vector2(19, 0), Vector2(0, 23), Vector2(-19, 0)])
	var inner = PackedVector2Array([Vector2(0, -18), Vector2(14, 0), Vector2(0, 18), Vector2(-14, 0)])
	draw_colored_polygon(outer, Color("30233f"))
	draw_colored_polygon(inner, Color("eab64f"))
	draw_line(Vector2(4, -11), Vector2(-5, 0), Color("fff5bd"), 5)
	draw_line(Vector2(-5, 0), Vector2(5, 0), Color("fff5bd"), 5)
	draw_line(Vector2(5, 0), Vector2(-4, 11), Color("fff5bd"), 5)
