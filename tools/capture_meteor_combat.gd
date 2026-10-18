extends "res://tools/capture_spell_combat.gd"

const Part = preload("res://scripts/engine/SpellPart.gd")
var capture_frame := 0
var parts: Array = []
var resolved: Array = []
var primary_record := {}

func stamp() -> Dictionary:
	return {"frame":capture_frame,"movie_frame":Engine.get_frames_drawn(),"physics_frame":Engine.get_physics_frames()}

func observe_part(node):
	if node.get_script() != Part:
		return
	var owner_cast = node.get_parent()
	if str(owner_cast.source.get("spell", "")) != "meteor_shower":
		return
	var birth := stamp()
	birth["clock"] = owner_cast.clock
	record_part.call_deferred(node, birth)

func record_part(part, birth: Dictionary):
	if not is_instance_valid(part):
		failures.append("part_lost_before_observation")
		return
	var record := {"id":str(part.get_instance_id()),"part":part.part_name,"source":part.cast.source.duplicate(true),"birth":birth,"position":[part.global_position.x,part.global_position.y],"definition":part.def.duplicate(true),"exit":{}}
	parts.append(record)
	part.tree_exiting.connect(func():
		record.exit = stamp()
		record.exit.merge({"age":part.age,"hits":part.hit_count,"done":part.done,"clock":part.cast.clock}))

func record_damage(amount: float, position: Vector2, source: Dictionary, target: int):
	var event := stamp()
	event.merge({"amount":amount,"position":[position.x,position.y],"source":source.duplicate(true),"target":target})
	resolved.append(event)

