extends Node2D

const CELL_SIZE = 800.0
const GROVE_RADIUS = 190.0
const MIN_TRUNK_SPACING = 180.0
const CLEARING_RADIUS = 300.0
const TRUNK_RADIUS = 11.0
const TREE_TRUNK_PIVOT = Vector2(39, 120)
const TILE_SIZE = 128.0
const ART = "res://assets/typecast/"
var camera: Camera2D
var player: CharacterBody2D
var clearing_center = Vector2.ZERO
var initialized = false
var floor_textures: Array[Texture2D] = []
var grass_density = FastNoiseLite.new()
var decorations: Dictionary = {}
var layouts: Dictionary = {}
var last_cell = Vector2i(2147483647, 2147483647)
var last_view = Vector2.ZERO

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_viewport().size_changed.connect(queue_redraw)
	z_index = -100
	grass_density.seed = 7319
	grass_density.frequency = 0.16
	grass_density.fractal_octaves = 2
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

func generate_layout(cell: Vector2i) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("grove:%d:%d" % [cell.x, cell.y])
	var center = Vector2(cell) * CELL_SIZE + Vector2.ONE * CELL_SIZE / 2 + Vector2(rng.randf_range(-100, 100), rng.randf_range(-100, 100))
	var trees: Array[Vector2] = []
	var bushes: Array[Vector2] = []
	var kind = rng.randf()
	var target = 0 if kind < 0.12 else (1 if kind < 0.37 else rng.randi_range(3, 5))
	for attempt in range(120):
		if trees.size() >= target:
			break
		var point = center if target == 1 else center + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * GROVE_RADIUS
		if point.distance_to(clearing_center) <= CLEARING_RADIUS:
			continue
		var fits = true
		for tree in trees:
			if point.distance_to(tree) < MIN_TRUNK_SPACING:
				fits = false
				break
		if fits:
			trees.append(point)
	for tree in trees:
		for i in range(rng.randi_range(1, 3)):
			var point = tree + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(48, 95)
			if point.distance_to(clearing_center) > CLEARING_RADIUS:
				bushes.append(point)
	return {"trees": trees, "bushes": bushes}

func layout_for(cell: Vector2i) -> Dictionary:
	return layouts[cell] if layouts.has(cell) else generate_layout(cell)

func tree_position(cell: Vector2i) -> Vector2:
	var trees = layout_for(cell).trees
	return trees[0] if not trees.is_empty() else Vector2(cell) * CELL_SIZE + Vector2.ONE * CELL_SIZE / 2

func has_tree(cell: Vector2i) -> bool:
	return not layout_for(cell).trees.is_empty()

func nearby_trunks(point: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var cell = cell_for(point)
	for y in range(cell.y - 1, cell.y + 2):
		for x in range(cell.x - 1, cell.x + 2):
			result.append_array(layout_for(Vector2i(x, y)).trees)
	return result

func is_clear(point: Vector2, radius: float) -> bool:
	for trunk in nearby_trunks(point):
		if point.distance_to(trunk) < radius + TRUNK_RADIUS + 8:
			return false
	return true

func is_spawn_clear(point: Vector2, radius: float) -> bool:
	var half_extent = radius * 32.0 / 29.0
	for trunk in nearby_trunks(point):
		var edge = (point - trunk).abs() - Vector2.ONE * half_extent
		var closest = Vector2(maxf(edge.x, 0), maxf(edge.y, 0))
		if closest.length() < TRUNK_RADIUS + 8:
			return false
	return true

func clear_spawn(point: Vector2, radius: float) -> Vector2:
	if is_spawn_clear(point, radius):
		return point
	for ring in range(1, 7):
		for step in range(16):
			var candidate = point + Vector2.from_angle(step * TAU / 16) * ring * 48.0
			if is_spawn_clear(candidate, radius):
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
				layouts[key] = generate_layout(key)
				decorations[key] = create_decoration(key)
	for key in decorations.keys():
		if not wanted.has(key):
			decorations[key].queue_free()
			decorations.erase(key)
			layouts.erase(key)

func create_decoration(cell: Vector2i) -> Node2D:
	var holder = Node2D.new()
	add_child(holder)
	var layout = layout_for(cell)
	for i in range(layout.trees.size()):
		var point = layout.trees[i]
		var body = StaticBody2D.new()
		body.position = point
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
		tree.texture = load(ART + ("Level Tiles/Level Deco/Fir Tree 1 shaded.png" if posmod(cell.x + cell.y + i, 2) == 0 else "Level Tiles/Level Deco/Fir Tree 1.png"))
		tree.scale = Vector2(2, 2)
		tree.position = (tree.texture.get_size() / 2 - TREE_TRUNK_PIVOT) * tree.scale
		tree.z_as_relative = false
		tree.z_index = 2
		body.add_child(tree)
	for i in range(layout.bushes.size()):
		var bush = Sprite2D.new()
		bush.texture = load(ART + "Level Tiles/Level Deco/Bush v%d.png" % (1 + posmod(cell.x + cell.y + i, 2)))
		bush.scale = Vector2(2, 2)
		bush.position = layout.bushes[i]
		holder.add_child(bush)
	return holder

func _process(_delta):
	if not initialized:
		return
	refresh_decorations()
	for holder in decorations.values():
		for body in holder.get_children():
			var canopy = body.get_node_or_null("Canopy")
			if canopy:
				canopy.modulate.a = 1.0
				var offset = player.global_position - body.global_position
				if absf(offset.x) < 100 and offset.y > -265 and offset.y < 40:
					canopy.modulate.a = 0.35
	queue_redraw()

func floor_variant(cell: Vector2i) -> int:
	var density = grass_density.get_noise_2d(cell.x, cell.y)
	var variants = [1, 7] if density < -0.12 else ([0, 3, 4, 5] if density > 0.12 else [2, 6, 8])
	return variants[posmod(hash("grass:%d:%d" % [cell.x, cell.y]), variants.size())]

func _draw():
	if not initialized:
		return
	var visible = (get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()).grow(TILE_SIZE)
	for y in range(floori(visible.position.y / TILE_SIZE), ceili(visible.end.y / TILE_SIZE)):
		for x in range(floori(visible.position.x / TILE_SIZE), ceili(visible.end.x / TILE_SIZE)):
			var index = floor_variant(Vector2i(x, y))
			draw_texture_rect(floor_textures[index], Rect2(Vector2(x, y) * TILE_SIZE, Vector2.ONE * TILE_SIZE), false, Color(0.72, 0.78, 0.72))
