extends Area2D

const VISUAL_SCALE = 1.5
const GREEN_THRESHOLD = 25.0
const PURPLE_THRESHOLD = 100.0

static var visual_textures: Array[Texture2D] = []

var collected: bool = false

var xp_value: float = 10.0:
	set(value):
		xp_value = value
		if is_node_ready():
			update_visual()
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
	if collected:
		return
	collected = true
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

func set_xp_value(value: float):
	xp_value = value

func update_visual():
	var tier = 2 if xp_value >= PURPLE_THRESHOLD else (1 if xp_value >= GREEN_THRESHOLD else 0)
	$Visual.scale = Vector2.ONE * VISUAL_SCALE * [1.0, 1.08, 1.16][tier]
	$Visual.texture = crystal_textures()[tier]

static func crystal_textures() -> Array:
	if visual_textures.is_empty():
		var original = preload("res://assets/typecast/Pickups/Mana Crystal.png")
		visual_textures.append(original)
		for hue in [0.32, 0.76]:
			var image = original.get_image()
			image.convert(Image.FORMAT_RGBA8)
			for y in range(image.get_height()):
				for x in range(image.get_width()):
					var pixel = image.get_pixel(x, y)
					if pixel.a > 0 and pixel.s > 0.15:
						image.set_pixel(x, y, Color.from_hsv(hue, pixel.s, pixel.v, pixel.a))
			visual_textures.append(ImageTexture.create_from_image(image))
	return visual_textures

func add_sparkle_effect():
	update_visual()

func play_collection_effect():
	# Create particle effect
	var scene_tree = get_tree()
	if scene_tree:
		var game_node = scene_tree.get_first_node_in_group("game")
		if game_node and game_node.has_method("create_xp_collect_effect"):
			game_node.create_xp_collect_effect(global_position)
