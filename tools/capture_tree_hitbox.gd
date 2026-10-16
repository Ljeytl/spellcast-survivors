extends SceneTree
## Walks the wizard into the nearest tree from four sides and reports how close the feet get to the
## trunk; saves a screenshot of the last approach.  godot --path . --script tools/capture_tree_hitbox.gd -- <out.png>
func _initialize():
	run.call_deferred()

func run():
	var out = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://tree.png"
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 10:
		await process_frame
	var monsters = game.get_node("MonsterManager")
	monsters.spawn_timer.stop()
	monsters.set_process(false)
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var player = game.player
	player.is_invincible = true
	player.set_physics_process(false)
	var trees = get_nodes_in_group("tree_obstacles")
	trees.sort_custom(func(a, b): return a.global_position.distance_to(player.global_position) < b.global_position.distance_to(player.global_position))
	var trunk: Vector2 = trees[0].global_position
	var feet_offset := Vector2(0, 33)   # wizard art: 35 px tall at 2x, feet ~33 px below the node
	for dir in [Vector2.DOWN, Vector2.LEFT, Vector2(-1, 1).normalized(), Vector2.UP]:
		player.global_position = trunk + dir * 220.0 - feet_offset
		await physics_frame
		for f in 90:
			player.velocity = -dir * 260.0
			player.move_and_slide()
			await physics_frame
		var feet = player.global_position + feet_offset
		var hit = player.get_last_slide_collision()
		print("  last collider: ", hit.get_collider().name if hit and hit.get_collider() else "none", " at ", hit.get_collider().global_position - trunk if hit and hit.get_collider() is Node2D else Vector2.ZERO)
		print("approach %s: feet %.0f px from trunk base (dx %.0f, dy %.0f)" % [dir, feet.distance_to(trunk), feet.x - trunk.x, feet.y - trunk.y])
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	quit(0)