func run():
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		quit(2)
		return
	var folder: String = args[0]
	var reduced := args.has("reduced")
	DirAccess.make_dir_recursive_absolute(folder)
	seed(41)
	root.size = Vector2i(1280,850)
	root.content_scale_size = root.size
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000,10000)
	root.size = Vector2i(1280,850)
	root.content_scale_size = root.size
	game.get_node("UI").hide()
	game.spell_manager.set_process(false)
	game.spell_manager.set_process_input(false)
	game.spell_manager.cancel_typing()
	game.camera_shake.set_process(true)
	game.camera_shake.reduced_effects = reduced
	game.particle_manager.reduced_effects = reduced
	root.get_node("Vfx").reduced_effects = reduced
	game.player.style_health_damaged.connect(func(amount):
		damage_events += 1
		var event := stamp()
		event.merge({"type":"player_damage","amount":amount})
		events.append(event))
	root.get_node("AudioManager").audio_event_triggered.connect(func(event):
		var entry := stamp()
		entry.merge({"type":"audio","event":event})
		events.append(entry))
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	var enemies: Array = []
	var initial: Array = []
	var configured: Array = []
	for i in 14:
		var kind := "pursuer" if i < 10 else "imp"
		var definition: Dictionary = manager.encounter_config.variants[kind].duplicate(true)
		definition.id = kind
		var enemy = manager.spawn_monster(definition,false,true)
		enemy.global_position = game.player.global_position + (Vector2(-55,0) if i == 0 else Vector2.from_angle(i * TAU / 14.0) * (150.0 if i < 10 else 320.0))
		enemy.xp_value = 0.0
		enemy.damage_feedback.connect(record_damage.bind(enemy.get_instance_id()))
		enemies.append(enemy)
		initial.append(enemy.global_position)
		configured.append({"id":enemy.get_instance_id(),"kind":kind,"health":enemy.current_health,"physics":enemy.is_physics_processing()})
	var route := prepare_capture_spell(game.spell_manager,"meteor_shower",8)
	if route.has("error"):
		printerr(route.error)
		quit(2)
		return
	node_added.connect(observe_part)
	var stage := SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var frames: Array = []
	var moved := {}
	var secondary := {}
	var previous: Vector2 = game.player.global_position
	var travel := 0.0
	var warnings := 0
	var release_frame := -1
	var secondary_frame := -1
	for frame in 480:
		capture_frame = frame
		for action in ["move_right","move_down","move_left","move_up"]:
			Input.action_release(action)
		if damage_events > 0:
			Input.action_press(["move_right","move_down","move_left","move_up"][(frame / 60) % 4])
		if secondary_frame < 0 and damage_events > 0:
			game.spell_manager.last_generic_cast = null
			game.spell_manager.fire_mana_bolt()
			var bolt = game.spell_manager.last_generic_cast
			if not is_instance_valid(bolt):
				failures.append("secondary_release_failed")
				break
			secondary = {"source":bolt.source.duplicate(true),"release":stamp(),"hits":[]}
			bolt.tree_exiting.connect(func(): secondary.hits = bolt.hits_log.duplicate(true))
			secondary_frame = frame
		if release_frame < 0 and secondary_frame >= 0 and frame - secondary_frame == 24:
			game.spell_manager.last_generic_cast = null
			if not release_capture_spell(game.spell_manager,route) or not is_instance_valid(game.spell_manager.last_generic_cast):
				failures.append("primary_release_failed")
				break
			var primary = game.spell_manager.last_generic_cast
			primary_record = {"source":primary.source.duplicate(true),"plan":primary.plan.duplicate(true),"release":stamp(),"prior_damage_events":damage_events,"exit":{},"hits":[]}
			primary.tree_exiting.connect(func():
				primary_record.exit = stamp()
				primary_record.exit["clock"] = primary.clock
				primary_record.hits = primary.hits_log.duplicate(true))
			release_frame = frame
		await physics_frame
		await process_frame
		travel += game.player.global_position.distance_to(previous)
		previous = game.player.global_position
		for index in enemies.size():
			if is_instance_valid(enemies[index]):
				if enemies[index].global_position.distance_to(initial[index]) > 10:
					moved[index] = true
				if enemies[index].warning > 0:
					warnings += 1
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if stage.get_texture().get_image().save_png("%s/%04d.png" % [folder,frame]) != OK:
			failures.append("png_write_failed")
		var state := stamp()
		state.merge({"png":frame,"player":[previous.x,previous.y],"health":game.player.health,"camera":[game.camera.global_position.x,game.camera.global_position.y],"camera_offset":[game.camera.offset.x,game.camera.offset.y],"canvas_origin":[stage.canvas_transform.origin.x,stage.canvas_transform.origin.y],"shake_timer":game.camera_shake.shake_timer,"shake_intensity":game.camera_shake.shake_intensity,"camera_processing":game.camera_shake.is_processing(),"paused":paused,"time_scale":Engine.time_scale,"alive_enemies":get_nodes_in_group("enemies").size()})
		frames.append(state)
		if paused or Engine.time_scale != 1.0 or game.player.health <= 0 or game.current_state != game.GameState.PLAYING:
			failures.append("invalid_runtime_state")
			break
	for action in ["move_right","move_down","move_left","move_up"]:
		Input.action_release(action)
	if damage_events < 1 or warnings < 1 or moved.size() < 6 or travel < 100:
		failures.append("missing_actual_pressure_or_movement")
	if primary_record.is_empty() or primary_record.exit.is_empty() or primary_record.hits.is_empty():
		failures.append("missing_primary_damage_or_completion")
	if secondary.is_empty() or secondary.hits.is_empty():
		failures.append("missing_secondary_contact")
	if not resolved.any(func(event): return event.amount > 0 and event.source.get("spell", "") == "meteor_shower"):
		failures.append("missing_positive_meteor_damage")
	for kind in ["mark", "impact", "crater"]:
		var group := parts.filter(func(part): return part.part == kind)
		if group.size() != 6 or group.any(func(part): return part.exit.is_empty() or not part.exit.done):
			failures.append("incomplete_six_" + kind)
	if frames.size() != 480 or frames.any(func(frame): return not frame.camera_processing):
		failures.append("incomplete_frames_or_disabled_camera")
	var result := {"spell":"meteor_shower","rank":8,"reduced_effects":reduced,"actual_reduced":{"vfx":root.get_node("Vfx").reduced_effects,"particles":game.particle_manager.reduced_effects,"camera":game.camera_shake.reduced_effects},"fixture":"14 native-health hostile AI enemies; XP0 prevents progression modal. Actual player damage before one Magic Missile and one rank8 Meteor release. Ordinary movement input; live camera follow/shake. No forced hits or health writes. Impact misses retained.","configured_enemies":configured,"primary":primary_record,"secondary":secondary,"parts":parts,"resolved":resolved,"damage_events":damage_events,"warnings":warnings,"moving_enemies":moved.size(),"player_travel":travel,"frames":frames,"events":events,"failures":failures,"sound_grade":"U: not heard"}
	FileAccess.open(folder+"/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("METEOR_COMBAT ",JSON.stringify({"failures":failures,"parts":parts.size(),"frames":frames.size()}))
	stage.queue_free()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
