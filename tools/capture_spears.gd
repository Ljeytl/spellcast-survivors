extends "res://tools/capture_spell_gallery.gd"

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var args = OS.get_cmdline_user_args()
	if args.size() < 3 or not args[2].is_valid_int() or int(args[2]) < 1 or int(args[2]) > 8:
		printerr("Usage: capture_spears folder spell rank[1..8] [wake cap moving narrow reduced empty keyword]")
		quit(2)
		return
	var folder = args[0]
	var spell = args[1]
	var rank = int(args[2])
	await setup()
	root.size = Vector2i(720, 850) if args.has("narrow") else Vector2i(1280, 850)
	root.content_scale_size = root.size
	root.get_node("Vfx").reduced_effects = args.has("reduced")
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position + Vector2(150, 0)
	game.camera.force_update_scroll()
	var enemies = get_nodes_in_group("enemies")
	for i in enemies.size():
		enemies[i].global_position = game.player.global_position + Vector2(150 + i * 90, 0)
	if args.has("wake"):
		enemies.back().global_position = game.player.global_position + Vector2(100, 180)
	if args.has("empty"):
		for enemy in enemies:
			enemy.free()
		enemies = []
	if spell != "spear":
		if spell == "meteor_spear":
			assert(game.spell_manager.learn_spell("ember_spear"))
			assert(game.spell_manager.learn_spell("meteor_shower"))
		assert(game.spell_manager.learn_spell(spell))
		for id in [spell, "ember_spear", "meteor_shower"]:
			var slot = game.spell_manager.find_spell_slot(id)
			if slot > 0:
				game.spell_manager.get_spell_info(slot).level = 8 if spell == "meteor_spear" and id != spell else rank
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	DirAccess.make_dir_recursive_absolute(folder)
	var events: Array = []
	var casts: Array = []
	var maximum_trails := 0
	var all_hits: Dictionary = {}
	var last_trails := 0
	var wake_health := 0.0
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"audio":event,"movie_frame":Engine.get_frames_drawn()}))
	for frame in 330:
		if frame == 12 or (args.has("cap") and frame in [30, 48, 66, 84]):
			var phrase = spell.replace("_", " ")
			if args.has("keyword"):
				phrase = "fiery " + phrase
			assert(game.spell_manager.cast_freeform_spell(phrase))
			assert(is_instance_valid(game.spell_manager.last_generic_cast))
			casts.append(game.spell_manager.last_generic_cast)
			events.append({"cast_plan":game.spell_manager.last_generic_cast.plan.duplicate(true),"movie_frame":Engine.get_frames_drawn()})
		if args.has("moving") and frame > 30 and frame < 90:
			for enemy in enemies:
				enemy.position.y += 0.65
		if args.has("wake") and frame == 70:
			var enemy = enemies.back()
			enemy.global_position = game.player.global_position + Vector2(100, 0)
			wake_health = enemy.current_health
			events.append({"wake_entry_health":enemy.current_health,"movie_frame":Engine.get_frames_drawn()})
		await physics_frame
		await process_frame
		var trails := 0
		for cast in casts:
			if is_instance_valid(cast):
				for hit in cast.hits_log:
					all_hits[str(cast.get_instance_id()) + ":" + str(hit)] = hit.duplicate(true)
				for part in cast.parts:
					if is_instance_valid(part) and part.part_name == "trail":
						trails += 1
		maximum_trails = maxi(maximum_trails, trails)
		last_trails = trails
		if frame % 30 == 0:
			var health: Array = []
			for enemy in enemies:
				health.append(enemy.current_health)
			var hits: Array = []
			for cast in casts:
				if is_instance_valid(cast):
					hits.append_array(cast.hits_log)
			events.append({"frame":frame,"health":health,"hits":hits.duplicate(true),"trails":trails,"fields":root.get_node("Vfx")._fields.duplicate(true)})
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if frame % 2 == 0:
			assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) == OK)
			events.append({"png":frame / 2,"movie_frame":Engine.get_frames_drawn()})
	var direct = all_hits.values().filter(func(hit): return hit.part == "spear")
	var meteors = all_hits.values().filter(func(hit): return hit.part == "meteor")
	assert(direct.is_empty() if args.has("empty") else not direct.is_empty())
	assert(last_trails == 0 and maximum_trails <= 3)
	if spell == "meteor_spear" :
		assert(meteors.size() == direct.size())
	if args.has("wake"):
		assert(enemies.back().current_health < wake_health)
	events.append({"all_hits":all_hits.values(),"maximum_trails":maximum_trails,"final_trails":last_trails,"native_assertions":2 + int(spell == "meteor_spear" ) + int(args.has("wake"))})
	FileAccess.open(folder + "/events.json", FileAccess.WRITE).store_string(JSON.stringify(events,"\t"))
	print("SPEAR_CAPTURE frames=165 max_trails=", maximum_trails)
	casts.clear()
	stage.queue_free()
	await teardown()
	quit()
