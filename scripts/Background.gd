extends Node2D

var tile_size: Vector2 = Vector2(512, 512)  # Size of floor sprites - 4x larger for bigger tiles
var bg_color: Color = Color(0.1, 0.1, 0.15, 1.0)

@onready var camera: Camera2D = null
var last_camera_pos: Vector2
var cache_threshold: float = 32.0

# Floor textures
var floor_textures: Array[Texture2D] = []
var texture_weights: Array[float] = []

# Performance settings
var draw_distance: float = 800.0  # How far to draw tiles
var tile_cache: Dictionary = {}

# Debug logging
var log_file: FileAccess
var debug_log_path: String = "user://background_debug.log"

func _ready():
	# Setup debug logging
	setup_debug_log()
	
	debug_log("🎮 Background system starting...")
	
	# Delay camera search to ensure Game.gd has finished setup
	call_deferred("find_camera")
	
func find_camera():
	# Find camera reference - try multiple approaches
	camera = get_tree().get_first_node_in_group("camera")
	if not camera:
		# Look for camera in the scene
		var game_node = get_tree().get_first_node_in_group("game")
		if game_node:
			camera = game_node.get_node_or_null("Camera2D")
	
	debug_log("📷 Camera found: " + str(camera != null))
	if camera:
		debug_log("✅ Camera located successfully!")
	else:
		debug_log("❌ Camera not found - will retry")
	
	# Load floor textures
	load_floor_textures()

func load_floor_textures():
	# Load floor textures from the sprites/environment folder
	# Load consistent stone-themed floor textures
	var textures = [
		{"path": "res://sprites/environment/floor_stone.png", "weight": 40.0},
		{"path": "res://sprites/environment/limestone_0.png", "weight": 35.0},
		{"path": "res://sprites/environment/marble_floor_1.png", "weight": 25.0}
	]
	
	debug_log("🎨 Loading floor textures...")
	
	for tex_data in textures:
		var texture = load(tex_data.path)
		if texture:
			floor_textures.append(texture)
			texture_weights.append(tex_data.weight)
			debug_log("✅ Loaded texture: " + tex_data.path)
		else:
			debug_log("❌ Failed to load texture: " + tex_data.path)
	
	debug_log("🎨 Total loaded floor textures: " + str(floor_textures.size()))
	
	# Fallback: if no textures loaded, create a simple colored texture
	if floor_textures.is_empty():
		debug_log("⚠️ No textures loaded! Creating fallback...")
		create_fallback_textures()

func setup_debug_log():
	"""Setup debug logging to file"""
	# Print to console immediately to test if Background script is running
	print("🔧 Background script starting...")
	
	log_file = FileAccess.open(debug_log_path, FileAccess.WRITE)
	if log_file:
		var start_msg = "🔧 Debug log started - " + Time.get_datetime_string_from_system()
		print(start_msg)
		log_file.store_line(start_msg)
		log_file.store_line("📁 Log file: " + debug_log_path)
		log_file.flush()
		print("✅ Debug log file created successfully")
	else:
		print("❌ Failed to create debug log file at: " + debug_log_path)

func debug_log(message: String):
	"""Log message to both console and file"""
	var timestamp = Time.get_datetime_string_from_system()
	var log_message = "[" + timestamp + "] " + message
	
	# Print to console
	print(log_message)
	
	# Write to file
	if log_file:
		log_file.store_line(log_message)
		log_file.flush()

func create_fallback_textures():
	"""Create simple colored textures as fallback if image loading fails"""
	debug_log("🎨 Creating fallback textures...")
	
	var image = Image.create(512, 512, false, Image.FORMAT_RGB8)
	
	# Create consistent stone-themed floor textures
	var colors = [
		Color(0.45, 0.45, 0.45),  # Light gray stone
		Color(0.4, 0.4, 0.4),     # Medium gray stone
		Color(0.35, 0.35, 0.35)   # Dark gray stone
	]
	
	for color in colors:
		image.fill(color)
		var texture = ImageTexture.new()
		texture.set_image(image)
		floor_textures.append(texture)
		texture_weights.append(33.3)
	
	debug_log("✅ Created " + str(floor_textures.size()) + " fallback textures")

