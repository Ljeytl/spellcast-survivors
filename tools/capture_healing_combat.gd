extends "res://tools/capture_spell_combat.gd"

var healing_context := {"cast_id":"", "source":"", "releasing":false}
var healing_events: Array = []
var capture_frame := 0

func stamp() -> Dictionary:
	return {"frame":capture_frame,"movie_frame":Engine.get_frames_drawn(),"physics_frame":Engine.get_physics_frames(),"wall_msec":Time.get_ticks_msec()}

func run():
	var args := OS.get_cmdline_user_args()
	if args.size() < 2 or args[0] not in ["life", "regeneration"]:
		quit(2)
		return
	var spell: String = args[0]
	var folder: String = args[1]
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
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	var enemies: Array = []
	var positions: Array = []
	for i in 4:
		var kind := "imp" if i == 3 else "pursuer"
		var definition: Dictionary = manager.encounter_config.variants[kind].duplicate(true)
		definition.id = kind
		var enemy = manager.spawn_monster(definition,false,true)
		enemy.global_position = game.player.global_position + (Vector2(-55,0) if i == 0 else Vector2.from_angle(i * TAU / 4.0) * (300.0 if i == 3 else 180.0))
		enemy.max_health = 10000
		enemy.current_health = 10000
		enemy.xp_value = 0.0
		enemies.append(enemy)
		positions.append(enemy.global_position)
	var health := {"previous":float(game.player.health)}
	game.player.style_health_damaged.connect(func(amount):
		damage_events += 1
		var event := stamp()
		event.merge({"type":"player_damage","amount":amount})
		events.append(event))
	game.player.health_changed.connect(func(value, maximum, _overheal):
		var amount: float = value - health.previous
		if amount > 0.0:
			var event := stamp()
			event.merge({"amount":amount,"before":health.previous,"after":value,"maximum":maximum,"context":healing_context.duplicate(true)})
			healing_events.append(event)
			if value > maximum or healing_context.source != spell:
				failures.append("unbound_or_overcap_heal")
		health.previous = value)
	var route := prepare_capture_spell(game.spell_manager,spell,8,"")
	if route.has("error"):
		quit(2)
		return
	var stage := SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var primary
	var primary_record := {}
	var secondary: Array = []
	var contacts := {}
	var frames: Array = []
	var visual_emissions: Array = []
	var seen_visuals := {}
	var release_frame := -1
	var travel := 0.0
	var previous: Vector2 = game.player.global_position
	var warnings := 0
	for frame in 450:
		capture_frame = frame
		for action in ["move_right","move_down","move_left","move_up"]:
			Input.action_release(action)
		if damage_events > 0:
			Input.action_press(["move_right","move_down","move_left","move_up"][(frame / 45) % 4])
		if release_frame < 0 and damage_events > 0 and game.player.health < game.player.max_health:
			healing_context = {"source":spell,"cast_id":"pending_release","releasing":true}
			game.spell_manager.last_generic_cast = null
			var before: float = game.player.health
			if not release_capture_spell(game.spell_manager,route) or not is_instance_valid(game.spell_manager.last_generic_cast):
				failures.append("primary_release_failed")
				break
			primary = game.spell_manager.last_generic_cast
			healing_context.cast_id = str(primary.get_instance_id())
			healing_context.releasing = false
			for event in healing_events:
				if event.context.cast_id == "pending_release":
					event.context.cast_id = healing_context.cast_id
			release_frame = frame
			primary_record = {"cast_id":healing_context.cast_id,"source":primary.source.duplicate(true),"before":before,"release":stamp(),"plan":primary.plan.duplicate(true),"exit":{}}
			primary.tree_exiting.connect(func():
				primary_record.exit = stamp()
				primary_record.exit["clock"] = primary.clock
				healing_context.source = "")
		if release_frame >= 0 and frame - release_frame in [10,70]:
			game.spell_manager.last_generic_cast = null
			game.spell_manager.fire_mana_bolt()
			var bolt = game.spell_manager.last_generic_cast
			if not is_instance_valid(bolt):
				failures.append("secondary_release_failed")
				break
			var key := str(bolt.get_instance_id())
			secondary.append(bolt)
			contacts[key] = []
			bolt.tree_exiting.connect(func(): contacts[key] = bolt.hits_log.duplicate(true))
		await physics_frame
		await process_frame
		for visual in get_nodes_in_group("healing_visuals"):
			var visual_id := str(visual.get_instance_id())
			if not seen_visuals.has(visual_id):
				seen_visuals[visual_id] = true
				var emission := stamp()
				emission.merge({"id":visual_id,"script":visual.get_script().resource_path})
				visual_emissions.append(emission)
		travel += game.player.global_position.distance_to(previous)
		previous = game.player.global_position
		for bolt in secondary:
			if is_instance_valid(bolt):
				contacts[str(bolt.get_instance_id())] = bolt.hits_log.duplicate(true)
		for enemy in enemies:
			if enemy.warning > 0:
				warnings += 1
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if stage.get_texture().get_image().save_png("%s/%04d.png" % [folder,frame]) != OK:
			failures.append("png_write_failed")
		var state := stamp()
		state.merge({"png":frame,"health":game.player.health,"invincible":game.player.is_invincible,"player":[previous.x,previous.y],"healing_visuals":get_nodes_in_group("healing_visuals").size(),"paused":paused,"time_scale":Engine.time_scale})
		frames.append(state)
		if game.player.health <= 0 or game.current_state != game.GameState.PLAYING:
			failures.append("encounter_not_survived")
			break
		if release_frame >= 0 and frame - release_frame >= (210 if spell == "life" else 300) and not primary_record.exit.is_empty():
			break
	for action in ["move_right","move_down","move_left","move_up"]:
		Input.action_release(action)
	var moved := 0
	for i in enemies.size():
		if enemies[i].global_position.distance_to(positions[i]) > 20:
			moved += 1
	if damage_events == 0 or healing_events.is_empty() or travel < 100 or moved < 2 or warnings == 0:
		failures.append("missing_damage_healing_movement_or_threat")
	if contacts.size() != 2 or contacts.values().any(func(hits): return hits.is_empty()):
		failures.append("each_secondary_requires_contact")
	if primary_record.is_empty() or primary_record.exit.is_empty():
		failures.append("missing_primary_completion")
	if spell == "regeneration":
		if healing_events.size() < 3:
			failures.append("missing_continuous_recovery")
		if not primary_record.is_empty() and not primary_record.exit.is_empty():
			var duration: float = primary_record.plan.parts.aura.timing.duration
			if float(primary_record.exit.clock) + 0.04 < duration:
				failures.append("regeneration_ended_before_duration")
		if get_nodes_in_group("healing_visuals").size() != 0:
			failures.append("healing_visuals_not_retired")
	if frames.any(func(state): return state.invincible or state.paused or state.time_scale != 1.0):
		failures.append("invalid_runtime_state")
	var result := {"spell":spell,"rank":8,"fps":30,"fixture":"Four genuine hostile AI enemies,10000HP/XP0; actual damage before release, ordinary movement input, no health writes/invincibility/direct healing. Unique primary healing source; Magic Missile secondary cannot heal. UI hidden. Visual throttle uses wall-clock350ms; record wall and physics timestamps separately.","failures":failures,"primary":primary_record,"heals":healing_events,"visual_emissions":visual_emissions,"damage_events":damage_events,"events":events,"secondary_contacts":contacts,"player_travel":travel,"moving_enemies":moved,"warnings":warnings,"frames":frames,"sound_grade":"U: not heard"}
	FileAccess.open(folder+"/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("HEALING_COMBAT ",JSON.stringify({"failures":failures,"heals":healing_events.size(),"frames":frames.size()}))
	stage.queue_free()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
