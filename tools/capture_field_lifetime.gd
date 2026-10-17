extends "res://tools/capture_spell_gallery.gd"

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	if not root.is_node_ready():
		await root.ready
	await process_frame
	var args = OS.get_cmdline_user_args()
	if args.size() < 3:
		quit(2)
		return
	var folder = args[0]
	var spell = args[1]
	var rank = int(args[2])
	await setup()
	root.size = Vector2i(720, 850) if args.has("narrow") else Vector2i(1280, 850)
	root.content_scale_size = root.size
	var vfx = root.get_node("Vfx")
	vfx.reduced_effects = args.has("reduced")
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position + Vector2(150, 0)
	game.camera.force_update_scroll()
	if spell != "field":
		assert(game.spell_manager.learn_spell(spell))
		game.spell_manager.get_spell_info(game.spell_manager.find_spell_slot(spell)).level = rank
	var enemies = get_nodes_in_group("enemies")
	for i in enemies.size():
		enemies[i].global_position = game.player.global_position + Vector2(170 + i * 12, 0)
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	DirAccess.make_dir_recursive_absolute(folder)
	var events: Array = []
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"audio":event,"movie_frame":Engine.get_frames_drawn()}))
	var late_samples := 0
	var missing_samples := 0
	var damage := 0.0
	var last_health := 40000.0
	var frames := 720 if args.has("recast") else 420
	for frame in frames:
		if frame == 12 or (args.has("recast") and frame in [42, 72, 102]):
			assert(game.spell_manager.cast_freeform_spell(spell.replace("_", " ")))
		await physics_frame
		await process_frame
		var health := 0.0
		for enemy in enemies:
			health += float(enemy.current_health)
		damage += maxf(0.0, last_health - health)
		last_health = health
		if frame % 15 == 0:
			var rows: Array = []
			for cast in get_nodes_in_group("generic_casts"):
				for part in cast.parts:
					if not is_instance_valid(part) or part.done or part.delivery != "field" or part.def.get("payload", []).is_empty():
						continue
					var st = vfx.presenter._parts.get(part.get_instance_id())
					var painted: bool = st != null and st.has("field") and vfx._fields.has(st.field)
					rows.append({"id":cast.plan.id,"part":part.part_name,"age":part.age,"life":part.total_life(),"painted":painted,"hits":part.hit_count})
					if part.age > part.total_life() * 0.7:
						late_samples += 1
						if not painted:
							missing_samples += 1
				events.append({"frame":frame,"fields":rows,"health":health,"movie_frame":Engine.get_frames_drawn()})
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if frame == 0:
			print("FIRST_PNG_MOVIE_FRAME=", Engine.get_frames_drawn())
		if frame % 2 == 0:
			assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) == OK)
	FileAccess.open(folder + "/events.json", FileAccess.WRITE).store_string(JSON.stringify(events, "\t"))
	print("FIELD_CAPTURE spell=", spell, " late=", late_samples, " missing=", missing_samples, " damage=", damage)
	stage.queue_free()
	await teardown()
	quit(0 if late_samples > 0 and missing_samples == 0 and damage > 0.0 else 1)
