extends SceneTree
## Captures a screenshot of an elite patrol beside the wizard (visual check for elites).
## godot --path . --script tools/capture_elites.gd -- <out.png>
func _initialize():
	run.call_deferred()

func run():
	var out = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://elites.png"
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 10:
		await process_frame
	var monsters = game.get_node("MonsterManager")
	monsters.spawn_timer.stop()
	monsters.set_process(false)
	var at = game.player.global_position
	var i = 0
	for spec in [["charger", ["icy"]], ["juggernaut", ["massive", "fiery"]], ["pursuer", ["quick", "leeching"]], ["pursuer", []]]:
		var def = monsters.encounter_config.variants[spec[0]].duplicate(true)
		def.id = spec[0]
		var m = monsters.spawn_monster(def, false, true, NAN, -1.0, spec[1])
		if m:
			m.global_position = at + Vector2(-180 + i * 120, -60 + (i % 2) * 50)
			m.set_physics_process(false)
		i += 1
	for f in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit(0)
