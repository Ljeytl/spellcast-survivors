extends SceneTree
## Chunky-magic VFX layer contract (docs/VFX_PORT_BRIEF.md, Milestone 0).

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

func run():
	root.get_node("AudioManager").quitting = true
	var vfx = root.get_node_or_null("Vfx")
	check(vfx != null, "Vfx autoload exists")
	if vfx == null:
		quit(1)
		return
	check(is_equal_approx(vfx.CELL, 8.0), "1 VFX cell = 8 world px = 4x4 art px")
	check(is_equal_approx(preload("res://scripts/VisualDefaults.gd").CAMERA_ZOOM * 2.0, 3.0), "Integer art scaling: 3 screen px per art px")
	check(is_equal_approx(vfx.CELL * preload("res://scripts/VisualDefaults.gd").CAMERA_ZOOM, 12.0), "One VFX cell is 12 screen px at 1080p")
	check(vfx.GROUND_Z < 0 and vfx.AIR_Z > 20 and vfx.AIR_Z < 4096, "Ground layer under actors, air layer over actors and enemy projectiles")
	await process_frame
	check(not vfx._ground_layer.visible and not vfx._air_layer.visible, "Layers hidden with no game camera")

	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	game.spell_manager.set_process(false)
	await process_frame
	check(vfx._air_layer.visible and vfx._ground_layer.visible, "Layers active in the game scene")

	var time_scale = Engine.time_scale
	var flame_world = game.player.global_position + Vector2(64, 8)
	vfx.add_test_flame(flame_world)
	for i in 45:
		await process_frame
	check(vfx.stats.flames > 0, "Test flame emits flames")
	# Buffers, not textures: the headless renderer keeps no texture data.
	var hot = 0
	var near = 0
	var fc = Vector2i((flame_world / vfx.CELL).round()) - vfx._origin
	for i in vfx._heat.size():
		if vfx._heat[i] > 0.12:
			hot += 1
			var c = Vector2i(i % vfx._size.x, i / vfx._size.x)
			if absi(c.x - fc.x) <= 22 and c.y <= fc.y + 20 and c.y >= fc.y - 30:
				near += 1
	check(hot > 0, "Heat field has burning cells")
	check(near * 10 >= hot * 9, "Flames sit at the test flame's world position (world-locked)")
	check(vfx._decals.size() == 1, "Test flame leaves one scorch decal")
	var decal: Sprite2D = vfx._decals[0][0]
	check(decal.z_index == vfx.GROUND_Z and not decal.z_as_relative, "Scorch decal sits on the ground layer, under actors")
	check(is_equal_approx(fposmod(decal.position.x, vfx.CELL), 0.0) and is_equal_approx(fposmod(decal.position.y, vfx.CELL), 0.0) and decal.scale == Vector2.ONE * vfx.CELL, "Scorch decal is on the world cell grid")

	# World lock: layer origin is on the world cell grid wherever the camera is.
	for offset in [Vector2(0.37, 0.0), Vector2(13.9, -5.25), Vector2(-101.5, 77.125)]:
		game.camera.global_position += offset
		await process_frame
		await process_frame
		var pos: Vector2 = vfx._air_layer.position
		check(is_equal_approx(fposmod(pos.x, vfx.CELL), 0.0) and is_equal_approx(fposmod(pos.y, vfx.CELL), 0.0), "Air layer snapped to world grid at camera offset " + str(offset))
		check(vfx._ground_layer.position == pos, "Ground and air share one grid")
		var vis: Rect2 = vfx._visible_world_rect()
		var covered = Rect2(pos, Vector2(vfx._size) * vfx.CELL)
		check(covered.encloses(vis), "Grid covers the visible world rect")

	# Hit-stop is VFX-only.
	vfx.hitstop(5)
	await process_frame
	check(Engine.time_scale == time_scale and not paused, "VFX hit-stop never changes game time")
	vfx._stop = 0

	vfx.clear_test_flames()
	vfx.clear()
	check(vfx._f_count == 0 and vfx._decals.is_empty(), "Clear removes all flames and decals")
	print("VFX layer: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
