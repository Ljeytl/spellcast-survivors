extends SceneTree

const OUT = "res://builds/spell-gallery/"
const TIMES = [0.04, 0.10, 0.18, 0.3, 0.5, 0.65, 0.85, 1.0, 1.5, 2.0]
var entries: Array = []
var game

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		printerr("Gallery requires isolated test saves")
		quit(2)
		return
	run.call_deferred()

func setup():
	seed(41)
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("UI").hide()
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	game.player.is_invincible = true
	game.player.health = 30
	game.camera_shake.set_process(false)
	game.camera.zoom = Vector2.ONE * 1.5
	game.camera.position = game.player.position + Vector2(160, 0)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	var background = game.get_node("Background")
	background.set_process(false)
	for holder in background.decorations.values():
		holder.hide()
	for offset in [Vector2(210, 0), Vector2(285, 0), Vector2(300, -85), Vector2(300, 85)]:
		var definition = manager.encounter_config.variants.pursuer.duplicate(true)
		definition.id = "pursuer"
		var enemy = manager.spawn_monster(definition, false, true)
		enemy.global_position = game.player.global_position + offset
		enemy.current_health = 10000
		enemy.max_health = 10000
		enemy.set_physics_process(false)
		enemy.get_node("HealthBar").hide()
	await process_frame

func capture(id: String, frame: int):
	paused = true
	await RenderingServer.frame_post_draw
	var path = "%s-%02d.png" % [id, frame]
	var error = root.get_texture().get_image().save_png(OUT + path)
	assert(error == OK)
	paused = false
	return path

func teardown():
	game.queue_free()
	await process_frame
	await process_frame

func run():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(5000, 5000)
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i(1280, 800)
	root.get_node("AudioManager").quitting = true
	DirAccess.make_dir_recursive_absolute(OUT)
	var ids = ["mana_bolt"]
	ids.append_array(load("res://scripts/SpellManager.gd").BASE_SPELL_IDS)
	var recipes = load("res://scripts/SynergyCatalog.gd").RECIPES
	for id in recipes:
		if recipes[id].get("enabled", true):
			ids.append(id)
	for id in ids:
		await setup()
		var manager = game.spell_manager
		var title = "Mana Bolt"
		if id == "mana_bolt":
			manager.fire_mana_bolt()
		else:
			if recipes.has(id):
				for ingredient in recipes[id].ingredients:
					assert(manager.learn_spell(ingredient) or ingredient == "bolt")
			assert(manager.learn_spell(id) or id == "bolt")
			var slot = manager.find_spell_slot(id)
			title = manager.get_spell_info(slot).get("name", id)
			assert(manager.cast_spell_by_type(slot))
		var frames = []
		var elapsed = 0.0
		for index in range(TIMES.size()):
			while elapsed < TIMES[index]:
				await physics_frame
				await process_frame
				var delta = 1.0 / Engine.physics_ticks_per_second
				elapsed += delta
				manager.process_healing_effects(delta)
				if id == "ember_trail":
					game.player.position.x += delta * 85.0
			frames.append(await capture(id, index))
		entries.append({"id":id,"name":title,"group":"Spells","frames":frames,"times":TIMES,"bonus":recipes.has(id)})
		await teardown()
		print("GALLERY spell ", id)
	await setup()
	var pm = game.particle_manager
	var origin = game.player.global_position + Vector2(120, 0)
	var methods = []
	for method in pm.get_method_list():
		if method.name.begins_with("create_") and method.name != "create_tween":
			methods.append(method.name)
	for method in methods:
		for effect in pm.get_children():
			effect.free()
		var args = [origin]
		match method:
			"create_spell_effect": args = [origin, "mana"]
			"create_directional_effect": args = [origin, Vector2.RIGHT, "ice", 160.0, 0.6]
			"create_link_effect": args = [origin, origin + Vector2(150, 0), "lightning"]
			"create_persistent_life_circle", "create_persistent_shield_circle":
				game.player.overheal = 20
				args = [game.player, 2.0]
			"create_persistent_lightning_arc": args = [game.player, origin + Vector2(150,0), 1.0]
			"create_expanding_circle": args = [origin, 100.0, Color.ORANGE, 1.0]
			"create_powerful_spell_effect": args = [origin, "meteor shower"]
			"create_elite_spawn_effect": args = [origin, "elite"]
			"create_attack_warning": args = [origin, 95.0, 1.0]
			"create_aoe_telegraph": args = [origin, 220.0, 1.0]
			"create_projectile_warning": args = [origin, origin + Vector2(150,0), 1.0]
		pm.callv(method, args)
		var frames = []
		for index in range(3):
			for effect in pm.get_children():
				effect.set_process(false)
				effect.age = effect.duration * [0.15, 0.45, 0.75][index]
				if effect.followed:
					effect.global_position = game.player.global_position
				effect.queue_redraw()
			await process_frame
			frames.append(await capture(method, index))
		entries.append({"id":method,"name":method.trim_prefix("create_").replace("_", " ").capitalize(),"group":"Particles","frames":frames,"times":["Early","Middle","Late"]})
	await teardown()
	var file = FileAccess.open(OUT + "catalog.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(entries, "  "))
	print("GALLERY COMPLETE: ", entries.size(), " entries")
	quit()
