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
	game.player.is_invincible = true
	for spec in [["charger", ["icy"]], ["marksman", ["fiery"]], ["pursuer", ["shocking"]], ["juggernaut", ["massive", "iron"]]]:
		var def = monsters.encounter_config.variants[spec[0]].duplicate(true)
		def.id = spec[0]
		var m = monsters.spawn_monster(def, false, true, NAN, -1.0, spec[1])
		if m:
			m.global_position = at + Vector2(-260 + i * 170, -120 + (i % 2) * 60)
			m.speed = 0.0   # stand still but keep casting
		i += 1
	# Optional second argument: physics seconds to wait; a third: also save a frame every N physics frames.
	var seconds = float(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else 0.3
	var every = int(OS.get_cmdline_user_args()[2]) if OS.get_cmdline_user_args().size() > 2 else 0
	var frames = int(seconds * 60.0)
	for f in frames:
		await physics_frame
		if every > 0 and f % every == 0 and f > frames / 2:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.replace(".png", "-%03d.png" % f))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit(0)
