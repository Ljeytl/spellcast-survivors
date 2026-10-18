extends "res://tools/capture_spell_gallery.gd"

func _initialize() -> void:
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func snapshot(spirit) -> Dictionary:
	return {"age":spirit.age, "ending":spirit.spirit_ending, "returning":spirit.returning_life, "finishing":spirit.finishing_hunt, "return_age":spirit.return_age, "stolen_life":spirit.stolen_life, "hunted":spirit.hunted_targets.keys(), "excluded":spirit.exclude.keys(), "position":[spirit.global_position.x, spirit.global_position.y], "hits":spirit.cast.hits_log.duplicate(true), "done":spirit.done}

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3 or not args[0].begins_with("/") or not args[1] in ["1", "8"] or not args[2] in ["wounded", "full"]:
		printerr("Expected absolute output folder, rank 1|8, wounded|full, optional audio")
		quit(2)
		return
	var folder := args[0]
	var rank := int(args[1])
	var mode := args[2]
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	root.get_node("AudioManager").quitting = not args.has("audio")
	var audio_events: Array = []
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): audio_events.append({"event":event,"movie_frame":Engine.get_frames_drawn()}))
	DirAccess.make_dir_recursive_absolute(folder)
	await setup()
	await create_timer(1.0).timeout
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000, 10000)
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	var foes := get_nodes_in_group("enemies")
	if foes.size() < 4:
		quit(2)
		return
	var hunt_enemy = foes[0]
	for foe in foes:
		if foe != hunt_enemy:
			foe.free()
	hunt_enemy.global_position = game.player.global_position + Vector2(210, 0)
	game.player.health = game.player.max_health - 10.0 if mode == "wounded" else game.player.max_health
	var initial_health: float = game.player.health
	var stage := SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var manager = game.spell_manager
	if not manager.learn_spell("seeker"):
		quit(2)
		return
	var slot = manager.find_spell_slot("seeker")
	manager.get_spell_info(slot).level = rank
	manager.last_generic_cast = null
	if not manager.cast_spell_by_type(slot) or not is_instance_valid(manager.last_generic_cast) or manager.last_generic_cast.parts.size() != 1:
		quit(2)
		return
	var cast = manager.last_generic_cast
	var spirit = cast.parts[0]
	var lifetime: float = spirit.total_life()
	var outbound_speed: float = spirit.def.motion[0].speed
	var final_state := {}
	spirit.tree_exiting.connect(func(): final_state.merge(snapshot(spirit), true))
	var frames: Array = []
	var samples: Array = []
	var ending_state := {}
	var fresh_enemy = null
	var fresh_id := 0
	var tail := 0
	var previous := snapshot(spirit)
	var return_speeds: Array = []
	for frame in int((lifetime + 6.0) * 30.0):
		await physics_frame
		await process_frame
		if is_instance_valid(spirit):
			var state := snapshot(spirit)
			if state.ending and ending_state.is_empty():
				ending_state = state.duplicate(true)
				if mode == "full":
					var monsters = game.get_node("MonsterManager")
					var definition = monsters.encounter_config.variants.pursuer.duplicate(true)
					definition.id = "pursuer"
					fresh_enemy = monsters.spawn_monster(definition, false, true)
					fresh_enemy.global_position = game.player.global_position + Vector2(250, 120)
					fresh_enemy.current_health = 10000
					fresh_enemy.max_health = 10000
					fresh_enemy.set_physics_process(false)
					fresh_enemy.get_node("HealthBar").hide()
					fresh_id = fresh_enemy.get_instance_id()
			if state.returning and previous.returning and state.age > previous.age:
				var distance := Vector2(state.position[0], state.position[1]).distance_to(Vector2(previous.position[0], previous.position[1]))
				return_speeds.append(distance / (state.age - previous.age))
			state["frame"] = frame
			state["player_health"] = game.player.health
			samples.append(state)
			previous = state
		else:
			tail += 1
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if stage.get_texture().get_image().save_png(folder + "/%04d.png" % frame) != OK:
			quit(2)
			return
		frames.append({"png":frame,"movie_frame":Engine.get_frames_drawn()})
		if tail >= 15:
			break
	var failures: Array = []
	var expected_lifetime := 12.0 if rank == 1 else 24.0
	if absf(lifetime - expected_lifetime) > 0.02 or ending_state.is_empty() or float(ending_state.get("age", 0)) < expected_lifetime:
		failures.append("missing_full_hunt")
	var hunt_hits: Array = ending_state.get("hits", [])
	if hunt_hits.size() < 3 or float(hunt_hits[-1].t) - float(hunt_hits[0].t) < expected_lifetime - 3.0 or hunt_enemy.current_health >= 10000 or hunt_enemy.current_health <= 0 or not ending_state.get("hunted", []).has(hunt_enemy.get_instance_id()):
		failures.append("missing_sustained_actual_damage")
	if final_state.is_empty() or not final_state.get("done", false) or float(final_state.get("return_age", 4.0)) >= 4.0:
		failures.append("missing_completion_or_timeout")
	var ending_hits: Array = final_state.get("hits", []).slice(hunt_hits.size())
	if mode == "wounded":
		if not ending_state.get("returning", false) or game.player.health <= initial_health or game.player.health - initial_health > 2.001 or not ending_hits.is_empty():
			failures.append("missing_capped_heal_or_return_damage")
		if return_speeds.is_empty() or return_speeds.any(func(speed): return absf(speed - outbound_speed * 0.8) > 1.0):
			failures.append("return_not_slower")
	else:
		if not ending_state.get("finishing", false) or fresh_id == 0 or ending_hits.size() != 1 or int(ending_hits[0].enemy) != fresh_id or ending_state.get("hunted", []).has(fresh_id) or ending_state.get("excluded", []).has(fresh_id) or not is_instance_valid(fresh_enemy) or fresh_enemy.current_health >= 10000 or game.player.health != initial_health:
			failures.append("missing_fresh_target_damage_or_unexpected_heal")
	var result := {"spell":"seeker","rank":rank,"mode":mode,"fixture":"controlled stationary target; fresh full-health target introduced only after ending begins; no hostile AI or secondary spell","fps":30,"lifetime":lifetime,"outbound_speed":outbound_speed,"return_speeds":return_speeds,"initial_health":initial_health,"final_health":game.player.health,"hunt_target":hunt_enemy.get_instance_id(),"hunt_target_health":hunt_enemy.current_health,"fresh_target":fresh_id,"fresh_target_health":fresh_enemy.current_health if is_instance_valid(fresh_enemy) else null,"ending_state":ending_state,"final_state":final_state,"samples":samples,"frames":frames,"audio_events":audio_events,"failures":failures,"sound_grade":"U: not heard"}
	FileAccess.open(folder + "/manifest.json", FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("SEEKER_CAPTURE rank=",rank," mode=",mode," hunt_hits=",hunt_hits.size()," health_delta=",game.player.health-initial_health," ending_hits=",ending_hits.size()," failures=",failures)
	stage.queue_free()
	await teardown()
	quit(0 if failures.is_empty() else 1)
