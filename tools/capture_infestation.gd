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
	if args.size() > 0 and args[0] == "lifecycle":
		await capture_soul_lifecycle(args)
		return
	var label = args[0] if args.size() else "candidate"
	root.get_node("AudioManager").quitting = not args.has("audio")
	var events: Array = []
	root.get_node("AudioManager").audio_event_triggered.connect(func(event): events.append({"frame": Engine.get_process_frames(), "type": event}))
	var spell_id = "soul_bloom" if args.has("soul") else "infestation"
	for rank in ([8] if args.has("soul") or args.has("resting") or args.has("crowded") else [1, 8]):
		await setup()
		await create_timer(1.0).timeout
		root.mode = Window.MODE_WINDOWED
		root.position = Vector2i(10000, 10000)
		root.size = Vector2i(1280, 850)
		root.content_scale_size = root.size
		for enemy in get_nodes_in_group("enemies"):
			if enemy.max_health != 10000:
				enemy.free()
		if args.has("crowded"):
			var manager = game.get_node("MonsterManager")
			for i in 8:
				var definition = manager.encounter_config.variants.pursuer.duplicate(true)
				definition.id = "pursuer"
				var enemy = manager.spawn_monster(definition, false, true)
				enemy.current_health = 10000
				enemy.max_health = 10000
				enemy.set_physics_process(false)
		var foes = get_nodes_in_group("enemies")
		var origins: Array = []
		for i in foes.size():
			foes[i].global_position = game.player.global_position + Vector2(160 + i * (250 if args.has("resting") else (50 if rank == 1 else 85)), 0)
			if args.has("crowded"):
				foes[i].global_position = game.player.global_position + Vector2(160 + (i % 4) * 55, (i / 4 - 1) * 48)
			origins.append(foes[i].global_position)
		var stage = SubViewport.new()
		stage.size = root.size
		stage.world_2d = root.world_2d
		stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(stage)
		var folder = "res://builds/infestation/" + label + "/rank-" + str(rank)
		DirAccess.make_dir_recursive_absolute(folder)
		if spell_id == "soul_bloom":
			for ingredient in load("res://scripts/SynergyCatalog.gd").RECIPES.soul_bloom.ingredients:
				game.spell_manager.learn_spell(ingredient)
				game.spell_manager.get_spell_info(game.spell_manager.find_spell_slot(ingredient)).level = 8
		assert(game.spell_manager.learn_spell(spell_id))
		var slot = game.spell_manager.find_spell_slot(spell_id)
		game.spell_manager.get_spell_info(slot).level = rank
		events.append({"type":"case_start", "rank":rank, "frame":Engine.get_process_frames()})
		for frame in 480:
			for i in foes.size():
				if is_instance_valid(foes[i]):
					foes[i].global_position = origins[i] + Vector2(0, sin(float(frame) / 50.0) * 36.0)
			if frame == 12 or (args.has("crowded") and frame in [60, 120, 180]):
				assert(game.spell_manager.cast_spell_by_type(slot))
			if frame == 110:
				foes[0].take_damage(20000, game.player.global_position)
			await physics_frame
			await process_frame
			if frame % 30 == 0:
				var cast = game.spell_manager.last_generic_cast
				if is_instance_valid(cast):
					var parts = cast.root_parts()
					if not parts.is_empty() and is_instance_valid(parts[0]):
						var infection = parts[0].infection
						if infection != null:
							events.append({"type":"lifecycle", "rank":rank, "frame":frame, "hosts":infection.hosts.size(), "started":infection.hosts_started, "links":infection.links.size(), "resting":infection.spores.size(), "ghosts":get_nodes_in_group("soul_ghosts").size()})
			stage.canvas_transform = root.get_canvas_transform()
			game.get_node("Background").queue_redraw()
			await RenderingServer.frame_post_draw
			if frame == 0:
				print("FIRST_PNG_MOVIE_FRAME rank=", rank, " frame=", Engine.get_frames_drawn())
			assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % frame) == OK)
		stage.queue_free()
		await teardown()
		root.get_node("Vfx").clear()
		await process_frame
		await process_frame
	FileAccess.open("res://builds/infestation/" + label + "/events.json", FileAccess.WRITE).store_string(JSON.stringify(events))
	quit()

