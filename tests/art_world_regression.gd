extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	run.call_deferred()

func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	var terrain = game.get_node("Background")
	var player = game.player
	player.set_physics_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.spell_manager.set_process(false)
	check(player.get_node("Sprite2D").texture.resource_path.ends_with("Wizard 2.0.png"), "Assembled wizard is active")
	check(terrain.floor_textures.size() == 9, "All grass variants load")
	check(terrain.is_clear(terrain.clearing_center, 200), "Starting clearing is open")
	var trunk = get_nodes_in_group("tree_obstacles")[0].global_position
	var saved = player.global_position
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		player.global_position = trunk + direction * 130
		check(player.test_move(player.global_transform, -direction * 200), "Player collides with trunk from every side")
	player.collision_mask = 0
	check(not player.test_move(player.global_transform, -Vector2.DOWN * 200), "Known-bad missing collision mask is detected")
	player.collision_mask = 32
	player.global_position = saved
	check(not terrain.is_clear(trunk, 30), "Trunk is rejected for spawning")
	for radius in [20.0, 38.0, 65.0]:
		check(terrain.is_clear(terrain.clear_spawn(trunk, radius), radius), "Spawn clearance handles grunt and boss footprints")
	var cell = terrain.cell_for(trunk)
	var original_tree = terrain.tree_position(cell)
	for i in range(8):
		player.global_position += Vector2(2000, -1800)
		terrain.refresh_decorations()
		await process_frame
		check(terrain.decorations.size() < 150, "Scenery stays bounded across travel")
	player.global_position = saved
	terrain.refresh_decorations()
	await physics_frame
	check(terrain.tree_position(cell) == original_tree, "Revisited trees keep their positions")
	var manager = game.get_node("MonsterManager")
	for id in manager.encounter_config.variants:
		var definition = manager.encounter_config.variants[id].duplicate(true)
		definition.id = id
		var enemy = manager.spawn_monster(definition, false)
		check(enemy != null, "Variant spawns: " + id)
		check(enemy.get_node("Sprite2D").texture.resource_path.begins_with("res://assets/typecast/"), "Variant uses supplied art: " + id)
		check(terrain.is_clear(enemy.global_position, 29 * enemy.scale.x), "Variant clears trees: " + id)
		enemy.queue_free()
		await process_frame
	var def = manager.encounter_config.variants.pursuer.duplicate(true)
	def.id = "pursuer"
	var pursuer = manager.spawn_monster(def)
	pursuer.set_physics_process(false)
	trunk = get_nodes_in_group("tree_obstacles")[0].global_position
	var target = trunk + Vector2(0, 200)
	for side in [-20.0, 0.0, 20.0]:
		pursuer.global_position = trunk + Vector2(side, -160)
		for i in range(720):
			pursuer.velocity = terrain.steer(pursuer.global_position, pursuer.global_position.direction_to(target) * 65, 29 * pursuer.scale.x)
			pursuer.move_and_slide()
			await physics_frame
		check(pursuer.global_position.y > trunk.y + 65, "Pursuer steers past trunk from centered and mirrored approaches")
	check(game.health_bar.has_node("AuthoredHealth"), "Authored health overlay is installed")
	for health in [0.0, 50.0, 100.0]:
		game.health_bar.value = health
		game.update_overheal_display(health, 100, 25)
		check(game.health_bar.get_node("AuthoredHealth").shield_ratio == 0.25, "Shield amount reaches authored gauge at every health level")
		check(not game.health_bar.has_node("OverhealBar"), "Shield does not cover authored art with legacy rectangle")
	game.update_overheal_display(100, 100, 0)
	check(game.health_bar.get_node("AuthoredHealth").shield_ratio == 0, "Expired shield clears authored gauge")
	game.queue_free()
	await process_frame
	print("ART WORLD: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
