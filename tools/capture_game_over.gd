extends SceneTree
## Captures the end-of-run screen after a busy run (many spells, reactions) for layout review.
## godot --path . --resolution 1280x720 --script tools/capture_game_over.gd -- <out.png>
func _initialize():
	run.call_deferred()

func run():
	var out = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://gameover.png"
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 10:
		await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	var s = game.style_session
	var spells = {"lightning_bolt": [9200, {"shocked": 1400, "chain": 2100}], "cross_blade": [7100, {"bleed": 3100}], "meteor_shower": [6400, {"burn": 1200}],
		"mana_bolt": [3900, {}], "frost_nova": [2600, {"chilled": 300}], "soul_bloom": [2400, {"infection": 900, "plague": 600}], "cinder_field": [1800, {"burn": 1700}],
		"steam_field": [1500, {"scald": 800}], "ember_spear": [1300, {"burn": 400}], "rune_trap": [900, {}]}
	for id in spells:
		s.damage_by_spell[id] = float(spells[id][0])
		s.damage_by_effect[id] = spells[id][1]
	for id in ["bolt", "ice_blast", "lightning", "rune_trap", "life", "fireball"]:
		game.spell_manager.learn_spell(id)
	game.game_time = 812.0
	game.enemies_killed = 1234
	game.spells_cast = 456
	game.show_game_over_screen()
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	quit(0)
