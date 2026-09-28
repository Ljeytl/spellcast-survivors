extends SceneTree
var checks = 0
var failures = 0
func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()
func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
func barrier(parent, point, layer):
	var body = StaticBody2D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(20, 160)
	body.add_child(shape)
	parent.add_child(body)
	body.global_position = point
	return body
func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	game.player.set_physics_process(false)
	var origin = Vector2(5000, 5000)
	barrier(game, origin + Vector2(100,0), 2)
	barrier(game, origin + Vector2(260,0), 32)
	for is_boss in [false, true]:
		var data = manager.encounter_config.variants.charger.duplicate(true)
		data.id = "charger"
		var enemy = manager.spawn_monster(data, is_boss)
		enemy.set_physics_process(false)
		enemy.global_position = origin
		await physics_frame
		enemy.update_crowd_collision(false)
		check(enemy.get_collision_mask_value(6), "Scenery blocks all enemies")
		check(enemy.get_collision_layer_value(2), "Enemy remains hittable and detectable")
		var collision = enemy.move_and_collide(Vector2(150,0), true)
		check((collision == null) == is_boss, "Only boss passes crowd without charge")
		enemy.update_crowd_collision(true)
		collision = enemy.move_and_collide(Vector2(150,0))
		check(collision == null and enemy.global_position.x > origin.x + 140, "Charging enemy crosses occupied crowd")
		collision = enemy.move_and_collide(Vector2(200,0), true)
		check(collision != null, "Charging enemy still collides with scenery")
		enemy.update_crowd_collision(false)
		check(enemy.get_collision_mask_value(2) == not is_boss, "Charge-end collision restored; boss remains crowd-transparent")
		enemy.global_position = origin
		enemy.warning = 0.001
		enemy.charge_remaining = 0.0
		enemy.action_direction = Vector2.RIGHT
		enemy._physics_process(0.01)
		check(not enemy.get_collision_mask_value(2), "Charge-start frame ignores crowd")
		enemy.charge_remaining = 0.001
		enemy._physics_process(0.01)
		check(not enemy.get_collision_mask_value(2), "Final dash movement ignores crowd")
		enemy._physics_process(0.01)
		check(enemy.get_collision_mask_value(2) == not is_boss, "Following normal frame restores crowd collision")
		enemy.queue_free()
		await process_frame
	game.queue_free()
	await process_frame
	print("CROWD_COLLISION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
