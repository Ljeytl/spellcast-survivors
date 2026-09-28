extends Node2D

const DROP_CHANCE = 0.02
const HEAL_AMOUNT = 10.0
const PICKUP_RADIUS = 30.0
const MAX_DROPS = 12
const RECLAIM_DISTANCE = 2000.0
var collected = false
var player: Node2D

static func try_drop(parent: Node, point: Vector2, roll: float = -1.0):
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return null
	var chance = randf() if roll < 0.0 else roll
	if chance >= DROP_CHANCE:
		return null
	var drops = parent.get_tree().get_nodes_in_group("health_potions")
	if drops.size() >= MAX_DROPS:
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
		oldest_distant.remove_from_group("health_potions")
		oldest_distant.queue_free()
	var potion = load("res://scripts/HealthPotion.gd").new()
	parent.add_child(potion)
	potion.global_position = point
	return potion

func _ready():
	add_to_group("health_potions")
	player = get_tree().get_first_node_in_group("player")
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(_delta):
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= PICKUP_RADIUS:
		collect()

func collect() -> bool:
	if collected or not is_instance_valid(player) or player.health <= 0.0 or player.health >= player.max_health:
		return false
	collected = true
	player.heal(HEAL_AMOUNT)
	get_node("/root/AudioManager").on_xp_collected()
	queue_free()
	return true

func _draw():
	draw_rect(Rect2(-13, -8, 26, 26), Color("252b32"))
	draw_rect(Rect2(-9, -5, 18, 19), Color("d5eff0"))
	draw_rect(Rect2(-9, 1, 18, 13), Color("c9384b"))
	draw_rect(Rect2(-5, -15, 10, 11), Color("d5eff0"))
	draw_rect(Rect2(-6, -19, 12, 6), Color("9e6c43"))
	draw_rect(Rect2(-6, -2, 3, 10), Color("fff2d1"))
	draw_rect(Rect2(-2, 3, 4, 9), Color("fff2d1"))
	draw_rect(Rect2(-5, 6, 10, 3), Color("fff2d1"))
