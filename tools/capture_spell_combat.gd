extends SceneTree

var game
var events: Array = []
var failures: Array = []
var damage_events := 0
var atomic_hits: Array = []

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
	if rank < 1 or rank > 8 or (spell == "seeker" and rank != 8):
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
	var initial_input_state := {"typing":game.spell_manager.is_typing, "time_scale":Engine.time_scale}
	game.spell_manager.set_process(false)
	game.spell_manager.set_process_input(false)
	game.spell_manager.cancel_typing()
	if spell == "atomic":
		game.particle_manager.reduced_effects = args.has("reduced")
		root.get_node("Vfx").reduced_effects = args.has("reduced")
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
	var enemy_count := 6 if spell == "seeker" else 14
	for i in enemy_count:
		var kind = "pursuer" if i < (5 if spell == "seeker" else 10) else "imp"
		var definition = manager.encounter_config.variants[kind].duplicate(true)
		definition.id = kind
		var enemy = manager.spawn_monster(definition, false, true)
		enemy.global_position = game.player.global_position + Vector2.from_angle(float(i) * TAU / 14.0) * (130.0 if i < 10 else 340.0)
		if spell == "seeker":
			enemy.global_position = game.player.global_position + (Vector2(-55, 0) if i == 0 else Vector2.from_angle(float(i) * TAU / 6.0) * (180.0 if i < 5 else 340.0))
		enemy.max_health = 10000
		enemy.current_health = 10000
		if spell in ["atomic", "seeker"]:
			enemy.xp_value = 0.0
		enemy.set_physics_process(not negative)
		if negative:
			enemy.damage = 0.0
			enemy.base_damage = 0.0
		enemies.append(enemy)
		initial_positions.append(enemy.global_position)
		if spell == "atomic":
			enemy.damage_feedback.connect(_record_atomic_damage.bind(enemy.get_instance_id()))
	var stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	if spell == "lightning_bolt":
		game.spell_manager.learn_spell("lightning")
		for ingredient in ["bolt", "lightning"]:
			game.spell_manager.get_spell_info(game.spell_manager.find_spell_slot(ingredient)).level = 8
	if spell == "prism_ray":
		assert(game.spell_manager.learn_spell("focus_ray"))
		assert(game.spell_manager.learn_spell("ember_spear"))
	var modifiers := ""
	for argument in args:
		if argument.begins_with("modifiers="):
			modifiers = argument.trim_prefix("modifiers=").replace("_", " ")
	var route := prepare_capture_spell(game.spell_manager, spell, rank, modifiers)
	if route.has("error"):
		printerr(route.error)
		quit(2)
		return
	if spell == "seeker":
		await capture_seeker_combat(stage, route, enemies, initial_positions, folder)
		return
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
	var moved_before_wipe: Dictionary = {}
	var atomic_state := {"releases":0, "before_release":{}, "charge_after_release":-1, "special_casts_before":game.style_session.special_casts, "live_samples":0, "impact_samples":0}
	var atomic_blast
	for frame in 240:
		for action in ["move_right", "move_down", "move_left", "move_up"]:
			Input.action_release(action)
		if frame % 60 < 25:
			Input.action_press(["move_right", "move_down", "move_left", "move_up"][frame / 60])
		if frame in ([100] if spell == "atomic" else [12, 100, 185]):
			if spell == "atomic":
				atomic_state.before_release = {"damage_events":damage_events, "warnings":warnings, "moving_enemies":moved_before_wipe.size(), "alive_enemies":get_nodes_in_group("enemies").size()}
				game.style_session.score.atomic_charges = 1
				game.style_session.score.combo = 3700.0
			if release_capture_spell(game.spell_manager, route):
				if spell == "atomic":
					atomic_state.releases += 1
					atomic_state.charge_after_release = game.style_session.score.atomic_charges
					for child in game.get_children():
						if child.get_script() == preload("res://scripts/AtomicBlast.gd"):
							atomic_blast = child
				else:
					casts.append(game.spell_manager.last_generic_cast)
				events.append({"type":"primary_cast", "frame":frame, "movie_frame":Engine.get_frames_drawn()})
		if frame in ([22] if spell == "atomic" else [22, 110, 195]):
			game.spell_manager.last_generic_cast = null
			if spell == "mana_bolt":
				game.spell_manager.cast_spell_by_type(game.spell_manager.find_spell_slot("bolt"))
			else:
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
		if spell == "atomic":
			for index in enemies.size():
				if is_instance_valid(enemies[index]) and enemies[index].global_position.distance_to(initial_positions[index]) > 10.0:
					moved_before_wipe[index] = true
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		var output = "%s/%04d.png" % [folder, frame]
		if stage.get_texture().get_image().save_png(output) != OK:
			failures.append("frame_write_failed")
		frames.append({"png":frame,"movie_frame":Engine.get_frames_drawn(),"player":[previous.x,previous.y],"camera":[game.camera.global_position.x,game.camera.global_position.y], "canvas_origin":[stage.canvas_transform.origin.x,stage.canvas_transform.origin.y], "camera_offset":[game.camera.offset.x,game.camera.offset.y], "time_scale":Engine.time_scale, "typing":game.spell_manager.is_typing, "tree_paused":paused, "game_state":game.current_state, "pending_level_ups":game.pending_level_ups.size()})
		if spell == "atomic":
			if is_instance_valid(atomic_blast):
				atomic_state.live_samples += 1
				if atomic_blast.impacted:
					atomic_state.impact_samples += 1
			frames[-1].atomic = {"live":is_instance_valid(atomic_blast), "age":atomic_blast.elapsed if is_instance_valid(atomic_blast) else -1.0, "impacted":atomic_blast.impacted if is_instance_valid(atomic_blast) else false, "alive_enemies":get_nodes_in_group("enemies").size(), "enemy_projectiles":get_nodes_in_group("enemy_projectiles").size()}
	for action in ["move_right", "move_down", "move_left", "move_up"]:
		Input.action_release(action)
	var hit_count := 0
	for hits in contacts.values():
		hit_count += hits.size()
	var moved := 0
	for i in enemies.size():
		if is_instance_valid(enemies[i]) and enemies[i].global_position.distance_to(initial_positions[i]) > 10:
			moved += 1
	if spell == "atomic":
		moved = moved_before_wipe.size()
		hit_count = atomic_hits.size()
		if atomic_state.releases != 1 or atomic_state.charge_after_release != 0 or game.style_session.special_casts != atomic_state.special_casts_before + 1:
			failures.append("atomic_release_or_charge_spend")
		if atomic_state.before_release.is_empty() or (atomic_state.before_release.get("damage_events", 0) == 0 and atomic_state.before_release.get("warnings", 0) == 0) or atomic_state.before_release.get("moving_enemies", 0) < 5:
			failures.append("missing_pre_atomic_hostile_activity")
		var atomic_damage := 0.0
		for hit in atomic_hits:
			atomic_damage += maxf(float(hit.amount), 0.0)
		atomic_state.resolved_damage = atomic_damage
		if atomic_damage <= 0.0:
			failures.append("atomic_no_resolved_damage")
		for sample in frames:
			if sample.typing or sample.tree_paused or sample.game_state != game.GameState.PLAYING or not is_equal_approx(float(sample.time_scale), 1.0):
				failures.append("atomic_capture_time_or_input_changed")
				break
		if atomic_state.live_samples == 0 or atomic_state.impact_samples == 0:
			failures.append("atomic_lifecycle_not_observed")
		if is_instance_valid(atomic_blast):
			failures.append("atomic_aftermath_not_retired")
	if damage_events == 0 and warnings == 0:
		failures.append("missing_hostile_activity")
	if spell != "atomic" and casts.size() != 3:
		failures.append("missing_primary_casts")
	if hit_count == 0:
		failures.append("missing_primary_contacts")
	if travel < 100 or moved < 5:
		failures.append("missing_motion")
	var secondary_hits := 0
	for hits in secondary_contacts.values():
		secondary_hits += hits.size()
	if secondary < (1 if spell == "atomic" else 3) or secondary_hits == 0 or frames.size() != 240:
		failures.append("missing_casts_or_frames")
	var result = {"spell":spell,"rank":rank,"cast_route":route,"secondary_spell":"bolt" if spell == "mana_bolt" else "mana_bolt","negative_control":negative,"failures":failures,"damage_events":damage_events,"hostile_warning_samples":warnings,"primary_contacts":contacts,"primary_hit_count":hit_count,"player_travel":travel,"moving_enemies":moved,"secondary_casts":secondary,"secondary_contacts":secondary_contacts,"secondary_hits":secondary_hits,"frames":frames,"events":events,"sound_grade":"U: not heard"}
	if spell == "atomic":
		result.fixture_enemy_xp = 0.0
		result.initial_input_state = initial_input_state
		result.atomic = atomic_state
		result.atomic_hits = atomic_hits
		result.reduced_effects = args.has("reduced")
		result.rank_applicability = "Atomic is a charge-gated ability; rank does not apply"
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

