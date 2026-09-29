extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test") or DisplayServer.get_name()=="headless":
		quit(2)
		return
	run.call_deferred()

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)

func capture(label: String):
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/spell-scaling-0135/" + label + ".png")

func run():
	root.get_node("AudioManager").quitting = true
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var manager = game.spell_manager
	var monsters = game.get_node("MonsterManager")
	monsters.set_process(false)
	monsters.spawn_timer.stop()
	manager.set_process(false)
	game.player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"): enemy.free()
	monsters.monsters_alive = 0
	for offset in [Vector2(180,0),Vector2(270,20),Vector2(370,-12),Vector2(-200,80)]:
		var enemy = monsters.spawn_monster(monsters.get_available_variants(0)[0])
		enemy.set_physics_process(false)
		enemy.global_position = game.player.global_position + offset
		enemy.max_health = 10000
		enemy.current_health = 10000
		enemy.update_health_bar()
	for id in ["focus_ray","ember_lance","prism_ray"]:
		check(manager.learn_spell(id), "Learn "+id)
	check(manager.cast_build_spell(manager.find_spell_slot("prism_ray")),"Cast Prism")
	var beam = get_nodes_in_group("active_spell_channels")[-1]
	beam.set_physics_process(false)
	beam.advance(0.25)
	check(beam.beam_radius()==32,"Prism visible width")
	await capture("prism-gameplay")
	beam.queue_free()
	var area = load("res://scripts/LingeringArea.gd").new()
	area.configure(game.player.global_position+Vector2(160,0),100,10,2,Color("8dcfff"),"lightning")
	game.add_child(area)
	area.set_physics_process(false)
	var seed = load("res://scripts/HealingSeed.gd").new()
	seed.player_ref = weakref(game.player)
	seed.radius = 60
	seed.position = game.player.position + Vector2(-140,50)
	game.add_child(seed)
	seed.set_physics_process(false)
	await capture("lingering-and-healing")
	area.queue_free()
	seed.queue_free()
	var ui = game.level_up_screen
	for geometry in [Vector2i(1280,720),Vector2i(640,480)]:
		root.size = geometry
		await process_frame
		game.get_node("GameplayReadability").layout()
		game.pending_level_ups.append(2)
		game.show_next_level_up()
		ui.available_upgrades = [ui.generic_upgrades.spell_duration.duplicate(true),ui.generic_upgrades.projectile_speed.duplicate(true),{"name":"Prism Ray+","effect":{"type":"spell_upgrade","spell":"prism_ray"}}]
		ui.update_ui(2,{})
		await capture("upgrades-"+str(geometry.x))
		check(ui.visible,"Upgrade menu visible")
		for button in ui.upgrade_buttons:
			var label = button.get_node("CardText")
			check(button.get_global_rect().encloses(label.get_global_rect()),"Card copy contained")
		var before = game.player.spell_duration_multiplier
		ui.upgrade_buttons[0].pressed.emit()
		await create_timer(0.5).timeout
		check(is_equal_approx(game.player.spell_duration_multiplier,before+0.1),"Button applies Duration")
		check(game.current_state==game.GameState.PLAYING and not ui.visible,"Selection returns to game")
		await capture("duration-selected-"+str(geometry.x))
		check(game.player.passive_ranks.has("spell_duration"),"Passive retained after menu closes")
	game.queue_free()
	await process_frame
	print("SCALING_VISUAL: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
