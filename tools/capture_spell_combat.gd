extends SceneTree

var game
var events: Array = []
var failures: Array = []
var damage_events := 0

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var args = OS.get_cmdline_user_args()
	var spell = args[0] if args.size() > 0 else "lightning"
	var rank = int(args[1]) if args.size() > 1 else 1
	if rank < 1 or rank > 8:
		printerr("Rank must be 1 through 8")
		quit(2)
		return
	var folder = args[2] if args.size() > 2 else "res://builds/combat"
	var negative = args.has("no-hostiles")
	DirAccess.make_dir_recursive_absolute(folder)
	seed(41)
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000, 10000)
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	game.get_node("UI").hide()
	game.spell_manager.set_process(false)
	game.player.style_health_damaged.connect(func(amount):
		damage_events += 1
		events.append({"type":"player_damage", "amount":amount, "context":game.player.last_damage_context.duplicate(true), "movie_frame":Engine.get_frames_drawn()}))
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"type":"audio", "event":event, "movie_frame":Engine.get_frames_drawn()}))
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	var enemies: Array = []
	var initial_positions: Array = []
	for i in 14:
		var kind = "pursuer" if i < 10 else "imp"
		var definition = manager.encounter_config.variants[kind].duplicate(true)
		definition.id = kind
		var enemy = manager.spawn_monster(definition, false, true)
		enemy.global_position = game.player.global_position + Vector2.from_angle(float(i) * TAU / 14.0) * (130.0 if i < 10 else 340.0)
		enemy.max_health = 10000
		enemy.current_health = 10000
		enemy.set_physics_process(not negative)
		if negative:
			enemy.damage = 0.0
			enemy.base_damage = 0.0
		enemies.append(enemy)
		initial_positions.append(enemy.global_position)
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	if spell == "prism_ray":
		assert(game.spell_manager.learn_spell("focus_ray"))
		assert(game.spell_manager.learn_spell("ember_spear"))
	if not game.spell_manager.learn_spell(spell) and spell != "bolt":
		printerr("Spell not learned: ", spell)
		quit(2)
		return
	var slot = game.spell_manager.find_spell_slot(spell)
	if slot <= 0:
		printerr("No spell slot: ", spell)
		quit(2)
		return
	game.spell_manager.get_spell_info(slot).level = rank
	var origin: Vector2 = game.player.global_position
	var travel := 0.0
	var previous: Vector2 = origin
	var casts: Array = []
	var contacts: Dictionary = {}
	var secondary_casts: Array = []
	var secondary_contacts: Dictionary = {}
	var warnings := 0
	var secondary := 0
	var frames: Array = []
	for frame in 240:
		for action in ["move_right", "move_down", "move_left", "move_up"]:
			Input.action_release(action)
		if frame % 60 < 25:
			Input.action_press(["move_right", "move_down", "move_left", "move_up"][frame / 60])
		if frame in [12, 100, 185]:
			if game.spell_manager.cast_spell_by_type(slot):
				casts.append(game.spell_manager.last_generic_cast)
				events.append({"type":"primary_cast", "frame":frame, "movie_frame":Engine.get_frames_drawn()})
		if frame in [22, 110, 195]:
			game.spell_manager.last_generic_cast = null
			game.spell_manager.fire_mana_bolt()
			var bolt = game.spell_manager.last_generic_cast
			if is_instance_valid(bolt):
				secondary_casts.append(bolt)
				secondary += 1
			events.append({"type":"secondary_cast", "frame":frame, "movie_frame":Engine.get_frames_drawn()})
		await physics_frame
		await process_frame
		travel += game.player.global_position.distance_to(previous)
		previous = game.player.global_position
		for cast in casts:
			if is_instance_valid(cast):
				contacts[str(cast.get_instance_id())] = cast.hits_log.duplicate(true)
		for cast in secondary_casts:
			if is_instance_valid(cast):
				secondary_contacts[str(cast.get_instance_id())] = cast.hits_log.duplicate(true)
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.warning > 0.0:
				warnings += 1
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		var output = "%s/%04d.png" % [folder, frame]
		if stage.get_texture().get_image().save_png(output) != OK:
			failures.append("frame_write_failed")
		frames.append({"png":frame,"movie_frame":Engine.get_frames_drawn(),"player":[previous.x,previous.y],"camera":[game.camera.global_position.x,game.camera.global_position.y]})
	for action in ["move_right", "move_down", "move_left", "move_up"]:
		Input.action_release(action)
	var hit_count := 0
	for hits in contacts.values():
		hit_count += hits.size()
	var moved := 0
	for i in enemies.size():
		if is_instance_valid(enemies[i]) and enemies[i].global_position.distance_to(initial_positions[i]) > 10:
			moved += 1
	if damage_events == 0 and warnings == 0:
		failures.append("missing_hostile_activity")
	if hit_count == 0:
		failures.append("missing_primary_contacts")
	if travel < 100 or moved < 5:
		failures.append("missing_motion")
	var secondary_hits := 0
	for hits in secondary_contacts.values():
		secondary_hits += hits.size()
	if secondary < 3 or secondary_hits == 0 or frames.size() != 240:
		failures.append("missing_casts_or_frames")
	var result = {"spell":spell,"rank":rank,"negative_control":negative,"failures":failures,"damage_events":damage_events,"hostile_warning_samples":warnings,"primary_contacts":contacts,"primary_hit_count":hit_count,"player_travel":travel,"moving_enemies":moved,"secondary_casts":secondary,"secondary_contacts":secondary_contacts,"secondary_hits":secondary_hits,"frames":frames,"events":events,"sound_grade":"U: not heard"}
	var file = FileAccess.open(folder + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("COMBAT_RESULT ", JSON.stringify({"failures":failures,"damage":damage_events,"warnings":warnings,"hits":hit_count,"travel":travel,"moving_enemies":moved}))
	casts.clear()
	secondary_casts.clear()
	stage.queue_free()
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
