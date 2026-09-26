extends SceneTree

class CircularSpawnTerrain extends "res://scripts/Background.gd":
	func is_spawn_clear(point: Vector2, radius: float) -> bool:
		return is_clear(point, radius)

var checks = 0
var failures = 0
var known_bad = "--known-bad-uniform" in OS.get_cmdline_user_args()

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func connected_sample(terrain, start_cell: Vector2i) -> bool:
	var width = 120
	var origin = Vector2(start_cell) * terrain.CELL_SIZE
	var blocked: Dictionary = {}
	for y in range(width):
		for x in range(width):
			var key = Vector2i(x, y)
			if not terrain.is_clear(origin + Vector2(key) * 20 + Vector2.ONE * 10, 46):
				blocked[key] = true
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	var visited: Dictionary = {Vector2i.ZERO: true}
	var cursor = 0
	while cursor < queue.size():
		var point = queue[cursor]
		cursor += 1
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor = point + step
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= width or neighbor.y >= width:
				continue
			if not blocked.has(neighbor) and not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	return visited.size() + blocked.size() == width * width

func run():
	Engine.max_fps = 120
	var game = load("res://scenes/Game.tscn").instantiate()
	if "--known-bad-circular-spawn" in OS.get_cmdline_user_args():
		game.get_node("Background").set_script(CircularSpawnTerrain)
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	var terrain = game.get_node("Background")
	var player = game.player
	player.set_physics_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.spell_manager.set_process(false)
	var original_player = player.position
	var grove_cells = 0
	var lone_cells = 0
	var empty_cells = 0
	var tree_count = 0
	var counts: Dictionary = {}
	var minimum_distance = INF
	var samples: Dictionary = {}
	for y in range(-5, 6):
		for x in range(-5, 6):
			var cell = Vector2i(x, y)
			var layout = terrain.generate_layout(cell)
			if known_bad:
				layout.trees = [Vector2(cell) * terrain.CELL_SIZE + Vector2.ONE * terrain.CELL_SIZE / 2]
			samples[cell] = layout
			terrain.layouts[cell] = layout
			counts[layout.trees.size()] = true
			tree_count += layout.trees.size()
			grove_cells += 1 if layout.trees.size() >= 3 else 0
			lone_cells += 1 if layout.trees.size() == 1 else 0
			empty_cells += 1 if layout.trees.is_empty() else 0
			check(layout == terrain.generate_layout(cell), "Cell layout is deterministic: " + str(cell))
			for point in layout.trees:
				check(point.distance_to(terrain.clearing_center) > 300, "Starting clearing remains open")
				check(terrain.cell_for(point) == cell, "Trees stay within their deterministic streaming cell")
				var local = point - Vector2(cell) * terrain.CELL_SIZE
				check(minf(minf(local.x, local.y), minf(terrain.CELL_SIZE - local.x, terrain.CELL_SIZE - local.y)) >= 110, "Cell edges preserve broad connected routes")
			for bush in layout.bushes:
				check(bush.distance_to(terrain.clearing_center) > 300, "Bush clusters preserve starting clearing")
	check(grove_cells > 50 and lone_cells > 10 and empty_cells > 5, "World mixes groves, isolated trees, and empty ground")
	check(counts.size() >= 4, "Grove sizes vary within the world")
	for cell in samples:
		for point in samples[cell].trees:
			for other in terrain.nearby_trunks(point):
				if point != other:
					minimum_distance = minf(minimum_distance, point.distance_to(other))
			for radius in [20.0, 38.0, 65.0]:
				check(terrain.is_clear(terrain.clear_spawn(point, radius), radius), "Blocked spawn relocates clear for regular and boss footprints")
	check(minimum_distance >= terrain.MIN_TRUNK_SPACING - 0.01, "All trunks leave passage for the full diagonal player footprint")
	for start in [Vector2i(-4, -4), Vector2i(0, 0), Vector2i(2, -3)]:
		check(connected_sample(terrain, start), "Expanded player navigation has no sealed pockets: " + str(start))
	var sealed_cell = Vector2i(-3, -3)
	var saved_layout = terrain.layouts[sealed_cell]
	var sealed_trees: Array[Vector2] = []
	for i in range(12):
		sealed_trees.append(Vector2(sealed_cell) * terrain.CELL_SIZE + Vector2.ONE * terrain.CELL_SIZE / 2 + Vector2.from_angle(i * TAU / 12) * 110)
	terrain.layouts[sealed_cell] = {"trees": sealed_trees, "bushes": []}
	check(not connected_sample(terrain, Vector2i(-4, -4)), "Known-bad enclosed ring is rejected by navigation coverage")
	terrain.layouts[sealed_cell] = saved_layout
	terrain.layouts.clear()
	for cell in terrain.decorations:
		terrain.layouts[cell] = terrain.generate_layout(cell)
	for destination in [original_player + Vector2(5000, -4500), original_player + Vector2(-6000, 5000), original_player]:
		player.position = destination
		terrain.refresh_decorations()
		await process_frame
		await physics_frame
		check(terrain.layouts.size() == terrain.decorations.size(), "Streaming drops matching layout and scenery caches")
		check(terrain.decorations.size() < 100, "Streaming remains bounded after long travel")
		var expected_bodies = 0
		for cell in terrain.decorations:
			var holder = terrain.decorations[cell]
			var layout = terrain.generate_layout(cell)
			expected_bodies += layout.trees.size()
			var rendered: Array[Vector2] = []
			for child in holder.get_children():
				if child is StaticBody2D:
					rendered.append(child.global_position)
					check(child.collision_layer == 32 and child.get_child(0).shape.radius == 11, "Trees retain physical trunk geometry")
					check(child.has_node("Canopy"), "Rendered canopy and collision share one trunk position")
					var canopy = child.get_node("Canopy")
					var art_trunk = canopy.to_global(Vector2(39, 120) - canopy.texture.get_size() / 2)
					check(art_trunk.is_equal_approx(child.global_position), "Both art variants anchor the visible lower trunk at the collider center")
				else:
					check(child is Sprite2D and child.get_child_count() == 0, "Bushes remain decorative and nonblocking")
			check(rendered == layout.trees, "Rendering, physics, spawn checks and regeneration share positions")
		check(get_nodes_in_group("tree_obstacles").size() == expected_bodies, "No stale colliders survive streamed cell eviction")
	for cell in terrain.decorations:
		if terrain.layout_for(cell).trees.size() != 1:
			continue
		var trunk = terrain.decorations[cell].get_child(0)
		player.position = trunk.position + Vector2(48, -130)
		check(not player.test_move(player.global_transform, Vector2(0, 260)), "Player passes close to narrowed trunk outside11px radius")
		trunk.get_child(0).shape.radius = 22
		await physics_frame
		await physics_frame
		check(player.test_move(player.global_transform, Vector2(0, 260)), "Known-bad old22px trunk blocks the same close pass")
		trunk.get_child(0).shape.radius = 11
		await physics_frame
		await physics_frame
		player.position = original_player
		break
	var boss_shape = RectangleShape2D.new()
	boss_shape.size = Vector2.ONE * 64 * 1.25 * 1.7
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = boss_shape
	query.collision_mask = 32
	var checked_trunks = 0
	for body in get_nodes_in_group("tree_obstacles"):
		if checked_trunks >= 30:
			break
		checked_trunks += 1
		for i in range(8):
			var candidate = body.position + Vector2.from_angle(i * TAU / 8) * 90
			var safe = terrain.clear_spawn(candidate, 29.0 * 1.25 * 1.7)
			query.transform = Transform2D(0, safe)
			check(root.world_2d.direct_space_state.intersect_shape(query).is_empty(), "Actual boss square clears physical trunk, including diagonal corners")
	var canopy_body = get_nodes_in_group("tree_obstacles")[0]
	player.position = canopy_body.position + Vector2(0, -80)
	await process_frame
	await process_frame
	check(canopy_body.get_node("Canopy").modulate.a < 0.4, "Grove canopy fades over an obscured player")
	player.position = original_player
	await process_frame
	await process_frame
	check(canopy_body.get_node("Canopy").modulate.a == 1.0, "Canopy restores opacity after actor leaves")
	var orb = load("res://scenes/XPOrb.tscn").instantiate()
	orb.position = player.position + Vector2(110, 0)
	game.add_child(orb)
	check(orb.scale == Vector2.ONE and orb.get_node("Visual").scale == Vector2.ONE * 1.5, "Crystal starts 1.5 times larger without scaling root")
	check(orb.get_node("CollisionShape2D").shape.radius == 8 and orb.get_node("CollectionArea/CollectionShape").scale == Vector2.ONE * 3, "Pickup collision shapes remain unchanged")
	check(orb.collection_distance == 100 and orb.move_speed == 200 and orb.xp_value == 10, "Pickup gameplay values remain unchanged")
	orb.set_process(false)
	var pulse_min = INF
	var pulse_max = 0.0
	var started = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 1100:
		await process_frame
		var scale_value = orb.get_node("Visual").scale.x
		pulse_min = minf(pulse_min, scale_value)
		pulse_max = maxf(pulse_max, scale_value)
	check(pulse_min >= 1.499 and pulse_min < 1.53 and pulse_max > 1.77 and pulse_max <= 1.801, "Entire pulse remains 1.5 times the prior 1.0–1.2 range")
	orb._process(0)
	check(not orb.is_moving_to_player, "Larger crystal does not expand magnet range")
	orb.position = player.position + Vector2(90, 0)
	orb._process(0)
	check(orb.is_moving_to_player, "Existing magnet range still attracts crystal")
	var xp_before = player.xp
	orb.collect_xp()
	orb.collect_xp()
	check(player.xp == xp_before + 10, "Crystal still awards its XP exactly once")
	await create_timer(2.1).timeout
	for audio in root.get_node("AudioManager").get_children():
		if audio is AudioStreamPlayer:
			audio.stop()
			audio.stream = null
	await create_timer(0.1).timeout
	game.queue_free()
	await process_frame
	print("FOREST GROVES: %d checks, %d failures; %d groves, %d lone, %d empty, %d trees, closest %.2f" % [checks, failures, grove_cells, lone_cells, empty_cells, tree_count, minimum_distance])
	quit(1 if failures else 0)
