extends "res://tools/capture_spell_combat.gd"

var frame_index := 0
var retaliation: Array = []

func stamp() -> Dictionary:
	return {"frame":frame_index,"movie_frame":Engine.get_frames_drawn(),"physics_frame":Engine.get_physics_frames()}

func record_damage(amount: float, _position: Vector2, source: Dictionary, enemy_id: int):
	if str(source.get("spell", "")) == "earth_shield":
		var event := stamp()
		event.merge({"amount":amount,"source":source.duplicate(true),"enemy_id":enemy_id})
		retaliation.append(event)

func run():
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		quit(2)
		return
	var folder: String = args[0]
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
	for i in 3:
		var kind := "imp" if i == 2 else "pursuer"
		var definition: Dictionary = manager.encounter_config.variants[kind].duplicate(true)
		definition.id = kind
		var enemy = manager.spawn_monster(definition,false,true)
		enemy.global_position = game.player.global_position + [Vector2(-120,0),Vector2(170,50),Vector2(0,-280)][i]
		enemy.max_health = 10000
		enemy.current_health = 10000
		enemy.xp_value = 0.0
		enemy.damage_feedback.connect(record_damage.bind(enemy.get_instance_id()))
		enemies.append(enemy)
		positions.append(enemy.global_position)
	game.player.style_health_damaged.connect(func(amount):
		damage_events += 1
		var event := stamp()
		event.merge({"amount":amount,"health":game.player.health,"charges":game.player.earth_shield.charges.size(),"context":game.player.last_damage_context.duplicate(true)})
		events.append(event))
	var route := prepare_capture_spell(game.spell_manager,"earth_shield",8,"")
	if route.has("error"):
		quit(2)
		return
	var stage := SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var casts := 0
	var blocks: Array = []
	var eruptions := {}
	var secondary: Array = []
	var contacts := {}
	var frames: Array = []
	var recast_frame := -1
	var restored := false
	var travel := 0.0
	var previous: Vector2 = game.player.global_position
	var warnings := 0
	var previous_charges := 0
	for frame in 450:
		frame_index = frame
		for action in ["move_right","move_down","move_left","move_up"]:
			Input.action_release(action)
		if recast_frame >= 0 or frame % 15 < 4:
			Input.action_press(["move_right","move_down","move_left","move_up"][(frame / 30) % 4])
		if frame in [0,6] or (casts == 2 and damage_events > 0):
			if not release_capture_spell(game.spell_manager,route):
				failures.append("shield_release_failed")
				break
			casts += 1
			previous_charges = game.player.earth_shield.charges.size()
			if casts == 2 and previous_charges != 2:
				failures.append("two_initial_charges_not_observed")
			if casts == 3:
				recast_frame = frame
				restored = previous_charges == 1
		if frame in [30,90]:
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
		var health_before: float = game.player.health
		await physics_frame
		await process_frame
		var charges: int = game.player.earth_shield.charges.size()
		if charges < previous_charges:
			var block := stamp()
			block.merge({"before":previous_charges,"after":charges,"health_before":health_before,"health_after":game.player.health,"context":game.player.last_damage_context.duplicate(true)})
			blocks.append(block)
			if previous_charges - charges != 1 or not block.context.get("blocked",false) or health_before != game.player.health:
				failures.append("charge_consumption_not_bound_to_absorbed_attack")
		previous_charges = charges
		for cast in get_nodes_in_group("generic_casts"):
			if str(cast.plan.get("id","")) == "earth_shield":
				var key := str(cast.get_instance_id())
				if not eruptions.has(key):
					eruptions[key] = {"spawn":stamp(),"direction":[cast.forced_dir.x,cast.forced_dir.y],"source":cast.source.duplicate(true)}
		for bolt in secondary:
			if is_instance_valid(bolt):
				contacts[str(bolt.get_instance_id())] = bolt.hits_log.duplicate(true)
		travel += game.player.global_position.distance_to(previous)
		previous = game.player.global_position
		for enemy in enemies:
			if enemy.warning > 0:
				warnings += 1
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if stage.get_texture().get_image().save_png("%s/%04d.png" % [folder,frame]) != OK:
			failures.append("png_write_failed")
		var state := stamp()
		state.merge({"png":frame,"health":game.player.health,"charges":game.player.earth_shield.charges.duplicate(true),"player":[previous.x,previous.y],"invincible":game.player.is_invincible,"paused":paused,"time_scale":Engine.time_scale})
		frames.append(state)
		if game.player.health <= 0 or game.current_state != game.GameState.PLAYING:
			failures.append("encounter_not_survived")
			break
		if recast_frame >= 0 and frame - recast_frame >= 90 and frame >= 210:
			break
	for action in ["move_right","move_down","move_left","move_up"]:
		Input.action_release(action)
	var moved := 0
	for i in enemies.size():
		if enemies[i].global_position.distance_to(positions[i]) > 20:
			moved += 1
	if casts != 3 or not restored or blocks.size() < 2 or eruptions.size() < 2 or retaliation.filter(func(hit): return hit.amount > 0).is_empty():
		failures.append("missing_stack_blocks_retaliation_or_recast")
	if events.is_empty() or not events.any(func(event): return event.charges == 0 and event.amount > 0):
		failures.append("missing_post_exhaustion_health_damage")
	if contacts.size() != 2 or contacts.values().any(func(hits): return hits.is_empty()):
		failures.append("each_secondary_requires_contact")
	if travel < 100 or moved < 2 or warnings == 0:
		failures.append("missing_movement_or_hostile_threat")
	if frames.any(func(state): return state.invincible or state.paused or state.time_scale != 1.0):
		failures.append("invalid_runtime_state")
	var result := {"spell":"earth_shield","rank":8,"fps":30,"fixture":"Two pursuers and one imp with genuine AI,10000HP/XP0; ordinary player movement and vulnerability. No damage/block/projectile calls, teleports or health writes after setup. Natural attack kinds recorded, not a guarantee of both projectile and contact blocks.","failures":failures,"casts":casts,"restored":restored,"blocks":blocks,"eruptions":eruptions,"retaliation":retaliation,"damage_events":events,"secondary_contacts":contacts,"player_travel":travel,"moving_enemies":moved,"warnings":warnings,"frames":frames,"sound_grade":"U: not heard"}
	FileAccess.open(folder+"/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("SHIELD_COMBAT ",JSON.stringify({"failures":failures,"frames":frames.size(),"blocks":blocks.size(),"retaliation":retaliation.size()}))
	stage.queue_free()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
