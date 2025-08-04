extends Node2D
class_name ChestManager

@export var chest_spawn_interval: float = 15.0  # Spawn chest every 15 seconds
@export var max_chests: int = 3  # Maximum chests on screen at once
@export var spawn_distance: float = 600.0  # Distance from player to spawn chests

var chest_scene = preload("res://scenes/Chest.tscn")
var active_chests: Array[Chest] = []
var spawn_timer: float = 0.0

@onready var player: CharacterBody2D = null
@onready var camera: Camera2D = null

func _ready():
	# Find player and camera
	player = get_tree().get_first_node_in_group("player")
	camera = get_tree().get_first_node_in_group("camera")
	
	if not player:
		# Try to find player through game node
		var game = get_tree().get_first_node_in_group("game")
		if game:
			player = game.get_node_or_null("Player")
	
	print("ChestManager: Player found: ", player != null)
	print("ChestManager: Camera found: ", camera != null)

func _process(delta):
	if not player:
		return
	
	spawn_timer += delta
	
	# Check if we should spawn a new chest
	if spawn_timer >= chest_spawn_interval and active_chests.size() < max_chests:
		spawn_timer = 0.0
	
	# Clean up collected chests from array
	active_chests = active_chests.filter(func(chest): return is_instance_valid(chest))

func spawn_chest():
	if not player:
		return
	
	var chest = chest_scene.instantiate() as Chest
	if not chest:
		print("ERROR: Failed to instantiate chest scene")
		return
	
	# Set random chest type
	chest.set_random_chest_type()
	
	# Position chest at screen edge
	var spawn_position = get_edge_spawn_position()
	chest.global_position = spawn_position
	
	# Connect chest collection signal
	chest.chest_collected.connect(_on_chest_collected)
	
	# Add to scene and track
	get_parent().add_child(chest)
	active_chests.append(chest)
	
	print("ChestManager: Spawned chest at ", spawn_position)

func get_edge_spawn_position() -> Vector2:
	if not player:
		return Vector2.ZERO
	
	var player_pos = player.global_position
	
	# Get screen dimensions
	var screen_size = get_viewport().get_visible_rect().size
	if camera:
		screen_size = screen_size / camera.zoom
	
	# Choose random edge (0=top, 1=right, 2=bottom, 3=left)
	var edge = randi() % 4
	var spawn_pos = Vector2.ZERO
	
	match edge:
		0:  # Top edge
			spawn_pos = Vector2(
				player_pos.x + randf_range(-screen_size.x * 0.6, screen_size.x * 0.6),
				player_pos.y - screen_size.y * 0.6
			)
		1:  # Right edge
			spawn_pos = Vector2(
				player_pos.x + screen_size.x * 0.6,
				player_pos.y + randf_range(-screen_size.y * 0.6, screen_size.y * 0.6)
			)
		2:  # Bottom edge
			spawn_pos = Vector2(
				player_pos.x + randf_range(-screen_size.x * 0.6, screen_size.x * 0.6),
				player_pos.y + screen_size.y * 0.6
			)
		3:  # Left edge
			spawn_pos = Vector2(
				player_pos.x - screen_size.x * 0.6,
				player_pos.y + randf_range(-screen_size.y * 0.6, screen_size.y * 0.6)
			)
	
	return spawn_pos

func _on_chest_collected(chest_type, health_reward: float, xp_reward: float):
	print("ChestManager: Chest collected - Type: ", chest_type, " Health: ", health_reward, " XP: ", xp_reward)
	
	# Create collection feedback
	var game = get_tree().get_first_node_in_group("game")
	if game:
		# Trigger screen shake
		if game.has_method("shake_light"):
			game.shake_light()

func force_spawn_chest():
	# Debug function to force spawn a chest
	if active_chests.size() < max_chests:
		spawn_chest()

func clear_all_chests():
	# Remove all active chests
	for chest in active_chests:
		if is_instance_valid(chest):
			chest.queue_free()
	active_chests.clear()