func _record_atomic_damage(amount: float, position: Vector2, source: Dictionary, target_id: int):
	if str(source.get("spell", "")) == "atomic":
		atomic_hits.append({"target":target_id, "amount":amount, "position":[position.x, position.y], "source":source.duplicate(true), "movie_frame":Engine.get_frames_drawn()})

static func prepare_capture_spell(manager, spell: String, rank: int, modifiers: String = "") -> Dictionary:
	if spell == "atomic":
		if rank != 1 or not modifiers.is_empty():
			return {"error":"Atomic has no learned rank or keyword modifiers"}
		return {"kind":"style_atomic"}
	if spell == "mana_bolt":
		if not modifiers.is_empty():
			return {"error":"Modifiers are not supported for automatic Magic Missile"}
		manager.mana_bolt_level = rank
		return {"kind":"automatic_missile"}
	if spell in ["nova", "orbit", "spear", "slash", "field", "trap"] and manager.find_spell_slot(spell) <= 0:
		if rank != 1:
			return {"error":"Bare shapes have no learned rank; use rank 1 and explicit modifiers"}
		var phrase := (modifiers + " " + spell).strip_edges()
		var parsed: Dictionary = manager.parse_incantation(phrase)
		if not parsed.ok or not parsed.rejected.is_empty() or not manager.castable_generic_spells().has(parsed.spell):
			return {"error":"Invalid bare-shape incantation: " + phrase}
		return {"kind":"bare_freeform", "phrase":phrase, "rank_applicability":"Bare shapes have no learned ranks"}
	if not modifiers.is_empty():
		return {"error":"Modifiers are supported only for bare-shape capture"}
	if not manager.learn_spell(spell) and spell != "bolt":
		return {"error":"Spell not learned: " + spell}
	var slot: int = manager.find_spell_slot(spell)
	if slot <= 0:
		return {"error":"No spell slot: " + spell}
	manager.get_spell_info(slot).level = rank
	return {"kind":"learned_slot", "slot":slot}