func soul_snapshot(ghost) -> Dictionary:
	return {"id":ghost.get_instance_id(), "age":ghost.age, "position":[ghost.global_position.x, ghost.global_position.y], "healing":ghost.healing, "amount":ghost.amount, "source":ghost.source.duplicate(true), "form":ghost.get_child(0).form, "trail_points":ghost.trail.size()}

func capture_soul_lifecycle(args):
	if args.size() < 4 or not args[1].begins_with("/") or not args[2] in ["1", "8"] or not args[3] in ["wounded", "full"]:
		printerr("Expected lifecycle absolute-folder rank1|8 wounded|full optional audio")
		quit(2)
		return
	var folder: String = args[1]
	var rank := int(args[2])
	var mode: String = args[3]
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
	var manager = game.spell_manager
	manager.set_process_input(false)
	manager.cancel_typing()
	var foes := get_nodes_in_group("enemies")
	if foes.size() < 2:
		quit(2)
		return
	var victim = foes[0]
	var recipient = foes[1]
	for foe in foes:
		if foe != victim and foe != recipient:
			foe.free()
	var victim_id: int = victim.get_instance_id()
	var recipient_id: int = recipient.get_instance_id()
	var birth_at: Vector2 = game.player.global_position + Vector2(210, 0)
	victim.global_position = birth_at
	victim.current_health = 1.0
	victim.xp_value = 0.0
	recipient.global_position = game.player.global_position + Vector2(470, 0)
	recipient.xp_value = 0.0
	game.player.health = game.player.max_health - 5.0 if mode == "wounded" else game.player.max_health
	var initial_health: float = game.player.health
	var damage: Array = []
	for foe in [victim, recipient]:
		var enemy_id: int = foe.get_instance_id()
		foe.damage_feedback.connect(func(amount, at, source): damage.append({"enemy":enemy_id,"amount":amount,"position":[at.x,at.y],"source":source.duplicate(true),"movie_frame":Engine.get_frames_drawn()}))
	var health_events: Array = []
	game.player.health_changed.connect(func(health, maximum, overheal): health_events.append({"health":health,"max":maximum,"overheal":overheal,"movie_frame":Engine.get_frames_drawn()}))
	for ingredient in load("res://scripts/SynergyCatalog.gd").RECIPES.soul_bloom.ingredients:
		manager.learn_spell(ingredient)
		manager.get_spell_info(manager.find_spell_slot(ingredient)).level = 8
	if not manager.learn_spell("soul_bloom"):
		quit(2)
		return
	var slot = manager.find_spell_slot("soul_bloom")
	manager.get_spell_info(slot).level = rank
	var stage := SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	manager.last_generic_cast = null
	if not manager.cast_spell_by_type(slot) or not is_instance_valid(manager.last_generic_cast):
		quit(2)
		return
	var cast = manager.last_generic_cast
	var source: Dictionary = cast.source.duplicate(true)
	var infection = cast.root_parts()[0].infection
	var expected_amount := float(infection.cfg.bloom.amount)
	var spread_radius: float = infection.resting_radius()
	var ghost = null
	var births: Array = []
	var samples: Array = []
	var frames: Array = []
	var final_state := {}
	var death_seen := false
	var tail := 0
	for frame in 420:
		await physics_frame
		await process_frame
		death_seen = death_seen or not is_instance_valid(victim) or victim.dying
		for candidate in get_nodes_in_group("soul_ghosts"):
			if not births.has(candidate.get_instance_id()):
				births.append(candidate.get_instance_id())
				ghost = candidate
				var observed = candidate
				observed.tree_exiting.connect(func(): final_state.merge(soul_snapshot(observed), true))
		if is_instance_valid(ghost):
			var sample := soul_snapshot(ghost)
			sample["frame"] = frame
			sample["movie_frame"] = Engine.get_frames_drawn()
			sample["player_health"] = game.player.health
			samples.append(sample)
		elif not births.is_empty():
			tail += 1
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if stage.get_texture().get_image().save_png(folder + "/%04d.png" % frame) != OK:
			quit(2)
			return
		frames.append({"png":frame,"movie_frame":Engine.get_frames_drawn(),"health":game.player.health,"victim_dead":death_seen,"ghost_live":is_instance_valid(ghost),"time_scale":Engine.time_scale,"paused":paused,"typing":manager.is_typing})
		if tail >= 30:
			break
	var failures: Array = []
	if int(source.get("cast_id",0)) <= 0 or source.get("spell", "") != "soul_bloom":
		failures.append("missing_explicit_cast_source")
	var infection_hits := damage.filter(func(hit): return hit.enemy == victim_id and hit.amount > 0 and hit.source.get("cast_id") == source.get("cast_id") and hit.source.get("spell") == "soul_bloom" and hit.source.get("via", "") != "ghost")
	var ghost_hits := damage.filter(func(hit): return hit.source.get("via", "") == "ghost")
	if infection_hits.is_empty() or not death_seen or births.size() != 1 or samples.is_empty():
		failures.append("missing_infection_death_or_single_spirit")
	if not samples.is_empty():
		var first: Dictionary = samples[0]
		if Vector2(first.position[0],first.position[1]).distance_to(birth_at) > 12.0 or first.source.get("cast_id") != source.get("cast_id") or first.source.get("via") != "ghost" or not is_equal_approx(float(first.amount), expected_amount):
			failures.append("spirit_birth_or_source_mismatch")
	if samples.size() < 8 or samples.any(func(sample): return sample.form != "hybrid") or final_state.is_empty() or float(final_state.get("age",4.0)) >= 4.0 or is_instance_valid(ghost):
		failures.append("missing_travel_hybrid_or_arrival_retirement")
	var expected_heal := minf(expected_amount, game.player.max_health - initial_health)
	if mode == "wounded":
		if not is_equal_approx(game.player.health-initial_health,expected_heal) or not ghost_hits.is_empty() or not final_state.get("healing",false) or health_events.size() != 1:
			failures.append("missing_capped_heal_or_unexpected_damage")
	else:
		if game.player.health != initial_health or ghost_hits.size() != 1 or not health_events.is_empty() or final_state.get("healing",true):
			failures.append("missing_attack_or_unexpected_heal")
		elif ghost_hits[0].enemy != recipient_id or ghost_hits[0].source.get("cast_id") != source.get("cast_id") or not is_equal_approx(float(ghost_hits[0].amount),expected_amount) or not is_equal_approx(10000.0-recipient.current_health,expected_amount):
			failures.append("ghost_damage_target_or_amount_mismatch")
	if birth_at.distance_to(recipient.global_position) <= spread_radius or damage.any(func(hit): return hit.enemy == recipient_id and hit.source.get("via", "") != "ghost"):
		failures.append("recipient_not_isolated_from_infection")
	if frames.any(func(frame): return frame.paused or frame.typing or not is_equal_approx(frame.time_scale,1.0)):
		failures.append("interrupted_gameplay_time")
	var result := {"spell":"soul_bloom","rank":rank,"mode":mode,"fixture":"controlled real stationary monsters, one 1HP host killed by actual infection tick, XP0, recipient held outside spread/resting radius; not mixed hostile combat","source":source,"expected_ghost_amount":expected_amount,"initial_health":initial_health,"final_health":game.player.health,"victim_id":victim_id,"recipient_id":recipient_id,"resting_radius":spread_radius,"recipient_distance":birth_at.distance_to(recipient.global_position),"damage":damage,"health_events":health_events,"births":births,"samples":samples,"final_state":final_state,"frames":frames,"audio_events":audio_events,"remaining_infection":{"hosts":infection.hosts.size(),"links":infection.links.size(),"spores":infection.spores.size()},"failures":failures,"sound_grade":"U: not heard"}
	FileAccess.open(folder + "/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("SOUL_CAPTURE rank=",rank," mode=",mode," infection_hits=",infection_hits.size()," ghosts=",births.size()," ghost_hits=",ghost_hits.size()," health_delta=",game.player.health-initial_health," failures=",failures)
	stage.queue_free()
	await teardown()
	quit(0 if failures.is_empty() else 1)
