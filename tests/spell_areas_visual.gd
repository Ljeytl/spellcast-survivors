extends SceneTree

var game

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(5000, 5000)
	root.get_node("AudioManager").quitting = true
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	var manager = game.get_node("MonsterManager")
	manager.spawn_timer.stop()
	manager.set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	var origin = game.player.position
	var host = null
	for index in range(18):
		var enemy = manager.spawn_monster(manager.get_available_variants(0)[0])
		enemy.position = origin + Vector2(220 + (index % 6) * 35, -150 + (index / 6) * 45)
		enemy.max_health = 10000
		enemy.current_health = 10000
		enemy.update_health_bar()
		enemy.set_physics_process(false)
		if index == 0:
			host = enemy
	# Ported spells run on the generic engine and draw through the VFX layer (doc 18 phase 2).
	var spells = game.spell_manager
	for entry in [["cinder_field", Vector2(-260, -130)], ["rune_trap", Vector2(-300, 160)], ["arcane_orbit", Vector2.ZERO], ["infestation", Vector2.ZERO], ["lightning", Vector2(240, 75)], ["meteor_shower", Vector2(-30, -230)]]:
		var info = spells.spell_catalog[entry[0]]
		var cast = spells.spawn_ported(info, 0, {}, host)
		if cast == null:
			continue
		cast.manual = true
		if info.type == "plague":
			var plague = cast.root_parts()[0].infection
			for enemy in get_nodes_in_group("enemies").slice(1, 8):
				plague.infect(enemy, host.global_position, 600.0)
			cast.advance(0.6)
		elif info.type == "orbit":
			pass
		else:
			for part in cast.root_parts():
				part.global_position = origin + entry[1]
			if info.type == "trap":
				cast.advance(1.0)
	var trail = spells.spawn_ported(spells.spell_catalog.firewalk, 0, {}, null)
	trail.manual = true
	for index in range(7):
		trail._make_part("patch", origin + Vector2(-150 + index * 45, 190), Vector2.RIGHT, 1, 1.0, 1.0)
	await create_timer(0.3).timeout
	paused = true
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://builds/evidence")
	root.get_texture().get_image().save_png("res://builds/evidence/spell-areas-crowded.png")
	root.size = Vector2i(800, 600)
	game.particle_manager.reduced_effects = true
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/evidence/spell-areas-narrow-reduced.png")
	print("Saved spell-areas-crowded.png and spell-areas-narrow-reduced.png")
	quit()
