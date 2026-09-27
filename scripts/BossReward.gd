extends Node2D

const TEXTURE = preload("res://sprites/items/chest_2_closed.png")
var collected = false
var collection_radius = 58.0

func _ready():
	add_to_group("boss_rewards")
	z_index = 3
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _physics_process(_delta):
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= collection_radius:
		collect()

func collect() -> bool:
	if collected:
		return false
	var game = get_tree().get_first_node_in_group("game")
	if not game or not game.queue_boss_reward():
		return false
	collected = true
	queue_free()
	return true

func _draw():
	draw_circle(Vector2.ZERO, 34, Color(0.9, 0.67, 0.2, 0.22))
	draw_arc(Vector2.ZERO, 34, 0, TAU, 32, Color("f7d87a"), 3)
	draw_texture_rect(TEXTURE, Rect2(-40, -40, 80, 80), false)
