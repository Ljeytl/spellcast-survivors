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
	for spec in [["charger", ["icy"], Vector2(-150, -40)], ["marksman", ["fiery"], Vector2(-90, -180)], ["pursuer", ["shocking"], Vector2(150, -150)], ["juggernaut", ["massive", "iron"], Vector2(250, 40)]]:
		var def = monsters.encounter_config.variants[spec[0]].duplicate(true)
		def.id = spec[0]
		var m = monsters.spawn_monster(def, false, true, NAN, -1.0, spec[1])
		if m:
			m.global_position = at + spec[2]
			m.speed = 0.0   # stand still but keep casting
		i += 1
	# Optional fourth argument "cast": every elite casts its word spell at once, to see the telegraphs.
	if OS.get_cmdline_user_args().size() > 3 and OS.get_cmdline_user_args()[3] == "cast":
		for m in monsters.get_tree().get_nodes_in_group("elites"):
			for cfg in m.elite.get("casts", []):
				preload("res://scripts/Elites.gd").cast(m, cfg, game.player)
	# Optional second argument: physics seconds to wait; a third: also save a frame every N physics frames.
	var seconds = float(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else 0.3
	var every = int(OS.get_cmdline_user_args()[2]) if OS.get_cmdline_user_args().size() > 2 else 0
	var frames = int(seconds * 60.0)
	for f in frames:
		await physics_frame
		if every > 0 and f % every == 0 and (f > frames / 2 or OS.get_cmdline_user_args().size() > 3):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.replace(".png", "-%03d.png" % f))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit(0)
