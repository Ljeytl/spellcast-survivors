extends SceneTree

var game

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
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
	for entry in [["cinder_field", Vector2(-260, -130)], ["rune_trap", Vector2(-300, 160)], ["arcane_orbit", Vector2.ZERO], ["plague_seed", Vector2.ZERO]]:
		var info = game.spell_manager.spell_catalog[entry[0]]
		var effect = load("res://scripts/TacticalSpellEffect.gd" if info.type == "trap" else "res://scripts/BuildSpellEffect.gd").new()
		effect.configure(info, 0, game.player, host if info.type == "plague" else null)
		game.add_child(effect)
		effect.set_physics_process(false)
		if info.type == "plague":
			for enemy in get_nodes_in_group("enemies").slice(1, 8):
				effect.infect(enemy, host.global_position)
		else:
			effect.position = origin + entry[1]
			if info.type == "trap":
				effect.age = 1
	var trail = load("res://scripts/TacticalSpellEffect.gd").new()
	trail.configure(game.spell_manager.spell_catalog.ember_trail, 0, game.player, null)
	game.add_child(trail)
	trail.set_physics_process(false)
	trail.trail_points.clear()
	for index in range(7):
		trail.trail_points.append({"position": origin + Vector2(-150 + index * 45, 190), "age": 1.0})
	var lightning = load("res://scripts/LightningArea.gd").new()
	lightning.configure(origin + Vector2(240, 75), {"radius": 160, "active_duration": 0.2}, 0, game.player)
	game.add_child(lightning)
	lightning.set_physics_process(false)
	lightning.age = 0.08
	var warning = load("res://scenes/SpellProjectile.tscn").instantiate()
	warning.setup_aoe_effect(origin + Vector2(-30, -230), 150, Color.RED, "warning")
	warning.lifetime = 1
	game.add_child(warning)
	warning.lifetime_timer = 0.55
	warning.set_process(false)
	for node in get_nodes_in_group("build_spell_effects"):
		node.queue_redraw()
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
