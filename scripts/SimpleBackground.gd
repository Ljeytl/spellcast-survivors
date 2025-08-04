extends Node2D

# Simple tiled background using direct texture loading
var floor_texture: Texture2D
var tile_size: int = 32
var last_camera_pos: Vector2
var cache_threshold: float = 32.0

func _ready():
	print("🎨 SimpleBackground starting...")
	
	# Try to load a simple floor texture directly
	floor_texture = load("res://sprites/environment/floor_stone.png")
	if floor_texture:
		print("✅ Loaded floor texture successfully!")
		print("📐 Texture size: ", floor_texture.get_width(), "x", floor_texture.get_height())
	else:
		print("❌ Failed to load floor texture")
		# Try alternative texture
		floor_texture = load("res://sprites/environment/limestone_0.png")
		if floor_texture:
			print("✅ Loaded limestone texture as fallback!")
		else:
			print("❌ No textures available - will use colored background")

func _draw():
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var screen_size = get_viewport().get_visible_rect().size
	var camera_pos = camera.global_position
	
	if floor_texture:
		# Draw tiled floor
		draw_tiled_floor(camera_pos, screen_size)
	else:
		# Fallback: solid color background
		var half_screen = screen_size * 0.5
		var rect = Rect2(camera_pos - half_screen, screen_size)
		draw_rect(rect, Color(0.3, 0.25, 0.2))  # Brown dungeon color

func draw_tiled_floor(camera_pos: Vector2, screen_size: Vector2):
	# Calculate visible area
	var half_screen = screen_size * 0.5
	var top_left = camera_pos - half_screen - Vector2(64, 64)
	var bottom_right = camera_pos + half_screen + Vector2(64, 64)
	
	# Calculate tile grid bounds
	var start_x = floor(top_left.x / tile_size) * tile_size
	var start_y = floor(top_left.y / tile_size) * tile_size
	var end_x = ceil(bottom_right.x / tile_size) * tile_size
	var end_y = ceil(bottom_right.y / tile_size) * tile_size
	
	# Draw tiles
	var y = start_y
	while y < end_y:
		var x = start_x
		while x < end_x:
			draw_texture(floor_texture, Vector2(x, y))
			x += tile_size
		y += tile_size

func _process(_delta):
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var camera_pos = camera.global_position
	var distance = last_camera_pos.distance_to(camera_pos)
	
	if distance > cache_threshold:
		queue_redraw()
		last_camera_pos = camera_pos