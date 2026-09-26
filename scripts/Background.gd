extends Node2D

const CELL_SIZE = 460.0
const TRUNK_RADIUS = 22.0
const TILE_SIZE = 128.0
const ART = "res://assets/typecast/"
var camera: Camera2D
var player: CharacterBody2D
var clearing_center = Vector2.ZERO
var initialized = false
var floor_textures: Array[Texture2D] = []
var decorations: Dictionary = {}
var last_cell = Vector2i(2147483647, 2147483647)
var last_view = Vector2.ZERO

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = -100
	for i in range(1, 10):
		floor_textures.append(load(ART + "Level Tiles/Grass Tile %d.png" % i))
	initialize.call_deferred()

func initialize():
	camera = get_parent().get_node("Camera2D")
	player = get_parent().get_node("Player")
	clearing_center = player.global_position
	initialized = true
	refresh_decorations()
	queue_redraw()

func cell_for(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / CELL_SIZE), floori(point.y / CELL_SIZE))

func tree_position(cell: Vector2i) -> Vector2:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("typecast:%d:%d" % [cell.x, cell.y])
	return Vector2(cell) * CELL_SIZE + Vector2(CELL_SIZE / 2, CELL_SIZE / 2) + Vector2(rng.randf_range(-95, 95), rng.randf_range(-95, 95))

func has_tree(cell: Vector2i) -> bool:
	return tree_position(cell).distance_to(clearing_center) > 300.0

func nearby_trunks(point: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var cell = cell_for(point)
	for y in range(cell.y - 1, cell.y + 2):
		for x in range(cell.x - 1, cell.x + 2):
			var key = Vector2i(x, y)
			if has_tree(key):
				result.append(tree_position(key))
	return result

func is_clear(point: Vector2, radius: float) -> bool:
	for trunk in nearby_trunks(point):
		if point.distance_to(trunk) < radius + TRUNK_RADIUS + 8:
			return false
	return true

func clear_spawn(point: Vector2, radius: float) -> Vector2:
	if is_clear(point, radius):
		return point
	for ring in range(1, 7):
		for step in range(16):
			var candidate = point + Vector2.from_angle(step * TAU / 16) * ring * 48.0
			if is_clear(candidate, radius):
				return candidate
	return clearing_center

func steer(point: Vector2, desired: Vector2, radius: float) -> Vector2:
	if desired.is_zero_approx():
		return desired
	var heading = desired.normalized()
	for trunk in nearby_trunks(point):
		var offset = trunk - point
		var ahead = offset.dot(heading)
		var clearance = radius + TRUNK_RADIUS + 18.0
		if ahead > 0 and ahead < clearance + 90 and absf(offset.cross(heading)) < clearance:
			var side = 1.0 if offset.cross(heading) < 0 else -1.0
			return (heading * 0.25 + heading.orthogonal() * side).normalized() * desired.length()
	return desired

func refresh_decorations():
	var cell = cell_for(player.global_position)
	var view = get_viewport_rect().size / camera.zoom
	if cell == last_cell and view == last_view:
		return
	last_cell = cell
	last_view = view
	var extent = Vector2i(ceili(view.x / (2 * CELL_SIZE)) + 2, ceili(view.y / (2 * CELL_SIZE)) + 2)
	var wanted: Dictionary = {}
	for y in range(cell.y - extent.y, cell.y + extent.y + 1):
		for x in range(cell.x - extent.x, cell.x + extent.x + 1):
			var key = Vector2i(x, y)
			wanted[key] = true
			if not decorations.has(key):
				decorations[key] = create_decoration(key)
	for key in decorations.keys():
		if not wanted.has(key):
			decorations[key].queue_free()
			decorations.erase(key)

func create_decoration(cell: Vector2i) -> Node2D:
	var holder = Node2D.new()
	holder.position = tree_position(cell)
	add_child(holder)
	if has_tree(cell):
		var body = StaticBody2D.new()
		body.collision_layer = 32
		body.collision_mask = 0
		body.add_to_group("tree_obstacles")
		holder.add_child(body)
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = TRUNK_RADIUS
		shape.shape = circle
		body.add_child(shape)
		var tree = Sprite2D.new()
		tree.name = "Canopy"
		tree.texture = load(ART + ("Level Tiles/Level Deco/Fir Tree 1 shaded.png" if posmod(cell.x + cell.y, 2) == 0 else "Level Tiles/Level Deco/Fir Tree 1.png"))
		tree.scale = Vector2(2, 2)
		tree.position.y = 20 - tree.texture.get_height()
		tree.z_as_relative = false
		tree.z_index = 2
		holder.add_child(tree)
	var bush = Sprite2D.new()
	bush.texture = load(ART + "Level Tiles/Level Deco/Bush v%d.png" % (1 + posmod(cell.x + cell.y, 2)))
	bush.scale = Vector2(2, 2)
	bush.position = Vector2(125, 80)
	holder.add_child(bush)
	return holder

func _process(_delta):
	if not initialized:
		return
	refresh_decorations()
	var actors: Array = get_tree().get_nodes_in_group("enemies")
	actors.append(player)
	for holder in decorations.values():
		var canopy = holder.get_node_or_null("Canopy")
		if canopy:
			canopy.modulate.a = 1.0
			for actor in actors:
				var offset = actor.global_position - holder.global_position
				if absf(offset.x) < 100 and offset.y > -265 and offset.y < 40:
					canopy.modulate.a = 0.35
					break
	queue_redraw()

func _draw():
	if not initialized:
		return
	var half_view = get_viewport_rect().size / camera.zoom / 2 + Vector2.ONE * TILE_SIZE
	var center = camera.get_screen_center_position()
	for y in range(floori((center.y - half_view.y) / TILE_SIZE), ceili((center.y + half_view.y) / TILE_SIZE)):
		for x in range(floori((center.x - half_view.x) / TILE_SIZE), ceili((center.x + half_view.x) / TILE_SIZE)):
			var index = posmod(hash("grass:%d:%d" % [x, y]), floor_textures.size())
			draw_texture_rect(floor_textures[index], Rect2(Vector2(x, y) * TILE_SIZE, Vector2.ONE * TILE_SIZE), false, Color(0.72, 0.78, 0.72))