func _draw():
	if not camera:
		# Try to find camera again if we haven't found it yet
		camera = get_tree().get_first_node_in_group("camera")
		if not camera:
			var game_node = get_tree().get_first_node_in_group("game")
			if game_node:
				camera = game_node.get_node_or_null("Camera2D")
		
		# Only log occasionally to avoid spam
		if randi() % 60 == 0:  # Log every ~60 frames at 60fps = once per second
			debug_log("⚠️ _draw() called but no camera found!")
		return
	
	# If no textures, show a simple background
	if floor_textures.is_empty():
		debug_log("⚠️ _draw() called but no floor textures available!")
		var screen_size = get_viewport().get_visible_rect().size
		var camera_pos = camera.global_position
		var half_screen = screen_size * 0.5
		var rect = Rect2(camera_pos - half_screen, screen_size)
		draw_rect(rect, Color(0.2, 0.2, 0.25))
		return
	
	var screen_size = get_viewport().get_visible_rect().size
	var camera_pos = camera.global_position
	
	# Calculate visible area around camera
	var half_screen = screen_size * 0.5
	var top_left = camera_pos - half_screen - Vector2(256, 256)  # Extra margin for larger tiles
	var bottom_right = camera_pos + half_screen + Vector2(256, 256)
	
	# Draw tiled floor
	draw_tiled_floor(top_left, bottom_right)

func draw_tiled_floor(top_left: Vector2, bottom_right: Vector2):
	# Draw a tiled floor using various floor textures
	# Calculate grid bounds aligned to tile size
	var start_x = floor(top_left.x / tile_size.x) * tile_size.x
	var start_y = floor(top_left.y / tile_size.y) * tile_size.y
	var end_x = ceil(bottom_right.x / tile_size.x) * tile_size.x
	var end_y = ceil(bottom_right.y / tile_size.y) * tile_size.y
	
	# Draw tiles
	var y = start_y
	while y < end_y:
		var x = start_x
		while x < end_x:
			var tile_pos = Vector2(x, y)
			var texture = get_tile_texture(x, y)
			
			if texture:
				# Draw the floor tile scaled to tile_size with smooth filtering
				var dst_rect = Rect2(tile_pos, tile_size)
				draw_texture_rect(texture, dst_rect, false)
				
				# Occasionally add some variation/wear
				if get_tile_variation(x, y) > 0.9:
					# Slightly darken some tiles for variation
					draw_rect(Rect2(tile_pos, tile_size), Color(0, 0, 0, 0.1))
			
			x += tile_size.x
		y += tile_size.y

func get_tile_texture(x: float, y: float) -> Texture2D:
	# Get texture for a tile at given position, with deterministic randomness
	if floor_textures.is_empty():
		return null
	
	# Use position as seed for deterministic "randomness"
	var seed_value = int(x * 0.1) + int(y * 0.1) * 1000
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	# Weighted random selection
	var total_weight = 0.0
	for weight in texture_weights:
		total_weight += weight
	
	var random_value = rng.randf() * total_weight
	var current_weight = 0.0
	
	for i in range(floor_textures.size()):
		current_weight += texture_weights[i]
		if random_value <= current_weight:
			return floor_textures[i]
	
	# Fallback to first texture
	return floor_textures[0]

func get_tile_variation(x: float, y: float) -> float:
	# Get variation value for tile effects
	var seed_value = int(x * 0.05) + int(y * 0.05) * 2000 + 12345
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng.randf()

func _process(_delta):
	# Only redraw when camera moves significantly
	if not camera:
		return
	
	var camera_pos = camera.global_position
	var distance = last_camera_pos.distance_to(camera_pos)
	
	if distance > cache_threshold:
		queue_redraw()
		last_camera_pos = camera_pos