static func release_capture_spell(manager, route: Dictionary) -> bool:
	if route.kind == "style_atomic":
		return manager.get_parent().style_session.cast_atomic()
	if route.kind == "automatic_missile":
		manager.last_generic_cast = null
		manager.fire_mana_bolt()
		return is_instance_valid(manager.last_generic_cast)
	if route.kind == "bare_freeform":
		return manager.cast_freeform_spell(route.phrase)
	return manager.cast_spell_by_type(route.slot)

func seeker_state(spirit) -> Dictionary:
	return {"age":spirit.age,"ending":spirit.spirit_ending,"returning":spirit.returning_life,"finishing":spirit.finishing_hunt,"ending_age":spirit.return_age,"done":spirit.done,"stolen_life":spirit.stolen_life,"hunted":spirit.hunted_targets.keys(),"hits":spirit.cast.hits_log.duplicate(true),"position":[spirit.global_position.x,spirit.global_position.y],"player_health":game.player.health,"movie_frame":Engine.get_frames_drawn()}

func capture_seeker_combat(stage, route: Dictionary, enemies: Array, initial_positions: Array, folder: String) -> void:
	var health_state := {"previous":float(game.player.health)}
	var heals: Array = []
	game.player.health_changed.connect(func(health, _maximum, _overheal):
		var delta: float = health - health_state.previous
		if delta > 0.0:
			var arrivals: Array = []
			for live in get_nodes_in_group("engine_spirits"):
				if live.returning_life and live.global_position.distance_to(game.player.global_position) <= 18.01:
					arrivals.append(str(live.cast.get_instance_id()))
			heals.append({"amount":delta,"arrival_casts":arrivals,"movie_frame":Engine.get_frames_drawn()})
		health_state.previous = health)
	var records := {}
	var live_casts: Array = []
	var secondary_casts: Array = []
	var secondary_contacts := {}
	var frames: Array = []
	var max_active := 0
	var triple_samples := 0
	var warnings := 0
	var travel := 0.0
	var previous: Vector2 = game.player.global_position
	var movement_start := -1
	var tail := 0
	for frame in 990:
		for action in ["move_right", "move_down", "move_left", "move_up"]:
			Input.action_release(action)
		if damage_events > 0 and movement_start < 0:
			movement_start = frame
		if movement_start >= 0:
			var moving_frame := frame - movement_start
			var leg := 30
			if moving_frame % leg < 20:
				Input.action_press(["move_right", "move_down", "move_left", "move_up"][(moving_frame / leg) % 4])
		if frame in [12, 42, 72]:
			game.spell_manager.last_generic_cast = null
			if not release_capture_spell(game.spell_manager, route) or not is_instance_valid(game.spell_manager.last_generic_cast):
				failures.append("seeker_release_failed")
				break
			var cast = game.spell_manager.last_generic_cast
			if cast.parts.size() != 1:
				failures.append("seeker_root_count")
				break
			var key := str(cast.get_instance_id())
			var spirit = cast.parts[0]
			var record := {"cast_id":key,"spirit_id":spirit.get_instance_id(),"release_frame":frame,"lifetime":spirit.total_life(),"outbound_speed":spirit.def.motion[0].speed,"ending":{},"final":{},"samples":[]}
			records[key] = record
			spirit.tree_exiting.connect(func():
				record.final = seeker_state(spirit)
				if record.ending.is_empty() and spirit.spirit_ending:
					record.ending = record.final.duplicate(true)
					record.ending["observed_at_exit_only"] = true)
			live_casts.append(cast)
			events.append({"type":"primary_cast","cast_id":key,"frame":frame,"movie_frame":Engine.get_frames_drawn()})
		if frame in [22, 300, 600]:
			game.spell_manager.last_generic_cast = null
			game.spell_manager.fire_mana_bolt()
			if is_instance_valid(game.spell_manager.last_generic_cast):
				var secondary_cast = game.spell_manager.last_generic_cast
				var secondary_key := str(secondary_cast.get_instance_id())
				secondary_casts.append(secondary_cast)
				secondary_cast.tree_exiting.connect(func(): secondary_contacts[secondary_key] = secondary_cast.hits_log.duplicate(true))
				events.append({"type":"secondary_cast","frame":frame,"movie_frame":Engine.get_frames_drawn()})
		await physics_frame
		await process_frame
		travel += game.player.global_position.distance_to(previous)
		previous = game.player.global_position
		var active := 0
		for cast in live_casts:
			if is_instance_valid(cast):
				for spirit in cast.root_parts():
					active += 1
					var record: Dictionary = records[str(cast.get_instance_id())]
					var state := seeker_state(spirit)
					if state.ending and record.ending.is_empty():
						record.ending = state.duplicate(true)
					record.samples.append(state)
		max_active = maxi(max_active, active)
		if active == 3:
			triple_samples += 1
		for cast in secondary_casts:
			if is_instance_valid(cast):
				secondary_contacts[str(cast.get_instance_id())] = cast.hits_log.duplicate(true)
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.warning > 0.0:
				warnings += 1
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if stage.get_texture().get_image().save_png("%s/%04d.png" % [folder, frame]) != OK:
			failures.append("frame_write_failed")
		frames.append({"png":frame,"movie_frame":Engine.get_frames_drawn(),"active_spirits":active,"health":game.player.health,"invincible":game.player.is_invincible,"player":[previous.x,previous.y],"camera":[game.camera.global_position.x,game.camera.global_position.y],"typing":game.spell_manager.is_typing,"time_scale":Engine.time_scale,"paused":paused,"game_state":game.current_state})
		if records.size() == 3 and records.values().all(func(record): return not record.final.is_empty()):
			tail += 1
		if tail >= 15:
			break
		if game.player.health <= 0 or game.current_state != game.GameState.PLAYING:
			failures.append("encounter_interrupted")
			break
	for action in ["move_right", "move_down", "move_left", "move_up"]:
		Input.action_release(action)
	var moved := 0
	for i in enemies.size():
		if is_instance_valid(enemies[i]) and enemies[i].global_position.distance_to(initial_positions[i]) > 10.0:
			moved += 1
	if records.size() != 3 or max_active != 3 or triple_samples < 30:
		failures.append("missing_three_distinct_concurrent_spirits")
	var healed := {}
	for heal in heals:
		if heal.arrival_casts.size() != 1:
			failures.append("heal_not_bound_to_unique_arrival")
		else:
			var key: String = heal.arrival_casts[0]
			healed[key] = float(healed.get(key, 0.0)) + float(heal.amount)
	for record in records.values():
		var ending: Dictionary = record.ending
		var final: Dictionary = record.final
		var hits: Array = final.get("hits", []).filter(func(hit): return float(hit.t) <= float(record.lifetime) + 0.00001)
		if absf(float(record.lifetime) - 24.0) > 0.02 or float(ending.get("age", 0.0)) < 24.0 or hits.size() < 3 or float(hits[-1].t) - float(hits[0].t) < 20.0:
			failures.append("incomplete_sustained_hunt_" + record.cast_id)
		if not final.get("done", false) or float(final.get("ending_age", 4.0)) >= 4.0 or not ending.get("returning", false) or final.get("hits", []).size() != hits.size():
			failures.append("missing_natural_return_" + record.cast_id)
		if float(healed.get(record.cast_id, 0.0)) <= 0.0 or float(healed.get(record.cast_id, 0.0)) > 2.001:
			failures.append("missing_capped_arrival_heal_" + record.cast_id)
	var secondary_hits := 0
	for hits in secondary_contacts.values():
		secondary_hits += hits.size()
	if damage_events == 0 or moved < 5 or travel < 500 or secondary_casts.size() != 3 or secondary_hits == 0:
		failures.append("missing_actual_mixed_combat")
	if frames.any(func(frame): return frame.invincible or frame.typing or frame.paused or not is_equal_approx(frame.time_scale, 1.0)):
		failures.append("invalid_encounter_state")
	var result := {"spell":"seeker","rank":8,"fps":30,"fixture":"Six genuine moving/attacking AI enemies with 10000 HP and zero XP; bounded movement input after actual damage; no health writes, invincibility or healing calls. Three real learned releases; no fourth-cast eviction claim.","failures":failures,"records":records,"max_active":max_active,"triple_samples":triple_samples,"damage_events":damage_events,"heals":heals,"healed_by_cast":healed,"moving_enemies":moved,"player_travel":travel,"hostile_warning_samples":warnings,"secondary_contacts":secondary_contacts,"secondary_hits":secondary_hits,"frames":frames,"events":events,"sound_grade":"U: not heard"}
	FileAccess.open(folder + "/manifest.json", FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("SEEKER_COMBAT ",JSON.stringify({"failures":failures,"max_active":max_active,"healed":healed,"damage_events":damage_events,"moving":moved,"frames":frames.size()}))
	live_casts.clear()
	secondary_casts.clear()
	stage.queue_free()
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
