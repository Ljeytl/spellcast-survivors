extends Area2D

var xp_value: float = 10.0
var collection_distance: float = 100.0
var move_speed: float = 200.0

var player: CharacterBody2D
var is_moving_to_player: bool = false

func _ready():
	# Find player
	var scene_tree = get_tree()
	if scene_tree:
		player = scene_tree.get_first_node_in_group("player")
	
	# Add to xp_orbs group
	add_to_group("xp_orbs")
	
	# Add some visual sparkle effect
	add_sparkle_effect()

func _process(delta):
	if not player:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Apply player's XP range multiplier
	var effective_collection_distance = collection_distance
	if player and player.has_method("get") and player.get("xp_range_multiplier") != null:
		effective_collection_distance = collection_distance * player.xp_range_multiplier
	
	# Start moving toward player when within collection distance
	if distance_to_player <= effective_collection_distance:
		is_moving_to_player = true
	
	# Move toward player
	if is_moving_to_player:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * move_speed * delta
		
		# Speed up as we get closer
		var speed_multiplier = max(1.0, 3.0 - (distance_to_player / 50.0))
		global_position += direction * move_speed * speed_multiplier * delta

func _on_collection_area_body_entered(body):
	if body.is_in_group("player"):
		collect_xp()

func _on_collection_area_area_entered(area):
	# Handle if player has Area2D components
	if area.get_parent() and area.get_parent().is_in_group("player"):
		collect_xp()

func collect_xp():
	# Give XP to player
	if player and player.has_method("add_xp"):
		player.add_xp(xp_value)
	
	# Play XP collection sound
	if AudioManager:
		AudioManager.on_xp_collected()
	
	# Play collection effect
	play_collection_effect()
	
	# Remove orb
	queue_free()

func add_sparkle_effect():
	# Simple pulsing effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property($Visual, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property($Visual, "scale", Vector2(1.0, 1.0), 0.5)

func play_collection_effect():
	# Create particle effect
	var scene_tree = get_tree()
	if scene_tree:
		var game_node = scene_tree.get_first_node_in_group("game")
		if game_node and game_node.has_method("create_xp_collect_effect"):
			game_node.create_xp_collect_effect(global_position)
	
	# Quick scale up before disappearing
	var tween = create_tween()
	tween.parallel().tween_property($Visual, "scale", Vector2(1.5, 1.5), 0.1)
	tween.parallel().tween_property($Visual, "modulate", Color.TRANSPARENT, 0.1)